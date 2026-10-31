// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_io_path
use xiom.io;

fn main() -> Int {
  if io.join_paths("base", "child") != "base/child" { return 1; }
  if io.join_paths("base/", "child") != "base/child" { return 2; }
  if io.join_paths("", "child") != "child" { return 3; }
  if io.join_paths("base", "") != "base" { return 4; }
  if io.join_paths("", "") != "" { return 5; }
  // Backslash is a separator too (Windows-style callers).
  if io.join_paths("base\\dir", "child") != "base\\dir/child" { return 20; }
  if io.join_paths("base\\dir\\", "child") != "base\\dir\\child" { return 21; }

  // normalize_path is lexical: separators, dot segments, roots.
  if io.normalize_path("a\\b/../c") != "a/c" { return 22; }
  if io.normalize_path("C:\\foo\\..\\bar") != "C:/bar" { return 23; }
  if io.normalize_path("//server\\share\\x") != "//server/share/x" { return 24; }
  if io.normalize_path("/a/./b//") != "/a/b" { return 25; }
  if io.normalize_path("") != "." { return 26; }

  if io.is_absolute("/usr/bin") != true { return 6; }
  if io.is_absolute("relative") != false { return 7; }
  if io.is_absolute("") != false { return 8; }

  match io.parent_path("/usr/bin/xiom") {
    Some(p) => { if p != "/usr/bin" { return 9; } },
    None => { return 10; },
  };
  match io.parent_path("noparent") {
    Some(_) => { return 11; },
    None => {},
  };

  match io.file_name("/usr/bin/xiom") {
    Some(n) => { if n != "xiom" { return 12; } },
    None => { return 13; },
  };

  match io.extension("file.xi") {
    Some(e) => { if e != "xi" { return 14; } },
    None => { return 15; },
  };
  match io.extension("noext") {
    Some(_) => { return 16; },
    None => {},
  };

  return 0;
}
