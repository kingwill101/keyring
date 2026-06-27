# keyring

Umbrella package for the Dart keyring ecosystem. Re-exports core types from
[`keyring_core`](../keyring_core) and provides a convenience top-level API that
delegates to a lazily-initialized global `defaultStore`.

## Quick Start

```dart
import 'package:keyring/keyring.dart';

void main() async {
  final entry = KeyringEntry('my-app', 'alice');
  await setPassword(entry, 's3cret');
  final password = await getPassword(entry);
  print(password); // s3cret
}
```

## Platform Selection

`defaultStore` is initialized once on first access:

- **Web** (`dart2js` / `dart2wasm`) — `WebKeyringStore()` (in-memory)
- **Native** (VM, AOT) — `NativeKeyringStore()` (Rust FFI)

Override with `setDefaultStore()`:

```dart
setDefaultStore(WebKeyringStore()); // force in-memory
```

## Convenience API

All top-level functions delegate to `defaultStore`:

| Function | Delegates to |
|----------|-------------|
| `setPassword(entry, password)` | `defaultStore.setPassword` |
| `getPassword(entry)` | `defaultStore.getPassword` |
| `setSecret(entry, secret)` | `defaultStore.setSecret` |
| `getSecret(entry)` | `defaultStore.getSecret` |
| `deleteCredential(entry)` | `defaultStore.deleteCredential` |
| `getAttributes(entry)` | `defaultStore.getAttributes` |
| `updateAttributes(entry, attrs)` | `defaultStore.updateAttributes` |
| `buildEntry(service, user, {modifiers})` | `defaultStore.build` |
| `searchEntries(spec)` | `defaultStore.search` |

## Re-exports

The package re-exports these types from `keyring_core`:

- `KeyringEntry`
- `KeyringException`
- `KeyringErrorType`
- `CredentialPersistence`
