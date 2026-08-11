// XIOM - OS: Memory Mapping
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.os.mmap

// Depends on: xiom.ffi + xiom.io

// ============================================================================
// Anonymous and file-backed memory mapping, protection, sync, lock and copy
// helpers. NOTE: current implementation lives in os.xi - move the functions
// here during the implementation phase. TODO(compiler): implement.
// ============================================================================

// fn mmap_anonymous(length: Int) -> Result[Int, Str] - map a private anonymous region and return its address. TODO(compiler): implement.
// fn mmap_file(fd: Int, offset: Int, length: Int) -> Result[Int, Str] - map a read-only view of a file region. TODO(compiler): implement.
// fn mmap_writeable(fd: Int, offset, length) -> Result[Int, Str] - map a writable view of a file region. TODO(compiler): implement.
// fn mmap_unmap(ptr: Int, length: Int) -> Result[Unit, Str] - unmap a previously mapped region. TODO(compiler): implement.
// fn mmap_sync(ptr: Int, length: Int, flags: Int) -> Result[Unit, Str] - flush mapped pages back to the backing file. TODO(compiler): implement.
// fn mmap_advise(ptr, length, advice: Int) -> Result[Unit, Str] - give the kernel usage advice about a mapped region. TODO(compiler): implement.
// fn mmap_protect(ptr, length, prot: Int) -> Result[Unit, Str] - change the protection flags of a mapped region. TODO(compiler): implement.
// fn mmap_lock(ptr, length) -> Result[Unit, Str] - lock mapped pages in memory. TODO(compiler): implement.
// fn mmap_unlock(ptr, length) -> Result[Unit, Str] - unlock mapped pages. TODO(compiler): implement.
// fn mmap_copy(ptr, length) -> Vec[UInt8] - copy length bytes out of a mapped region. TODO(compiler): implement.
// fn mmap_write(ptr, data: &Vec[UInt8]) -> Result[Unit, Str] - copy bytes into a mapped region. TODO(compiler): implement.
// fn mmap_resize(ptr, old_len, new_len) -> Result[Int, Str] - grow or shrink a mapping and return the new address. TODO(compiler): implement.
