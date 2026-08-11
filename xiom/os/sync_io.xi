// XIOM - OS: Synchronous I/O Helpers
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.os.sync_io

// Depends on: xiom.ffi + xiom.io

// ============================================================================
// Blocking fd helpers: exact reads, full writes, buffered line reads, copying
// and file advice/locking. NOTE: current implementation lives in os.xi - move
// the functions here during the implementation phase. TODO(compiler): implement.
// ============================================================================

// fn read_exact(fd: Int, buf: &mut Vec[UInt8]) -> Result[Int, Str] - fill buf completely or fail. TODO(compiler): implement.
// fn write_all(fd: Int, data: &Vec[UInt8]) -> Result[Int, Str] - write every byte or fail. TODO(compiler): implement.
// fn read_until_eof(fd: Int) -> Result[Vec[UInt8], Str] - read everything until end of file. TODO(compiler): implement.
// fn read_line_buffered(fd: Int) -> Result[Str, Str] - read one line (without trailing newline). TODO(compiler): implement.
// fn copy_fd(src: Int, dst: Int) -> Result[Int, Str] - copy all bytes between two fds; returns the total copied. TODO(compiler): implement.
// fn copy_fd_n(src, dst, n) -> Result[Int, Str] - copy up to n bytes between two fds. TODO(compiler): implement.
// fn flush_fd(fd: Int) -> Result[Unit, Str] - flush userspace buffers for an fd. TODO(compiler): implement.
// fn sync_fd(fd: Int) -> Result[Unit, Str] - fsync an fd to stable storage. TODO(compiler): implement.
// fn fsync_dir(path: Str) -> Result[Unit, Str] - fsync a directory so entry changes are durable. TODO(compiler): implement.
// fn file_advise(fd: Int, offset, length, advice) -> Result[Unit, Str] - give access-pattern advice for a file range. TODO(compiler): implement.
// fn file_allocate(fd, offset, length) -> Result[Unit, Str] - preallocate space for a file range. TODO(compiler): implement.
// fn file_lock(fd: Int) -> Result[Unit, Str] - take an exclusive advisory lock, blocking. TODO(compiler): implement.
// fn file_unlock(fd: Int) -> Result[Unit, Str] - release an advisory lock. TODO(compiler): implement.
// fn file_try_lock(fd) -> Bool - attempt a non-blocking exclusive lock. TODO(compiler): implement.
