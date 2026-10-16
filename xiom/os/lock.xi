// XIOM -- Advisory Whole-File Locks (xiom.os.lock)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Advisory, cross-process, whole-file exclusive locks: one cooperating
// writer per shard/home (REL-20261016-1128-orbitdb station shard
// ownership / -1129-xvector single-writer-per-home; plan item 12).
// A FileLock holds an open read-write fd on the target file plus the
// OS advisory lock on it. Documented semantics:
//
//   * Advisory only. The OS keeps no mandatory guard: processes that do
//     not call this module can read/write a locked file freely. The lock
//     is a coordination protocol between cooperating processes, not a
//     security boundary.
//   * The target file must ALREADY EXIST. The wrappers open it
//     read-write (write access is required by F_WRLCK / LockFileEx) and
//     do NOT create it: a missing or unwritable path is an Err. Create
//     the sentinel first (e.g. io.write_file(path, "")) when the lock
//     file is dedicated.
//   * The lock covers the whole file (byte range 0..endless) and is
//     attached to the file (inode), not the path: renaming or deleting
//     the path while the lock is held detaches it from the new name, so
//     cooperative consumers must not replace/delete a locked file.
//   * POSIX (fcntl F_WRLCK) locks are owned by the PROCESS, not the fd:
//     two fds in the same process do NOT contend -- the second lock
//     simply converts the process's existing lock -- and closing ANY fd
//     the process has for that file drops ALL of the process's locks on
//     it (a close in file_lock_release included). Keep at most one
//     FileLock per path per process on POSIX.
//   * Windows (LockFileEx) locks are per handle: a second open in the
//     SAME process DOES contend (file_lock_try -> Err, LOCK_HELD_MSG),
//     closing that fd releases only that handle's lock, and a blocking
//     re-lock of a range the same handle already holds deadlocks --
//     never take file_lock on a path this process holds (take it after
//     the try/release/blocking sequence instead).
//   * Release-or-die: the lock lives until file_lock_release closes the
//     fd, or the process dies (the OS closes every fd and drops the
//     locks). There is no implicit release on scope exit: a forgotten
//     FileLock holds the lock until process exit.
//   * FileLock is intentionally NOT Clone: it owns the fd and
//     file_lock_release consumes it, so a double release cannot be
//     written (moving the value out is a compile error). For the same
//     reason there is no file_lock_release_all(): the module keeps no
//     registry of held locks -- release each FileLock explicitly, or
//     exit the process, which releases every lock.
//   * Contention contract: file_lock_try is non-blocking and returns
//     Err(LOCK_HELD_MSG) when the lock is currently held; file_lock
//     blocks until the lock is free (it never returns "held").
//
// Cross-process contention itself is not asserted by the probe (the
// probe harness cannot spawn a second process); the same-process shape
// above is the deterministic stand-in, and the per-process POSIX
// non-contention is documented, not a bug.

module xiom.os.lock

extern "C" {
  // Int32 fd/open returns are annotated at the call sites (wave-119 ABI
  // family); the lock shims return C `long long` (0 acquired, 1 held,
  // -1 error) so they bind as Int.
  fn xiom_open_rw_existing(path: *UInt8) -> Int32;
  fn xiom_close(fd: Int32) -> Int32;
  fn xiom_file_lock_try(fd: Int32) -> Int;
  fn xiom_file_lock_wait(fd: Int32) -> Int;
  fn xiom_file_unlock(fd: Int32) -> Int;
}

/// LOCK_HELD_MSG is the stable contention message of file_lock_try; the
/// lock is currently held (POSIX: by another process; Windows: by
/// another process or another open handle of this process). String
/// comparison against this const is the supported way to classify the
/// contention outcome.
pub const LOCK_HELD_MSG: Str = "file_lock_try: lock is already held";

/// struct FileLock - one held advisory whole-file lock. `fd` is the open
/// read-write descriptor the lock is bound to; `path` is the locked path
/// (diagnostics). The value owns the fd until file_lock_release consumes
/// it; the struct is intentionally not Clone so a double release cannot
/// be written.
pub type FileLock = {
  fd: Int;
  path: Str;
}

/// file_lock_try attempts a NON-blocking exclusive advisory lock on
/// `path` and returns the held lock. The file must already exist and be
/// writable (opened read-write, never created).
/// Returns: Ok(lock) when the lock is now held; Err(LOCK_HELD_MSG) when
/// it is held elsewhere; Err("file_lock_try: empty path") /
/// Err("file_lock_try: open failed...") / Err("file_lock_try: lock
/// failed") otherwise. An Ok lock stays held until file_lock_release.
/// Complexity: O(1) syscall (no waiting).
pub fn file_lock_try(path: Str) -> Result[FileLock, Str]
  ensures: (path.len() == 0) => (result.is_err == true)
{
  if path.len() == 0 {
    return Err("file_lock_try: empty path");
  }
  let fd32: Int32;
  unsafe {
    fd32 = xiom_open_rw_existing(path.c_str());
  }
  let fd = fd32 as Int;
  if fd < 0 {
    return Err("file_lock_try: open failed (the file must exist and be writable)");
  }
  let rc: Int;
  unsafe {
    rc = xiom_file_lock_try(fd as Int32);
  }
  if rc == 1 {
    unsafe {
      let _ = xiom_close(fd as Int32);
    }
    return Err(LOCK_HELD_MSG);
  }
  if rc != 0 {
    unsafe {
      let _ = xiom_close(fd as Int32);
    }
    return Err("file_lock_try: lock failed");
  }
  Ok(FileLock { fd: fd; path: path })
}

/// file_lock acquires the exclusive advisory lock on `path`, BLOCKING
/// until it is free. The file must already exist and be writable (opened
/// read-write, never created). On POSIX the wait survives EINTR; on
/// Windows a synchronous fd queues inside LockFileEx.
/// Returns: Ok(lock) once held (there is no "contended" outcome);
/// Err("file_lock: empty path") / Err("file_lock: open failed...") /
/// Err("file_lock: lock failed"). Do not call this on a path this
/// process already holds on Windows (self-re-lock deadlocks).
/// Complexity: blocking wait + O(1) syscall.
pub fn file_lock(path: Str) -> Result[FileLock, Str]
  ensures: (path.len() == 0) => (result.is_err == true)
{
  if path.len() == 0 {
    return Err("file_lock: empty path");
  }
  let fd32: Int32;
  unsafe {
    fd32 = xiom_open_rw_existing(path.c_str());
  }
  let fd = fd32 as Int;
  if fd < 0 {
    return Err("file_lock: open failed (the file must exist and be writable)");
  }
  let rc: Int;
  unsafe {
    rc = xiom_file_lock_wait(fd as Int32);
  }
  if rc != 0 {
    unsafe {
      let _ = xiom_close(fd as Int32);
    }
    return Err("file_lock: lock failed");
  }
  Ok(FileLock { fd: fd; path: path })
}

/// file_lock_release releases the advisory lock and closes its fd. The
/// unlock is best-effort: the authoritative release is the fd close
/// (both platforms drop the locks when the fd/handle is closed), so a
/// failed unlock is still released by the close. Consumes the FileLock
/// (move): the value cannot be used or released again.
pub fn file_lock_release(l: FileLock) {
  if l.fd < 0 {
    return;
  }
  let rc: Int;
  unsafe {
    rc = xiom_file_unlock(l.fd as Int32);
  }
  let _ = rc;
  unsafe {
    let _ = xiom_close(l.fd as Int32);
  }
}
