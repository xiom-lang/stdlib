// XIOM - OS: Ioctl
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.os.ioctl

// Depends on: xiom.ffi

// ============================================================================
// Raw ioctl(2) wrapper plus common helpers for terminal and socket control.
// NOTE: no implementation yet - add the FFI bindings and implement these
// functions during the implementation phase. TODO(compiler): implement.
// ============================================================================

// fn ioctl(fd: Int, request: Int, arg: Int) -> Result[Int, Str] - issue an ioctl request on fd, returning the kernel result. TODO(compiler): implement.
// fn ioctl_get_winsize(fd: Int) -> Result[(Int, Int), Str] - fetch the terminal size as (rows, cols). TODO(compiler): implement.
// fn ioctl_set_nonblock(fd: Int, on: Bool) -> Result[Unit, Str] - enable or disable non-blocking mode on fd. TODO(compiler): implement.
// fn ioctl_fionread(fd: Int) -> Result[Int, Str] - number of bytes available for reading on fd. TODO(compiler): implement.
