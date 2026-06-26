mod platform;

use keyring_core::{Entry, Error};
use libc::c_char;
use std::collections::HashMap;
use std::ffi::{CStr, CString};
use std::sync::{Mutex, OnceLock};

static LAST_ERROR: OnceLock<Mutex<Option<(i32, String)>>> = OnceLock::new();

fn last_error_mutex() -> &'static Mutex<Option<(i32, String)>> {
    LAST_ERROR.get_or_init(|| Mutex::new(None))
}

fn set_last_error(code: i32) {
    let msg = error_message(code);
    if let Ok(mut lock) = last_error_mutex().lock() {
        *lock = Some((code, msg));
    }
}

fn error_to_code(err: &Error) -> i32 {
    match err {
        Error::PlatformFailure(_) => 1,
        Error::NoStorageAccess(_) => 2,
        Error::NoEntry => 3,
        Error::BadEncoding(_) => 4,
        Error::BadDataFormat(_, _) => 5,
        Error::BadStoreFormat(_) => 6,
        Error::TooLong(_, _) => 7,
        Error::Invalid(_, _) => 8,
        Error::Ambiguous(_) => 9,
        Error::NoDefaultStore => 10,
        Error::NotSupportedByStore(_) => 11,
        _ => -1,
    }
}

fn error_message(code: i32) -> String {
    match code {
        1 => "Platform failure".to_string(),
        2 => "No storage access".to_string(),
        3 => "No entry found".to_string(),
        4 => "Bad encoding".to_string(),
        5 => "Bad data format".to_string(),
        6 => "Bad store format".to_string(),
        7 => "Entry too long".to_string(),
        8 => "Invalid input".to_string(),
        9 => "Ambiguous match".to_string(),
        10 => "No default store".to_string(),
        11 => "Operation not supported".to_string(),
        _ => "Unknown error".to_string(),
    }
}

fn ensure_init() -> Result<(), i32> {
    static INIT: OnceLock<Result<(), i32>> = OnceLock::new();
    *INIT.get_or_init(|| match platform::init() {
        Ok(store) => {
            keyring_core::set_default_store(store);
            Ok(())
        }
        Err(e) => {
            let code = error_to_code(&e);
            set_last_error(code);
            Err(code)
        }
    })
}

