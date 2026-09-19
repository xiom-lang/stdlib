// XIOM - OS: Terminal
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.os.terminal

// Depends on: xiom.ffi, xiom.io

// ============================================================================
// Terminal control via FFI: isatty, tty names, pseudo-terminals, termios
// modes (raw/cbreak/canonical), nonblocking I/O, window size, and simple
// terminal effects. The escape-sequence helpers (title/bell) are pure and
// fully implemented; the termios/ioctl-backed functions are documented stubs
// returning Err (or documented defaults) because the pure stdlib does not
// expose those syscalls.
// ============================================================================

/// struct Termios { c_iflag: UInt32, c_oflag: UInt32, c_cflag: UInt32,
///   c_lflag: UInt32, c_cc: Vec[UInt8] } - terminal attribute struct; layout
/// mirrors struct termios.
pub type Termios = {
  c_iflag: UInt32;
  c_oflag: UInt32;
  c_cflag: UInt32;
  c_lflag: UInt32;
  c_cc: Vec[UInt8];
}

/// Return true if fd refers to a terminal.
/// NOT IMPLEMENTED: requires the isatty syscall. Returns false.
pub fn isatty(fd: Int) -> Bool {
  let _ = fd;
  false
}

/// Return the name of the tty device for fd.
/// NOT IMPLEMENTED: requires the ttyname syscall.
/// Returns: Err("tty_name: ttyname not available in the pure stdlib").
pub fn tty_name(fd: Int) -> Result[Str, Str] {
  let _ = fd;
  Err("tty_name: ttyname not available in the pure stdlib")
}

/// Open a pseudo-terminal pair (master, slave).
/// NOT IMPLEMENTED: requires posix_openpt/grantpt/unlockpt/ptsname.
/// Returns: Err("pty_open: pseudo-terminals not available in the pure stdlib").
pub fn pty_open() -> Result[(Int, Int), Str] {
  Err("pty_open: pseudo-terminals not available in the pure stdlib")
}

/// Close both ends of a pseudo-terminal pair.
/// NO-OP: no pty pairs exist in the pure stdlib.
pub fn pty_close(master: Int, slave: Int) -> Unit {
  let _ = master;
  let _ = slave;
}

/// Read the current termios attributes for fd.
/// NOT IMPLEMENTED: requires tcgetattr.
/// Returns: Err("termios_get: tcgetattr not available in the pure stdlib").
pub fn termios_get(fd: Int) -> Result[Termios, Str] {
  let _ = fd;
  Err("termios_get: tcgetattr not available in the pure stdlib")
}

/// Apply the given termios attributes to fd.
/// NOT IMPLEMENTED: requires tcsetattr.
/// Returns: Err("termios_set: tcsetattr not available in the pure stdlib").
pub fn termios_set(fd: Int, t: Termios) -> Result[Unit, Str] {
  let _ = fd;
  let _ = t;
  Err("termios_set: tcsetattr not available in the pure stdlib")
}

/// Enable raw mode; returns the previous attributes.
/// NOT IMPLEMENTED: requires tcgetattr/tcsetattr.
/// Returns: Err("raw_mode: termios not available in the pure stdlib").
pub fn raw_mode(fd: Int) -> Result[Termios, Str] {
  let _ = fd;
  Err("raw_mode: termios not available in the pure stdlib")
}

/// Restore previously saved attributes.
/// NOT IMPLEMENTED: requires tcsetattr.
/// Returns: Err("restore_mode: tcsetattr not available in the pure stdlib").
pub fn restore_mode(fd: Int, t: Termios) -> Result[Unit, Str] {
  let _ = fd;
  let _ = t;
  Err("restore_mode: tcsetattr not available in the pure stdlib")
}

/// Enable cbreak mode; returns the previous attributes.
/// NOT IMPLEMENTED: requires tcgetattr/tcsetattr.
/// Returns: Err("cbreak_mode: termios not available in the pure stdlib").
pub fn cbreak_mode(fd: Int) -> Result[Termios, Str] {
  let _ = fd;
  Err("cbreak_mode: termios not available in the pure stdlib")
}

/// Enable canonical (line-buffered) mode; returns the previous attributes.
/// NOT IMPLEMENTED: requires tcgetattr/tcsetattr.
/// Returns: Err("canonical_mode: termios not available in the pure stdlib").
pub fn canonical_mode(fd: Int) -> Result[Termios, Str] {
  let _ = fd;
  Err("canonical_mode: termios not available in the pure stdlib")
}

/// Set the fd to nonblocking I/O.
/// NOT IMPLEMENTED: requires fcntl(F_GETFL/F_SETFL).
/// Returns: Err("nonblock: fcntl not available in the pure stdlib").
pub fn nonblock(fd: Int) -> Result[Unit, Str] {
  let _ = fd;
  Err("nonblock: fcntl not available in the pure stdlib")
}

/// Clear the nonblocking flag on fd.
/// NOT IMPLEMENTED: requires fcntl(F_GETFL/F_SETFL).
/// Returns: Err("blocking: fcntl not available in the pure stdlib").
pub fn blocking(fd: Int) -> Result[Unit, Str] {
  let _ = fd;
  Err("blocking: fcntl not available in the pure stdlib")
}

/// Return the terminal window size as (rows, cols).
/// NOT IMPLEMENTED: requires ioctl(TIOCGWINSZ).
/// Returns: Err("winsize: TIOCGWINSZ not available in the pure stdlib").
pub fn winsize(fd: Int) -> Result[(Int, Int), Str] {
  let _ = fd;
  Err("winsize: TIOCGWINSZ not available in the pure stdlib")
}

/// Set the terminal window size.
/// NOT IMPLEMENTED: requires ioctl(TIOCSWINSZ).
/// Returns: Err("set_winsize: TIOCSWINSZ not available in the pure stdlib").
pub fn set_winsize(fd: Int, rows: Int, cols: Int) -> Result[Unit, Str] {
  let _ = fd;
  let _ = rows;
  let _ = cols;
  Err("set_winsize: TIOCSWINSZ not available in the pure stdlib")
}

/// Query the width of the controlling terminal.
/// NOT IMPLEMENTED: no termios query is available. Returns 0.
pub fn terminal_width() -> Int {
  0
}

/// Query the height of the controlling terminal.
/// NOT IMPLEMENTED: no termios query is available. Returns 0.
pub fn terminal_height() -> Int {
  0
}

/// Return the escape sequence that sets the window title.
/// Parameters: title -- the desired title text.
/// Returns: the "ESC]0;<title>BEL" sequence.
/// Complexity: O(n). Pure.
pub fn terminal_title(title: Str) -> Str {
  var result = "\x1b]0;";
  result = result + title;
  result = result + "\x07";
  result
}

/// Return the bell escape sequence.
/// Returns: the BEL character "\x07".
/// Complexity: O(1). Pure.
pub fn terminal_bell() -> Str {
  "\x07"
}
