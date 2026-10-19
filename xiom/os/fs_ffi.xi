// XIOM - OS: fs_ffi (advanced file system via FFI syscalls)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.os.fs_ffi

// Depends on: xiom.ffi, xiom.io

// ============================================================================
// Advanced file-system operations that go beyond os.xi / io.xi: symlinks,
// mmap, dup, positional and vectored I/O, sendfile/splice, fsync family,
// memory advice and FIFOs. Wave 120 makes the mmap family real (mmap /
// munmap / msync / madvise / mlock / munlock; REL-20261012-1945-xvector-2)
// by delegating to xiom.os.mmap; wave 159 makes writev and sendfile real
// through runtime shims (REL-20261015-2202-pulse item 6: POSIX writev(2) /
// sendfile(2); Windows WSASend + sequential _write fallback / TransmitFile);
// chmod delegates to xiom.io (set_permissions); the remaining operations
// (symlinks, dup, pread/pwrite, readv, splice, mkfifo, fallocate) still need
// raw syscalls the pure stdlib does not expose -- they are documented stubs
// returning Err (or documented defaults) as of wave 159.
// ============================================================================

use xiom.io;
use xiom.os.mmap as mmap_ffi; // alias: the local fn mmap shadows the module leaf
use xiom.os.sync_io;

/// struct MappedFile { ptr: Int; length: Int; fd: Int; } - mmap result.
pub type MappedFile = {
  ptr: Int;
  length: Int;
  fd: Int;
}

/// Create a symbolic link.
/// NOT IMPLEMENTED: requires the symlink syscall.
/// Returns: Err("symlink: symlink syscall not available in the pure stdlib").
pub fn symlink(target: Str, link: Str) -> Result[Unit, Str] {
  let _ = target;
  let _ = link;
  Err("symlink: symlink syscall not available in the pure stdlib")
}

/// Read a symlink target.
/// NOT IMPLEMENTED: requires the readlink syscall.
/// Returns: Err("readlink: readlink syscall not available in the pure stdlib").
pub fn readlink(path: Str) -> Result[Str, Str] {
  let _ = path;
  Err("readlink: readlink syscall not available in the pure stdlib")
}

/// True if path is a symbolic link.
/// NOT IMPLEMENTED: requires lstat. Returns false.
pub fn is_symlink(path: Str) -> Bool {
  let _ = path;
  false
}

/// Create a hard link.
/// NOT IMPLEMENTED: requires the link syscall.
/// Returns: Err("hard_link: link syscall not available in the pure stdlib").
pub fn hard_link(old: Str, new: Str) -> Result[Unit, Str] {
  let _ = old;
  let _ = new;
  Err("hard_link: link syscall not available in the pure stdlib")
}

/// Change owner/group.
/// NOT IMPLEMENTED: requires the chown syscall.
/// Returns: Err("chown: chown syscall not available in the pure stdlib").
pub fn chown(path: Str, uid: Int, gid: Int) -> Result[Unit, Str] {
  let _ = path;
  let _ = uid;
  let _ = gid;
  Err("chown: chown syscall not available in the pure stdlib")
}

/// Change permissions.
/// Delegates to xiom.io.set_permissions.
/// Parameters: path -- the file path; mode -- the permission bits.
/// Returns: Ok(()) on success, Err with the underlying message otherwise.
/// Complexity: O(1). Pure (OS call).
pub fn chmod_path(path: Str, mode: Int) -> Result[Unit, Str]
  requires: path.len() > 0
  requires: mode >= 0
{
  let r = io.set_permissions(path, mode);
  match r {
    Ok(()) => Ok(());
    Err(e) => Err(e.message);
  }
}

