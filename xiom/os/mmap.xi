// XIOM - OS: Memory Mapping
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.os.mmap

// Depends on: xiom.ffi + xiom.io

// ============================================================================
// Anonymous and file-backed memory mapping, protection, sync, lock and copy
// helpers. Wave 120 (REL-20261012-1945-xvector-2 P5) makes the family real
// through the runtime shims below (runtime/xiom_runtime.c): mmap/munmap/
// msync/madvise/mprotect/mlock/munlock on POSIX, CreateFileMapping/
// MapViewOfFile/FlushViewOfFile/VirtualProtect/VirtualLock on Windows.
// Platform notes: mapping offsets must be page-aligned on POSIX and 64 KiB
// (allocation granularity) aligned on Windows -- offset 0 is the portable
// default; madvise is a documented no-op success on Windows; mmap_resize
// (mremap) stays a documented stub (Linux-only, no portable equivalent).
// ============================================================================

extern "C" {
  fn xiom_mmap_file(fd: Int32, offset: Int, length: Int, writable: Int32) -> *UInt8;
  fn xiom_mmap_anon(length: Int) -> *UInt8;
  fn xiom_munmap(ptr: *UInt8, length: Int) -> Int32;
  fn xiom_msync(ptr: *UInt8, length: Int, flags: Int32) -> Int32;
  fn xiom_madvise(ptr: *UInt8, length: Int, advice: Int32) -> Int32;
  fn xiom_mprotect(ptr: *UInt8, length: Int, prot: Int32) -> Int32;
  fn xiom_mlock(ptr: *UInt8, length: Int) -> Int32;
  fn xiom_munlock(ptr: *UInt8, length: Int) -> Int32;
  fn xiom_mem_write(ptr: *UInt8, buf: *UInt8, count: Int) -> Int;
}

/// Map a private anonymous read/write region and return its address.
/// Real implementation (wave 120): mmap(MAP_PRIVATE|MAP_ANONYMOUS) on
/// POSIX, CreateFileMapping(INVALID_HANDLE_VALUE) + MapViewOfFile on
/// Windows. Non-positive lengths return Err.
/// Returns: Ok(address) with a non-zero mapping address.
/// Complexity: O(1). Pure (OS call).
pub fn mmap_anonymous(length: Int) -> Result[Int, Str]
  ensures: result is Ok => result > 0
{
  if length <= 0 {
    return Err("mmap_anonymous: length must be positive");
  }
  let p: *UInt8;
  unsafe {
    p = xiom_mmap_anon(length);
  }
  if p == 0 {
    return Err("mmap_anonymous: map failed");
  }
  let addr: Int;
  unsafe {
    addr = (p as *UInt8) as Int;
  }
  Ok(addr)
}

/// Map a read-only view of a file region (the fd must be readable).
/// Real implementation (wave 120): mmap(PROT_READ, MAP_SHARED) /
/// MapViewOfFile(FILE_MAP_READ). The offset must be page-aligned (POSIX) or
/// 64 KiB-aligned (Windows); use 0 for the portable case.
/// Returns: Ok(address) on success; Err on bad arguments or map failure.
/// Complexity: O(1). Pure (OS call).
pub fn mmap_file(fd: Int, offset: Int, length: Int) -> Result[Int, Str]
  ensures: result is Ok => result > 0
{
  if fd < 0 || offset < 0 || length <= 0 {
    return Err("mmap_file: bad fd, offset or length");
  }
  let p: *UInt8;
  unsafe {
    p = xiom_mmap_file(fd as Int32, offset, length, 0);
  }
  if p == 0 {
    return Err("mmap_file: map failed");
  }
  let addr: Int;
  unsafe {
    addr = (p as *UInt8) as Int;
  }
  Ok(addr)
}

