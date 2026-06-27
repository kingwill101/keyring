# keyring_native

Native keyring implementation backed by Rust FFI via
[`native_toolchain_rust`](https://pub.dev/packages/native_toolchain_rust).

## Supported Backends

| Platform | Backend | Crate |
|----------|---------|-------|
| Linux | Secret Service (D-Bus via zbus) | [`zbus-secret-service-keyring-store`](https://crates.io/crates/zbus-secret-service-keyring-store) |
| Linux | Secret Service (D-Bus via libdbus) | [`dbus-secret-service-keyring-store`](https://crates.io/crates/dbus-secret-service-keyring-store) |
| Linux | Kernel Keyutils | [`linux-keyutils-keyring-store`](https://crates.io/crates/linux-keyutils-keyring-store) |
| macOS | Apple Keychain | [`apple-native-keyring-store`](https://crates.io/crates/apple-native-keyring-store) |
| Windows | Credential Manager | `windows-native-keyring-store` |

On Linux, backends are tried in fallback order: `zbus` → `dbus` → `keyutils`.
Secret Service (via either D-Bus crate) is required for `search` and
`update_attributes`.

## Usage

```dart
import 'package:keyring_core/keyring_core.dart';
import 'package:keyring_native/keyring_native.dart';

final store = NativeKeyringStore();
final entry = KeyringEntry('my-app', 'alice');

await store.setPassword(entry, 's3cret');
final password = await store.getPassword(entry);
```

## How It Works

1. `native_toolchain_rust` compiles the Rust source in `native/` to a shared
   library (`.so`/`.dylib`/`.dll`) during `dart run` or `dart build`.
2. `cbindgen` generates a C header from the Rust `extern "C"` functions.
3. `ffigen` generates Dart FFI bindings (`ffi.g.dart`) from that header.
4. `NativeKeyringStore` wraps the 15 extern functions and converts between Dart
   types and C pointers.

## Building

The native library is built automatically by `native_toolchain_rust`. To build
manually:

```bash
cd native
cargo build --release
```

## Architecture

```
NativeKeyringStore (Dart)
  └── ffi.g.dart (auto-generated bindings)
        └── libkeyring_dart_native.so (Rust shared library)
              ├── lib.rs (15 FFI extern "C" functions)
              └── platform.rs (backend selection per OS)
```

## Error Codes

The Rust layer returns integer error codes mapped to `KeyringErrorType`:

| Code | KeyringErrorType |
|------|------------------|
| 1 | `platformFailure` |
| 2 | `noStorageAccess` |
| 3 | `noEntry` |
| 4 | `badEncoding` |
| 5 | `badDataFormat` |
| 6 | `tooLong` |
| 7 | `invalid` |
| 8 | `ambiguous` |
| 9 | `noDefaultStore` |
| 10 | `notSupported` |
