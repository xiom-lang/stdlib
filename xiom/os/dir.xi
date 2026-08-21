// XIOM -- Directory Helpers (xiom.os.dir)
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.
//
// Directory helpers built on the xiom.io and xiom.env runtime
// primitives. Delegates to the flat xiom.io / xiom.env modules.

module xiom.os.dir

use xiom.io;
use xiom.env;
use xiom.os.fs;

// dir_current returns the current working directory.
// Delegates to env.current_dir. Complexity: O(1) syscall.
pub fn dir_current() -> Result[Str, Str] {
  let r = env.current_dir();
  match r {
    Ok(p) => Ok(p);
    Err(e) => Err(e);
  }
}

// dir_create creates a single directory.
// Delegates to io.create_dir. Complexity: O(1) syscall.
pub fn dir_create(path: Str) -> Result[Unit, Str] {
  if path.len() == 0 {
    return Err("dir_create: empty path");
  }
  let r = io.create_dir(path);
  match r {
    Ok(()) => Ok(());
    Err(e) => Err(e.message);
  }
}

// dir_create_all creates a directory and all missing parents.
// Delegates to io.create_dir_all. Complexity: O(depth) syscalls.
pub fn dir_create_all(path: Str) -> Result[Unit, Str] {
  if path.len() == 0 {
    return Ok(());
  }
  let r = io.create_dir_all(path);
  match r {
    Ok(()) => Ok(());
    Err(e) => Err(e.message);
  }
}

// dir_list returns the names of entries in a directory.
// Delegates to io.list_dir. Complexity: O(n) syscalls.
pub fn dir_list(path: Str) -> Result[Vec[Str], Str] {
  if path.len() == 0 {
    return Err("dir_list: empty path");
  }
  let r = io.list_dir(path);
  match r {
    Ok(items) => Ok(items);
    Err(e) => Err(e.message);
  }
}

// dir_exists returns true if path exists and is a directory.
// Delegates to io.is_dir. Complexity: O(1) syscall.
pub fn dir_exists(path: Str) -> Bool {
  if path.len() == 0 {
    return false;
  }
  io.is_dir(path)
}

// dir_remove removes an empty directory.
// Delegates to io.remove_file (which handles both files and dirs via
// the C runtime). Complexity: O(1) syscall.
pub fn dir_remove(path: Str) -> Result[Unit, Str] {
  if path.len() == 0 {
    return Err("dir_remove: empty path");
  }
  let r = io.remove_file(path);
  match r {
    Ok(()) => Ok(());
    Err(e) => Err(e.message);
  }
}

// dir_temp returns the system temporary directory.
// Delegates to env.temp_dir. Complexity: O(1).
pub fn dir_temp() -> Str {
  env.temp_dir()
}

// dir_home returns the current user's home directory, if known.
// Delegates to env.home_dir. Complexity: O(1).
pub fn dir_home() -> Option[Str] {
  env.home_dir()
}

// dir_is_empty returns true if a directory contains no entries.
// Complexity: O(n) syscalls.
pub fn dir_is_empty(path: Str) -> Bool {
  if !io.is_dir(path) {
    return false;
  }
  let r = io.list_dir(path);
  match r {
    Ok(items) => items.len() == 0;
    Err(_) => false;
  }
}

// dir_join joins two path components with the OS separator.
// Delegates to io.join_paths. Complexity: O(1).
pub fn dir_join(a: Str, b: Str) -> Str {
  io.join_paths(a, b)
}

// dir_parent returns the parent directory of path, or None if there is
// none. Delegates to fs.fs_parent_dir. Complexity: O(n).
pub fn dir_parent(path: Str) -> Option[Str] {
  fs.fs_parent_dir(path)
}
