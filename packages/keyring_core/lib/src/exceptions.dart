enum KeyringErrorType {
  platformFailure,
  noStorageAccess,
  noEntry,
  badEncoding,
  badDataFormat,
  tooLong,
  invalid,
  ambiguous,
  noDefaultStore,
  notSupported,
}

class KeyringException implements Exception {
  final KeyringErrorType type;
  final String message;
  final Object? platformError;

  const KeyringException(this.type, this.message, {this.platformError});

  @override
  String toString() => 'KeyringException($type): $message';
}
