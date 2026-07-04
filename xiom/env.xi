// XIOM — Environment Variables
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.env

extern "C" {
  fn getenv(name: *UInt8) -> *UInt8;
  fn setenv(name: *UInt8, value: *UInt8, overwrite: Int32) -> Int32;
  fn unsetenv(name: *UInt8) -> Int32;
  fn getcwd(buf: *UInt8, size: UInt) -> *UInt8;
  fn chdir(path: *UInt8) -> Int32;
}

pub const OS: Str = "windows";     // compile-time target OS
pub const ARCH: Str = "x86_64";    // compile-time target architecture
pub const FAMILY: Str = "windows"; // "unix" or "windows"

fn cstr(s: Str) -> *UInt8 {
  unsafe {
    return s as *UInt8;
  }
}

pub fn var(name: Str) -> Result<Str, Str> {
  let opt = var_opt(name);
  match opt {
    Some(v) => Ok(v);
    None => Err("environment variable not found");
  }
}

pub fn var_opt(name: Str) -> Option<Str> {
  unsafe {
    let raw = getenv(cstr(name));
    if raw == null {
      return None;
    };
    return Some(Str.from_cstring(raw));
  }
}

pub fn set_var(name: Str, value: Str) {
  unsafe {
    let _ = setenv(cstr(name), cstr(value), 1);
  }
}

pub fn remove_var(name: Str) {
  unsafe {
    let _ = unsetenv(cstr(name));
  }
}

pub fn vars() -> Vec<(Str, Str)> {
  // OS env var iteration is not supported via the C standard library.
  // On Unix, the `environ` external variable could be accessed but
  // is platform-specific and non-portable.
  return Vec[(Str, Str)].new();
}

pub fn args() -> Vec<Str> {
  return io.args();
}

pub fn args_os() -> Vec<Str> {
  return args();
}

pub fn current_exe() -> Result<Str, Str> {
  let a = args();
  if a.len() > 0 {
    return Ok(a[0]);
  };
  return Err("cannot determine executable path");
}

pub fn current_dir() -> Result<Str, Str> {
  unsafe {
    var buf: [4096]UInt8;
    let ptr = getcwd(&buf[0], 4096 as UInt);
    if ptr == null {
      return Err("failed to get current directory");
    };
    return Ok(Str.from_cstring(ptr));
  }
}

pub fn set_current_dir(path: Str) -> Result<Unit, Str> {
  unsafe {
    let rc = chdir(cstr(path));
    if rc != 0 {
      return Err("failed to set current directory");
    };
    return Ok(());
  }
}

pub fn temp_dir() -> Str {
  let v = var_opt("TMP");
  match v {
    Some(t) => return t;
    None => {}
  };
  let v = var_opt("TEMP");
  match v {
    Some(t) => return t;
    None => {}
  };
  let v = var_opt("TMPDIR");
  match v {
    Some(t) => return t;
    None => {}
  };
  return "/tmp";
}

pub fn home_dir() -> Option<Str> {
  let v = var_opt("USERPROFILE");
  match v {
    Some(h) => return Some(h);
    None => {}
  };
  return var_opt("HOME");
}

pub fn data_dir() -> Option<Str> {
  let v = var_opt("XDG_DATA_HOME");
  match v {
    Some(d) => return Some(d);
    None => {}
  };
  let h = home_dir();
  match h {
    Some(home) => Some(join_paths(home, if FAMILY == "windows" { "AppData/Roaming" } else { ".local/share" }));
    None => None;
  }
}

pub fn cache_dir() -> Option<Str> {
  let v = var_opt("XDG_CACHE_HOME");
  match v {
    Some(d) => return Some(d);
    None => {}
  };
  let h = home_dir();
  match h {
    Some(home) => Some(join_paths(home, if FAMILY == "windows" { "AppData/Local" } else { ".cache" }));
    None => None;
  }
}

pub fn config_dir() -> Option<Str> {
  let v = var_opt("XDG_CONFIG_HOME");
  match v {
    Some(d) => return Some(d);
    None => {}
  };
  let h = home_dir();
  match h {
    Some(home) => Some(join_paths(home, if FAMILY == "windows" { "AppData/Roaming" } else { ".config" }));
    None => None;
  }
}

pub fn executable_dir() -> Option<Str> {
  let exe = current_exe();
  match exe {
    Ok(path) => {
      let sep = path_separator();
      let idx = string.last_index_of(path, sep);
      match idx {
        Some(i) => Some(string.str_slice(path, 0, i));
        None => None;
      }
    };
    Err(_) => None;
  }
}

pub fn join_paths(a: Str, b: Str) -> Str {
  return string.str_concat(string.str_concat(a, path_separator()), b);
}

pub fn path_separator() -> Str {
  if FAMILY == "windows" {
    return "\\";
  };
  return "/";
}
