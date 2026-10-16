// p_foreign_method_call.xi -- known-failure repro (compiler v0.64.0)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Method-style call of a foreign module function whose first parameter is a
// struct by value resolves to a nonexistent symbol: `v.json_get_path(&path)`
// on a `xiom.serialize.json.JsonValue` produces C001 "unresolved function
// symbol(s) ... 'JsonValue.json_get_path'" (the qualified call
// `json.json_get_path(v, &path)` works). Found while landing the wave-89
// serialize.json clauses in tools/probes/p_wave89_shapes.xi; the same class
// of alias/shadowing resolution trap is C-PULSE-12 (PULSE, 2026-10-08).
//
// Expected when fixed: rc 0. Currently: codegen error C001.

module p_foreign_method_call

use xiom.serialize.json as sjson;

fn main() -> Int {
  let v = sjson.json_null();
  let path = Vec[Str].new();
  let g = v.json_get_path(&path);
  if g.is_none { return 1; }
  return 0;
}
