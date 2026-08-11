// XIOM - Async: IO
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.async.io

// Depends on: xiom.async

// ============================================================================
// Non-blocking wrappers over file, socket, and stream descriptors.
// NOTE: current implementation lives in async.xi - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

// type Future - an opaque handle to a pending async operation.
// fn async_read(fd: Int, buf: &mut Vec[UInt8]) -> Future - read into buf without blocking. TODO(compiler): implement.
// fn async_write(fd: Int, data: &Vec[UInt8]) -> Future - write data without blocking. TODO(compiler): implement.
// fn async_read_file(path: Str) -> Future - read an entire file into memory. TODO(compiler): implement.
// fn async_write_file(path: Str, data: &Vec[UInt8]) -> Future - write an entire file to disk. TODO(compiler): implement.
// fn async_accept(listener: Int) -> Future - accept a connection on the listener socket. TODO(compiler): implement.
// fn async_connect(fd: Int, addr: Str, port: Int) -> Future - open a TCP connection. TODO(compiler): implement.
// fn async_read_line(fd: Int) -> Future - read one line from the descriptor. TODO(compiler): implement.
// fn async_read_until(fd: Int, delim: UInt8) -> Future - read until the delimiter byte. TODO(compiler): implement.
