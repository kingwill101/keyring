use keyring_core::Result;
use std::sync::Arc;

pub fn init() -> Result<Arc<keyring_core::api::CredentialStore>> {
    #[cfg(target_os = "macos")]
    {
        apple_native_keyring_store::Store::new()
    }
    #[cfg(target_os = "windows")]
    {
        windows_native_keyring_store::Store::new()
    }
    #[cfg(target_os = "linux")]
    {
        zbus_secret_service_keyring_store::Store::new()
            .map(|s| s as Arc<keyring_core::api::CredentialStore>)
            .or_else(|_| {
                dbus_secret_service_keyring_store::Store::new()
                    .map(|s| s as Arc<keyring_core::api::CredentialStore>)
            })
            .or_else(|_| {
                linux_keyutils_keyring_store::Store::new()
                    .map(|s| s as Arc<keyring_core::api::CredentialStore>)
            })
    }
    #[cfg(any(target_os = "freebsd", target_os = "openbsd"))]
    {
        zbus_secret_service_keyring_store::Store::new()
            .map(|s| s as Arc<keyring_core::api::CredentialStore>)
            .or_else(|_| {
                dbus_secret_service_keyring_store::Store::new()
                    .map(|s| s as Arc<keyring_core::api::CredentialStore>)
            })
    }
    #[cfg(target_os = "ios")]
    {
        apple_native_keyring_store::Store::new()
    }
    #[cfg(not(any(
        target_os = "linux",
        target_os = "windows",
        target_os = "macos",
        target_os = "ios",
        target_os = "freebsd",
        target_os = "openbsd",
    )))]
    {
        compile_error!("Unsupported target OS")
    }
}
