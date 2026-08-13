// XIOM - I/O: File System
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.io.fs

// Depends on: xiom.io

// ============================================================================
// File system operations over paths.
// Delegates to the parent xiom.io helpers where names differ and the target
// is self-contained (io.copy_file's internal `?` miscompiles, so copy is
// implemented locally); range reads/writes, touch, and byte writes are
// implemented locally over stdio in binary mode.
// ============================================================================

use xiom.io;
use xiom.os;

extern "C" {
  fn fopen(path: *UInt8, mode: *UInt8) -> *UInt8;
  fn fclose(file: *UInt8) -> Int32;
  fn fread(buf: *UInt8, size: UInt, count: UInt, file: *UInt8) -> UInt;
  fn fwrite(buf: *UInt8, size: UInt, count: UInt, file: *UInt8) -> UInt;
  fn fseek(file: *UInt8, offset: Int32, whence: Int32) -> Int32;
  fn rename(old: *UInt8, new: *UInt8) -> Int32;
}

fn err_msg(action: Str, path: Str) -> Str {
  return "failed to " + action + ": " + path;
}

/// Read the whole file as bytes.
/// Params: path - the file path.
/// Returns: Ok(file bytes), Err on failure.
/// Complexity: O(n) where n is the file size.
pub fn fs_read(path: Str) -> Result[Vec[UInt8], Str> {
  let r = io.read_file_bytes(path);
  match r {
    Ok(b) => Ok(b);
    Err(e) => Err(e.message);
  }
}

/// Write bytes, truncating an existing file (binary mode).
/// Params: path - the file path; data - the bytes to write.
/// Returns: Ok(()) on success, Err on failure.
/// Complexity: O(n) where n is the data length.
pub fn fs_write(path: Str, data: &Vec[UInt8]) -> Result[Unit, Str> {
  let file: *UInt8;
  unsafe {
    file = fopen(path.c_str(), "wb");
  }
  if file == 0 {
    return Err(err_msg("open for write", path));
  }
  var i: UInt = 0;
  let n = data.len() as UInt;
  while i < n {
    let b = data[i];
    let written: UInt;
    unsafe {
      written = fwrite(&b, 1 as UInt, 1 as UInt, file);
    }
    i = i + 1;
  }
  unsafe {
    let _ = fclose(file);
  }
  return Ok(());
}

/// Append bytes to a file (binary mode).
/// Params: path - the file path; data - the bytes to append.
/// Returns: Ok(()) on success, Err on failure.
/// Complexity: O(n) where n is the data length.
pub fn fs_append(path: Str, data: &Vec[UInt8]) -> Result[Unit, Str> {
  let file: *UInt8;
  unsafe {
    file = fopen(path.c_str(), "ab");
  }
  if file == 0 {
    return Err(err_msg("open for append", path));
  }
  var i: UInt = 0;
  let n = data.len() as UInt;
  while i < n {
    let b = data[i];
    let written: UInt;
    unsafe {
      written = fwrite(&b, 1 as UInt, 1 as UInt, file);
    }
    i = i + 1;
  }
  unsafe {
    let _ = fclose(file);
  }
  return Ok(());
}

/// Read a file as UTF-8 text.
/// Params: path - the file path.
/// Returns: Ok(file content), Err on failure.
/// Complexity: O(n) where n is the file size.
pub fn fs_read_text(path: Str) -> Result[Str, Str> {
  let r = io.read_file(path);
  match r {
    Ok(s) => Ok(s);
    Err(e) => Err(e.message);
  }
}

/// Write a text string to a file.
/// Params: path - the file path; s - the content.
/// Returns: Ok(()) on success, Err on failure.
/// Complexity: O(n) where n is the content length.
pub fn fs_write_text(path: Str, s: Str) -> Result[Unit, Str> {
  let r = io.write_file(path, s);
  match r {
    Ok(()) => Ok(());
    Err(e) => Err(e.message);
  }
}

/// Copy a file to a new path.
/// Params: src - the source path; dst - the destination path.
/// Returns: Ok(()) on success, Err on failure.
/// Complexity: O(n) where n is the source size.
pub fn fs_copy(src: Str, dst: Str) -> Result[Unit, Str> {
  // Text-mode copy via the parent read_file/write_file helpers (both are
  // self-contained; io.copy_file's internal `?` miscompiles, and raw byte
  // streaming trips the loop stack protector).
  let r = io.read_file(src);
  match r {
    Ok(s) => {
      let w = io.write_file(dst, s);
      match w {
        Ok(()) => Ok(());
        Err(e) => Err(e.message);
      }
    }
    Err(e) => Err(e.message);
  }
}

/// Move or rename a file.
/// Params: src - the source path; dst - the destination path.
/// Returns: Ok(()) on success, Err on failure.
/// Complexity: O(n) copy + delete (non-atomic — documented; the libc
/// rename() path is unusable: its return code is corrupted through the
/// catalog unsafe-block trampoline, BUG 22 #15/26 family — the file moved
/// correctly but the code always read non-zero).
pub fn fs_move(src: Str, dst: Str) -> Result[Unit, Str> {
  let r = io.read_file_bytes(src);
  match r {
    Ok(s) => {
      let w = io.write_file_bytes(dst, &s);
      match w {
        Ok(()) => {
          let d = io.remove_file(src);
          match d {
            Ok(()) => Ok(()),
            Err(e) => Err(e.message),
          }
        }
        Err(e) => Err(e.message),
      }
    }
    Err(e) => Err(e.message),
  }
}

/// Whether the path exists.
/// Params: path - the path.
/// Returns: true if the path can be opened for reading.
/// Complexity: O(1).
pub fn fs_exists(path: Str) -> Bool {
  return io.file_exists(path);
}

/// Whether the path is a regular file.
/// Params: path - the path.
/// Returns: true if the path is a regular file.
/// Complexity: O(1).
pub fn fs_is_file(path: Str) -> Bool {
  let r = io.metadata(path);
  match r {
    Ok(m) => m.is_file;
    Err(_) => false;
  }
}

/// Whether the path is a directory.
/// Params: path - the path.
/// Returns: true if the path is a directory.
/// Complexity: O(1).
pub fn fs_is_dir(path: Str) -> Bool {
  return io.is_dir(path);
}

/// File size in bytes.
/// Params: path - the file path.
/// Returns: Ok(size in bytes), Err on failure.
/// Complexity: O(1).
pub fn fs_size(path: Str) -> Result[Int, Str> {
  let r = io.file_size(path);
  match r {
    Some(s) => Ok(s);
    None => Err(err_msg("stat", path));
  }
}

/// Last modification time as a Unix timestamp.
/// Params: path - the file path.
/// Returns: Ok(mtime in seconds since the epoch), Err on failure.
/// Complexity: O(1).
pub fn fs_mtime(path: Str) -> Result[Int, Str> {
  let r = io.file_modified_time(path);
  match r {
    Some(t) => Ok(t);
    None => Err(err_msg("stat", path));
  }
}

/// Read `len` bytes starting at `offset`.
/// Params: path - the file path; offset - the start offset; len - the count.
/// Returns: Ok(bytes read; fewer only at EOF), Err on failure.
/// Complexity: O(len).
pub fn fs_read_range(path: Str, offset: Int, len: Int) -> Result[Vec[UInt8], Str> {
  var count = len;
  if count < 0 {
    count = 0;
  }
  if offset < 0 {
    return Err(err_msg("read range", path));
  }
  let file: *UInt8;
  unsafe {
    file = fopen(path.c_str(), "rb");
  }
  if file == 0 {
    return Err(err_msg("open for read", path));
  }
  unsafe {
    let _ = fseek(file, offset as Int32, 0 as Int32);
  }
  var out: Vec[UInt8] = Vec[UInt8]::with_capacity(count as UInt);
  var buf: [4096]UInt8;
  var remaining = count;
  while remaining > 0 {
    var chunk = remaining;
    if chunk > 4096 {
      chunk = 4096;
    }
    var nread: UInt;
    unsafe {
      nread = fread(&buf[0], 1 as UInt, chunk as UInt, file);
    }
    if nread == 0 {
      remaining = 0;
    } else {
      var i: Int = 0;
      while i < (nread as Int) {
        out.push(buf[i]);
        i = i + 1;
      }
      remaining = remaining - (nread as Int);
    }
  }
  unsafe {
    let _ = fclose(file);
  }
  return Ok(out);
}

/// Write bytes at an offset, returning bytes written.
/// Params: path - the file path; offset - the start offset; data - the bytes.
/// Returns: Ok(bytes written), Err on failure.
/// Complexity: O(n) where n is the data length.
pub fn fs_write_range(path: Str, offset: Int, data: &Vec[UInt8]) -> Result[Int, Str> {
  if offset < 0 {
    return Err(err_msg("write range", path));
  }
  let file: *UInt8;
  unsafe {
    file = fopen(path.c_str(), "r+b");
  }
  if file == 0 {
    return Err(err_msg("open for write", path));
  }
  unsafe {
    let _ = fseek(file, offset as Int32, 0 as Int32);
  }
  var written_total: Int = 0;
  var i: UInt = 0;
  let n = data.len() as UInt;
  while i < n {
    let b = data[i];
    let written: UInt;
    unsafe {
      written = fwrite(&b, 1 as UInt, 1 as UInt, file);
    }
    written_total = written_total + (written as Int);
    i = i + 1;
  }
  unsafe {
    let _ = fclose(file);
  }
  return Ok(written_total);
}

/// Create an empty file if missing, update mtime.
/// Params: path - the file path.
/// Returns: Ok(()) on success, Err on failure.
/// Complexity: O(1).
pub fn fs_touch(path: Str) -> Result[Unit, Str> {
  let file: *UInt8;
  unsafe {
    file = fopen(path.c_str(), "ab");
  }
  if file == 0 {
    return Err(err_msg("touch", path));
  }
  unsafe {
    let _ = fclose(file);
  }
  return Ok(());
}

/// Return a usable temporary directory path.
/// Returns: the system temporary directory.
/// Complexity: O(1).
pub fn fs_temp_dir() -> Str {
  return os.temp_dir();
}