/// Memory-map a file read-only; the returned struct owns an open fd until
/// munmap. Real implementation (wave 120): opens the path (O_RDONLY), maps
/// it through the runtime mmap family (xiom.os.mmap) and keeps the fd.
/// Returns: Ok(MappedFile) on success; Err on bad arguments or failure.
pub fn mmap(path: Str, offset: Int, length: Int) -> Result[MappedFile, Str]
  requires: path.len() > 0
  // Payload-free Ok-side clause: struct payload reads in catalog ensures
  // clauses false-fire on v0.64.4 (catalog payload-read family in
  // tools/known_failures/README.md); re-add `result.ptr > 0` when the
  // compiler fixes it.
  ensures: result is Ok => length > 0
{
  if offset < 0 || length <= 0 {
    return Err("mmap: bad offset or length");
  }
  let h = sync_io.open_read(path);
  match h {
    Ok(f) => {
      let p = mmap_ffi.mmap_file(f, offset, length);
      match p {
        Ok(ptr) => {
          return Ok(MappedFile{ ptr: ptr, length: length, fd: f });
        },
        Err(e) => {
          let _ = sync_io.close_fd(f);
          return Err("mmap: " + e);
        },
      }
    },
    Err(_) => {
      return Err("mmap: open failed: " + path);
    },
  };
  return Err("mmap: unreachable");
}

/// Unmap a mapped region and close the fd held by the struct.
/// Real implementation (wave 120): munmap/UnmapViewOfFile + close; both
/// steps are best-effort because the signature returns no Result.
pub fn munmap(m: MappedFile)
  requires: m.ptr >= 0 && m.length >= 0
{
  let _ = mmap_ffi.mmap_unmap(m.ptr, m.length);
  let _ = sync_io.close_fd(m.fd);
}

/// Flush mapped pages back to the backing file (sync semantics).
/// Real implementation (wave 120): delegates to mmap_sync with flags 4
/// (MS_SYNC-equivalent; msync/flush).
/// Returns: Ok(()) once flushed; Err on failure.
pub fn msync(m: MappedFile) -> Result[Unit, Str]
  ensures: result is Ok => m.ptr > 0
{
  return mmap_ffi.mmap_sync(m.ptr, m.length, 4);
}

/// Advise the kernel on page use.
/// Real implementation (wave 120): madvise on POSIX (platform MADV_*
/// values; 0 = MADV_NORMAL is portable); a documented no-op success on
/// Windows.
/// Returns: Ok(()) once the advice was accepted; Err on failure.
pub fn madvise(m: MappedFile, advice: Int) -> Result[Unit, Str]
  ensures: result is Ok => m.ptr > 0
{
  return mmap_ffi.mmap_advise(m.ptr, m.length, advice);
}

/// Lock mapped pages in memory (mlock / VirtualLock).
/// Real implementation (wave 120): delegates to mmap_lock.
/// Returns: Ok(()) once the pages are resident; Err on failure.
pub fn mlock(m: MappedFile) -> Result[Unit, Str]
  ensures: result is Ok => m.ptr > 0
{
  return mmap_ffi.mmap_lock(m.ptr, m.length);
}

/// Unlock mapped pages (munlock / VirtualUnlock).
/// Real implementation (wave 120): delegates to mmap_unlock.
/// Returns: Ok(()) once the pages are unlocked; Err on failure.
pub fn munlock(m: MappedFile) -> Result[Unit, Str]
  ensures: result is Ok => m.ptr > 0
{
  return mmap_ffi.mmap_unlock(m.ptr, m.length);
}

/// Duplicate a file descriptor.
/// NOT IMPLEMENTED: requires the dup syscall.
/// Returns: Err("dup: dup syscall not available in the pure stdlib").
pub fn dup(fd: Int) -> Result[Int, Str] {
  let _ = fd;
  Err("dup: dup syscall not available in the pure stdlib")
}

/// Duplicate onto a specific fd.
/// NOT IMPLEMENTED: requires the dup2 syscall.
/// Returns: Err("dup2: dup2 syscall not available in the pure stdlib").
pub fn dup2(old: Int, new: Int) -> Result[Int, Str] {
  let _ = old;
  let _ = new;
  Err("dup2: dup2 syscall not available in the pure stdlib")
}

/// Truncate a file by path.
/// NOT IMPLEMENTED: requires the truncate syscall.
/// Returns: Err("truncate: truncate syscall not available in the pure stdlib").
pub fn truncate(path: Str, length: Int) -> Result[Unit, Str] {
  let _ = path;
  let _ = length;
  Err("truncate: truncate syscall not available in the pure stdlib")
}

/// Truncate an open file.
/// NOT IMPLEMENTED: requires the ftruncate syscall.
/// Returns: Err("ftruncate: ftruncate syscall not available in the pure stdlib").
pub fn ftruncate(fd: Int, length: Int) -> Result[Unit, Str] {
  let _ = fd;
  let _ = length;
  Err("ftruncate: ftruncate syscall not available in the pure stdlib")
}

