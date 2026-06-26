import 'entry.dart';

enum CredentialPersistence {
  entryOnly,
  processOnly,
  untilLogout,
  untilReboot,
  untilDelete,
  unspecified,
}

abstract class KeyringStore {
  String get vendor;
  String get id;
  CredentialPersistence get persistence;

  Future<KeyringEntry> build(
    String service,
    String user, {
    Map<String, String>? modifiers,
  });

  Future<List<KeyringEntry>> search(Map<String, String> spec);

  Future<void> setPassword(KeyringEntry entry, String password);
  Future<void> setSecret(KeyringEntry entry, List<int> secret);
  Future<String> getPassword(KeyringEntry entry);
  Future<List<int>> getSecret(KeyringEntry entry);
  Future<void> deleteCredential(KeyringEntry entry);
  Future<Map<String, String>> getAttributes(KeyringEntry entry);
  Future<void> updateAttributes(
      KeyringEntry entry, Map<String, String> attributes);
}
