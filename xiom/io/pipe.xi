// XIOM - I/O: Pipes
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.io.pipe

// Depends on: xiom.io

// ============================================================================
// Inter-process pipe file descriptors. NOTE: current implementation lives in
// io.xi - move the functions here during the implementation phase.
// TODO(compiler): implement.
// ============================================================================

// fn pipe_create() -> (Int, Int) - create a pipe; tuple is (read_fd, write_fd). TODO(compiler): implement.
// fn pipe_read(fd: Int, buf: &mut Vec[UInt8]) -> Result[Int, Str] - read available bytes into buf. TODO(compiler): implement.
// fn pipe_write(fd: Int, data: &Vec[UInt8]) -> Result[Int, Str] - write bytes to the pipe. TODO(compiler): implement.
// fn pipe_close(fd: Int) - close a pipe descriptor. TODO(compiler): implement.
// fn pipe_is_open(fd: Int) -> Bool - whether a descriptor is still valid. TODO(compiler): implement.
// fn pipe_read_line(fd: Int) -> Result[Str, Str] - read a line from a pipe. TODO(compiler): implement.
// fn pipe_write_line(fd: Int, s: Str) -> Result[Unit, Str] - write a line to a pipe. TODO(compiler): implement.
// fn pipe_available(fd: Int) -> Int - bytes currently buffered in the pipe. TODO(compiler): implement.
// fn pipe_read_timeout(fd, ms) -> Result[Int, Str] - read with a timeout, returning bytes read. TODO(compiler): implement.
// fn pipe_write_timeout(fd, data, ms) -> Result[Int, Str] - write with a timeout, returning bytes written. TODO(compiler): implement.
