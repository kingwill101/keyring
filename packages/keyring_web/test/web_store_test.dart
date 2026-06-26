import 'package:keyring_core/keyring_core.dart';
import 'package:keyring_web/keyring_web.dart';
import 'package:test/test.dart';

void main() {
  late WebKeyringStore store;

  setUp(() {
    store = WebKeyringStore();
  });

  group('WebKeyringStore', () {
    test('vendor returns expected string', () {
      expect(store.vendor, 'Web (in-memory)');
    });

    test('id returns expected string', () {
      expect(store.id, 'keyring-web-1.0.0');
    });

    test('persistence returns untilDelete', () {
      expect(store.persistence, CredentialPersistence.untilDelete);
    });

    group('setPassword / getPassword', () {
      test('round trip succeeds', () async {
        final entry = await store.build('test_app', 'alice');
        await store.setPassword(entry, 'secret123');
        final result = await store.getPassword(entry);
        expect(result, 'secret123');
      });

      test('getPassword throws on missing entry', () async {
        final entry = await store.build('missing', 'user');
        expect(
          () => store.getPassword(entry),
          throwsA(isA<KeyringException>()),
        );
      });

      test('overwrite existing password', () async {
        final entry = await store.build('test_app', 'alice');
        await store.setPassword(entry, 'first');
        await store.setPassword(entry, 'second');
        final result = await store.getPassword(entry);
        expect(result, 'second');
      });

      test('empty password is allowed', () async {
        final entry = await store.build('test_app', 'alice');
        await store.setPassword(entry, '');
        final result = await store.getPassword(entry);
        expect(result, '');
      });

      test('unicode password round trips', () async {
        final entry = await store.build('test_app', 'alice');
        await store.setPassword(entry, 'このきれいな花は桜です');
        final result = await store.getPassword(entry);
        expect(result, 'このきれいな花は桜です');
      });
    });

    group('setSecret / getSecret', () {
      test('round trip succeeds', () async {
        final entry = await store.build('test_app', 'bob');
        final secret = [1, 2, 3, 4, 5];
        await store.setSecret(entry, secret);
        final result = await store.getSecret(entry);
        expect(result, [1, 2, 3, 4, 5]);
      });

      test('getSecret returns a copy, not a reference', () async {
        final entry = await store.build('test_app', 'bob');
        await store.setSecret(entry, [1, 2, 3]);
        final result = await store.getSecret(entry);
        result.add(4);
        final again = await store.getSecret(entry);
        expect(again, [1, 2, 3]);
      });

      test('getSecret throws on missing entry', () async {
        final entry = await store.build('missing', 'user');
        expect(
          () => store.getSecret(entry),
          throwsA(isA<KeyringException>()),
        );
      });

      test('empty secret is allowed', () async {
        final entry = await store.build('test_app', 'bob');
        await store.setSecret(entry, []);
        final result = await store.getSecret(entry);
        expect(result, []);
      });
    });

    group('deleteCredential', () {
      test('deletes existing credential', () async {
        final entry = await store.build('test_app', 'alice');
        await store.setPassword(entry, 'secret');
        await store.deleteCredential(entry);
        expect(
          () => store.getPassword(entry),
          throwsA(isA<KeyringException>()),
        );
      });

      test('throws on missing credential', () async {
        final entry = await store.build('test_app', 'nobody');
        expect(
          () => store.deleteCredential(entry),
          throwsA(isA<KeyringException>()),
        );
      });

      test('delete only affects the targeted entry', () async {
        final entry1 = await store.build('app', 'user1');
        final entry2 = await store.build('app', 'user2');
        await store.setPassword(entry1, 'pw1');
        await store.setPassword(entry2, 'pw2');
        await store.deleteCredential(entry1);
        expect(await store.getPassword(entry2), 'pw2');
      });
    });

    group('getAttributes / updateAttributes', () {
      test('getAttributes returns empty map initially', () async {
        final entry = await store.build('app', 'user');
        await store.setPassword(entry, 'pw');
        final attrs = await store.getAttributes(entry);
        expect(attrs, isEmpty);
      });

      test('getAttributes throws on missing entry', () async {
        final entry = await store.build('missing', 'user');
        expect(
          () => store.getAttributes(entry),
          throwsA(isA<KeyringException>()),
        );
      });

      test('updateAttributes adds new attributes', () async {
        final entry = await store.build('app', 'user');
        await store.setPassword(entry, 'pw');
        await store.updateAttributes(entry, {
          'label': 'test',
          'comment': 'hello',
        });
        final attrs = await store.getAttributes(entry);
        expect(attrs['label'], 'test');
        expect(attrs['comment'], 'hello');
      });

      test('updateAttributes merges with existing attributes', () async {
        final entry = await store.build('app', 'user');
        await store.setPassword(entry, 'pw');
        await store.updateAttributes(entry, {'a': '1'});
        await store.updateAttributes(entry, {'b': '2'});
        final attrs = await store.getAttributes(entry);
        expect(attrs['a'], '1');
        expect(attrs['b'], '2');
      });

      test('updateAttributes overwrites existing keys', () async {
        final entry = await store.build('app', 'user');
        await store.setPassword(entry, 'pw');
        await store.updateAttributes(entry, {'label': 'old'});
        await store.updateAttributes(entry, {'label': 'new'});
        final attrs = await store.getAttributes(entry);
        expect(attrs['label'], 'new');
      });
    });

    group('search', () {
      test('returns empty list when no entries match', () async {
        final results = await store.search({'service': 'nonexistent'});
        expect(results, isEmpty);
      });

      test('finds entries by exact service match', () async {
        final entry = await store.build('myapp', 'alice');
        await store.setPassword(entry, 'pw');
        final results = await store.search({'service': 'myapp'});
        expect(results, hasLength(1));
        expect(results.first.service, 'myapp');
        expect(results.first.user, 'alice');
      });

      test('filters by service substring', () async {
        await store.build('myapp', 'a').then((e) => store.setPassword(e, 'p'));
        await store.build('myapp', 'b').then((e) => store.setPassword(e, 'p'));
        await store.build('other', 'c').then((e) => store.setPassword(e, 'p'));
        final results = await store.search({'service': 'myapp'});
        expect(results, hasLength(2));
      });

      test('filters by both service and user', () async {
        await store.build('myapp', 'alice').then((e) => store.setPassword(e, 'p'));
        await store.build('myapp', 'bob').then((e) => store.setPassword(e, 'p'));
        final results = await store.search({'service': 'myapp', 'user': 'bob'});
        expect(results, hasLength(1));
        expect(results.first.user, 'bob');
      });

      test('returns only entries with stored credentials', () async {
        final entry = await store.build('empty', 'entry');
        var results = await store.search({'service': 'empty'});
        expect(results, isEmpty);
        await store.setPassword(entry, 'pw');
        results = await store.search({'service': 'empty'});
        expect(results, hasLength(1));
      });
    });

    group('clean isolation between entries', () {
      test('credentials do not leak between services', () async {
        final e1 = await store.build('svc1', 'user');
        final e2 = await store.build('svc2', 'user');
        await store.setPassword(e1, 'pw1');
        await store.setPassword(e2, 'pw2');
        expect(await store.getPassword(e1), 'pw1');
        expect(await store.getPassword(e2), 'pw2');
      });

      test('credentials do not leak between users', () async {
        final e1 = await store.build('svc', 'alice');
        final e2 = await store.build('svc', 'bob');
        await store.setPassword(e1, 'pw_alice');
        expect(await store.getPassword(e1), 'pw_alice');
        expect(
          () => store.getPassword(e2),
          throwsA(isA<KeyringException>()),
        );
      });
    });
  });
}
