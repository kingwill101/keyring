## Goal
- Create a cross-platform Dart keyring package that uses the Rust keyring ecosystem compiled via `native_toolchain_rust`, covering all supported Dart platforms, with backend parity to `keyring-rs` (including both D-Bus Secret Service backends on Linux).

## Constraints & Preferences
- **No raw FFI** – `native_toolchain_rust: ^1.0.4+0` is acceptable because it abstracts FFI complexity.
- **Dart package, not Flutter** – must work for pure Dart consumers; no Flutter plugin API.
- **Pub workspace** – all packages live under a single `workspace: ["packages/*"]` root.
- **API must mirror Rust `keyring-core`** – Entry, KeyringStore, KeyringException types, error codes.
- **Web implementation** must be pure Dart (IndexedDB + Web Crypto); no WASM.
- **Desktop/mobile** use Rust FFI via `native_toolchain_rust` (builds `.so`/`.dylib`/`.dll` from `native/` source).
- **Rust edition 2024** requires `#[unsafe(no_mangle)]` instead of `#[no_mangle]`.
- **Workspace root is `/run/media/kingwill101/disk2/code/code/dart_packages/keyring/`** (symlinked as `/home/kingwill101/code/dart_packages/keyring/`).

## Progress
### Done
- Created all 5 packages with full implementations (keyring_core, keyring_native, keyring_web, keyring, keyring_cli).
- Rust FFI layer compiles on Linux with fallback chain: `zbus` → `dbus` → `keyutils`.
- All 49 tests pass (12 core, 27 web, 10 umbrella).
- `NativeKeyringStore` initializes correctly on Linux Secret Service.
- `WebKeyringStore` serves as `sample`/in-memory backend.
- CLI refactored to Dart-idiomatic `CommandRunner` pattern (not Rust clap-style), with 8 subcommands: `info`, `set`, `password`, `secret`, `attributes`, `credential`, `delete`, `search`.
- CLI migrated from `package:args` to `package:artisanal/args.dart`; uses artisanal `line()`/`error()` IO methods instead of raw `print`/`stderr.writeln`.
- All 6 READMEs written: root workspace overview, keyring_core (types), keyring_native (backends, arch diagram), keyring_web (in-memory store), keyring (umbrella convenience API), keyring_cli (commands table, module list).
- `apple-native-keyring-store` pulled from crates.io v0.1 (local repo not yet cloned).
- Added `///` doc comments to all public API in all 5 packages — 0 warnings/errors from `dart doc --dry-run` and `dart analyze`.
- Added per-package `example/` files for all 4 library packages (keyring_core, keyring_web, keyring_native, keyring) demonstrating real CRUD usage.

### In Progress
- (none)

### Blocked
- (none)

## Key Decisions
- `KeyringEntry` is pure data; all credential operations are on `KeyringStore` – avoids circular dependency.
- Umbrella `keyring.dart` uses lazy `??=` for `defaultStore` – prevents import-time crash when native lib is unavailable.
- CLI uses `CommandRunner` pattern from `package:artisanal/args.dart` – clean subcommand dispatch, auto-added `--help`/`--quiet`/`--verbose`/`--no-interaction` flags, `Console`-based IO.
- `[patch.crates-io]` in `Cargo.toml` ensures all third-party crates use the same local `keyring-core`.
- `apple-native-keyring-store` stays on crates.io until local repo is cloned; then switch to `path =` and restore in `[patch.crates-io]`.

## Next Steps
1. Clone `apple-native-keyring-store` into `third_party/`, switch back to `path =` dependency, and restore in `[patch.crates-io]`.
2. Regenerate `lib/src/ffi.g.dart` after any Rust API changes.
3. Add CLI test coverage.
4. Cross-platform testing (macOS Keychain, Windows Credential Manager).

## Critical Context
- Workspace root is at `/run/media/kingwill101/disk2/code/code/dart_packages/keyring/` (symlinked as `/home/kingwill101/code/dart_packages/keyring/`).
- All file reads/writes use the symlinked path; `dart run` and `cargo build` must use the resolved path for the workspace.
- Rust compiles successfully with Linux fallback chain. The `.so` is at `native/target/release/libkeyring_dart_native.so` and copied to `.dart_tool/lib/` by the build hook.
- `NativeKeyringStore()` initializes correctly on Linux (Secret Service found via zbus).
- `WebKeyringStore()` serves as the `sample` backend in the CLI (in-memory HashMap).
- `apple-native-keyring-store` v0.1 from crates.io doesn't have `keychain` or `protected` features – use without features until local repo is cloned.
- On Linux, `linux-keyutils` fallback only supports basic ops; `search` and `update_attributes` throw `notSupported` without Secret Service.
- CLI maps `--module sample` or `--module web` to `WebKeyringStore()`, all others to `NativeKeyringStore()`.

## Relevant Files
- `/home/kingwill101/code/dart_packages/keyring/packages/keyring_native/native/Cargo.toml` – target-specific deps with `[patch.crates-io]`
- `/home/kingwill101/code/dart_packages/keyring/packages/keyring_native/native/src/platform.rs` – Linux fallback chain, Apple cfg blocks
- `/home/kingwill101/code/dart_packages/keyring/packages/keyring_native/native/src/lib.rs` – 15 FFI extern "C" functions
- `/home/kingwill101/code/dart_packages/keyring/packages/keyring_cli/lib/src/cli.dart` – CLI commands using `CommandRunner` + `StoreMixin` + artisanal IO
- `/home/kingwill101/code/dart_packages/keyring/packages/keyring_cli/lib/src/utils.dart` – `setDefaultStoreByName`, `readPassword`, `decodeBase64`, `parseAttributes`
- `/home/kingwill101/code/dart_packages/keyring/packages/keyring_core/lib/src/` – core types: `entry.dart`, `exceptions.dart`, `store.dart`
- `/home/kingwill101/code/dart_packages/keyring/packages/keyring_web/lib/src/web_store.dart` – pure-Dart in-memory `WebKeyringStore`
- `/home/kingwill101/code/dart_packages/keyring/packages/keyring_native/lib/src/native_store.dart` – Rust FFI `NativeKeyringStore`
- `/home/kingwill101/code/dart_packages/keyring/packages/keyring/lib/keyring.dart` – umbrella convenience API + `selectStore`
- `/home/kingwill101/code/dart_packages/keyring/README.md` + all `packages/*/README.md` – documentation for every package
- `/home/kingwill101/code/dart_packages/keyring/third_party/` – cloned repos (missing `apple-native-keyring-store`)
