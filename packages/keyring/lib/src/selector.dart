import 'package:keyring_core/keyring_core.dart';
import 'package:keyring_native/keyring_native.dart';
import 'package:keyring_web/keyring_web.dart';

KeyringStore selectStore() {
  if (_isWeb) return WebKeyringStore();
  return NativeKeyringStore();
}

bool get _isWeb {
  try {
    return identical(0, 0.0);
  } catch (_) {
    return false;
  }
}
