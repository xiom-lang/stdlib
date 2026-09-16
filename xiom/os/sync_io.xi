// XIOM - OS: Synchronous I/O Helpers
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.os.sync_io

// Depends on: xiom.ffi + xiom.io

// ============================================================================
// Blocking fd helpers: exact reads, full writes, buffered line reads, copying
// and file advice/locking. All require raw fd syscalls (read/write/lseek/
// fcntl/posix_fadvise/posix_fallocate) that the pure stdlib does not expose --
// every function is a documented stub returning Err (or a documented default).
// ============================================================================

/// Fill buf completely or fail.
/// NOT IMPLEMENTED: requires raw fd read syscalls.
/// Returns: Err("read_exact: fd syscalls not available in the pure stdlib").
pub fn read_exact(fd: Int, buf: &mut Vec[UInt8]) -> Result[Int, Str] {
  let _ = fd;
  let _ = buf;
  Err("read_exact: fd syscalls not available in the pure stdlib")
}

/// Write every byte or fail.
/// NOT IMPLEMENTED: requires raw fd write syscalls.
/// Returns: Err("write_all: fd syscalls not available in the pure stdlib").
pub fn write_all(fd: Int, data: &Vec[UInt8]) -> Result[Int, Str] {
  let _ = fd;
  let _ = data;
  Err("write_all: fd syscalls not available in the pure stdlib")
}

/// Read everything until end of file.
/// NOT IMPLEMENTED: requires raw fd read syscalls.
/// Returns: Err("read_until_eof: fd syscalls not available in the pure stdlib").
pub fn read_until_eof(fd: Int) -> Result[Vec[UInt8], Str] {
  let _ = fd;
  Err("read_until_eof: fd syscalls not available in the pure stdlib")
}

/// Read one line (without trailing newline).
/// NOT IMPLEMENTED: requires raw fd read syscalls.
/// Returns: Err("read_line_buffered: fd syscalls not available in the pure stdlib").
pub fn read_line_buffered(fd: Int) -> Result[Str, Str] {
  let _ = fd;
  Err("read_line_buffered: fd syscalls not available in the pure stdlib")
}

/// Copy all bytes between two fds; returns the total copied.
/// NOT IMPLEMENTED: requires raw fd read/write syscalls.
/// Returns: Err("copy_fd: fd syscalls not available in the pure stdlib").
pub fn copy_fd(src: Int, dst: Int) -> Result[Int, Str] {
  let _ = src;
  let _ = dst;
  Err("copy_fd: fd syscalls not available in the pure stdlib")
}

/// Copy up to n bytes between two fds.
/// NOT IMPLEMENTED: requires raw fd read/write syscalls.
/// Returns: Err("copy_fd_n: fd syscalls not available in the pure stdlib").
pub fn copy_fd_n(src: Int, dst: Int, n: Int) -> Result[Int, Str] {
  let _ = src;
  let _ = dst;
  let _ = n;
  Err("copy_fd_n: fd syscalls not available in the pure stdlib")
}

/// Flush userspace buffers for an fd.
/// NOT IMPLEMENTED: requires fflush on an fd stream.
/// Returns: Err("flush_fd: fd flushing not available in the pure stdlib").
pub fn flush_fd(fd: Int) -> Result[Unit, Str] {
  let _ = fd;
  Err("flush_fd: fd flushing not available in the pure stdlib")
}

/// fsync an fd to stable storage.
/// NOT IMPLEMENTED: requires the fsync syscall.
/// Returns: Err("sync_fd: fsync not available in the pure stdlib").
pub fn sync_fd(fd: Int) -> Result[Unit, Str] {
  let _ = fd;
  Err("sync_fd: fsync not available in the pure stdlib")
}

/// fsync a directory so entry changes are durable.
/// NOT IMPLEMENTED: requires opening the directory and calling fsync.
/// Returns: Err("fsync_dir: fsync not available in the pure stdlib").
pub fn fsync_dir(path: Str) -> Result[Unit, Str] {
  let _ = path;
  Err("fsync_dir: fsync not available in the pure stdlib")
}

/// Give access-pattern advice for a file range.
/// NOT IMPLEMENTED: requires posix_fadvise.
/// Returns: Err("file_advise: posix_fadvise not available in the pure stdlib").
pub fn file_advise(fd: Int, offset: Int, length: Int, advice: Int) -> Result[Unit, Str] {
  let _ = fd;
  let _ = offset;
  let _ = length;
  let _ = advice;
  Err("file_advise: posix_fadvise not available in the pure stdlib")
}

/// Preallocate space for a file range.
/// NOT IMPLEMENTED: requires posix_fallocate.
/// Returns: Err("file_allocate: posix_fallocate not available in the pure stdlib").
pub fn file_allocate(fd: Int, offset: Int, length: Int) -> Result[Unit, Str] {
  let _ = fd;
  let _ = offset;
  let _ = length;
  Err("file_allocate: posix_fallocate not available in the pure stdlib")
}

/// Take an exclusive advisory lock, blocking.
/// NOT IMPLEMENTED: requires fcntl(F_SETLKW).
/// Returns: Err("file_lock: fcntl locking not available in the pure stdlib").
pub fn file_lock(fd: Int) -> Result[Unit, Str] {
  let _ = fd;
  Err("file_lock: fcntl locking not available in the pure stdlib")
}

/// Release an advisory lock.
/// NOT IMPLEMENTED: requires fcntl(F_SETLK).
/// Returns: Err("file_unlock: fcntl locking not available in the pure stdlib").
pub fn file_unlock(fd: Int) -> Result[Unit, Str] {
  let _ = fd;
  Err("file_unlock: fcntl locking not available in the pure stdlib")
}

/// Attempt a non-blocking exclusive lock.
/// NOT IMPLEMENTED: requires fcntl(F_SETLK). Returns false.
pub fn file_try_lock(fd: Int) -> Bool {
  let _ = fd;
  false
}