/// Pre-allocate space.
/// NOT IMPLEMENTED: requires posix_fallocate.
/// Returns: Err("fallocate: posix_fallocate not available in the pure stdlib").
pub fn fallocate(fd: Int, offset: Int, length: Int) -> Result[Unit, Str] {
  let _ = fd;
  let _ = offset;
  let _ = length;
  Err("fallocate: posix_fallocate not available in the pure stdlib")
}

/// Positioned read.
/// NOT IMPLEMENTED: requires the pread syscall.
/// Returns: Err("pread: pread syscall not available in the pure stdlib").
pub fn pread(fd: Int, offset: Int, length: Int) -> Result[Vec[UInt8], Str] {
  let _ = fd;
  let _ = offset;
  let _ = length;
  Err("pread: pread syscall not available in the pure stdlib")
}

/// Positioned write.
/// NOT IMPLEMENTED: requires the pwrite syscall.
/// Returns: Err("pwrite: pwrite syscall not available in the pure stdlib").
pub fn pwrite(fd: Int, offset: Int, data: &Vec[UInt8]) -> Result[Int, Str] {
  let _ = fd;
  let _ = offset;
  let _ = data;
  Err("pwrite: pwrite syscall not available in the pure stdlib")
}

/// Vectored read.
/// NOT IMPLEMENTED: requires the readv syscall.
/// Returns: Err("readv: readv syscall not available in the pure stdlib").
pub fn readv(fd: Int, buffers: &Vec[Vec[UInt8]]) -> Result[Int, Str] {
  let _ = fd;
  let _ = buffers;
  Err("readv: readv syscall not available in the pure stdlib")
}

/// Vectored write (scatter write): writes every segment of `buffers` to fd
/// in one call, in order.
/// Real implementation (wave 159; REL-20261015-2202-pulse item 6): POSIX
/// writev(2); on Windows a WSASend when the fd is a socket, otherwise a
/// sequential _write fallback (short writes loop; the full total or Err).
/// An empty `buffers` or all-empty segments is Ok(0); more than 1024
/// segments is Err. The returned count is the syscall's count -- a short
/// count (pipe/socket backpressure) is reported as-is, not as an error.
/// Returns: Ok(bytes written) on success; Err on an invalid fd or failure.
/// Complexity: O(total bytes). Pure (OS call).
pub fn writev(fd: Int, buffers: &Vec[Vec[UInt8]]) -> Result[Int, Str]
  ensures: result is Ok => fd >= 0
{
  if fd < 0 {
    return Err("writev: invalid fd");
  }
  let nseg = buffers.len();
  if nseg == 0 {
    return Ok(0);
  }
  if nseg > 1024 {
    return Err("writev: too many segments (max 1024)");
  }
  var layout: Vec[Int] = Vec[Int].new();
  var i = 0;
  var nlive = 0;
  while i < nseg {
    let seglen = buffers[i].len();
    if seglen > 0 {
      let addr: Int;
      unsafe {
        addr = (&buffers[i][0] as *UInt8) as Int;
      }
      layout.push(addr);
      layout.push(seglen);
      nlive = nlive + 1;
    }
    i = i + 1;
  }
  if nlive == 0 {
    return Ok(0);
  }
  let rc: Int;
  unsafe {
    rc = xiom_fd_writev(fd, &layout[0] as *Int, nlive);
  }
  if rc < 0 {
    return Err("writev: write failed");
  }
  Ok(rc)
}

