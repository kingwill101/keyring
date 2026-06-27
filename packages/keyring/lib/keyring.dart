/// Re-exports core types and provides a convenience top-level API.
///
/// This umbrella package re-exports [KeyringEntry], [KeyringException],
/// [KeyringErrorType], and [CredentialPersistence] from `keyring_core`.
///
/// All top-level functions delegate to the lazily-initialized [defaultStore].
/// On first access, [defaultStore] auto-selects `WebKeyringStore` for web
/// runtimes and `NativeKeyringStore` for native platforms.
///
/// ```dart
/// import 'package:keyring/keyring.dart';
///
/// void main() async {
///   final entry = KeyringEntry('my-app', 'alice');
///   await setPassword(entry, 's3cret');
///   print(await getPassword(entry)); // s3cret
/// }
/// ```
library;
export 'package:keyring_core/keyring_core.dart'
    show
        KeyringEntry,
        KeyringErrorType,
        KeyringException,
        CredentialPersistence;

import 'package:keyring_core/keyring_core.dart';
import 'src/selector.dart' show selectStore;

KeyringStore? _defaultStore;

/// The global [KeyringStore] used by the convenience API.
///
/// Lazily initialized on first access. Use [setDefaultStore] to override
/// with a custom store (e.g., for testing).
KeyringStore get defaultStore =>
    _defaultStore ??= selectStore();

/// Overrides the global [defaultStore] with [store].
///
/// Call this before any credential operations to use a specific backend.
void setDefaultStore(KeyringStore store) {
  _defaultStore = store;
}

/// Stores [password] for [entry] using [defaultStore].
Future<void> setPassword(KeyringEntry entry, String password) =>
    defaultStore.setPassword(entry, password);

/// Stores binary [secret] for [entry] using [defaultStore].
Future<void> setSecret(KeyringEntry entry, List<int> secret) =>
    defaultStore.setSecret(entry, secret);

/// Returns the stored password for [entry] from [defaultStore].
Future<String> getPassword(KeyringEntry entry) =>
    defaultStore.getPassword(entry);

/// Returns the stored binary secret for [entry] from [defaultStore].
Future<List<int>> getSecret(KeyringEntry entry) =>
    defaultStore.getSecret(entry);

/// Deletes the credential for [entry] from [defaultStore].
Future<void> deleteCredential(KeyringEntry entry) =>
    defaultStore.deleteCredential(entry);

/// Returns the attribute key-value pairs for [entry] from [defaultStore].
Future<Map<String, String>> getAttributes(KeyringEntry entry) =>
    defaultStore.getAttributes(entry);

/// Merges [attributes] into the existing attributes for [entry].
Future<void> updateAttributes(
        KeyringEntry entry, Map<String, String> attributes) =>
    defaultStore.updateAttributes(entry, attributes);

/// Builds a [KeyringEntry] for [service] and [user] with optional [modifiers].
Future<KeyringEntry> buildEntry(String service, String user,
        {Map<String, String>? modifiers}) =>
    defaultStore.build(service, user, modifiers: modifiers);

/// Searches for credentials matching [spec] using [defaultStore].
Future<List<KeyringEntry>> searchEntries(Map<String, String> spec) =>
    defaultStore.search(spec);
