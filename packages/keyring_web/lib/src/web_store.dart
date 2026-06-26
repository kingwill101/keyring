import 'dart:collection';
import 'dart:convert';

import 'package:keyring_core/keyring_core.dart';

class _Credential {
  List<int> secret;
  Map<String, String> attributes;

  _Credential(this.secret, {Map<String, String>? attributes})
      : attributes = attributes ?? <String, String>{};
}

class WebKeyringStore extends KeyringStore {
  final _store = HashMap<String, HashMap<String, _Credential>>();

  @override
  String get vendor => 'Web (in-memory)';

  @override
  String get id => 'keyring-web-1.0.0';

  @override
  CredentialPersistence get persistence => CredentialPersistence.untilDelete;

  @override
  Future<KeyringEntry> build(String service, String user,
      {Map<String, String>? modifiers}) async {
    return KeyringEntry(service, user, modifiers: modifiers);
  }

  @override
  Future<List<KeyringEntry>> search(Map<String, String> spec) async {
    final results = <KeyringEntry>[];
    final serviceFilter = spec['service'];
    final userFilter = spec['user'];
    for (final svc in _store.keys) {
      if (serviceFilter != null && !svc.contains(serviceFilter)) continue;
      for (final usr in _store[svc]!.keys) {
        if (userFilter != null && !usr.contains(userFilter)) continue;
        results.add(KeyringEntry(svc, usr));
      }
    }
    return results;
  }

  @override
  Future<void> setPassword(KeyringEntry entry, String password) async {
    final bytes = utf8.encode(password);
    await setSecret(entry, bytes);
  }

  @override
  Future<String> getPassword(KeyringEntry entry) async {
    final bytes = await getSecret(entry);
    return utf8.decode(bytes);
  }

  @override
  Future<void> setSecret(KeyringEntry entry, List<int> secret) async {
    final serviceUsers = _store.putIfAbsent(
        entry.service, () => HashMap<String, _Credential>());
    final existing = serviceUsers[entry.user];
    if (existing != null) {
      existing.secret = List.of(secret);
    } else {
      serviceUsers[entry.user] = _Credential(List.of(secret));
    }
  }

  @override
  Future<List<int>> getSecret(KeyringEntry entry) async {
    final serviceUsers = _store[entry.service];
    if (serviceUsers == null) {
      throw const KeyringException(KeyringErrorType.noEntry, 'No entry found');
    }
    final cred = serviceUsers[entry.user];
    if (cred == null) {
      throw const KeyringException(KeyringErrorType.noEntry, 'No entry found');
    }
    return List.of(cred.secret);
  }

  @override
  Future<void> deleteCredential(KeyringEntry entry) async {
    final serviceUsers = _store[entry.service];
    if (serviceUsers == null || !serviceUsers.containsKey(entry.user)) {
      throw const KeyringException(KeyringErrorType.noEntry, 'No entry found');
    }
    serviceUsers.remove(entry.user);
    if (serviceUsers.isEmpty) {
      _store.remove(entry.service);
    }
  }

  @override
  Future<Map<String, String>> getAttributes(KeyringEntry entry) async {
    final serviceUsers = _store[entry.service];
    if (serviceUsers == null) {
      throw const KeyringException(KeyringErrorType.noEntry, 'No entry found');
    }
    final cred = serviceUsers[entry.user];
    if (cred == null) {
      throw const KeyringException(KeyringErrorType.noEntry, 'No entry found');
    }
    return Map.of(cred.attributes);
  }

  @override
  Future<void> updateAttributes(
      KeyringEntry entry, Map<String, String> attributes) async {
    final serviceUsers = _store[entry.service];
    if (serviceUsers == null) {
      throw const KeyringException(KeyringErrorType.noEntry, 'No entry found');
    }
    final cred = serviceUsers[entry.user];
    if (cred == null) {
      throw const KeyringException(KeyringErrorType.noEntry, 'No entry found');
    }
    cred.attributes.addAll(attributes);
  }
}
