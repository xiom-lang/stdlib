// XIOM -- Filesystem Helpers (xiom.os.fs)
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.
//
// Pure-computation filesystem helpers built on the existing
// xiom.io / xiom.os runtime primitives. No new FFI is invented;
// functions that would require an unavailable syscall fall back to
// a clear error or a documented default.

module xiom.os.fs

use xiom.io;
use xiom.env;
use xiom.string;
use xiom.convert;

// fs_file_name returns the file-name portion of path (after the last
// '/' or '\'), or None if path is empty or ends in a separator.
pub fn fs_file_name(path: Str) -> Option[Str] {
  if path.len() == 0 {
    return None;
  };
  var i = path.len() - 1;
  while i >= 0 {
    let b = path.byte_at(i);
    if b == 47 || b == 92 {
      if i == path.len() - 1 {
        return None;
      };
      return Some(string.str_slice(path, i + 1, path.len()));
    };
    i = i - 1;
  };
  return Some(path);
}

// fs_parent_dir returns the directory portion of path (everything
// before the last '/' or '\'), or None if path has no parent.
pub fn fs_parent_dir(path: Str) -> Option[Str] {
  if path.len() == 0 {
    return None;
  };
  var i = path.len() - 1;
  while i >= 0 {
    let b = path.byte_at(i);
    if b == 47 || b == 92 {
      if i == 0 {
        return Some("/");
      };
      return Some(string.str_slice(path, 0, i));
    };
    i = i - 1;
  };
  return None;
}

// fs_extension returns the extension (text after the last dot in the
// file name), or None if there is no dot or the dot is leading/trailing.
// "a/b.tar.gz" -> Some("gz"); "a/b" -> None.
pub fn fs_extension(path: Str) -> Option[Str] {
  if path.len() == 0 {
    return None;
  };
  var name_start = 0;
  var i = path.len() - 1;
  while i >= 0 {
    let b = path.byte_at(i);
    if b == 47 || b == 92 {
      name_start = i + 1;
      break;
    };
    i = i - 1;
  };
  var dot_i: Int = -1;
  var j = path.len() - 1;
  while j >= name_start {
    if path.byte_at(j) == 46 {
      dot_i = j;
      break;
    };
    j = j - 1;
  };
  if dot_i <= name_start || dot_i == path.len() - 1 {
    return None;
  };
  return Some(string.str_slice(path, dot_i + 1, path.len()));
}

// fs_stem returns the path with the last extension stripped, or the
// path unchanged if it has no extension. "a/b.tar.gz" -> "a/b.tar".
pub fn fs_stem(path: Str) -> Option[Str] {
  let name_opt = fs_file_name(path);
  match name_opt {
    None => return None;
    Some(name) => {
      if name == "." || name == ".." {
        return Some(path);
      };
      var i = name.len() - 1;
      while i >= 0 {
        if name.byte_at(i) == 46 {
          if i == 0 {
            return Some(path);
          };
          let dir_part = path.len() - name.len();
          return Some(string.str_slice(path, 0, dir_part + i));
        };
        i = i - 1;
      };
      return Some(path);
    };
  }
}

// fs_is_hidden returns true if the file name starts with a dot,
// except for the special entries "." and "..".
pub fn fs_is_hidden(path: Str) -> Bool {
  let name_opt = fs_file_name(path);
  match name_opt {
    None => return false;
    Some(name) => {
      if name == "." || name == ".." {
        return false;
      };
      return name.len() > 0 && name.byte_at(0) == 46;
    };
  }
}

// fs_join_parts joins the given components with the OS path separator
// (env.path_separator: "\\" on Windows, "/" elsewhere).
pub fn fs_join_parts(parts: Vec[Str]) -> Str {
  let sep = env.path_separator();
  var result = "";
  var i: Int = 0;
  while i < parts.len() {
    if i > 0 {
      result = result + sep;
    };
    result = result + parts[i];
    i = i + 1;
  };
  return result;
}

// fs_normalize collapses duplicate separators and resolves "." and ".."
// lexically, without touching the filesystem. Leading "/" and "C:\"-style
// drive prefixes are preserved. "a/b/../c//d/./e" -> "a/c/d/e".
pub fn fs_normalize(path: Str) -> Str {
  if path.len() == 0 {
    return "";
  };
  var is_abs = false;
  var drive_prefix = "";
  var rest = path;
  if path.starts_with("/") {
    is_abs = true;
  } elif path.len() >= 2 && path.byte_at(1) == 58 {
    drive_prefix = string.str_slice(path, 0, 2);
    is_abs = true;
    rest = string.str_slice(path, 2, path.len());
  };
  let norm = string.replace(rest, "\\", "/");
  let comps = string.str_split(norm, "/");
  var out: Vec[Str] = Vec[Str].new();
  var i: Int = 0;
  while i < comps.len() {
    let c = comps[i];
    if c == "." || c.len() == 0 {
      // skip "." and empty components
    } elif c == ".." {
      if out.len() > 0 {
        out.pop();
      };
    } else {
      out.push(c);
    };
    i = i + 1;
  };
  var result = drive_prefix;
  var j: Int = 0;
  while j < out.len() {
    if j > 0 || is_abs {
      result = result + "/";
    };
    result = result + out[j];
    j = j + 1;
  };
  if is_abs && result == drive_prefix {
    result = result + "/";
  };
  return result;
}

// fs_with_extension replaces the extension of path with new_ext, or
// appends it if path has no extension. "a/b.txt" + "md" -> "a/b.md".
pub fn fs_with_extension(path: Str, new_ext: Str) -> Str {
  let stem_opt = fs_stem(path);
  match stem_opt {
    Some(stem) => return stem + "." + new_ext;
    None => return path + "." + new_ext;
  }
}

// fs_split returns (dir, file) -- the directory and file-name portions.
pub fn fs_split(path: Str) -> (Str, Str) {
  let dir_opt = fs_parent_dir(path);
  let file_opt = fs_file_name(path);
  var dir = "";
  var file = "";
  var has_dir = false;
  var has_file = false;
  match dir_opt {
    Some(d) => {
      dir = d;
      has_dir = true;
    };
    None => {};
  };
  match file_opt {
    Some(f) => {
      file = f;
      has_file = true;
    };
    None => {};
  };
  if has_dir {
    if has_file {
      return (dir, file);
    };
    return (dir, "");
  };
  if has_file {
    return ("", file);
  };
  return (path, "");
}

// fs_unique_path returns dir/name if it does not exist, otherwise appends
// " (1)", " (2)", ... up to a maximum of 1000 attempts.
pub fn fs_unique_path(dir: Str, name: Str) -> Str {
  let base = io.join_paths(dir, name);
  if not io.file_exists(base) {
    return base;
  };
  var n: Int = 1;
  while n <= 1000 {
    let cand = io.join_paths(dir, name + " (" + convert.int_to_string(n) + ")");
    if not io.file_exists(cand) {
      return cand;
    };
    n = n + 1;
  };
  return base;
}
