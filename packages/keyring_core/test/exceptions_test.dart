import 'package:keyring_core/keyring_core.dart';
import 'package:test/test.dart';

void main() {
  group('KeyringException', () {
    test('const constructor works', () {
      const exc = KeyringException(KeyringErrorType.noEntry, 'Not found');
      expect(exc.type, KeyringErrorType.noEntry);
      expect(exc.message, 'Not found');
      expect(exc.platformError, isNull);
    });

    test('toString includes type and message', () {
      const exc = KeyringException(KeyringErrorType.platformFailure, 'Oops');
      expect(exc.toString(), contains('platformFailure'));
      expect(exc.toString(), contains('Oops'));
    });

    test('optional platformError is stored', () {
      const exc = KeyringException(
        KeyringErrorType.platformFailure,
        'Error',
        platformError: 42,
      );
      expect(exc.platformError, 42);
    });

    test('all error types are distinguishable', () {
      for (final type in KeyringErrorType.values) {
        final exc = KeyringException(type, 'test');
        expect(exc.type, type);
      }
    });
  });

  group('CredentialPersistence', () {
    test('has all expected variants', () {
      expect(CredentialPersistence.values, hasLength(6));
      expect(
        CredentialPersistence.values,
        containsAll([
          CredentialPersistence.entryOnly,
          CredentialPersistence.processOnly,
          CredentialPersistence.untilLogout,
          CredentialPersistence.untilReboot,
          CredentialPersistence.untilDelete,
          CredentialPersistence.unspecified,
        ]),
      );
    });
  });
}