#[unsafe(no_mangle)]
pub extern "C" fn keyring_init() -> i32 {
    match ensure_init() {
        Ok(()) => 0,
        Err(code) => code,
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn keyring_set_password(
    service: *const c_char,
    user: *const c_char,
    password: *const c_char,
) -> i32 {
    if let Err(code) = ensure_init() {
        return code;
    }
    let service = match unsafe { CStr::from_ptr(service) }.to_str() {
        Ok(s) => s,
        Err(_) => return 4,
    };
    let user = match unsafe { CStr::from_ptr(user) }.to_str() {
        Ok(s) => s,
        Err(_) => return 4,
    };
    let password = match unsafe { CStr::from_ptr(password) }.to_str() {
        Ok(s) => s,
        Err(_) => return 4,
    };
    match Entry::new(service, user) {
        Ok(entry) => match entry.set_password(password) {
            Ok(()) => 0,
            Err(e) => {
                let code = error_to_code(&e);
                set_last_error(code);
                code
            }
        },
        Err(e) => {
            let code = error_to_code(&e);
            set_last_error(code);
            code
        }
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn keyring_get_password(
    service: *const c_char,
    user: *const c_char,
) -> *mut c_char {
    if ensure_init().is_err() {
        return std::ptr::null_mut();
    }
    let service = match unsafe { CStr::from_ptr(service) }.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };
    let user = match unsafe { CStr::from_ptr(user) }.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };
    match Entry::new(service, user) {
        Ok(entry) => match entry.get_password() {
            Ok(pw) => match CString::new(pw) {
                Ok(cs) => cs.into_raw(),
                Err(_) => std::ptr::null_mut(),
            },
            Err(e) => {
                set_last_error(error_to_code(&e));
                std::ptr::null_mut()
            }
        },
        Err(e) => {
            set_last_error(error_to_code(&e));
            std::ptr::null_mut()
        }
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn keyring_set_secret(
    service: *const c_char,
    user: *const c_char,
    secret: *const u8,
    secret_len: i32,
) -> i32 {
    if let Err(code) = ensure_init() {
        return code;
    }
    let service = match unsafe { CStr::from_ptr(service) }.to_str() {
        Ok(s) => s,
        Err(_) => return 4,
    };
    let user = match unsafe { CStr::from_ptr(user) }.to_str() {
        Ok(s) => s,
        Err(_) => return 4,
    };
    let secret = unsafe { std::slice::from_raw_parts(secret, secret_len as usize) };
    match Entry::new(service, user) {
        Ok(entry) => match entry.set_secret(secret) {
            Ok(()) => 0,
            Err(e) => {
                let code = error_to_code(&e);
                set_last_error(code);
                code
            }
        },
        Err(e) => {
            let code = error_to_code(&e);
            set_last_error(code);
            code
        }
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn keyring_get_secret(
    service: *const c_char,
    user: *const c_char,
    out_len: *mut i32,
) -> *mut u8 {
    if ensure_init().is_err() {
        return std::ptr::null_mut();
    }
    let service = match unsafe { CStr::from_ptr(service) }.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };
    let user = match unsafe { CStr::from_ptr(user) }.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };
    match Entry::new(service, user) {
        Ok(entry) => match entry.get_secret() {
            Ok(secret) => {
                let mut v = secret;
                v.shrink_to_fit();
                let ptr = v.as_mut_ptr();
                let len = v.len();
                std::mem::forget(v);
                unsafe { *out_len = len as i32 };
                ptr
            }
            Err(e) => {
                set_last_error(error_to_code(&e));
                std::ptr::null_mut()
            }
        },
        Err(e) => {
            set_last_error(error_to_code(&e));
            std::ptr::null_mut()
        }
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn keyring_delete_credential(
    service: *const c_char,
    user: *const c_char,
) -> i32 {
    if let Err(code) = ensure_init() {
        return code;
    }
    let service = match unsafe { CStr::from_ptr(service) }.to_str() {
        Ok(s) => s,
        Err(_) => return 4,
    };
    let user = match unsafe { CStr::from_ptr(user) }.to_str() {
        Ok(s) => s,
        Err(_) => return 4,
    };
    match Entry::new(service, user) {
        Ok(entry) => match entry.delete_credential() {
            Ok(()) => 0,
            Err(e) => {
                let code = error_to_code(&e);
                set_last_error(code);
                code
            }
        },
        Err(e) => {
            let code = error_to_code(&e);
            set_last_error(code);
            code
        }
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn keyring_get_attributes(
    service: *const c_char,
    user: *const c_char,
) -> *mut c_char {
    if ensure_init().is_err() {
        return std::ptr::null_mut();
    }
    let service = match unsafe { CStr::from_ptr(service) }.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };
    let user = match unsafe { CStr::from_ptr(user) }.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };
    match Entry::new(service, user) {
        Ok(entry) => match entry.get_attributes() {
            Ok(attrs) => {
                let json = serde_json::to_string(&attrs).unwrap_or_default();
                match CString::new(json) {
                    Ok(cs) => cs.into_raw(),
                    Err(_) => std::ptr::null_mut(),
                }
            }
            Err(e) => {
                set_last_error(error_to_code(&e));
                std::ptr::null_mut()
            }
        },
        Err(e) => {
            set_last_error(error_to_code(&e));
            std::ptr::null_mut()
        }
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn keyring_update_attributes(
    service: *const c_char,
    user: *const c_char,
    attributes_json: *const c_char,
) -> i32 {
    if let Err(code) = ensure_init() {
        return code;
    }
    let service = match unsafe { CStr::from_ptr(service) }.to_str() {
        Ok(s) => s,
        Err(_) => return 4,
    };
    let user = match unsafe { CStr::from_ptr(user) }.to_str() {
        Ok(s) => s,
        Err(_) => return 4,
    };
    let json = match unsafe { CStr::from_ptr(attributes_json) }.to_str() {
        Ok(s) => s,
        Err(_) => return 4,
    };
    let attrs: HashMap<&str, &str> = match serde_json::from_str(json) {
        Ok(m) => m,
        Err(_) => return 4,
    };
    match Entry::new(service, user) {
        Ok(entry) => match entry.update_attributes(&attrs) {
            Ok(()) => 0,
            Err(e) => {
                let code = error_to_code(&e);
                set_last_error(code);
                code
            }
        },
        Err(e) => {
            let code = error_to_code(&e);
            set_last_error(code);
            code
        }
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn keyring_search(spec_json: *const c_char) -> *mut c_char {
    if ensure_init().is_err() {
        return std::ptr::null_mut();
    }
    let json_str = match unsafe { CStr::from_ptr(spec_json) }.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };
    let spec: HashMap<&str, &str> = match serde_json::from_str(json_str) {
        Ok(m) => m,
        Err(_) => return std::ptr::null_mut(),
    };
    match Entry::search(&spec) {
        Ok(entries) => {
            let results: Vec<serde_json::Value> = entries
                .iter()
                .filter_map(|e| {
                    e.get_specifiers().map(|(service, user)| {
                        serde_json::json!({"service": service, "user": user})
                    })
                })
                .collect();
            let json = serde_json::to_string(&results).unwrap_or_else(|_| "[]".to_string());
            match CString::new(json) {
                Ok(cs) => cs.into_raw(),
                Err(_) => std::ptr::null_mut(),
            }
        }
        Err(e) => {
            set_last_error(error_to_code(&e));
            std::ptr::null_mut()
        }
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn keyring_last_error() -> i32 {
    if let Ok(lock) = last_error_mutex().lock() {
        lock.as_ref().map(|(code, _)| *code).unwrap_or(0)
    } else {
        0
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn keyring_last_error_message() -> *mut c_char {
    if let Ok(lock) = last_error_mutex().lock() {
        match lock.as_ref() {
            Some((_, msg)) => CString::new(msg.clone())
                .ok()
                .map(|cs| cs.into_raw())
                .unwrap_or(std::ptr::null_mut()),
            None => std::ptr::null_mut(),
        }
    } else {
        std::ptr::null_mut()
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn keyring_free_string(s: *mut c_char) {
    if !s.is_null() {
        unsafe {
            drop(CString::from_raw(s));
        }
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn keyring_free_secret(s: *mut u8, len: i32) {
    if !s.is_null() {
        unsafe {
            drop(Vec::from_raw_parts(s, len as usize, len as usize));
        }
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn keyring_store_vendor() -> *mut c_char {
    if ensure_init().is_err() {
        return std::ptr::null_mut();
    }
    match keyring_core::get_default_store() {
        Some(store) => {
            let vendor = store.vendor();
            match CString::new(vendor) {
                Ok(cs) => cs.into_raw(),
                Err(_) => std::ptr::null_mut(),
            }
        }
        None => {
            set_last_error(10);
            std::ptr::null_mut()
        }
    }
}
