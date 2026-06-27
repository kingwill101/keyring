// ignore_for_file: avoid_print

import 'package:keyring_native/keyring_native.dart';

void main() async {
  try {
    final store = NativeKeyringStore();
    print('Store created: ${store.vendor}');
  } catch (e) {
    print('Error: $e');
  }
}
