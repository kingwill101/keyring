# keyring_core

Core types and interfaces for the Dart keyring ecosystem. This package has zero
runtime dependencies and is the foundation that all other keyring packages build
on.

## Types

### `KeyringEntry`

An immutable data class representing a credential lookup key.

```dart
const entry = KeyringEntry('my-app', 'alice');
const withMods = KeyringEntry.withModifiers('app', 'bob', {'env': 'prod'});
```

| Field | Type | Description |
|-------|------|-------------|
| `service` | `String` | The service or application name |
| `user` | `String` | The user identifier |
| `modifiers` | `Map<String, String>?` | Optional platform-specific parameters |

### `KeyringException`

Typed exception carrying structured error information.

```dart
try {
  await store.getPassword(entry);
} on KeyringException catch (e) {
  if (e.type == KeyringErrorType.noEntry) {
    print('Credential not found');
  }
}
```

| Field | Type | Description |
|-------|------|-------------|
| `type` | `KeyringErrorType` | Categorizes the error |
| `message` | `String` | Human-readable description |
| `platformError` | `Object?` | Optional platform-specific error detail |

### `KeyringErrorType`

| Variant | Meaning |
|---------|---------|
| `platformFailure` | Underlying OS/backend error |
| `noStorageAccess` | No access to secure storage |
| `noEntry` | Credential does not exist |
| `badEncoding` | Invalid text encoding |
| `badDataFormat` | Malformed data |
| `tooLong` | Input exceeds length limit |
| `invalid` | Invalid argument or state |
| `ambiguous` | Multiple matching credentials |
| `noDefaultStore` | No global store configured |
| `notSupported` | Operation not available on this backend |

### `CredentialPersistence`

| Variant | Meaning |
|---------|---------|
| `entryOnly` | Credential exists only as an entry |
| `processOnly` | Lifetime of the current process |
| `untilLogout` | Until the user logs out |
| `untilReboot` | Until system restart |
| `untilDelete` | Until explicitly deleted |
| `unspecified` | Backend-defined default |

## `KeyringStore` Interface

The abstract class all keyring implementations must extend:

```dart
abstract class KeyringStore {
  String get vendor;
  String get id;
  CredentialPersistence get persistence;

  Future<KeyringEntry> build(String service, String user, {Map<String, String>? modifiers});
  Future<List<KeyringEntry>> search(Map<String, String> spec);

  Future<void> setPassword(KeyringEntry entry, String password);
  Future<String> getPassword(KeyringEntry entry);
  Future<void> setSecret(KeyringEntry entry, List<int> secret);
  Future<List<int>> getSecret(KeyringEntry entry);
  Future<void> deleteCredential(KeyringEntry entry);

  Future<Map<String, String>> getAttributes(KeyringEntry entry);
  Future<void> updateAttributes(KeyringEntry entry, Map<String, String> attributes);
}
```

Implementations: [`keyring_native`](../keyring_native) (Rust FFI),
[`keyring_web`](../keyring_web) (in-memory).
