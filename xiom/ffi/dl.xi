// XIOM - FFI: Dynamic Loading
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.ffi.dl

// Depends on: xiom.ffi

use xiom.convert;

// ============================================================================
// Dynamic library loading and symbol resolution.
//
// Cross-platform: the runtime shims xiom_dl_* map to
// LoadLibraryA / GetProcAddress / FreeLibrary on Windows and to
// dlopen / dlsym / dlclose on POSIX. Handles are returned as Int addresses.
// ============================================================================

extern "C" {
  fn xiom_dl_open(path: *UInt8) -> *UInt8;
  fn xiom_dl_sym(handle: *UInt8, name: *UInt8) -> *UInt8;
  fn xiom_dl_close(handle: *UInt8) -> Int;
  fn xiom_dl_self() -> *UInt8;
  fn xiom_dl_error_code() -> Int;
}

/// Load a shared library and return a handle (Int address), or Err.
/// Complexity: O(1).
pub fn dl_open(path: Str) -> Result[Int, Str]
  requires: true
{
  unsafe {
    let p = xiom_dl_open(path as *UInt8);
    if (p as Int) == 0 {
      return Err(dl_error());
    };
    Ok(p as Int)
  }
}

/// Resolve a symbol address in a library, or Err.
/// Complexity: O(1).
pub fn dl_sym(handle: Int, name: Str) -> Result[Int, Str]
  requires: true
{
  unsafe {
    let p = xiom_dl_sym(handle as *UInt8, name as *UInt8);
    if (p as Int) == 0 {
      return Err(dl_error());
    };
    Ok(p as Int)
  }
}

/// Unload a library.
/// Complexity: O(1).
pub fn dl_close(handle: Int) -> Result[Unit, Str]
  requires: true
{
  unsafe {
    let rc = xiom_dl_close(handle as *UInt8);
    if rc == 0 {
      return Err(dl_error());
    };
    Ok(())
  }
}

/// Description of the last dynamic-loading error (OS error code).
/// Complexity: O(1).
pub fn dl_error() -> Str
  requires: true
{
  unsafe {
    let code = xiom_dl_error_code();
    "dynamic library error (code " + convert.int_to_string(code) + ")"
  }
}

/// Handle of the current executable.
/// Complexity: O(1).
pub fn dl_self() -> Int
  requires: true
{
  unsafe {
    let p = xiom_dl_self();
    p as Int
  }
}

/// Load a library with global symbol visibility. Windows resolves symbols
/// with global visibility by default, so this is identical to `dl_open`.
/// Complexity: O(1).
pub fn dl_open_global(path: Str) -> Result[Int, Str] {
  dl_open(path)
}

/// Resolve a symbol as a data address. Identical to `dl_sym` on Windows.
/// Complexity: O(1).
pub fn dl_sym_address(handle: Int, name: Str) -> Result[Int, Str] {
  dl_sym(handle, name)
}

/// Whether a symbol exists in a library.
/// Complexity: O(1).
pub fn dl_has_symbol(handle: Int, name: Str) -> Bool
  requires: true
{
  unsafe {
    let p = xiom_dl_sym(handle as *UInt8, name as *UInt8);
    (p as Int) != 0
  }
}
