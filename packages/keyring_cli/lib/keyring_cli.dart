/// A CLI for reading and writing credentials in platform secure storage.
///
/// Mirrors the `keyring-rs` CLI with subcommands:
///   - `info` – display store and entry information
///   - `password` – retrieve a stored password
///   - `secret` – retrieve a binary secret (base64-encoded)
///   - `attributes` – retrieve credential attributes
///   - `credential` – retrieve a credential reference
///   - `set` – store a password, blob, or attributes
///   - `delete` – remove a credential
///   - `search` – search for credentials by attributes
///
/// Backend selection via `--module` flag (sample/web, secret-service, etc.).
///
/// See [KeyringCli] for the command runner entry point.
library;
export 'src/cli.dart';
export 'src/utils.dart';
