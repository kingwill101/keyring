use keyring_core::Result;
use std::sync::Arc;

type CredStore = keyring_core::api::CredentialStore;

pub fn init() -> Result<Arc<CredStore>> {
    #[cfg(target_os = "linux")]
    {
        let store: Arc<CredStore> = linux_keyutils_keyring_store::Store::new()?;
        Ok(store)
    }
    #[cfg(target_os = "windows")]
    {
        let store: Arc<CredStore> = windows_native_keyring_store::Store::new()?;
        Ok(store)
    }
    #[cfg(target_os = "macos")]
    {
        let store: Arc<CredStore> = keyring_core::mock::Store::new()?;
        Ok(store)
    }
    #[cfg(not(any(target_os = "linux", target_os = "windows", target_os = "macos")))]
    {
        compile_error!("Unsupported target OS")
    }
}
