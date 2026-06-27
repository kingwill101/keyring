import 'entry.dart';
import 'exceptions.dart';

/// The lifetime duration of a credential in secure storage.
///
/// Not all backends support every variant. Backends should fall back to
/// the nearest supported variant when an exact match is not available.
enum CredentialPersistence {
  /// The credential exists only as an entry reference.
  entryOnly,

  /// The credential lives only as long as the current process.
  processOnly,

  /// The credential persists until the user logs out.
  untilLogout,

  /// The credential persists until the system is restarted.
  untilReboot,

  /// The credential persists until explicitly deleted.
  untilDelete,

  /// The backend decides the default persistence policy.
  unspecified,
}

/// Abstract interface to platform secure storage.
///
/// Implementations wrap platform-specific credential backends such as
/// [Linux Secret Service][secserv], [macOS Keychain][keychain], [Windows
/// Credential Manager][credman], or an in-memory store for testing.
///
/// [secserv]: https://specifications.freedesktop.org/secret-service/latest/
/// [keychain]: https://developer.apple.com/documentation/security/keychain_services
/// [credman]: https://learn.microsoft.com/en-us/windows/win32/secauthn/credentials-management
///
/// ```dart
/// class MyStore extends KeyringStore {
///   @override
///   String get vendor => 'MyStore';
///
///   @override
///   String get id => 'my-store-1.0';
///
///   @override
///   CredentialPersistence get persistence =>
///       CredentialPersistence.untilDelete;
///
///   // ... implement remaining methods
/// }
/// ```
abstract class KeyringStore {
  /// The human-readable name of this backend.
  ///
  /// Examples: `"Secret Service"`, `"macOS Keychain"`, `"Web (in-memory)"`.
  String get vendor;

  /// A unique identifier for this store implementation.
  ///
  /// Typically includes the package name and version.
  String get id;

  /// The default persistence policy for credentials stored by this backend.
  CredentialPersistence get persistence;

  /// Builds a [KeyringEntry] for the given [service] and [user].
  ///
  /// The returned entry can be passed to other store methods. Backends may
  /// use this to lazily resolve or validate credential metadata. The
  /// optional [modifiers] provide platform-specific lookup parameters.
  Future<KeyringEntry> build(
    String service,
    String user, {
    Map<String, String>? modifiers,
  });

  /// Searches for credentials matching the given attribute [spec].
  ///
  /// Returns all matching [KeyringEntry] instances. An empty map matches
  /// all credentials supported by the backend.
  Future<List<KeyringEntry>> search(Map<String, String> spec);

  /// Stores the [password] string for the given [entry].
  ///
  /// If a credential already exists for the same entry, it is overwritten.
  /// Throws a [KeyringException] if the operation fails.
  Future<void> setPassword(KeyringEntry entry, String password);

  /// Stores the binary [secret] bytes for the given [entry].
  ///
  /// If a credential already exists for the same entry, it is overwritten.
  /// Throws a [KeyringException] if the operation fails.
  Future<void> setSecret(KeyringEntry entry, List<int> secret);

  /// Returns the stored password for the given [entry].
  ///
  /// Throws a [KeyringException] with [KeyringErrorType.noEntry] when no
  /// credential exists for [entry].
  Future<String> getPassword(KeyringEntry entry);

  /// Returns the stored binary secret for the given [entry].
  ///
  /// Throws a [KeyringException] with [KeyringErrorType.noEntry] when no
  /// credential exists for [entry].
  Future<List<int>> getSecret(KeyringEntry entry);

  /// Deletes the credential associated with [entry].
  ///
  /// Throws a [KeyringException] with [KeyringErrorType.noEntry] when no
  /// credential exists for [entry].
  Future<void> deleteCredential(KeyringEntry entry);

  /// Returns the attribute key-value pairs for the given [entry].
  ///
  /// Throws a [KeyringException] with [KeyringErrorType.noEntry] when no
  /// credential exists for [entry].
  Future<Map<String, String>> getAttributes(KeyringEntry entry);

  /// Merges [attributes] into the existing attributes for [entry].
  ///
  /// Existing keys with matching names are overwritten. New keys are added.
  /// Throws a [KeyringException] with [KeyringErrorType.noEntry] when no
  /// credential exists for [entry].
  Future<void> updateAttributes(
      KeyringEntry entry, Map<String, String> attributes);
}
