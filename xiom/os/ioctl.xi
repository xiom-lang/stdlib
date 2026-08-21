// XIOM - OS: Ioctl
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.os.ioctl

// Depends on: xiom.ffi

// ============================================================================
// Raw ioctl(2) wrapper plus common helpers for terminal and socket control.
// All functions require the ioctl syscall, which the pure stdlib does not
// expose -- every function is a documented stub returning Err.
// ============================================================================

/// Issue an ioctl request on fd, returning the kernel result.
/// NOT IMPLEMENTED: requires the ioctl syscall.
/// Returns: Err("ioctl: ioctl syscall not available in the pure stdlib").
pub fn ioctl(fd: Int, request: Int, arg: Int) -> Result[Int, Str] {
  let _ = fd;
  let _ = request;
  let _ = arg;
  Err("ioctl: ioctl syscall not available in the pure stdlib")
}

/// Fetch the terminal size as (rows, cols).
/// NOT IMPLEMENTED: requires ioctl(TIOCGWINSZ).
/// Returns: Err("ioctl_get_winsize: TIOCGWINSZ not available in the pure stdlib").
pub fn ioctl_get_winsize(fd: Int) -> Result[(Int, Int), Str] {
  let _ = fd;
  Err("ioctl_get_winsize: TIOCGWINSZ not available in the pure stdlib")
}

/// Enable or disable non-blocking mode on fd.
/// NOT IMPLEMENTED: requires fcntl(F_GETFL/F_SETFL).
/// Returns: Err("ioctl_set_nonblock: fcntl not available in the pure stdlib").
pub fn ioctl_set_nonblock(fd: Int, on: Bool) -> Result[Unit, Str] {
  let _ = fd;
  let _ = on;
  Err("ioctl_set_nonblock: fcntl not available in the pure stdlib")
}

/// Number of bytes available for reading on fd.
/// NOT IMPLEMENTED: requires ioctl(FIONREAD).
/// Returns: Err("ioctl_fionread: FIONREAD not available in the pure stdlib").
pub fn ioctl_fionread(fd: Int) -> Result[Int, Str] {
  let _ = fd;
  Err("ioctl_fionread: FIONREAD not available in the pure stdlib")
}
