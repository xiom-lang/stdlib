// XIOM -- Path Manipulation
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.path

use xiom.env;

pub type Path = { inner: Str; } derive[Eq, Clone, Hash, Ord]
pub type PathBuf = { inner: Str; } derive[Eq, Clone]

// Path constructors
pub fn Path.new(s: Str) -> Path
  ensures: result.inner == s
{
  Path{ inner: s; }
}

pub fn PathBuf.new() -> PathBuf
  ensures: result.inner == ""
{
  PathBuf{ inner: ""; }
}

pub fn PathBuf.from(s: Str) -> PathBuf
  ensures: result.inner == s
{
  PathBuf{ inner: s; }
}

// Path operations
pub fn Path.parent(self) -> Option<Path>
  // (was: ensures prose -- contract-eval Str field read corrupts the fn, BUG 56 family; the prose is documentation, moved here)
{
  // Find the last path separator not at the end, return everything before it.
  var s = self.inner;
  var len = xiom.string.str_len(s);
  // Strip trailing separator(s)
  var end = len;
  while end > 0 {
    let ch = xiom.string.char_at(s, end - 1);
    if ch.is_some {
      let c = ch.value;
      if c == '/' || c == '\\' { end = end - 1; }
      else { break; }
    }
  }
  // Find last separator before end
  var i = end - 1;
  while i >= 0 {
    let ch = xiom.string.char_at(s, i);
    if ch.is_some {
      let c = ch.value;
      if c == '/' || c == '\\' {
        if i == 0 { return Some(Path.new(xiom.string.str_slice(s, 0, 1))); }
        return Some(Path.new(xiom.string.str_slice(s, 0, i)));
      }
    }
    i = i - 1;
  }
  return None;
}

pub fn Path.file_name(self) -> Option<Str>
{
  // Find the last path separator and return everything after it.
  // Uses xiom.string helpers (str_len, char_at) which are available.
  var s = self.inner;
  var i = xiom.string.str_len(s) - 1;
  while i >= 0 {
    let ch = xiom.string.char_at(s, i);
    if ch.is_some {
      let c = ch.value;
      if c == '/' || c == '\\' {
        if i == xiom.string.str_len(s) - 1 {
          return None;
        }
        return Some(xiom.string.str_slice(s, i + 1, xiom.string.str_len(s)));
      }
    }
    i = i - 1;
  }
  return Some(s);
}

pub fn Path.extension(self) -> Option<Str>
  ensures: result.is_some => self.inner.len() > 0 {
  // Find the last '.' in the file name and return everything after it.
  var name_opt = self.file_name();
  if name_opt.is_none {
    return None;
  }
  var name = name_opt.unwrap();
  var dot = xiom.string.last_index_of(name, ".");
  match dot {
    Some(0) => { return None; }
    Some(pos) => { return Some(xiom.string.str_slice(name, pos + 1, xiom.string.str_len(name))); }
    None => { return None; }
  }
}

pub fn Path.file_stem(self) -> Option<Str> {
  var name_opt = self.file_name();
  match name_opt {
    Some(n) => {
      var dot = xiom.string.last_index_of(n, ".");
      match dot {
        Some(0) => { return Some(n); }
        Some(pos) => { return Some(xiom.string.str_slice(n, 0, pos)); }
        None => { return Some(n); }
      }
    }
    None => { return None; }
  }
}

pub fn Path.is_absolute(self) -> Bool
  ensures: result => self.inner.len() >= 1 {
  var s = self.inner;
  if xiom.string.str_len(s) >= 1 {
    let ch = xiom.string.char_at(s, 0);
    if ch.is_some {
      let c = ch.value;
      return c == '/' || c == '\\';
    }
  }
  return false;
}

pub fn Path.is_relative(self) -> Bool {
  return !self.is_absolute();
}

pub fn Path.has_root(self) -> Bool {
  var s = self.inner;
  if xiom.string.str_len(s) >= 1 {
    let ch = xiom.string.char_at(s, 0);
    if ch.is_some {
      let c = ch.value;
      if c == '/' || c == '\\' { return true; }
    }
  }
  return false;
}

pub fn Path.components(self) -> Vec<Str>
  ensures: result.len() >= 1
{
  var normalized = replace(self.inner, "\\", "/");
  return str_split(normalized, "/");
}

