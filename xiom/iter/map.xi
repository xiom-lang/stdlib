// XIOM - Iterator: Map
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.iter.map

// Depends on: none

// ============================================================================
// Transform adapters: map, flat_map, filter_map, enumerate, zip.
// Function parameters must be passed as NAMED functions (inline lambdas
// crash the runtime - see docs/STDLIB_GENERICS.md). Implemented as concrete
// Int specializations of the frozen generic API (compiler fn-ptr codegen bug).
// ============================================================================

/// Apply f to every element of v, producing a new vector. O(n).
pub fn iter_map(v: &Vec[Int], f: fn(&Int) -> Int) -> Vec[Int] {
  var out = Vec[Int].new();
  var i = 0;
  while i < v.len() {
    var x = v[i];
    out.push(f(&x));
    i = i + 1;
  }
  out
}

/// Apply f to every element, then concatenate the result vectors. O(n + m).
pub fn iter_flat_map(v: &Vec[Int], f: fn(&Int) -> Vec[Int]) -> Vec[Int] {
  var out = Vec[Int].new();
  var i = 0;
  while i < v.len() {
    var x = v[i];
    var inner = f(&x);
    var j = 0;
    while j < inner.len() {
      out.push(inner[j]);
      j = j + 1;
    }
    i = i + 1;
  }
  out
}

/// Keep and unwrap elements where f returns Some. O(n).
pub fn iter_filter_map(v: &Vec[Int], f: fn(&Int) -> Option[Int]) -> Vec[Int] {
  var out = Vec[Int].new();
  var i = 0;
  while i < v.len() {
    var x = v[i];
    var r = f(&x);
    match r {
      Some(val) => { out.push(val); },
      None => {},
    }
    i = i + 1;
  }
  out
}

/// (index, value) tuple for each element of v. O(n). Returns Vec[(Int, Int)].
pub fn iter_enumerate(v: &Vec[Int]) -> Vec[(Int, Int)] {
  var out = Vec[(Int, Int)].new();
  var i = 0;
  while i < v.len() {
    out.push((i, v[i]));
    i = i + 1;
  }
  out
}

/// (a[i], b[i]) pairs, truncated to the shorter input. O(min(len)).
/// Returns Vec[(Int, Int)].
pub fn iter_zip(a: &Vec[Int], b: &Vec[Int]) -> Vec[(Int, Int)] {
  var out = Vec[(Int, Int)].new();
  var n = a.len();
  if b.len() < n { n = b.len(); }
  var i = 0;
  while i < n {
    out.push((a[i], b[i]));
    i = i + 1;
  }
  out
}
