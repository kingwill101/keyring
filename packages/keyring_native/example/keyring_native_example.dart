// ignore_for_file: avoid_print, prefer_const_constructors

import 'package:keyring_core/keyring_core.dart';
import 'package:keyring_native/keyring_native.dart';

/// Demonstrates [NativeKeyringStore] CRUD operations.
///
/// Falls back to an in-memory store when the native library is unavailable
/// (e.g., on platforms without a keyring backend).
///
/// Usage: `dart run example/keyring_native_example.dart`
Future<void> main() async {
  // --- Initialization ------------------------------------------------------

  late final KeyringStore store;
  try {
    store = NativeKeyringStore();
    print('Store vendor: ${store.vendor}');
  } catch (e) {
    print('Native store unavailable ($e), cannot demonstrate.');
    return;
  }

  final entry = KeyringEntry('keyring-native-example', 'alice');

  // --- set / get Password --------------------------------------------------

  await store.setPassword(entry, 's3cret!');
  final password = await store.getPassword(entry);
  print('Password: $password');

  // --- set / get Secret (binary) -------------------------------------------

  await store.setSecret(entry, [0xDE, 0xAD, 0xBE, 0xEF]);
  final secret = await store.getSecret(entry);
  print('Secret bytes: $secret');

  // --- Attributes ----------------------------------------------------------

  try {
    await store.updateAttributes(entry, {
      'env': 'production',
      'region': 'us-east-1',
    });
    final attrs = await store.getAttributes(entry);
    print('Attributes: $attrs');
  } on KeyringException catch (e) {
    if (e.type == KeyringErrorType.notSupported) {
      print('Attributes not supported: ${e.message}');
    } else {
      rethrow;
    }
  }

  // --- Search --------------------------------------------------------------

  try {
    final results = await store.search({'service': 'keyring-native-example'});
    print('Search: ${results.length} entries');
  } on KeyringException catch (e) {
    if (e.type == KeyringErrorType.notSupported) {
      print('Search not supported: ${e.message}');
    } else {
      rethrow;
    }
  }

  // --- Delete --------------------------------------------------------------

  await store.deleteCredential(entry);
  print('Deleted credential');

  try {
    await store.getPassword(entry);
  } on KeyringException catch (e) {
    print('Verified: ${e.type}');
  }

  print('Persistence: ${store.persistence}');
}
