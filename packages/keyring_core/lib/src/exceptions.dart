/// Categorizes the type of error returned by a [KeyringStore] operation.
///
/// Each variant describes a specific failure mode that callers can match on
/// to provide appropriate error handling.
enum KeyringErrorType {
  /// An underlying platform or operating system error occurred.
  platformFailure,

  /// The application has no access to secure storage.
  noStorageAccess,

  /// The requested credential does not exist.
  noEntry,

  /// A text encoding or decoding operation failed.
  badEncoding,

  /// The provided data was in an unexpected format.
  badDataFormat,

  /// The input exceeded the backend's length limit.
  tooLong,

  /// An invalid argument or state was encountered.
  invalid,

  /// Multiple credentials matched the lookup.
  ambiguous,

  /// No default [KeyringStore] has been configured.
  noDefaultStore,

  /// The operation is not supported by this backend.
  notSupported,
}

/// An exception from the keyring system with structured error information.
///
/// Contains a [type] categorizing the error, a human-readable [message], and
/// an optional [platformError] with backend-specific details.
///
/// ```dart
/// try {
///   await store.getPassword(entry);
/// } on KeyringException catch (e) {
///   if (e.type == KeyringErrorType.noEntry) {
///     print('Credential not found');
///   }
/// }
/// ```
class KeyringException implements Exception {
  /// The category of this error.
  final KeyringErrorType type;

  /// A human-readable description of the error.
  final String message;

  /// Optional platform-specific error detail.
  ///
  /// For native backends this may contain the OS-level error code or message.
  final Object? platformError;

  /// Creates a [KeyringException] with the given [type] and [message].
  ///
  /// An optional [platformError] can provide backend-specific context.
  const KeyringException(this.type, this.message, {this.platformError});

  @override
  String toString() => 'KeyringException($type): $message';
}
