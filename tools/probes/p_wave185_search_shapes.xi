// p_wave185_search_shapes.xi -- wave-185 search contract shapes
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the wave-185 xiom.search edge contracts: empty-array rows for
// linear/binary/interpolation/exponential/jump/lower/upper/range, the
// empty-pattern KMP/Rabin-Karp rows, good-suffix length, and the
// ternary-search result range.
// Expected: rc 0.

module p_wave185_search_shapes

use xiom.search;
use xiom.search.boyer;
use xiom.search.kmp;
use xiom.search.linear;
use xiom.search.interpolation;
use xiom.io;

fn is_even(x: &Int) -> Bool {
  *x % 2 == 0
}

fn unimodal(x: Int) -> Int {
  -(x - 5) * (x - 5)
}

fn main() -> Int {
  var empty: Vec[Int] = Vec[Int].new();
  match search.linear_search(&empty, &1) {
    Some(_) => { return 1; }
    None => {}
  }
  match search.binary_search(&empty, &1) {
    Some(_) => { return 2; }
    None => {}
  }
  match search.interpolation_search(&empty, 1) {
    Some(_) => { return 3; }
    None => {}
  }
  match search.exponential_search(&empty, &1) {
    Some(_) => { return 4; }
    None => {}
  }
  match search.jump_search(&empty, &1) {
    Some(_) => { return 5; }
    None => {}
  }
  if search.lower_bound(&empty, &1) != 0 { return 6; }
  if search.upper_bound(&empty, &1) != 0 { return 7; }
  let br = search.binary_search_range(&empty, &1);
  if br.0 != 0 || br.1 != 0 { return 8; }
  match linear.linear_search_by(&empty, is_even) {
    Some(_) => { return 9; }
    None => {}
  }

  if kmp.kmp_contains("", "") { return 10; }
  if kmp.kmp_contains("a", "ab") { return 11; }
  if boyer.boyer_moore_good_suffix("abc").len() != 3 { return 12; }
  if boyer.boyer_moore_good_suffix("").len() != 0 { return 13; }
  if boyer.rabin_karp_hash("") != 0 { return 14; }
  if boyer.rabin_karp_hash("abc") < 0 { return 15; }
  match boyer.rabin_karp_search("abc", "") {
    Some(_) => { return 16; }
    None => {}
  }
  match boyer.rabin_karp_search("a", "ab") {
    Some(_) => { return 17; }
    None => {}
  }
  let ts = interpolation.ternary_search(unimodal, 0, 10);
  if ts < 0 || ts > 10 { return 18; }

  io.println("p_wave185_search_shapes: OK");
  return 0;
}
