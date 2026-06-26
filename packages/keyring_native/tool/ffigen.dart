import 'dart:io';

import 'package:ffigen/ffigen.dart';

void main() {
  final packageRoot = Platform.script.resolve('../');

  FfiGenerator(
    headers: Headers(
      entryPoints: [packageRoot.resolve('native/bindings.h')],
    ),
    output: Output(dartFile: packageRoot.resolve('lib/src/ffi.g.dart')),
    functions: Functions.includeSet({
      'keyring_init',
      'keyring_set_password',
      'keyring_get_password',
      'keyring_set_secret',
      'keyring_get_secret',
      'keyring_delete_credential',
      'keyring_get_attributes',
      'keyring_update_attributes',
      'keyring_search',
      'keyring_last_error',
      'keyring_last_error_message',
      'keyring_free_string',
      'keyring_free_secret',
      'keyring_store_vendor',
    }),
  ).generate();
}
