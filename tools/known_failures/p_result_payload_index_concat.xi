// p_result_payload_index_concat.xi -- inline Result.value[i] payload index
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Expected: rc 0 -- both the inline form and the bound form concatenate the
// actual payload element.
// Observed on compiler v0.64.2 (official archive, Windows x64): the inline
// chain `"[" + ld.value[0] + "]"` reads the payload element as raw bits
// (prints a pointer-looking number such as [140697916152657]); the SAME
// element compares equal and the bound form
// (`let v = ld.value; let s = v[0]; ... s ...`) is correct. Found while
// re-triaging PULSE's C-PULSE-17 (io.list_dir "dangling names"): list_dir
// itself is correct on the pin (its from_c_str copy emits xiom_str_len +
// xiom_str_from_vec, m211), the break is the consumer's inline payload
// index in an rvalue context. Workaround: bind the payload (and element)
// before using it. Related family: the catalog payload-read finding.

module p_result_payload_index_concat

use xiom.string;

fn mk_res() -> Result[Vec[Str], Str] {
  var v = Vec[Str].new();
  v.push("aa.txt");
  v.push("bb.txt");
  return Ok(v);
}

fn main() -> Int {
  let ld = mk_res();
  if ld.is_ok != true { return 9; }
  // Control 1: direct comparison of the same inline element is correct.
  if ld.value[0] != "aa.txt" && ld.value[0] != "bb.txt" { return 8; }
  // Case A (bug): inline payload index in a concat rvalue context.
  let shown = "[" + ld.value[0] + "]";
  if !string.str_contains(shown, "aa.txt") && !string.str_contains(shown, "bb.txt") { return 1; }
  // Case B (control, bound form): bind payload + element first.
  let v = ld.value;
  let s = v[0];
  let bound = "[" + s + "]";
  if !string.str_contains(bound, "aa.txt") && !string.str_contains(bound, "bb.txt") { return 2; }
  return 0;
}
