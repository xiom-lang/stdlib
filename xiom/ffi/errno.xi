// XIOM - FFI: Errno
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.ffi.errno

// Depends on: xiom.ffi

use xiom.io;

// ============================================================================
// Errno access and C error string helpers.
//
// The CRT `_errno()` accessor returns a pointer to the thread-local errno;
// `strerror` maps codes to messages (verified on this Windows/MSVC toolchain,
// e.g. errno 2 -> "No such file or directory").
// ============================================================================

extern "C" {
  fn _errno() -> *UInt8;
  fn strerror(code: Int) -> *UInt8;
}

/// Last observed errno value (snapshot updated by `errno_get`).
var last_errno: Int = 0;

/// Read the current errno value (and record it as the snapshot). Reads the
/// CRT errno cell byte-wise (64-bit little-endian).
/// Complexity: O(1).
pub fn errno_get() -> Int
  requires: true
{
  unsafe {
    let p = _errno() as *UInt8;
    let b0 = p[0] as Int;
    let b1 = p[1] as Int;
    let b2 = p[2] as Int;
    let b3 = p[3] as Int;
    let b4 = p[4] as Int;
    let b5 = p[5] as Int;
    let b6 = p[6] as Int;
    let b7 = p[7] as Int;
    let v = b0 | (b1 << 8) | (b2 << 16) | (b3 << 24) | (b4 << 32) | (b5 << 40) | (b6 << 48) | (b7 << 56);
    last_errno = v;
    v
  }
}

/// Set the errno value (byte-wise 64-bit little-endian store).
/// Complexity: O(1).
pub fn errno_set(code: Int) {
  unsafe {
    let p = _errno() as *UInt8;
    p[0] = ( code        & 0xFF) as UInt8;
    p[1] = ((code >>  8) & 0xFF) as UInt8;
    p[2] = ((code >> 16) & 0xFF) as UInt8;
    p[3] = ((code >> 24) & 0xFF) as UInt8;
    p[4] = ((code >> 32) & 0xFF) as UInt8;
    p[5] = ((code >> 40) & 0xFF) as UInt8;
    p[6] = ((code >> 48) & 0xFF) as UInt8;
    p[7] = ((code >> 56) & 0xFF) as UInt8;
  };
  last_errno = code;
}

/// Human-readable message for an error code.
/// Complexity: O(1).
pub fn errno_strerror(code: Int) -> Str
  requires: true
{
  unsafe {
    Str.from_cstring(strerror(code))
  }
}

/// Print `msg` followed by the current errno message.
/// Complexity: O(1).
pub fn errno_perror(msg: Str) {
  let code = errno_get();
  io.println(msg + ": " + errno_strerror(code));
}

/// Last recorded errno (snapshot).
/// Complexity: O(1).
pub fn errno_last() -> Int {
  last_errno
}

/// Whether a code represents an error (non-zero).
/// Complexity: O(1).
pub fn errno_is_error(code: Int) -> Bool {
  code != 0
}

/// Symbolic name for an error code (for example "ENOENT"). Unknown codes map
/// to "UNKNOWN".
/// Complexity: O(1).
pub fn errno_name(code: Int) -> Str {
  if code == 1 {
    return "EPERM";
  };
  if code == 2 {
    return "ENOENT";
  };
  if code == 5 {
    return "EIO";
  };
  if code == 9 {
    return "EBADF";
  };
  if code == 11 {
    return "EAGAIN";
  };
  if code == 12 {
    return "ENOMEM";
  };
  if code == 13 {
    return "EACCES";
  };
  if code == 20 {
    return "ENOTDIR";
  };
  if code == 21 {
    return "EISDIR";
  };
  if code == 22 {
    return "EINVAL";
  };
  if code == 28 {
    return "ENOSPC";
  };
  if code == 32 {
    return "EPIPE";
  };
  "UNKNOWN"
}
