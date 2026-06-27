## 1.0.0

- Initial release.
- Native [NativeKeyringStore] implementation backed by Rust FFI via
  `native_toolchain_rust`.
- Linux: Secret Service support (zbus and dbus) with linux-keyutils fallback.
- macOS: Apple Keychain support.
- Windows: Credential Manager support.
