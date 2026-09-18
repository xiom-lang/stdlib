// XIOM -- Environment Variables
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.env

use xiom.io;
use xiom.string;

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

fn cstr(s: Str) -> *UInt8
  requires: s.len() > 0
  ensures:  result != null
{
  unsafe {
    return s as *UInt8;
  }
}

pub fn get_var(name: Str) -> Result<Str, Str>
  requires: name.len() > 0
{
  let opt = var_opt(name);
  match opt {
    Some(v) => Ok(v);
    None => Err("environment variable not found");
  }
}

pub fn var_opt(name: Str) -> Option<Str>
  requires: name.len() > 0
{
  // read_file-proven shape (multiple unsafe blocks, ~25 statements ->
  // inlinehint, never always-inlined): pointer/Int assignments + Vec.push
  // inside unsafe, Str built OUTSIDE via Str::from_utf8. Small unsafe fns
  // lose statements when always-inlined into a caller (BUG 21/26 family --
  // re-triggered by 4e95717e; see COMPILER_BUGS.md BUG 28 #1).
  let c_name = cstr(name);
  let raw: *UInt8;
  unsafe {
    raw = getenv(c_name);
    if raw == null {
      return None;
    }
  }
  var len: Int = 0;
  unsafe {
    var i = 0;
    while *(raw.offset(i)) != 0 {
      len = len + 1;
      i = i + 1;
    }
  }
  var buf: Vec[UInt8] = Vec[UInt8]::with_capacity(len as UInt);
  unsafe {
    var i = 0;
    while i < len {
      buf.push(*(raw.offset(i)));
      i = i + 1;
    }
  }
  return Some(Str::from_utf8(buf));
}

pub fn set_var(name: Str, value: Str)
  requires: name.len() > 0
{
  unsafe {
    let _ = setenv(cstr(name), cstr(value), 1);
  }
}

pub fn remove_var(name: Str)
  requires: name.len() > 0
{
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

pub fn current_dir() -> Result<Str, Str>
  requires: true
  ensures: result is Ok => result.len() > 0
{
  unsafe {
    var buf: [4096]UInt8;
    let ptr = getcwd(&buf[0], 4096 as UInt);
    if ptr == null {
      return Err("failed to get current directory");
    };
    return Ok(Str.from_cstring(ptr));
  }
}

pub fn set_current_dir(path: Str) -> Result<Unit, Str>
  requires: path.len() > 0
{
  unsafe {
    let rc = chdir(cstr(path));
    if rc != 0 {
      return Err("failed to set current directory");
    };
    return Ok(());
  }
}

pub fn temp_dir() -> Str
  ensures: result.len() > 0
{
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

pub fn home_dir() -> Option<Str>
  ensures: result is Some => result.len() > 0
{
  let v = var_opt("USERPROFILE");
  match v {
    Some(h) => return Some(h);
    None => {}
  };
  let v2 = var_opt("HOME");
  match v2 {
    Some(h) => return Some(h);
    None => {}
  };
  return None;
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

// ----------------------------------------------------------
//  Convenience wrappers
// ----------------------------------------------------------

// var_or returns the value of the environment variable name,
// or default if the variable is not set.
// Complexity: O(1).
/// var_or returns the value of the environment variable name,
/// or default if the variable is not set.
/// Complexity: O(1).
pub fn var_or(name: Str, default: Str) -> Str {
  let result = var_opt(name);
  match result {
    Some(val) => val;
    None => default;
  }
}

// has_var returns true if the environment variable name is set.
// Complexity: O(1).
/// has_var returns true if the environment variable name is set.
/// Complexity: O(1).
pub fn has_var(name: Str) -> Bool {
  let result = var_opt(name);
  match result {
    Some(_) => true;
    None => false;
  }
}

// all_var_names returns an empty vector on all platforms -- the Xiom
// runtime does not support iterating over environment variables
// via the C standard library.
/// all_var_names returns an empty vector on all platforms -- the Xiom
/// runtime does not support iterating over environment variables
/// via the C standard library.
pub fn all_var_names() -> Vec[Str] {
  var result: Vec[Str] = Vec[Str]::new();
  return result;
}

// all_var_values returns an empty vector on all platforms -- see
// all_var_names for rationale.
/// all_var_values returns an empty vector on all platforms -- see
/// all_var_names for rationale.
pub fn all_var_values() -> Vec[Str] {
  var result: Vec[Str] = Vec[Str]::new();
  return result;
}

// set_var_if_absent sets name to value only if name is not already set.
// Complexity: O(1).  WARNING: setenv is not available on Windows MSVC.
/// set_var_if_absent sets name to value only if name is not already set.
/// Complexity: O(1).  WARNING: setenv is not available on Windows MSVC.
pub fn set_var_if_absent(name: Str, value: Str) {
  if !has_var(name) {
    let _ = set_var(name, value);
  };
}

// clear_var removes the environment variable name.
// Alias for remove_var.  Same Windows caveat.
/// clear_var removes the environment variable name.
/// Alias for remove_var.  Same Windows caveat.
pub fn clear_var(name: Str) {
  let _ = remove_var(name);
}

// ----------------------------------------------------------
//  Command-line argument helpers
// ----------------------------------------------------------

// args_len returns the number of command-line arguments.
// Complexity: O(1).
/// args_len returns the number of command-line arguments.
/// Complexity: O(1).
pub fn args_len() -> Int {
  let a = io.args();
  return a.len();
}

// arg_at returns the i-th command-line argument, or None if
// i is out of bounds.  Complexity: O(1).
/// arg_at returns the i-th command-line argument, or None if
/// i is out of bounds.  Complexity: O(1).
pub fn arg_at(i: Int) -> Option[Str] {
  let a = io.args();
  if i < 0 || i >= a.len() {
    return None;
  };
  return Some(a[i]);
}

// arg_contains returns true if any command-line argument equals s.
// Complexity: O(n) where n = arg count.
/// arg_contains returns true if any command-line argument equals s.
/// Complexity: O(n) where n = arg count.
pub fn arg_contains(s: Str) -> Bool {
  let a = io.args();
  var i = 0;
  while i < a.len() {
    if a[i] == s {
      return true;
    };
    i = i + 1;
  };
  return false;
}

// ----------------------------------------------------------
//  Directory helpers
// ----------------------------------------------------------

// current_dir_str returns the current working directory as a Str,
// or "." if the OS call fails.  Wraps getcwd directly.
// Complexity: O(1).
/// current_dir_str returns the current working directory as a Str,
/// or "." if the OS call fails.  Wraps getcwd directly.
/// Complexity: O(1).
pub fn current_dir_str() -> Str
  requires: true
{
  unsafe {
    var buf: [4096]UInt8;
    let ptr = getcwd(&buf[0], 4096 as UInt);
    if ptr == null {
      return ".";
    };
    return Str.from_cstring(ptr);
  }
}
