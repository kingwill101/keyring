/// Core types and interfaces for the Dart keyring ecosystem.
///
/// This package defines the foundation that all other keyring packages build
/// on: the [KeyringEntry] credential key, the [KeyringStore] abstract
/// interface, the [KeyringException] error hierarchy, and the
/// [CredentialPersistence] policy enum.
///
/// ## Classes
///
/// - [KeyringEntry] — an immutable credential lookup key
/// - [KeyringException] — typed exception with structured error information
/// - [KeyringStore] — abstract interface for secure storage backends
///
/// ## Enums
///
/// - [KeyringErrorType] — categorizes keyring operation failures
/// - [CredentialPersistence] — credential lifetime policies
library;
export 'src/entry.dart';
export 'src/exceptions.dart';
export 'src/store.dart';
