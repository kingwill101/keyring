import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:artisanal/args.dart';
import 'package:keyring/keyring.dart';

import 'utils.dart';

/// Command-line interface for reading and writing credentials.
///
/// Wraps the `keyring` package's `KeyringStore` API in a
/// [CommandRunner]-based CLI with subcommands mirroring the Rust
/// `keyring-rs` CLI.
///
/// Global options:
/// - `--module` / `-m` — the credential store backend to use
/// - `--service` / `-s` — the service name for the target entry
/// - `--user` / `-u` — the user name for the target entry
class KeyringCli extends CommandRunner<void> {
  KeyringCli()
      : super(
          'keyring_cli',
          'Read and write credentials in platform secure storage.',
        ) {
    argParser
      ..addOption('module', abbr: 'm', help: 'The credential store module to use.', defaultsTo: 'sample')
      ..addOption('service', abbr: 's', help: 'The service for the entry.', defaultsTo: 'keyring-cli')
      ..addOption('user', abbr: 'u', help: 'The user for the entry.', defaultsTo: 'keyring-user');

    addCommand(InfoCommand());
    addCommand(PasswordCommand());
    addCommand(SecretCommand());
    addCommand(AttributesCommand());
    addCommand(CredentialCommand());
    addCommand(SetCommand());
    addCommand(DeleteCommand());
    addCommand(SearchCommand());
  }
}

/// Mixin that resolves the global `--module`, `--service`, and `--user`
/// options and runs credential operations against the selected store.
///
/// Wraps errors in structured [KeyringException] handling and prints
/// user-friendly error messages via [error] from artisanal.
mixin StoreMixin on Command<void> {
  String get _module => globalResults!['module'] as String;
  String get _service => globalResults!['service'] as String;
  String get _user => globalResults!['user'] as String;
  String get _description => '$_user@$_service';

  Future<void> _useStore() => setDefaultStoreByName(_module);

  Future<void> _runWithStore(Future<void> Function(KeyringEntry entry) fn) async {
    try {
      await _useStore();
      await fn(KeyringEntry(_service, _user));
    } on KeyringException catch (e) {
      _fail(e);
    }
  }

  Never _fail(KeyringException e) {
    switch (e.type) {
      case KeyringErrorType.noEntry:
        error("No credential found for '$_description'");
      case KeyringErrorType.ambiguous:
        error("More than one credential found for '$_description':\n${e.message}");
      default:
        error("Couldn't complete operation for '$_description': $e");
    }
    exit(1);
  }
}

/// Displays information about the active store and target entry.
class InfoCommand extends Command<void> with StoreMixin {
  @override
  final name = 'info';
  @override
  final description = 'Show info about the store and entry in use.';

  @override
  FutureOr<void> run() async {
    await _runWithStore((_) async {
      line('Store info: $defaultStore');
      line('Entry info: ${KeyringEntry(_service, _user)}');
    });
  }
}

/// Retrieves a stored password and prints it to stdout.
class PasswordCommand extends Command<void> with StoreMixin {
  @override
  final name = 'password';
  @override
  final description = 'Retrieve the password from the secure store.';

  @override
  FutureOr<void> run() async {
    await _runWithStore((entry) async {
      line(await getPassword(entry));
    });
  }
}

/// Retrieves a stored binary secret as a base64-encoded string.
class SecretCommand extends Command<void> with StoreMixin {
  @override
  final name = 'secret';
  @override
  final description = 'Retrieve the binary secret from the secure store as base64.';

  @override
  FutureOr<void> run() async {
    await _runWithStore((entry) async {
      line(base64Encode(await getSecret(entry)));
    });
  }
}

/// Retrieves and displays credential attributes.
class AttributesCommand extends Command<void> with StoreMixin {
  @override
  final name = 'attributes';
  @override
  final description = 'Retrieve attributes from the secure store.';

  @override
  FutureOr<void> run() async {
    await _runWithStore((entry) async {
      final attrs = await getAttributes(entry);
      if (attrs.isEmpty) {
        line("No attributes found for '$_description'");
      } else {
        line("Attributes for '$_description' are:");
        for (final a in attrs.entries) {
          line('    ${a.key}: ${a.value}');
        }
      }
    });
  }
}

