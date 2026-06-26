import 'package:keyring/keyring.dart';
import 'package:keyring_core/keyring_core.dart';
import 'package:test/test.dart';

class _MockStore extends KeyringStore {
  String? _password;
  List<int>? _secret;
  final _attributes = <String, String>{};
  final _entries = <String>{};

  @override
  String get vendor => 'MockStore';

  @override
  String get id => 'mock-1.0.0';

  @override
  CredentialPersistence get persistence => CredentialPersistence.untilDelete;

  @override
  Future<KeyringEntry> build(String service, String user,
      {Map<String, String>? modifiers}) async {
    _entries.add('$service:$user');
    return KeyringEntry(service, user, modifiers: modifiers);
  }

  @override
  Future<void> setPassword(KeyringEntry entry, String password) async {
    _password = password;
  }

  @override
  Future<String> getPassword(KeyringEntry entry) async {
    if (_password == null) throw const KeyringException(KeyringErrorType.noEntry, '');
    return _password!;
  }

  @override
  Future<void> setSecret(KeyringEntry entry, List<int> secret) async {
    _secret = List.of(secret);
  }

  @override
  Future<List<int>> getSecret(KeyringEntry entry) async {
    if (_secret == null) throw const KeyringException(KeyringErrorType.noEntry, '');
    return List.of(_secret!);
  }

  @override
  Future<void> deleteCredential(KeyringEntry entry) async {
    _password = null;
    _secret = null;
  }

  @override
  Future<Map<String, String>> getAttributes(KeyringEntry entry) async {
    return Map.of(_attributes);
  }

  @override
  Future<void> updateAttributes(
      KeyringEntry entry, Map<String, String> attributes) async {
    _attributes.addAll(attributes);
  }

  @override
  Future<List<KeyringEntry>> search(Map<String, String> spec) async {
    return [];
  }
}

void main() {
  late _MockStore mock;

  setUp(() {
    mock = _MockStore();
    setDefaultStore(mock);
  });

  group('top-level convenience API', () {
    test('setDefaultStore replaces the default store', () {
      expect(defaultStore, mock);
    });

    test('buildEntry delegates to store', () async {
      final entry = await buildEntry('app', 'user');
      expect(entry.service, 'app');
      expect(entry.user, 'user');
    });

    test('setPassword / getPassword round trip', () async {
      final entry = const KeyringEntry('app', 'user');
      await setPassword(entry, 'secret');
      final result = await getPassword(entry);
      expect(result, 'secret');
    });

    test('setSecret / getSecret round trip', () async {
      final entry = const KeyringEntry('app', 'user');
      await setSecret(entry, [1, 2, 3]);
      final result = await getSecret(entry);
      expect(result, [1, 2, 3]);
    });

    test('deleteCredential delegates to store', () async {
      final entry = const KeyringEntry('app', 'user');
      await setPassword(entry, 'pw');
      await deleteCredential(entry);
      // After deletion, getPassword should throw
      expect(
        () => getPassword(entry),
        throwsA(isA<KeyringException>()),
      );
    });

    test('getAttributes / updateAttributes round trip', () async {
      final entry = const KeyringEntry('app', 'user');
      await setPassword(entry, 'pw');
      await updateAttributes(entry, {'label': 'test'});
      final attrs = await getAttributes(entry);
      expect(attrs['label'], 'test');
    });

    test('searchEntries delegates to store', () async {
      final results = await searchEntries({'service': 'app'});
      expect(results, isEmpty);
    });
  });

  group('re-exports from keyring_core', () {
    test('KeyringEntry is available', () {
      final entry = const KeyringEntry('app', 'user');
      expect(entry, isA<KeyringEntry>());
    });

    test('KeyringException is available', () {
      final exc = const KeyringException(KeyringErrorType.noEntry, 'test');
      expect(exc, isA<KeyringException>());
    });

    test('CredentialPersistence is available', () {
      expect(CredentialPersistence.untilDelete, isA<CredentialPersistence>());
    });
  });
}
