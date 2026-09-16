// XIOM - OS: Memory Mapping
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.os.mmap

// Depends on: xiom.ffi + xiom.io

// ============================================================================
// Anonymous and file-backed memory mapping, protection, sync, lock and copy
// helpers. All functions require the mmap/mprotect/msync family of syscalls,
// which the pure stdlib does not expose -- every function is a documented
// stub returning Err.
// ============================================================================

/// Map a private anonymous region and return its address.
/// NOT IMPLEMENTED: requires the mmap syscall.
/// Returns: Err("mmap_anonymous: mmap not available in the pure stdlib").
pub fn mmap_anonymous(length: Int) -> Result[Int, Str] {
  let _ = length;
  Err("mmap_anonymous: mmap not available in the pure stdlib")
}

/// Map a read-only view of a file region.
/// NOT IMPLEMENTED: requires the mmap syscall.
/// Returns: Err("mmap_file: mmap not available in the pure stdlib").
pub fn mmap_file(fd: Int, offset: Int, length: Int) -> Result[Int, Str] {
  let _ = fd;
  let _ = offset;
  let _ = length;
  Err("mmap_file: mmap not available in the pure stdlib")
}

/// Map a writable view of a file region.
/// NOT IMPLEMENTED: requires the mmap syscall.
/// Returns: Err("mmap_writeable: mmap not available in the pure stdlib").
pub fn mmap_writeable(fd: Int, offset: Int, length: Int) -> Result[Int, Str] {
  let _ = fd;
  let _ = offset;
  let _ = length;
  Err("mmap_writeable: mmap not available in the pure stdlib")
}

/// Unmap a previously mapped region.
/// NOT IMPLEMENTED: requires the munmap syscall.
/// Returns: Err("mmap_unmap: munmap not available in the pure stdlib").
pub fn mmap_unmap(ptr: Int, length: Int) -> Result[Unit, Str] {
  let _ = ptr;
  let _ = length;
  Err("mmap_unmap: munmap not available in the pure stdlib")
}

/// Flush mapped pages back to the backing file.
/// NOT IMPLEMENTED: requires the msync syscall.
/// Returns: Err("mmap_sync: msync not available in the pure stdlib").
pub fn mmap_sync(ptr: Int, length: Int, flags: Int) -> Result[Unit, Str] {
  let _ = ptr;
  let _ = length;
  let _ = flags;
  Err("mmap_sync: msync not available in the pure stdlib")
}

/// Give the kernel usage advice about a mapped region.
/// NOT IMPLEMENTED: requires the madvise syscall.
/// Returns: Err("mmap_advise: madvise not available in the pure stdlib").
pub fn mmap_advise(ptr: Int, length: Int, advice: Int) -> Result[Unit, Str] {
  let _ = ptr;
  let _ = length;
  let _ = advice;
  Err("mmap_advise: madvise not available in the pure stdlib")
}

/// Change the protection flags of a mapped region.
/// NOT IMPLEMENTED: requires the mprotect syscall.
/// Returns: Err("mmap_protect: mprotect not available in the pure stdlib").
pub fn mmap_protect(ptr: Int, length: Int, prot: Int) -> Result[Unit, Str] {
  let _ = ptr;
  let _ = length;
  let _ = prot;
  Err("mmap_protect: mprotect not available in the pure stdlib")
}

/// Lock mapped pages in memory.
/// NOT IMPLEMENTED: requires the mlock syscall.
/// Returns: Err("mmap_lock: mlock not available in the pure stdlib").
pub fn mmap_lock(ptr: Int, length: Int) -> Result[Unit, Str] {
  let _ = ptr;
  let _ = length;
  Err("mmap_lock: mlock not available in the pure stdlib")
}

/// Unlock mapped pages.
/// NOT IMPLEMENTED: requires the munlock syscall.
/// Returns: Err("mmap_unlock: munlock not available in the pure stdlib").
pub fn mmap_unlock(ptr: Int, length: Int) -> Result[Unit, Str] {
  let _ = ptr;
  let _ = length;
  Err("mmap_unlock: munlock not available in the pure stdlib")
}

/// Copy length bytes out of a mapped region.
/// NOT IMPLEMENTED: no mappings exist in the pure stdlib. Returns an empty
/// vector.
pub fn mmap_copy(ptr: Int, length: Int) -> Vec[UInt8] {
  let _ = ptr;
  let _ = length;
  var out = Vec[UInt8].new();
  out
}

/// Copy bytes into a mapped region.
/// NOT IMPLEMENTED: no mappings exist in the pure stdlib.
/// Returns: Err("mmap_write: no mappings available in the pure stdlib").
pub fn mmap_write(ptr: Int, data: &Vec[UInt8]) -> Result[Unit, Str] {
  let _ = ptr;
  let _ = data;
  Err("mmap_write: no mappings available in the pure stdlib")
}

/// Grow or shrink a mapping and return the new address.
/// NOT IMPLEMENTED: requires mremap.
/// Returns: Err("mmap_resize: mremap not available in the pure stdlib").
pub fn mmap_resize(ptr: Int, old_len: Int, new_len: Int) -> Result[Int, Str] {
  let _ = ptr;
  let _ = old_len;
  let _ = new_len;
  Err("mmap_resize: mremap not available in the pure stdlib")
}
