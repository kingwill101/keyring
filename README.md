# keyring

A cross-platform Dart package for reading and writing credentials in platform
secure storage, mirroring the Rust [keyring-rs](https://github.com/hwchen/keyring-rs) ecosystem.

## Packages

| Package | Description |
|---------|-------------|
| [`keyring_core`](packages/keyring_core) | Core types: `KeyringEntry`, `KeyringStore` interface, `KeyringException`, `CredentialPersistence` |
| [`keyring_native`](packages/keyring_native) | Native implementation backed by Rust FFI (Secret Service, Keychain, Credential Manager) |
| [`keyring_web`](packages/keyring_web) | Pure-Dart in-memory store for web and testing |
| [`keyring`](packages/keyring) | Umbrella package with convenience API and automatic platform selection |
| [`keyring_cli`](packages/keyring_cli) | CLI tool mirroring `keyring-rs` CLI commands |

## Usage

```dart
import 'package:keyring/keyring.dart';

void main() async {
  final entry = KeyringEntry('my-app', 'alice');
  await setPassword(entry, 's3cret');
  print(await getPassword(entry)); // s3cret
}
```

## Development

```bash
# Run all tests
dart test

# Analyze all packages
dart analyze

# Build native library
cd packages/keyring_native/native
cargo build --release
```

## Architecture

```
keyring (umbrella convenience API)
  ├── keyring_core (abstract interface + data types)
  ├── keyring_native (Rust FFI — Secret Service / Keychain / CredMan)
  └── keyring_web (pure Dart — in-memory)
```

The umbrella package auto-selects the appropriate backend at runtime: web
runtimes get `WebKeyringStore`; all other platforms use `NativeKeyringStore`.