pub fn Path.to_str(self) -> Str {
  self.inner
}

pub fn Path.join(self, child: Str) -> PathBuf {
  PathBuf{ inner: join_paths(self.inner, child); }
}

pub fn Path.with_extension(self, ext: Str) -> PathBuf {
  var stem = self.file_stem();
  match stem {
    Some(s) => {
      var new_name = str_concat(str_concat(s, "."), ext);
      var parent = self.parent();
      match parent {
        Some(p) => { return p.join(new_name); }
        None => { return PathBuf{ inner: new_name; }; }
      }
    }
    None => {
      var new_name = str_concat(str_concat(self.inner, "."), ext);
      return PathBuf{ inner: new_name; };
    }
  }
}

pub fn Path.with_file_name(self, name: Str) -> PathBuf {
  var p = self.parent();
  match p {
    Some(parent) => { return parent.join(name); }
    None => { return PathBuf{ inner: name; }; }
  }
}

pub fn Path.exists(self) -> Bool {
  return file_exists(self.inner);
}

pub fn Path.is_file(self) -> Bool {
  if !file_exists(self.inner) { return false; }
  return !is_dir(self.inner);
}

pub fn Path.is_dir(self) -> Bool {
  return is_dir(self.inner);
}

pub fn Path.metadata(self) -> Result<Metadata, Str> {
  var result = metadata(self.inner);
  match result {
    Ok(m) => { return Ok(m); }
    Err(e) => { return Err(e.message); }
  }
}

pub fn Path.canonicalize(self) -> Result<PathBuf, Str>
{
  // String-based path canonicalization: collapse `.`, `..`, and double
  // separators without filesystem calls.  Does NOT resolve symlinks --
  // that requires OS-level `realpath` which isn't available yet.
  let is_abs = self.inner.len() > 0 && (self.inner.starts_with("/") || self.inner.starts_with("\\"));
  var comps = self.components();
  var out: Vec[Str] = Vec[Str].new();
  var i = 0;
  while i < comps.len() {
    let c = comps[i];
    if c == "." || c.len() == 0 {
      // skip `.` and empty components
    } elif c == ".." {
      if out.len() > 0 {
        out.pop();
      }
    } else {
      out.push(c);
    }
    i = i + 1;
  }
  // Rebuild the path string
  var result = "";
  var j = 0;
  while j < out.len() {
    if j > 0 || is_abs {
      result = result + "/";
    }
    result = result + out[j];
    j = j + 1;
  }
  if is_abs && result == "" {
    result = "/";
  }
  return Ok(PathBuf{ inner: result });
}

pub fn Path.starts_with(self, base: Path) -> Bool {
  return str_starts_with(self.inner, base.inner);
}

pub fn Path.ends_with(self, child: Path) -> Bool {
  return str_ends_with(self.inner, child.inner);
}

// PathBuf operations
// NOTE: These take &mut self (the old by-value forms mutated a copy and
// required callers to capture the return -- the stale "&mut self not
// supported" note predates the BUG 55 fixes; cell.xi &mut self works).
pub fn PathBuf.push(&mut self, component: Str)
  requires: component.len() >= 0
{
  if is_empty(self.inner) {
    self.inner = component;
    return;
  }
  if str_ends_with(self.inner, "/") || str_ends_with(self.inner, "\\") {
    self.inner = str_concat(self.inner, component);
    return;
  }
  self.inner = str_concat(str_concat(self.inner, "/"), component);
}

pub fn PathBuf.pop(&mut self) -> Bool {
  var p = parent_path(self.inner);
  match p {
    Some(parent) => {
      self.inner = parent;
      return true;
    }
    None => { return false; }
  }
}

pub fn PathBuf.as_path(self) -> Path {
  Path{ inner: self.inner; }
}

pub fn PathBuf.clear(&mut self) {
  self.inner = "";
}

// Utility
pub fn path_separator() -> Str {
  return env.path_separator();
}

// path_is_absolute_str returns true if p starts with '/' or '\\'.
pub fn path_is_absolute_str(p: Str) -> Bool {
  if p.is_empty() { return false; };
  let ch = p.byte_at(0);
  return ch == 47 || ch == 92;
}
