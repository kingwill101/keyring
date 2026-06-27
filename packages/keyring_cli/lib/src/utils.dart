import 'dart:convert';
import 'dart:io';

import 'package:keyring/keyring.dart';
import 'package:keyring_native/keyring_native.dart';
import 'package:keyring_web/keyring_web.dart';

/// Resolves a module [name] to a `KeyringStore` and sets it as the default.
///
/// Known stores:
/// - `sample` / `web` → [WebKeyringStore]
/// - `keychain`, `secret-service`, `zbus-secret-service`, `dbus-secret-service`,
///   `keyutils`, `linux-keyutils`, `windows`, `windows-native`, `protected`,
///   `apple-native`, `apple-protected` → [NativeKeyringStore]
Future<void> setDefaultStoreByName(String name) async {
  final lower = name.toLowerCase();
  switch (lower) {
    case 'sample':
    case 'web':
      setDefaultStore(WebKeyringStore());
    case 'keychain':
    case 'apple-native':
    case 'secret-service':
    case 'zbus-secret-service':
    case 'dbus-secret-service':
    case 'keyutils':
    case 'linux-keyutils':
    case 'windows':
    case 'windows-native':
    case 'protected':
    case 'apple-protected':
      setDefaultStore(NativeKeyringStore());
    default:
      throw Exception(
        'Unknown store "$name". Known stores: sample, keychain, apple-protected, '
        'secret-service, dbus-secret-service, keyutils, windows, web',
      );
  }
}

/// Reads a password from stdin without echoing.
///
/// Disables echo mode, reads a single line, then restores echo. Returns an
/// empty string if no input is provided.
///
/// Works on all platforms that support `stdin.echoMode`.
String readPassword() {
  try {
    stdout.write('Password: ');
    stdin.lineMode = false;
    stdin.echoMode = false;
    final password = stdin.readLineSync() ?? '';
    return password;
  } finally {
    stdin.echoMode = true;
    stdin.lineMode = true;
  }
}

/// Decodes a [base64][base64]-encoded [encoded] string into its raw bytes.
///
/// Exits the process with code 1 if decoding fails.
///
/// [base64]: https://en.wikipedia.org/wiki/Base64
List<int> decodeBase64(String encoded) {
  if (encoded.isEmpty) return [];
  try {
    return base64Decode(encoded);
  } catch (e) {
    stderr.writeln('Sorry, the provided secret data is not base64-encoded: $e');
    exit(1);
  }
}

/// Parses a comma-separated string of `key=value` pairs.
///
/// Example: `"env=prod,region=us-east-1"` → `{'env': 'prod', 'region': 'us-east-1'}`.
///
/// Exits the process with code 1 if any token is not a valid `key=value` pair.
Map<String, String> parseAttributes(String input) {
  final attributes = <String, String>{};
  if (input.isEmpty) return attributes;

  final parts = input.split(',');
  for (final part in parts) {
    final kv = part.split('=');
    if (kv.length != 2 || kv[0].isEmpty) {
      stderr.writeln('Sorry, this part of the attributes string is not a key=val pair: $part');
      exit(1);
    }
    attributes[kv[0]] = kv[1];
  }
  return attributes;
}
