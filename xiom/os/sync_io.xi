// XIOM - OS: Synchronous I/O Helpers
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.os.sync_io

// Depends on: xiom.ffi + xiom.io

// ============================================================================
// Blocking fd helpers: exact reads, full writes, buffered line reads, copying
// and file advice/locking. Wave 115 lands the read/write/close/open-append/
// open-read/fsync/fsync_dir syscalls through the runtime shims below
// (runtime/xiom_runtime.c); the remaining helpers (lseek-class positions,
// fcntl locking, fadvise/fallocate, flush_fd) stay documented stubs
// returning Err.
// ============================================================================

extern "C" {
  fn xiom_read(fd: Int32, buf: *UInt8, count: UInt) -> Int;
  fn xiom_write(fd: Int32, buf: *UInt8, count: UInt) -> Int;
  fn xiom_close(fd: Int32) -> Int32;
  fn xiom_open_append(path: *UInt8) -> Int;
  fn xiom_open_read(path: *UInt8) -> Int;
  fn xiom_fsync_fd(fd: Int) -> Int32;
  fn xiom_fsync_dir(path: *UInt8) -> Int32;
}

/// Fill buf completely from fd or fail on early EOF.
/// Real implementation (wave 115): reads through the xiom_read runtime shim
/// in 4 KiB staging chunks; a short read returns
/// Err("read_exact: unexpected EOF").
/// Returns: Ok(buf.len()) when every byte was read.
pub fn read_exact(fd: Int, buf: &mut Vec[UInt8]) -> Result[Int, Str]
  requires: fd >= 0
{
  let want = buf.len();
  if want == 0 {
    return Ok(0);
  }
  var got = 0;
  var stage: [4096]UInt8;
  while got < want {
    var chunk = want - got;
    if chunk > 4096 {
      chunk = 4096;
    }
    let n: Int;
    unsafe {
      n = xiom_read(fd as Int32, &stage[0] as *UInt8, chunk as UInt);
    }
    if n <= 0 {
      return Err("read_exact: unexpected EOF");
    }
    var i = 0;
    while i < n && got < want {
      buf[got] = stage[i];
      got = got + 1;
      i = i + 1;
    }
  }
  Ok(got)
}

/// Write every byte of data to fd or fail.
/// Real implementation (wave 115): advances by the syscall-reported partial
/// counts through the xiom_write runtime shim (no per-byte writes).
/// Returns: Ok(data.len()) on success; Err("write_all: write failed").
pub fn write_all(fd: Int, data: &Vec[UInt8]) -> Result[Int, Str]
  requires: fd >= 0
{
  let n = data.len();
  if n == 0 {
    return Ok(0);
  }
  var sent = 0;
  while sent < n {
    let w: Int;
    unsafe {
      w = xiom_write(fd as Int32, &data[sent] as *UInt8, (n - sent) as UInt);
    }
    if w <= 0 {
      return Err("write_all: write failed");
    }
    sent = sent + w;
  }
  Ok(sent)
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
/// Real implementation (wave 115): fsync(2) / _commit through the
/// xiom_fsync_fd runtime shim.
/// Returns: Ok(()) once the fd is durable; Err on failure.
pub fn sync_fd(fd: Int) -> Result[Unit, Str]
  requires: fd >= 0
{
  let rc: Int32;
  unsafe {
    rc = xiom_fsync_fd(fd);
  }
  if rc != 0 {
    return Err("sync_fd: fsync failed");
  }
  Ok(())
}

/// fsync a directory so entry changes are durable.
/// Real implementation (wave 115): POSIX open + fsync + close; Windows opens
/// the directory with backup semantics and flushes its handle (documented
/// no-op-with-success where the filesystem rejects directory flushes).
/// Returns: Ok(()) once the directory entry is durable; Err on failure.
pub fn fsync_dir(path: Str) -> Result[Unit, Str]
  requires: path.len() > 0
{
  let rc: Int32;
  unsafe {
    rc = xiom_fsync_dir(path.c_str());
  }
  if rc != 0 {
    return Err("fsync_dir: dir sync failed");
  }
  Ok(())
}

/// Open `path` for durable appends and return a file descriptor.
/// O_CREAT|O_APPEND binary open (runtime); write with write_all, flush with
/// sync_fd, release with close_fd.
pub fn open_append(path: Str) -> Result[Int, Str]
  requires: path.len() > 0
{
  let fd: Int;
  unsafe {
    fd = xiom_open_append(path.c_str());
  }
  if fd < 0 {
    return Err("open_append: open failed");
  }
  Ok(fd)
}

/// Open `path` for reading and return a file descriptor.
/// Binary read-only open (runtime); read with read_exact, release with
/// close_fd.
pub fn open_read(path: Str) -> Result[Int, Str]
  requires: path.len() > 0
{
  let fd: Int;
  unsafe {
    fd = xiom_open_read(path.c_str());
  }
  if fd < 0 {
    return Err("open_read: open failed");
  }
  Ok(fd)
}

/// Close a file descriptor returned by open_append/open_read.
pub fn close_fd(fd: Int) -> Result[Unit, Str]
  requires: fd >= 0
{
  let rc: Int32;
  unsafe {
    rc = xiom_close(fd as Int32);
  }
  if rc != 0 {
    return Err("close_fd: close failed");
  }
  Ok(())
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
