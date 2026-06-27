/// An immutable credential lookup key.
///
/// Identifies a credential in platform secure storage by its [service] name,
/// [user] identifier, and optional platform-specific [modifiers].
///
/// ```dart
/// const entry = KeyringEntry('my-app', 'alice');
/// const withMods = KeyringEntry.withModifiers('app', 'bob', {'env': 'prod'});
/// ```
class KeyringEntry {
  /// The service or application name that owns the credential.
  final String service;

  /// The user identifier associated with the credential.
  final String user;

  /// Optional platform-specific parameters for credential lookup.
  ///
  /// Contents are backend-dependent. For example, Secret Service backends may
  /// use modifiers to specify attribute-based lookups.
  final Map<String, String>? modifiers;

  /// Creates an [KeyringEntry] with optional [modifiers].
  const KeyringEntry(this.service, this.user, {this.modifiers});

  /// Creates an [KeyringEntry] with required [modifiers].
  ///
  /// Unlike [KeyringEntry.new], this constructor takes a non-nullable
  /// [modifiers] map.
  const KeyringEntry.withModifiers(
    this.service,
    this.user,
    this.modifiers,
  );

  @override
  String toString() => 'KeyringEntry(service: $service, user: $user)';
}
