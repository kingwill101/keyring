import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'package:keyring_core/keyring_core.dart';

import 'ffi.g.dart';

/// Converts a Rust error [code] and optional [context] into a [KeyringException].
KeyringException _mapError(int code, Object? context) {
  final msgPtr = keyring_last_error_message();
  try {
    return KeyringException(
      _codeToErrorType(code),
      _utf8(msgPtr).isEmpty ? context.toString() : _utf8(msgPtr),
    );
  } finally {
    keyring_free_string(msgPtr);
  }
}

/// Maps an integer error [code] from the Rust FFI layer to a [KeyringErrorType].
KeyringErrorType _codeToErrorType(int code) {
  switch (code) {
    case 1:
      return KeyringErrorType.platformFailure;
    case 2:
      return KeyringErrorType.noStorageAccess;
    case 3:
      return KeyringErrorType.noEntry;
    case 4:
      return KeyringErrorType.badEncoding;
    case 5:
      return KeyringErrorType.badDataFormat;
    case 7:
      return KeyringErrorType.tooLong;
    case 8:
      return KeyringErrorType.invalid;
    case 9:
      return KeyringErrorType.ambiguous;
    case 10:
      return KeyringErrorType.noDefaultStore;
    case 11:
      return KeyringErrorType.notSupported;
    default:
      return KeyringErrorType.platformFailure;
  }
}

/// Decodes a null-terminated C string [ptr] into a Dart [String].
///
/// Returns an empty string when [ptr] is `nullptr`.
String _utf8(Pointer<Char> ptr) {
  if (ptr == nullptr) return '';
  var len = 0;
  while (ptr[len] != 0) {
    len++;
  }
  return utf8.decode(ptr.cast<Uint8>().asTypedList(len));
}

/// A [KeyringStore] backed by the Rust keyring FFI library.
///
/// Uses `native_toolchain_rust` to compile the native shared library
/// (`libkeyring_dart_native.so` on Linux, `.dylib` on macOS, `.dll` on
/// Windows) and communicates with it through auto-generated FFI bindings.
///
/// On Linux, the backend fallback chain is: Secret Service via `zbus` →
/// Secret Service via `dbus` → Kernel Keyutils.
///
/// On macOS, the Apple Keychain is used. On Windows, the Credential Manager.
///
/// ```dart
/// final store = NativeKeyringStore();
/// final entry = KeyringEntry('app', 'alice');
/// await store.setPassword(entry, 's3cret');
/// ```
class NativeKeyringStore extends KeyringStore {
  /// Initializes the native keyring backend.
  ///
  /// Throws a [KeyringException] if the native library cannot be loaded or
  /// no supported backend is available.
  NativeKeyringStore() {
    final code = keyring_init();
    if (code != 0) throw _mapError(code, 'init_failed');
  }

  /// Returns the name of the active Rust backend, such as `"Secret Service"`.
  @override
  String get vendor {
    final ptr = keyring_store_vendor();
    if (ptr == nullptr) throw _mapError(keyring_last_error(), 'get_vendor_failed');
    try {
      return _utf8(ptr);
    } finally {
      keyring_free_string(ptr);
    }
  }

  @override
  String get id => 'keyring-native-1.0.0';

  @override
  CredentialPersistence get persistence => CredentialPersistence.untilDelete;

  @override
  Future<KeyringEntry> build(String service, String user,
      {Map<String, String>? modifiers}) async {
    return KeyringEntry(service, user, modifiers: modifiers);
  }

  @override
  Future<List<KeyringEntry>> search(Map<String, String> spec) async {
    final jsonPtr = jsonEncode(spec).toNativeUtf8().cast<Char>();
    try {
      final result = keyring_search(jsonPtr);
      if (result == nullptr) throw _mapError(keyring_last_error(), 'search_failed');
      try {
        final list = jsonDecode(_utf8(result)) as List;
        return list
            .map((e) {
              final map = e as Map<String, dynamic>;
              return KeyringEntry(
                map['service'] as String,
                map['user'] as String,
              );
            })
            .toList();
      } finally {
        keyring_free_string(result);
      }
    } finally {
      calloc.free(jsonPtr);
    }
  }

  @override
  Future<void> setPassword(KeyringEntry entry, String password) async {
    final code = keyring_set_password(
      entry.service.toNativeUtf8().cast<Char>(),
      entry.user.toNativeUtf8().cast<Char>(),
      password.toNativeUtf8().cast<Char>(),
    );
    if (code != 0) throw _mapError(code, 'set_password_failed');
  }

  @override
  Future<String> getPassword(KeyringEntry entry) async {
    final result = keyring_get_password(
      entry.service.toNativeUtf8().cast<Char>(),
      entry.user.toNativeUtf8().cast<Char>(),
    );
    if (result == nullptr) throw _mapError(keyring_last_error(), 'get_password_failed');
    try {
      return _utf8(result);
    } finally {
      keyring_free_string(result);
    }
  }

  @override
  Future<void> setSecret(KeyringEntry entry, List<int> secret) async {
    final secretPtr = calloc<Uint8>(secret.length);
    try {
      for (var i = 0; i < secret.length; i++) {
        secretPtr[i] = secret[i];
      }
      final code = keyring_set_secret(
        entry.service.toNativeUtf8().cast<Char>(),
        entry.user.toNativeUtf8().cast<Char>(),
        secretPtr,
        secret.length,
      );
      if (code != 0) throw _mapError(code, 'set_secret_failed');
    } finally {
      calloc.free(secretPtr);
    }
  }

  @override
  Future<List<int>> getSecret(KeyringEntry entry) async {
    final outLen = calloc<Int32>();
    try {
      final result = keyring_get_secret(
        entry.service.toNativeUtf8().cast<Char>(),
        entry.user.toNativeUtf8().cast<Char>(),
        outLen,
      );
      if (result == nullptr) throw _mapError(keyring_last_error(), 'get_secret_failed');
      final len = outLen.value;
      try {
        return result.asTypedList(len).toList();
      } finally {
        keyring_free_secret(result, len);
      }
    } finally {
      calloc.free(outLen);
    }
  }

  @override
  Future<void> deleteCredential(KeyringEntry entry) async {
    final code = keyring_delete_credential(
      entry.service.toNativeUtf8().cast<Char>(),
      entry.user.toNativeUtf8().cast<Char>(),
    );
    if (code != 0) throw _mapError(code, 'delete_failed');
  }

  @override
  Future<Map<String, String>> getAttributes(KeyringEntry entry) async {
    final result = keyring_get_attributes(
      entry.service.toNativeUtf8().cast<Char>(),
      entry.user.toNativeUtf8().cast<Char>(),
    );
    if (result == nullptr) throw _mapError(keyring_last_error(), 'get_attributes_failed');
    try {
      return (jsonDecode(_utf8(result)) as Map<String, dynamic>)
          .cast<String, String>();
    } finally {
      keyring_free_string(result);
    }
  }

  @override
  Future<void> updateAttributes(
      KeyringEntry entry, Map<String, String> attributes) async {
    final jsonPtr = jsonEncode(attributes).toNativeUtf8().cast<Char>();
    final svcPtr = entry.service.toNativeUtf8().cast<Char>();
    final usrPtr = entry.user.toNativeUtf8().cast<Char>();
    try {
      final code = keyring_update_attributes(svcPtr, usrPtr, jsonPtr);
      if (code != 0) throw _mapError(code, 'update_attributes_failed');
    } finally {
      calloc.free(svcPtr);
      calloc.free(usrPtr);
      calloc.free(jsonPtr);
    }
  }
}