/// Retrieves and displays a credential reference for the target entry.
class CredentialCommand extends Command<void> with StoreMixin {
  @override
  final name = 'credential';
  @override
  final description = 'Retrieve the credential from the secure store.';

  @override
  FutureOr<void> run() async {
    await _runWithStore((_) async {
      final credential = await defaultStore.build(_service, _user);
      line("Credential for '$_description' is: $credential");
    });
  }
}

/// Stores a password, binary blob, or attributes for the target entry.
///
/// Exactly one of `--password`, `--blob`, or `--attributes` must be specified.
/// If `--input` is omitted, the value is read interactively from stdin.
class SetCommand extends Command<void> with StoreMixin {
  SetCommand() {
    argParser
      ..addFlag('password', abbr: 'p', help: 'The input is a utf8-encoded password.')
      ..addFlag('blob', abbr: 'b', help: 'The input is a base64-encoded blob.')
      ..addFlag('attributes', abbr: 'a', help: 'The input is comma-separated, key=val attribute pairs.')
      ..addOption('input', help: 'The input value. If not specified, read interactively.');
  }

  @override
  final name = 'set';
  @override
  final description = 'Set the password, secret, or attributes in the secure store.';

  @override
  FutureOr<void> run() async {
    await _runWithStore((entry) async {
      final password = argResults!['password'] as bool? ?? false;
      final blob = argResults!['blob'] as bool? ?? false;
      final attrs = argResults!['attributes'] as bool? ?? false;
      final input = argResults!['input'] as String?;

      if (password) {
        final value = input ?? _readPassword();
        await setPassword(entry, value);
        line("Set password for '$_description' to '$value'");
      } else if (blob) {
        final encoded = input ?? _readBlob();
        await setSecret(entry, decodeBase64(encoded));
        line("Set secret for '$_description' to decode of '$encoded'");
      } else if (attrs) {
        final parsed = parseAttributes(input ?? _readAttrs());
        await updateAttributes(entry, parsed);
        line("The following attributes for '$_description' were sent for update:");
        for (final a in parsed.entries) {
          line('    ${a.key}: ${a.value}');
        }
      } else {
        _fail(const KeyringException(KeyringErrorType.invalid, 'Must specify one of --password, --blob, or --attributes.'));
      }
    });
  }

  String _readPassword() {
    stdout.write('Password: ');
    stdin.lineMode = false;
    stdin.echoMode = false;
    try {
      return stdin.readLineSync() ?? '';
    } finally {
      stdin.echoMode = true;
      stdin.lineMode = true;
    }
  }

  String _readBlob() {
    stdout.write('Base64 encoding: ');
    return stdin.readLineSync() ?? '';
  }

  String _readAttrs() {
    stdout.write('Attributes: ');
    final input = stdin.readLineSync() ?? '';
    if (input.isEmpty) {
      error('You must specify at least one key=value attribute pair.');
      exit(1);
    }
    return input;
  }
}

/// Deletes a credential from secure storage.
class DeleteCommand extends Command<void> with StoreMixin {
  @override
  final name = 'delete';
  @override
  final description = 'Delete the credential from the secure store.';

  @override
  FutureOr<void> run() async {
    await _runWithStore((entry) async {
      await deleteCredential(entry);
      line("Successfully deleted credential for '$_description'");
    });
  }
}

/// Searches for credentials matching a query specification.
///
/// The `--query` option accepts comma-separated `key=value` pairs.
class SearchCommand extends Command<void> with StoreMixin {
  SearchCommand() {
    argParser.addOption('query', abbr: 'q', help: 'The query spec: key1=value1,key2=value2');
  }

  @override
  final name = 'search';
  @override
  final description = 'Search for credentials in the secure store.';

  @override
  FutureOr<void> run() async {
    await _runWithStore((_) async {
      final query = argResults!['query'] as String?;
      final spec = query != null ? parseAttributes(query) : <String, String>{};
      final results = await searchEntries(spec);
      final suffix = query != null ? " matching '$query'" : '';
      if (results.isEmpty) {
        line('No credentials found$suffix');
      } else {
        final word = results.length > 1 ? 'credentials' : 'credential';
        line('Search found ${results.length} $word$suffix:');
        for (var i = 0; i < results.length; i++) {
          line('${(i + 1).toString().padLeft(6)}: ${results[i]}');
        }
      }
    });
  }
}
