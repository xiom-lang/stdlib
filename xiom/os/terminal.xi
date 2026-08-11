// XIOM - OS: Terminal
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.os.terminal

// Depends on: xiom.ffi, xiom.io

// ============================================================================
// Terminal control via FFI: isatty, tty names, pseudo-terminals, termios
// modes (raw/cbreak/canonical), nonblocking I/O, window size, and simple
// terminal effects. Raw termios/ioctl syscalls; no external dependencies.
// ============================================================================

// struct Termios { c_iflag: UInt32, c_oflag: UInt32, c_cflag: UInt32, c_lflag: UInt32, c_cc: Vec[UInt8] } - terminal attribute struct; layout mirrors struct termios.

// fn isatty(fd: Int) -> Bool - return true if fd refers to a terminal. TODO(compiler): implement.
// fn tty_name(fd: Int) -> Result[Str, Str] - return the name of the tty device for fd. TODO(compiler): implement.
// fn pty_open() -> Result[(Int, Int), Str] - open a pseudo-terminal pair (master, slave). TODO(compiler): implement.
// fn pty_close(master: Int, slave: Int) -> Unit - close both ends of a pseudo-terminal pair. TODO(compiler): implement.
// fn termios_get(fd: Int) -> Result[Termios, Str] - read the current termios attributes for fd. TODO(compiler): implement.
// fn termios_set(fd: Int, t: Termios) -> Result[Unit, Str] - apply the given termios attributes to fd. TODO(compiler): implement.
// fn raw_mode(fd: Int) -> Result[Termios, Str] - enable raw mode; returns the previous attributes. TODO(compiler): implement.
// fn restore_mode(fd: Int, t: Termios) -> Result[Unit, Str] - restore previously saved attributes. TODO(compiler): implement.
// fn cbreak_mode(fd: Int) -> Result[Termios, Str] - enable cbreak mode; returns the previous attributes. TODO(compiler): implement.
// fn canonical_mode(fd: Int) -> Result[Termios, Str] - enable canonical (line-buffered) mode; returns the previous attributes. TODO(compiler): implement.
// fn nonblock(fd: Int) -> Result[Unit, Str] - set the fd to nonblocking I/O. TODO(compiler): implement.
// fn blocking(fd: Int) -> Result[Unit, Str] - clear the nonblocking flag on fd. TODO(compiler): implement.
// fn winsize(fd: Int) -> Result[(Int, Int), Str] - return the terminal window size as (rows, cols). TODO(compiler): implement.
// fn set_winsize(fd: Int, rows: Int, cols: Int) -> Result[Unit, Str] - set the terminal window size. TODO(compiler): implement.
// fn terminal_width() -> Int - query the width of the controlling terminal, 0 if unknown. TODO(compiler): implement.
// fn terminal_height() -> Int - query the height of the controlling terminal, 0 if unknown. TODO(compiler): implement.
// fn terminal_title(title: Str) -> Str - return the escape sequence that sets the window title. TODO(compiler): implement.
// fn terminal_bell() -> Str - return the bell escape sequence. TODO(compiler): implement.
