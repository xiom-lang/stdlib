// XIOM - I/O: File System
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.io.fs

// Depends on: xiom.io

// ============================================================================
// File system operations over paths. NOTE: current implementation lives in
// io.xi - move the functions here during the implementation phase.
// TODO(compiler): implement.
// ============================================================================

// fn fs_read(path: Str) -> Result[Vec[UInt8], Str] - read the whole file as bytes. TODO(compiler): implement.
// fn fs_write(path: Str, data: &Vec[UInt8]) -> Result[Unit, Str] - write bytes, truncating an existing file. TODO(compiler): implement.
// fn fs_append(path, data) -> Result[Unit, Str] - append bytes to a file. TODO(compiler): implement.
// fn fs_read_text(path) -> Result[Str, Str] - read a file as UTF-8 text. TODO(compiler): implement.
// fn fs_write_text(path, s: Str) -> Result[Unit, Str] - write a text string to a file. TODO(compiler): implement.
// fn fs_copy(src, dst) -> Result[Unit, Str] - copy a file to a new path. TODO(compiler): implement.
// fn fs_move(src, dst) -> Result[Unit, Str] - move or rename a file. TODO(compiler): implement.
// fn fs_exists(path) -> Bool - whether the path exists. TODO(compiler): implement.
// fn fs_is_file(path) -> Bool - whether the path is a regular file. TODO(compiler): implement.
// fn fs_is_dir(path) -> Bool - whether the path is a directory. TODO(compiler): implement.
// fn fs_size(path) -> Result[Int, Str] - file size in bytes. TODO(compiler): implement.
// fn fs_mtime(path) -> Result[Int, Str] - last modification time as a Unix timestamp. TODO(compiler): implement.
// fn fs_read_range(path, offset, len) -> Result[Vec[UInt8], Str] - read len bytes starting at offset. TODO(compiler): implement.
// fn fs_write_range(path, offset, data) -> Result[Int, Str] - write bytes at an offset, returning bytes written. TODO(compiler): implement.
// fn fs_touch(path) -> Result[Unit, Str] - create an empty file if missing, update mtime. TODO(compiler): implement.
// fn fs_temp_dir() -> Str - return a usable temporary directory path. TODO(compiler): implement.