/// Map a writable view of a file region (the fd must be read/write).
/// Real implementation (wave 120): mmap(PROT_READ|PROT_WRITE, MAP_SHARED) /
/// MapViewOfFile(FILE_MAP_WRITE). Writes through the mapping are visible to
/// other readers of the file after mmap_sync (MS_SYNC-equivalent).
/// Returns: Ok(address) on success; Err on bad arguments or map failure.
/// Complexity: O(1). Pure (OS call).
pub fn mmap_writeable(fd: Int, offset: Int, length: Int) -> Result[Int, Str]
  ensures: result is Ok => result > 0
{
  if fd < 0 || offset < 0 || length <= 0 {
    return Err("mmap_writeable: bad fd, offset or length");
  }
  let p: *UInt8;
  unsafe {
    p = xiom_mmap_file(fd as Int32, offset, length, 1);
  }
  if p == 0 {
    return Err("mmap_writeable: map failed");
  }
  let addr: Int;
  unsafe {
    addr = (p as *UInt8) as Int;
  }
  Ok(addr)
}

/// Unmap a region previously returned by the mmap_* functions.
/// Real implementation (wave 120): munmap / UnmapViewOfFile.
/// Returns: Ok(()) once the region is released; Err on bad arguments or
/// unmap failure.
/// Complexity: O(1). Pure (OS call).
pub fn mmap_unmap(ptr: Int, length: Int) -> Result[Unit, Str]
  ensures: result is Ok => ptr > 0
{
  if ptr <= 0 || length <= 0 {
    return Err("mmap_unmap: bad arguments");
  }
  let rc: Int32;
  unsafe {
    rc = xiom_munmap(ptr as *UInt8, length);
  }
  if rc != 0 {
    return Err("mmap_unmap: unmap failed");
  }
  Ok(())
}

/// Flush mapped pages back to the backing file.
/// Real implementation (wave 120): msync (flags: 1 = async, anything else =
/// sync, i.e. MS_SYNC semantics) / FlushViewOfFile (always sync).
/// Returns: Ok(()) once the flush completed; Err on bad arguments or
/// flush failure.
/// Complexity: O(pages). Pure (OS call, may block).
pub fn mmap_sync(ptr: Int, length: Int, flags: Int) -> Result[Unit, Str]
  ensures: result is Ok => ptr > 0
{
  if ptr <= 0 || length <= 0 {
    return Err("mmap_sync: bad arguments");
  }
  let rc: Int32;
  unsafe {
    rc = xiom_msync(ptr as *UInt8, length, flags as Int32);
  }
  if rc != 0 {
    return Err("mmap_sync: sync failed");
  }
  Ok(())
}

/// Give the kernel usage advice about a mapped region.
/// Real implementation (wave 120): madvise on POSIX (advice values are the
/// platform MADV_* numbers; 0 = MADV_NORMAL is portable); a documented
/// no-op success on Windows (no madvise equivalent).
/// Returns: Ok(()) once the advice was accepted; Err on bad arguments or
/// failure.
/// Complexity: O(1). Pure (OS call).
pub fn mmap_advise(ptr: Int, length: Int, advice: Int) -> Result[Unit, Str]
  ensures: result is Ok => ptr > 0
{
  if ptr <= 0 || length <= 0 {
    return Err("mmap_advise: bad arguments");
  }
  let rc: Int32;
  unsafe {
    rc = xiom_madvise(ptr as *UInt8, length, advice as Int32);
  }
  if rc != 0 {
    return Err("mmap_advise: advise failed");
  }
  Ok(())
}

/// Change the protection flags of a mapped region.
/// Real implementation (wave 120): mprotect (prot bits: 1 = read, 2 = write,
/// 4 = execute) / VirtualProtect.
/// Returns: Ok(()) once the protection changed; Err on bad arguments or
/// failure.
/// Complexity: O(1). Pure (OS call).
pub fn mmap_protect(ptr: Int, length: Int, prot: Int) -> Result[Unit, Str]
  ensures: result is Ok => ptr > 0
{
  if ptr <= 0 || length <= 0 {
    return Err("mmap_protect: bad arguments");
  }
  let rc: Int32;
  unsafe {
    rc = xiom_mprotect(ptr as *UInt8, length, prot as Int32);
  }
  if rc != 0 {
    return Err("mmap_protect: protect failed");
  }
  Ok(())
}

