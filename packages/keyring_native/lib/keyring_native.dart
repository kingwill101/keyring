/// A credential store backed by native Rust FFI.
///
/// Uses `native_toolchain_rust` to compile platform-specific shared libraries
/// (`.so` / `.dylib` / `.dll`) from Rust source. Supports Linux Secret
/// Service, macOS Keychain, and Windows Credential Manager.
///
/// See [NativeKeyringStore] for implementation details.
library;
export 'src/native_store.dart';
