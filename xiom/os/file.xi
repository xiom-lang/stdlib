// XIOM -- File Helpers (xiom.os.file)
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// File helpers built on the xiom.io runtime primitives. Delegates to
// the flat xiom.io module.

module xiom.os.file

use xiom.io;
use xiom.string;
use xiom.os.fs;

/// file_read reads an entire file as text.
/// Delegates to io.read_file. Complexity: O(n).
pub fn file_read(path: Str) -> Result[Str, Str] {
  if path.len() == 0 {
    return Err("file_read: empty path");
  }
  let r = io.read_file(path);
  match r {
    Ok(s) => Ok(s);
    Err(e) => Err(e.message);
  }
}

/// file_write writes text to a file, truncating if it exists.
/// Delegates to io.write_file. Complexity: O(n).
pub fn file_write(path: Str, content: Str) -> Result[Unit, Str] {
  if path.len() == 0 {
    return Err("file_write: empty path");
  }
  let r = io.write_file(path, content);
  match r {
    Ok(()) => Ok(());
    Err(e) => Err(e.message);
  }
}

/// file_append appends text to a file, creating it if needed.
/// Delegates to io.append_file. Complexity: O(n).
pub fn file_append(path: Str, content: Str) -> Result[Unit, Str] {
  if path.len() == 0 {
    return Err("file_append: empty path");
  }
  let r = io.append_file(path, content);
  match r {
    Ok(()) => Ok(());
    Err(e) => Err(e.message);
  }
}

/// file_exists returns true if path exists (file or directory).
/// Implemented locally via io.metadata to avoid a same-name delegation.
/// Complexity: O(1) syscall.
pub fn file_exists(path: Str) -> Bool {
  if path.len() == 0 {
    return false;
  }
  let r = io.metadata(path);
  r.is_ok
}

/// file_remove deletes a file.
/// Delegates to io.remove_file. Complexity: O(1) syscall.
pub fn file_remove(path: Str) -> Result[Unit, Str] {
  if path.len() == 0 {
    return Err("file_remove: empty path");
  }
  let r = io.remove_file(path);
  match r {
    Ok(()) => Ok(());
    Err(e) => Err(e.message);
  }
}

/// file_copy copies a file from src to dst.
/// Delegates to io.copy_file. Complexity: O(n).
pub fn file_copy(src: Str, dst: Str) -> Result[Unit, Str] {
  if src.len() == 0 || dst.len() == 0 {
    return Err("file_copy: empty path");
  }
  let r = io.copy_file(src, dst);
  match r {
    Ok(()) => Ok(());
    Err(e) => Err(e.message);
  }
}

/// file_rename renames (moves) a file or directory.
/// Delegates to io.rename. Complexity: O(1) syscall.
pub fn file_rename(src: Str, dst: Str) -> Result[Unit, Str] {
  if src.len() == 0 || dst.len() == 0 {
    return Err("file_rename: empty path");
  }
  let r = io.rename(src, dst);
  match r {
    Ok(()) => Ok(());
    Err(e) => Err(e.message);
  }
}

/// file_size returns the size of a file in bytes.
/// Implemented locally via io.metadata. Complexity: O(1) syscall.
pub fn file_size(path: Str) -> Result[Int, Str] {
  if path.len() == 0 {
    return Err("file_size: empty path");
  }
  let r = io.metadata(path);
  match r {
    Ok(m) => Ok(m.size);
    Err(e) => Err(e.message);
  }
}

/// file_extension returns the extension of path's file name (text after
/// the last dot), or None. Delegates to fs.fs_extension. Complexity: O(n).
pub fn file_extension(path: Str) -> Option[Str] {
  fs.fs_extension(path)
}

/// file_stem returns path without its last extension.
/// Delegates to fs.fs_stem. Complexity: O(n).
pub fn file_stem(path: Str) -> Option[Str] {
  fs.fs_stem(path)
}

/// file_name returns the file-name portion of path, or None.
/// Delegates to fs.fs_file_name. Complexity: O(n).
pub fn file_name(path: Str) -> Option[Str] {
  fs.fs_file_name(path)
}

/// file_parent returns the directory portion of path, or None.
/// Delegates to fs.fs_parent_dir. Complexity: O(n).
pub fn file_parent(path: Str) -> Option[Str] {
  fs.fs_parent_dir(path)
}
