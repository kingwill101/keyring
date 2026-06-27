import 'package:keyring_core/keyring_core.dart';
import 'package:test/test.dart';

void main() {
  group('KeyringEntry', () {
    test('default constructor sets service and user', () {
      const entry = KeyringEntry('myapp', 'alice');
      expect(entry.service, 'myapp');
      expect(entry.user, 'alice');
      expect(entry.modifiers, isNull);
    });

    test('default constructor accepts optional modifiers', () {
      const entry = KeyringEntry('myapp', 'alice', modifiers: {
        'target': 'mykey',
      });
      expect(entry.service, 'myapp');
      expect(entry.user, 'alice');
      expect(entry.modifiers, {'target': 'mykey'});
    });

    test('withModifiers constructor sets all fields', () {
      final entry = const KeyringEntry.withModifiers(
        'myapp',
        'alice',
        {'target': 'mykey'},
      );
      expect(entry.service, 'myapp');
      expect(entry.user, 'alice');
      expect(entry.modifiers, {'target': 'mykey'});
    });

    test('withModifiers without modifiers is equivalent to default', () {
      const entry1 = KeyringEntry.withModifiers('s', 'u', {});
      const entry2 = KeyringEntry('s', 'u');
      expect(entry1.service, entry2.service);
      expect(entry1.user, entry2.user);
    });

    test('const entries with same fields are identical', () {
      const a = KeyringEntry('app', 'user');
      const b = KeyringEntry('app', 'user');
      expect(a, same(b));
    });

    test('non-const entries with same fields are not identical', () {
      // ignore: prefer_const_constructors - intentionally non-const for identity check
      final a = KeyringEntry('app', 'user');
      // ignore: prefer_const_constructors
      final b = KeyringEntry('app', 'user');
      expect(a, isNot(same(b)));
    });

    test('const constructor works', () {
      const entry = KeyringEntry('app', 'user');
      expect(entry.service, 'app');
      expect(entry.user, 'user');
    });
  });
}
