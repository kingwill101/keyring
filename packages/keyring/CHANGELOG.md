## 1.0.0

- Initial release.
- Convenience top-level API wrapping [KeyringStore] operations.
- Lazy [defaultStore] auto-selects [WebKeyringStore] on web runtimes and
  [NativeKeyringStore] on native platforms.
- Re-exports core types: [KeyringEntry], [KeyringException],
  [KeyringErrorType], [CredentialPersistence].
