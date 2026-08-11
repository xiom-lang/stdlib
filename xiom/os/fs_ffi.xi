// XIOM - OS: fs_ffi (advanced file system via FFI syscalls)
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.os.fs_ffi

// Depends on: xiom.ffi, xiom.io

// ============================================================================
// Advanced file-system operations that go beyond os.xi / io.xi: symlinks,
// mmap, dup, positional and vectored I/O, sendfile/splice, fsync family,
// memory advice and FIFOs. All via minimal C FFI; zero external libraries.
// The compiler's unsafe-extern path is fixed (BUG 11) so these can be
// implemented directly once the API freeze allows new FFI modules.
// ============================================================================

// fn symlink(target: Str, link: Str) -> Result[Unit, Str] - create a symbolic link. TODO(compiler): implement.
// fn readlink(path: Str) -> Result[Str, Str] - read a symlink target. TODO(compiler): implement.
// fn is_symlink(path: Str) -> Bool - true if path is a symbolic link. TODO(compiler): implement.
// fn hard_link(old: Str, new: Str) -> Result[Unit, Str] - create a hard link. TODO(compiler): implement.
// fn chown(path: Str, uid: Int, gid: Int) -> Result[Unit, Str] - change owner/group. TODO(compiler): implement.
// fn chmod(path: Str, mode: Int) -> Result[Unit, Str] - change permissions. TODO(compiler): implement.
// struct MappedFile { ptr: Int; length: Int; fd: Int; } - mmap result. TODO(compiler): implement.
// fn mmap(path: Str, offset: Int, length: Int) -> Result[MappedFile, Str] - memory-map a file. TODO(compiler): implement.
// fn munmap(m: MappedFile) - unmap a mapped region. TODO(compiler): implement.
// fn msync(m: MappedFile) -> Result[Unit, Str] - flush mapped pages. TODO(compiler): implement.
// fn madvise(m: MappedFile, advice: Int) -> Result[Unit, Str] - advise the kernel on page use. TODO(compiler): implement.
// fn mlock(m: MappedFile) -> Result[Unit, Str] - lock pages in memory. TODO(compiler): implement.
// fn munlock(m: MappedFile) -> Result[Unit, Str] - unlock pages. TODO(compiler): implement.
// fn dup(fd: Int) -> Result[Int, Str] - duplicate a file descriptor. TODO(compiler): implement.
// fn dup2(old: Int, new: Int) -> Result[Int, Str] - duplicate onto a specific fd. TODO(compiler): implement.
// fn truncate(path: Str, length: Int) -> Result[Unit, Str] - truncate a file by path. TODO(compiler): implement.
// fn ftruncate(fd: Int, length: Int) -> Result[Unit, Str] - truncate an open file. TODO(compiler): implement.
// fn fallocate(fd: Int, offset: Int, length: Int) -> Result[Unit, Str] - pre-allocate space. TODO(compiler): implement.
// fn pread(fd: Int, offset: Int, length: Int) -> Result[Vec[UInt8], Str] - positioned read. TODO(compiler): implement.
// fn pwrite(fd: Int, offset: Int, data: &Vec[UInt8]) -> Result[Int, Str] - positioned write. TODO(compiler): implement.
// fn readv(fd: Int, buffers: &Vec[Vec[UInt8]]) -> Result[Int, Str] - vectored read. TODO(compiler): implement.
// fn writev(fd: Int, buffers: &Vec[Vec[UInt8]]) -> Result[Int, Str] - vectored write. TODO(compiler): implement.
// fn sendfile(out_fd: Int, in_fd: Int, offset: Int, count: Int) -> Result[Int, Str] - copy between fds in-kernel. TODO(compiler): implement.
// fn splice(in_fd: Int, out_fd: Int, count: Int) -> Result[Int, Str] - move data between fds without copying. TODO(compiler): implement.
// fn fsync(fd: Int) -> Result[Unit, Str] - flush file data and metadata. TODO(compiler): implement.
// fn fdatasync(fd: Int) -> Result[Unit, Str] - flush file data only. TODO(compiler): implement.
// fn mkfifo(path: Str, mode: Int) -> Result[Unit, Str] - create a named pipe. TODO(compiler): implement.
// fn fifo_open(path: Str) -> Result[Int, Str] - open a named pipe. TODO(compiler): implement.
