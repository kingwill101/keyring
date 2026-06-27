import 'package:keyring_core/keyring_core.dart';
import 'package:keyring_native/keyring_native.dart';
import 'package:keyring_web/keyring_web.dart';

/// Detects the current platform and returns an appropriate [KeyringStore].
///
/// Returns [WebKeyringStore] when running on a web runtime (detected via
/// `identical(0, 0.0)`) and [NativeKeyringStore] on all other platforms.
KeyringStore selectStore() {
  if (_isWeb) return WebKeyringStore();
  return NativeKeyringStore();
}

/// Whether the current Dart runtime is a web (JS/Wasm) runtime.
bool get _isWeb {
  try {
    return identical(0, 0.0);
  } catch (_) {
    return false;
  }
}
