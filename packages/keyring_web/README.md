# keyring_web

Pure-Dart keyring implementation using an in-memory `HashMap`-backed store.
Suitable for web platforms and testing where native secure storage is
unavailable.

> **Note:** This is an in-memory implementation. Data does not persist between
> process restarts.

## Usage

```dart
import 'package:keyring_core/keyring_core.dart';
import 'package:keyring_web/keyring_web.dart';

final store = WebKeyringStore();
final entry = KeyringEntry('my-app', 'alice');

await store.setPassword(entry, 's3cret');
print(await store.getPassword(entry)); // s3cret
```

## Properties

| Property | Value |
|----------|-------|
| `vendor` | `'Web (in-memory)'` |
| `id` | `'keyring-web-1.0.0'` |
| `persistence` | `CredentialPersistence.untilDelete` |

## Testing

This package includes 27 tests covering all `KeyringStore` operations, including
edge cases for empty passwords, secret isolation between entries, and attribute
merge semantics:

```bash
dart test
```

## When to Use

- **Web applications** — the only option when running in a browser
- **Testing** — lightweight, fast, no OS dependencies
- **Prototyping** — swap in `NativeKeyringStore` when ready for production
