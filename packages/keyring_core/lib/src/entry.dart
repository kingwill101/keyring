class KeyringEntry {
  final String service;
  final String user;
  final Map<String, String>? modifiers;

  const KeyringEntry(this.service, this.user, {this.modifiers});

  const KeyringEntry.withModifiers(
    this.service,
    this.user,
    this.modifiers,
  );
}
