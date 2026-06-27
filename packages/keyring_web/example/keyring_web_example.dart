// ignore_for_file: avoid_print, prefer_const_constructors

import 'package:keyring_core/keyring_core.dart';
import 'package:keyring_web/keyring_web.dart';

/// Demonstrates [WebKeyringStore] CRUD operations.
///
/// Usage: `dart run example/keyring_web_example.dart`
Future<void> main() async {
  final store = WebKeyringStore();
  final entry = KeyringEntry('my-app', 'alice');

  // --- set / get Password --------------------------------------------------

  await store.setPassword(entry, 's3cret!');
  final password = await store.getPassword(entry);
  print('Password: $password');

  // --- set / get Secret (binary) -------------------------------------------

  await store.setSecret(entry, [0xDE, 0xAD, 0xBE, 0xEF]);
  final secret = await store.getSecret(entry);
  print('Secret bytes: $secret');

  // --- Attributes ----------------------------------------------------------

  await store.updateAttributes(entry, {
    'env': 'production',
    'region': 'us-east-1',
  });
  final attrs = await store.getAttributes(entry);
  print('Attributes: $attrs');

  // --- Delete --------------------------------------------------------------

  await store.deleteCredential(entry);

  try {
    await store.getPassword(entry);
  } on KeyringException catch (e) {
    print('After delete: $e');
  }

  // --- Search --------------------------------------------------------------

  await store.setPassword(KeyringEntry('app1', 'alice'), 'pw-a');
  await store.setPassword(KeyringEntry('app2', 'bob'), 'pw-b');
  await store.setPassword(KeyringEntry('app1', 'charlie'), 'pw-c');

  final results = await store.search({'service': 'app1'});
  print('Search for "app1": ${results.length} entries');

  // --- Store properties ----------------------------------------------------

  print('Vendor: ${store.vendor}');
  print('Id: ${store.id}');
  print('Persistence: ${store.persistence}');

  // --- Build entry with modifiers ------------------------------------------

  final custom = await store.build('my-app', 'dave', modifiers: {
    'target': 'custom-key',
  });
  await store.setPassword(custom, 'custom-pw');
  print('Custom entry: $custom');
}
