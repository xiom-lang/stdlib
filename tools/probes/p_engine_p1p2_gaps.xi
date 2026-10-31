// p_engine_p1p2_gaps.xi -- engine P1/P2 stdlib gap lock (REL-20261031-1423-engine-2).
// Covers the delivered surface: Vec insert/remove/swap_remove/reserve/truncate +
// the Vec.sort_by method (named comparator), the stderr diagnostics sink, and the
// separator-aware join/normalize helpers. list_dir's dangling-name fix is locked
// separately by p_io_listdir_roundtrip (REL-20261021-0918-pulse).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_engine_p1p2_gaps

use xiom.collections;
use xiom.io;

fn cmp_int(a: &Int, b: &Int) -> Int {
  if *a < *b { return -1; }
  if *a > *b { return 1; }
  return 0;
}

fn main() -> Int {
  // --- Vec mutators -------------------------------------------------------
  var v = Vec[Int].new();
  v.push(3);
  v.push(1);
  v.push(2);

  v.insert(1, 9);
  if v.len() != 4 { return 1; }
  match v.get(1) {
    Some(x) => { if x != 9 { return 2; } },
    None => { return 3; },
  };

  match v.remove(1) {
    Some(x) => { if x != 9 { return 4; } },
    None => { return 5; },
  };
  if v.len() != 3 { return 6; }

  v.reserve(16);
  if v.len() != 3 { return 7; }

  v.sort_by(cmp_int);
  if v[0] != 1 || v[1] != 2 || v[2] != 3 { return 8; }

  // swap_remove replaces the hole with the tail; order is not preserved.
  match v.swap_remove(0) {
    Some(x) => { if x != 1 { return 9; } },
    None => { return 10; },
  };
  if v.len() != 2 { return 11; }
  if v[0] != 3 || v[1] != 2 { return 12; }

  match v.swap_remove(-1) {
    Some(_) => { return 13; },
    None => {},
  };
  match v.swap_remove(99) {
    Some(_) => { return 14; },
    None => {},
  };

  v.truncate(1);
  if v.len() != 1 || v[0] != 3 { return 15; }
  v.truncate(99);
  if v.len() != 1 { return 16; }

  // --- stderr diagnostics sink -------------------------------------------
  // eprintln writes + flushes stderr; flush_stderr is the explicit control.
  io.eprintln("p_engine_p1p2_gaps: stderr sink");
  io.flush_stderr();

  // --- path join / normalize ---------------------------------------------
  if io.join_paths("a\\b", "c") != "a\\b/c" { return 17; }
  if io.join_paths("a\\b\\", "c") != "a\\b\\c" { return 18; }
  if io.join_paths("a\\b", "c\\d") != "a\\b/c\\d" { return 19; }
  if io.join_paths("base", "child") != "base/child" { return 20; }

  if io.normalize_path("a\\b/../c") != "a/c" { return 21; }
  if io.normalize_path("C:\\foo\\..\\bar") != "C:/bar" { return 22; }
  if io.normalize_path("//server\\share\\x") != "//server/share/x" { return 23; }
  if io.normalize_path("/a/./b//") != "/a/b" { return 24; }
  if io.normalize_path("..\\..\\x") != "../../x" { return 25; }
  if io.normalize_path("a/../../b") != "../b" { return 26; }
  if io.normalize_path("") != "." { return 27; }
  if io.normalize_path("../../..") != "../../.." { return 28; }
  if io.normalize_path("/..") != "/" { return 29; }

  return 0;
}