/// Copy a file region to an out fd without user-space copying.
/// Real implementation (wave 159; REL-20261015-2202-pulse item 6): Linux
/// sendfile(2); Windows TransmitFile (the out fd must be a socket; the in
/// fd is a CRT file fd, mapped with _get_osfhandle). Offset semantics:
/// offset >= 0 reads from that file offset; offset == -1 uses the current
/// position. POSIX leaves the position unchanged for an explicit offset
/// and advances it for -1; Windows keeps one shared file pointer, so the
/// position ends past the sent range in both cases -- callers that need
/// repeatable sends should pass an explicit offset. count == 0 is Ok(0).
/// A short Ok count means EOF was reached before `count` bytes (POSIX);
/// on Windows the count is clamped to the remaining file size first, so a
/// successful Windows call always sends the full min(count, remaining).
/// Returns: Ok(bytes sent); Err on invalid arguments, platform gaps (no
/// portable sendfile outside Linux/Windows) or a failed transfer.
/// Complexity: O(count) kernel-side. Pure (OS call).
pub fn sendfile(out_fd: Int, in_fd: Int, offset: Int, count: Int) -> Result[Int, Str]
  ensures: result is Ok => (out_fd >= 0 && in_fd >= 0 && count >= 0 && offset >= -1)
{
  if out_fd < 0 || in_fd < 0 {
    return Err("sendfile: invalid fd");
  }
  if count < 0 {
    return Err("sendfile: negative count");
  }
  if offset < -1 {
    return Err("sendfile: bad offset (-1 = current position)");
  }
  if count == 0 {
    return Ok(0);
  }
  let rc: Int;
  unsafe {
    rc = xiom_fd_sendfile(out_fd, in_fd, offset, count);
  }
  if rc == -2 {
    return Err("sendfile: not supported on this platform (Linux sendfile / Windows TransmitFile only)");
  }
  if rc == -3 {
    return Err("sendfile: on Windows the out fd must be a socket (TransmitFile requirement)");
  }
  if rc < 0 {
    return Err("sendfile: transfer failed");
  }
  Ok(rc)
}

/// Move data between fds without copying.
/// NOT IMPLEMENTED: requires the splice syscall.
/// Returns: Err("splice: splice syscall not available in the pure stdlib").
pub fn splice(in_fd: Int, out_fd: Int, count: Int) -> Result[Int, Str] {
  let _ = in_fd;
  let _ = out_fd;
  let _ = count;
  Err("splice: splice syscall not available in the pure stdlib")
}

extern "C" {
  fn xiom_fsync_fd(fd: Int) -> Int32;
  fn xiom_fdatasync_fd(fd: Int) -> Int32;
  // Wave 159 (2202 item 6): long-long returns and 64-bit Int arguments
  // (Windows C long is 32-bit; the runtime contract is long long -- cf.
  // xiom_poll's ABI note). writev takes a (address, length) pair array,
  // 2 entries per segment, as an Int vector.
  fn xiom_fd_writev(fd: Int, pairs: *Int, iovcnt: Int) -> Int;
  fn xiom_fd_sendfile(out_fd: Int, in_fd: Int, offset: Int, count: Int) -> Int;
}

/// Flush file data and metadata to stable storage.
/// Real implementation (wave 115): fsync(2) on POSIX, the CRT _commit on
/// Windows, through the xiom_fsync_fd runtime shim.
/// Returns: Ok(()) once the fd is durable; Err on failure.
pub fn fsync(fd: Int) -> Result[Unit, Str]
  requires: fd >= 0
{
  let rc: Int32;
  unsafe {
    rc = xiom_fsync_fd(fd);
  }
  if rc != 0 {
    return Err("fsync: flush failed");
  }
  Ok(())
}

/// Flush file data only (fdatasync; fsync fallback on macOS, _commit on
/// Windows).
/// Returns: Ok(()) once the fd data is durable; Err on failure.
pub fn fdatasync(fd: Int) -> Result[Unit, Str]
  requires: fd >= 0
{
  let rc: Int32;
  unsafe {
    rc = xiom_fdatasync_fd(fd);
  }
  if rc != 0 {
    return Err("fdatasync: flush failed");
  }
  Ok(())
}

/// Create a named pipe.
/// NOT IMPLEMENTED: requires the mkfifo syscall.
/// Returns: Err("mkfifo: mkfifo syscall not available in the pure stdlib").
pub fn mkfifo(path: Str, mode: Int) -> Result[Unit, Str] {
  let _ = path;
  let _ = mode;
  Err("mkfifo: mkfifo syscall not available in the pure stdlib")
}

/// Open a named pipe.
/// NOT IMPLEMENTED: requires the open syscall.
/// Returns: Err("fifo_open: open syscall not available in the pure stdlib").
pub fn fifo_open(path: Str) -> Result[Int, Str] {
  let _ = path;
  Err("fifo_open: open syscall not available in the pure stdlib")
}
