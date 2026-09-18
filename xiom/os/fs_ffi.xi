// XIOM - OS: fs_ffi (advanced file system via FFI syscalls)
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.os.fs_ffi

// Depends on: xiom.ffi, xiom.io

// ============================================================================
// Advanced file-system operations that go beyond os.xi / io.xi: symlinks,
// mmap, dup, positional and vectored I/O, sendfile/splice, fsync family,
// memory advice and FIFOs. chmod delegates to xiom.io (set_permissions); the
// remaining operations need raw syscalls the pure stdlib does not expose --
// they are documented stubs returning Err (or documented defaults).
// ============================================================================

use xiom.io;

// struct MappedFile { ptr: Int; length: Int; fd: Int; } - mmap result.
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
pub fn chmod_path(path: Str, mode: Int) -> Result[Unit, Str] {
  let r = io.set_permissions(path, mode);
  match r {
    Ok(()) => Ok(());
    Err(e) => Err(e.message);
  }
}

/// Memory-map a file.
/// NOT IMPLEMENTED: requires the mmap syscall.
/// Returns: Err("mmap: mmap syscall not available in the pure stdlib").
pub fn mmap(path: Str, offset: Int, length: Int) -> Result[MappedFile, Str] {
  let _ = path;
  let _ = offset;
  let _ = length;
  Err("mmap: mmap syscall not available in the pure stdlib")
}

/// Unmap a mapped region.
/// NO-OP: no mappings exist in the pure stdlib.
pub fn munmap(m: MappedFile) {
  let _ = m;
}

/// Flush mapped pages.
/// NOT IMPLEMENTED: requires the msync syscall.
/// Returns: Err("msync: msync syscall not available in the pure stdlib").
pub fn msync(m: MappedFile) -> Result[Unit, Str] {
  let _ = m;
  Err("msync: msync syscall not available in the pure stdlib")
}

/// Advise the kernel on page use.
/// NOT IMPLEMENTED: requires the madvise syscall.
/// Returns: Err("madvise: madvise syscall not available in the pure stdlib").
pub fn madvise(m: MappedFile, advice: Int) -> Result[Unit, Str] {
  let _ = m;
  let _ = advice;
  Err("madvise: madvise syscall not available in the pure stdlib")
}

/// Lock pages in memory.
/// NOT IMPLEMENTED: requires the mlock syscall.
/// Returns: Err("mlock: mlock syscall not available in the pure stdlib").
pub fn mlock(m: MappedFile) -> Result[Unit, Str] {
  let _ = m;
  Err("mlock: mlock syscall not available in the pure stdlib")
}

/// Unlock pages.
/// NOT IMPLEMENTED: requires the munlock syscall.
/// Returns: Err("munlock: munlock syscall not available in the pure stdlib").
pub fn munlock(m: MappedFile) -> Result[Unit, Str] {
  let _ = m;
  Err("munlock: munlock syscall not available in the pure stdlib")
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

/// Vectored write.
/// NOT IMPLEMENTED: requires the writev syscall.
/// Returns: Err("writev: writev syscall not available in the pure stdlib").
pub fn writev(fd: Int, buffers: &Vec[Vec[UInt8]]) -> Result[Int, Str] {
  let _ = fd;
  let _ = buffers;
  Err("writev: writev syscall not available in the pure stdlib")
}

/// Copy between fds in-kernel.
/// NOT IMPLEMENTED: requires the sendfile syscall.
/// Returns: Err("sendfile: sendfile syscall not available in the pure stdlib").
pub fn sendfile(out_fd: Int, in_fd: Int, offset: Int, count: Int) -> Result[Int, Str] {
  let _ = out_fd;
  let _ = in_fd;
  let _ = offset;
  let _ = count;
  Err("sendfile: sendfile syscall not available in the pure stdlib")
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

/// Flush file data and metadata.
/// NOT IMPLEMENTED: requires the fsync syscall.
/// Returns: Err("fsync: fsync syscall not available in the pure stdlib").
pub fn fsync(fd: Int) -> Result[Unit, Str] {
  let _ = fd;
  Err("fsync: fsync syscall not available in the pure stdlib")
}

/// Flush file data only.
/// NOT IMPLEMENTED: requires the fdatasync syscall.
/// Returns: Err("fdatasync: fdatasync syscall not available in the pure stdlib").
pub fn fdatasync(fd: Int) -> Result[Unit, Str] {
  let _ = fd;
  Err("fdatasync: fdatasync syscall not available in the pure stdlib")
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
