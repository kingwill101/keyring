export 'package:keyring_core/keyring_core.dart'
    show
        KeyringEntry,
        KeyringErrorType,
        KeyringException,
        CredentialPersistence;

import 'package:keyring_core/keyring_core.dart';
import 'src/selector.dart' show selectStore;

KeyringStore? _defaultStore;

KeyringStore get defaultStore =>
    _defaultStore ??= selectStore();

void setDefaultStore(KeyringStore store) {
  _defaultStore = store;
}

Future<void> setPassword(KeyringEntry entry, String password) =>
    defaultStore.setPassword(entry, password);

Future<void> setSecret(KeyringEntry entry, List<int> secret) =>
    defaultStore.setSecret(entry, secret);

Future<String> getPassword(KeyringEntry entry) =>
    defaultStore.getPassword(entry);

Future<List<int>> getSecret(KeyringEntry entry) =>
    defaultStore.getSecret(entry);

Future<void> deleteCredential(KeyringEntry entry) =>
    defaultStore.deleteCredential(entry);

Future<Map<String, String>> getAttributes(KeyringEntry entry) =>
    defaultStore.getAttributes(entry);

Future<void> updateAttributes(
        KeyringEntry entry, Map<String, String> attributes) =>
    defaultStore.updateAttributes(entry, attributes);

Future<KeyringEntry> buildEntry(String service, String user,
        {Map<String, String>? modifiers}) =>
    defaultStore.build(service, user, modifiers: modifiers);

Future<List<KeyringEntry>> searchEntries(Map<String, String> spec) =>
    defaultStore.search(spec);
