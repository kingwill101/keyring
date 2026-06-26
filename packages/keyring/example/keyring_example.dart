import 'dart:io' show Platform;

import 'package:keyring/keyring.dart';
import 'package:keyring_core/keyring_core.dart';
import 'package:keyring_native/keyring_native.dart';
import 'package:keyring_web/keyring_web.dart';

/// A simple example demonstrating the keyring API across platforms.
///
/// - Linux:  linux-keyutils (kernel keyring)
/// - Windows: Windows Credential Manager
/// - macOS:   in-memory store (native keychain support pending)
/// - Web:     in-memory store
///
/// Usage: `dart run example/keyring_example.dart`
Future<void> main() async {
  try {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      setDefaultStore(NativeKeyringStore());
      print('Using native store');
    } else {
      setDefaultStore(WebKeyringStore());
      print('Using in-memory store');
    }
  } catch (_) {
    setDefaultStore(WebKeyringStore());
    print('Falling back to in-memory store');
  }

  final service = 'my_app';
  final user = 'alice';
  final entry = KeyringEntry(service, user);

  await setPassword(entry, 'sup3r_s3cr3t');
  print('Stored password for $service/$user');

  final retrieved = await getPassword(entry);
  print('Retrieved password: $retrieved');

  try {
    await updateAttributes(entry, {
      'description': 'My app login',
      'created': '2025-01-01',
    });
  } on KeyringException catch (e) {
    if (e.type == KeyringErrorType.notSupported) {
      print('Attributes update not supported by this backend: ${e.message}');
    } else {
      rethrow;
    }
  }
  final attrs = await getAttributes(entry);
  print('Attributes: $attrs');

  final secret = [0x01, 0x02, 0x03, 0x04];
  await setSecret(entry, secret);
  final got = await getSecret(entry);
  print('Secret bytes: $got');

  List<KeyringEntry> results;
  try {
    results = await searchEntries({'service': 'my_app'});
  } on KeyringException catch (e) {
    if (e.type == KeyringErrorType.notSupported) {
      results = const [];
      print('Search not supported by this backend: ${e.message}');
    } else {
      rethrow;
    }
  }
  print('Search results: ${results.length} entries');

  await deleteCredential(entry);
  print('Deleted credential');

  try {
    await getPassword(entry);
  } on KeyringException catch (e) {
    if (e.type == KeyringErrorType.noEntry) {
      print('Confirmed: no entry after deletion');
    }
  }
}
