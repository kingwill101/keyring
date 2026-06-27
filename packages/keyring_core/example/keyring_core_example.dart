// ignore_for_file: avoid_print, prefer_const_constructors

import 'dart:collection';

import 'package:keyring_core/keyring_core.dart';

/// Demonstrates core types: [KeyringEntry], [KeyringException], and how to
/// extend [KeyringStore] with a custom implementation.
///
/// Usage: `dart run example/keyring_core_example.dart`
Future<void> main() async {
  // --- KeyringEntry ---------------------------------------------------------

  const entry = KeyringEntry('my-app', 'alice');
  print('Entry: $entry');

  const withMods = KeyringEntry.withModifiers(
    'my-app',
    'bob',
    {'env': 'production'},
  );
  print('Entry with modifiers: $withMods');
  assert(withMods.modifiers != null);
  assert(withMods.modifiers!['env'] == 'production');

  // --- KeyringException ----------------------------------------------------

  try {
    throw const KeyringException(
      KeyringErrorType.noEntry,
      'Credential not found',
    );
  } on KeyringException catch (e) {
    print('Caught: $e');
    assert(e.type == KeyringErrorType.noEntry);
    assert(e.message == 'Credential not found');
  }

  // --- Custom KeyringStore -------------------------------------------------

  final store = _ExampleStore();
  final alice = KeyringEntry('my-app', 'alice');

  await store.setPassword(alice, 's3cret!');
  print('Stored password: ${await store.getPassword(alice)}');

  await store.setSecret(alice, [0x01, 0x02, 0x03]);
  print('Stored secret: ${await store.getSecret(alice)}');

  print('Attributes: ${await store.getAttributes(alice)}');

  await store.updateAttributes(alice, {'role': 'admin'});
  print('After update: ${await store.getAttributes(alice)}');

  await store.deleteCredential(alice);
  print('Deleted credential');

  try {
    await store.getPassword(alice);
  } on KeyringException catch (e) {
    print('Expected error after delete: $e');
    assert(e.type == KeyringErrorType.noEntry);
  }

  // --- Search --------------------------------------------------------------

  await store.setPassword(KeyringEntry('app1', 'user1'), 'pw1');
  await store.setPassword(KeyringEntry('app2', 'user2'), 'pw2');
  await store.setPassword(KeyringEntry('app1', 'user3'), 'pw3');

  final results = await store.search({'service': 'app1'});
  print('Search found ${results.length} entries for "app1"');

  // --- CredentialPersistence -----------------------------------------------

  print('Persistence: ${store.persistence}');
  print('Vendor: ${store.vendor}');
  print('Id: ${store.id}');
}

/// A minimal in-memory [KeyringStore] for demonstration.
class _ExampleStore extends KeyringStore {
  final _store = HashMap<String, HashMap<String, _Credential>>();

  @override
  String get vendor => 'Example';

  @override
  String get id => 'example-1.0.0';

  @override
  CredentialPersistence get persistence => CredentialPersistence.untilDelete;

  @override
  Future<KeyringEntry> build(String service, String user,
          {Map<String, String>? modifiers}) async =>
      KeyringEntry(service, user, modifiers: modifiers);

  @override
  Future<List<KeyringEntry>> search(Map<String, String> spec) async {
    final out = <KeyringEntry>[];
    for (final svc in _store.keys) {
      if (spec.containsKey('service') && !svc.contains(spec['service']!)) {
        continue;
      }
      for (final usr in _store[svc]!.keys) {
        if (spec.containsKey('user') && !usr.contains(spec['user']!)) {
          continue;
        }
        out.add(KeyringEntry(svc, usr));
      }
    }
    return out;
  }

  @override
  Future<void> setPassword(KeyringEntry entry, String password) async =>
      _cred(entry).password = password;

  @override
  Future<String> getPassword(KeyringEntry entry) async =>
      _cred(entry).password;

  @override
  Future<void> setSecret(KeyringEntry entry, List<int> secret) async =>
      _cred(entry).secret = List.of(secret);

  @override
  Future<List<int>> getSecret(KeyringEntry entry) async =>
      List.of(_cred(entry).secret);

  @override
  Future<void> deleteCredential(KeyringEntry entry) async {
    final users = _store[entry.service];
    if (users == null || !users.containsKey(entry.user)) {
      throw const KeyringException(KeyringErrorType.noEntry, 'Not found');
    }
    users.remove(entry.user);
    if (users.isEmpty) _store.remove(entry.service);
  }

  @override
  Future<Map<String, String>> getAttributes(KeyringEntry entry) async =>
      Map.of(_cred(entry).attributes);

  @override
  Future<void> updateAttributes(
          KeyringEntry entry, Map<String, String> attributes) async =>
      _cred(entry).attributes.addAll(attributes);

  _Credential _cred(KeyringEntry entry) {
    final users = _store.putIfAbsent(
        entry.service, () => HashMap<String, _Credential>());
    return users.putIfAbsent(entry.user, () => _Credential());
  }
}

class _Credential {
  String password = '';
  List<int> secret = [];
  final attributes = <String, String>{};
}
