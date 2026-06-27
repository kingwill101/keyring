# keyring_cli

Command-line interface to platform secure storage, mirroring the Rust
[keyring-rs CLI](https://github.com/hwchen/keyring-rs). Supports reading,
writing, and deleting credentials across all major platforms.

## Usage

```bash
dart run keyring_cli <command> [arguments]
```

### Global options

| Flag | Default | Description |
|------|---------|-------------|
| `-m`, `--module` | `sample` | Backend module (`sample`, `secret-service`, `keychain`, `keyutils`, `windows`, `web`) |
| `-s`, `--service` | `keyring-cli` | Service name |
| `-u`, `--user` | `keyring-user` | User name |

### Commands

#### `info`

Show info about the store and current entry.

```bash
dart run keyring_cli info
```

#### `set`

Store a password, binary secret, or attributes.

```bash
# Set a password
dart run keyring_cli set --password --input "my-password"

# Set a binary secret (base64-encoded)
dart run keyring_cli set --blob --input "dGhpcyBpcyBhIGJpbmFyeSBzZWNyZXQ="

# Update attributes
dart run keyring_cli set --attributes --input "env=prod,region=us-east"

# Interactive (omitting --input reads from stdin)
dart run keyring_cli set --password
```

#### `password`

Retrieve and print the stored password.

```bash
dart run keyring_cli password
```

#### `secret`

Retrieve the binary secret as base64.

```bash
dart run keyring_cli secret
```

#### `attributes`

Retrieve stored attribute key-value pairs.

```bash
dart run keyring_cli attributes
```

#### `credential`

Show the credential entry metadata.

```bash
dart run keyring_cli credential
```

#### `delete`

Delete the credential from secure storage.

```bash
dart run keyring_cli delete
```

#### `search`

Search for credentials matching attributes.

```bash
dart run keyring_cli search --query "env=prod"
```

### Examples

```bash
# Set and retrieve a password using Secret Service
dart run keyring_cli --module secret-service --service my-app --user alice set --password --input "s3cret"
dart run keyring_cli --module secret-service --service my-app --user alice password

# Delete the credential
dart run keyring_cli --module secret-service --service my-app --user alice delete
```

## Backend modules

| Module | Backend | Platform |
|--------|---------|----------|
| `sample` / `web` | `WebKeyringStore` (in-memory) | All |
| `secret-service` / `zbus-secret-service` | Secret Service via zbus | Linux |
| `dbus-secret-service` | Secret Service via libdbus | Linux |
| `keyutils` / `linux-keyutils` | Linux Kernel Keyutils | Linux |
| `keychain` / `apple-native` | Apple Keychain | macOS |
| `protected` / `apple-protected` | Apple Protected Data | macOS/iOS |
| `windows` / `windows-native` | Windows Credential Manager | Windows |