/// Lock mapped pages in memory.
/// Real implementation (wave 120): mlock / VirtualLock. May fail when the
/// process locked-memory limit is exceeded.
/// Returns: Ok(()) once the pages are resident; Err on bad arguments or
/// failure.
/// Complexity: O(pages). Pure (OS call).
pub fn mmap_lock(ptr: Int, length: Int) -> Result[Unit, Str]
  ensures: result is Ok => ptr > 0
{
  if ptr <= 0 || length <= 0 {
    return Err("mmap_lock: bad arguments");
  }
  let rc: Int32;
  unsafe {
    rc = xiom_mlock(ptr as *UInt8, length);
  }
  if rc != 0 {
    return Err("mmap_lock: lock failed");
  }
  Ok(())
}

/// Unlock mapped pages.
/// Real implementation (wave 120): munlock / VirtualUnlock.
/// Returns: Ok(()) once the pages are unlocked; Err on bad arguments or
/// failure.
/// Complexity: O(pages). Pure (OS call).
pub fn mmap_unlock(ptr: Int, length: Int) -> Result[Unit, Str]
  ensures: result is Ok => ptr > 0
{
  if ptr <= 0 || length <= 0 {
    return Err("mmap_unlock: bad arguments");
  }
  let rc: Int32;
  unsafe {
    rc = xiom_munlock(ptr as *UInt8, length);
  }
  if rc != 0 {
    return Err("mmap_unlock: unlock failed");
  }
  Ok(())
}

/// Copy length bytes out of a mapped region.
/// Real implementation (wave 120): reads through the mapped pointer with
/// cached offsets (no syscalls). A null pointer or non-positive length
/// returns an empty vector.
/// Returns: a fresh Vec[UInt8] with the mapped bytes.
/// Complexity: O(length).
pub fn mmap_copy(ptr: Int, length: Int) -> Vec[UInt8]
  ensures: ptr <= 0 => result.len() == 0
  ensures: length <= 0 => result.len() == 0
{
  var out = Vec[UInt8].new();
  if ptr <= 0 || length <= 0 {
    return out;
  }
  unsafe {
    let p = ptr as *UInt8;
    var i = 0;
    while i < length {
      out.push(*(p.offset(i)));
      i = i + 1;
    }
  }
  out
}

/// Copy bytes into a mapped region.
/// Real implementation (wave 120): memcpy through the runtime shim.
/// Returns: Ok(()) once the bytes are copied; Err on a null pointer or a
/// short write; an empty `data` is a no-op.
/// Complexity: O(data.len()).
pub fn mmap_write(ptr: Int, data: &Vec[UInt8]) -> Result[Unit, Str]
  ensures: result is Ok => ptr > 0
{
  if ptr <= 0 {
    return Err("mmap_write: invalid mapping pointer");
  }
  let n = data.len();
  if n == 0 {
    return Ok(());
  }
  let wrote: Int;
  unsafe {
    wrote = xiom_mem_write(ptr as *UInt8, &data[0] as *UInt8, n);
  }
  if wrote != n {
    return Err("mmap_write: write failed");
  }
  Ok(())
}

/// Grow or shrink a mapping and return the new address.
/// NOT IMPLEMENTED: requires mremap (Linux-only; no Windows/macOS or POSIX
/// equivalent). Use mmap_unmap + a fresh mapping instead.
/// Returns: Err("mmap_resize: mremap not available in the pure stdlib").
pub fn mmap_resize(ptr: Int, old_len: Int, new_len: Int) -> Result[Int, Str] {
  let _ = ptr;
  let _ = old_len;
  let _ = new_len;
  Err("mmap_resize: mremap not available in the pure stdlib")
}
