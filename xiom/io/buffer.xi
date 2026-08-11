// XIOM - I/O: Buffered I/O
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.io.buffer

// Depends on: xiom.io

// ============================================================================
// Buffered readers and writers over raw file descriptors. NOTE: current
// implementation lives in io.xi - move the functions here during the
// implementation phase. TODO(compiler): implement.
// ============================================================================

// fn buf_reader_new(fd: Int) -> BufReader - wrap an fd; BufReader holds the fd and an internal buffer. TODO(compiler): implement.
// fn br_read_line(r) -> Result[Str, Str] - read one line through the buffer. TODO(compiler): implement.
// fn br_read_bytes(r, n) -> Result[Vec[UInt8], Str] - read exactly n bytes. TODO(compiler): implement.
// fn br_read_until(r, delim: UInt8) -> Result[Vec[UInt8], Str] - read bytes up to a delimiter. TODO(compiler): implement.
// fn br_peek(r, n) -> Result[Vec[UInt8], Str] - look ahead n bytes without consuming. TODO(compiler): implement.
// fn br_seek(r, pos: Int) - move the underlying read position. TODO(compiler): implement.
// fn br_tell(r) -> Int - current read position. TODO(compiler): implement.
// fn buf_writer_new(fd: Int) -> BufWriter - wrap an fd; BufWriter holds the fd and an internal buffer. TODO(compiler): implement.
// fn bw_write(w, data: &Vec[UInt8]) -> Result[Unit, Str] - buffer bytes for writing. TODO(compiler): implement.
// fn bw_write_str(w, s: Str) -> Result[Unit, Str] - buffer a string for writing. TODO(compiler): implement.
// fn bw_flush(w) -> Result[Unit, Str] - flush buffered bytes to the fd. TODO(compiler): implement.
// fn bw_into_inner(w) -> Int - flush and return the underlying fd. TODO(compiler): implement.
