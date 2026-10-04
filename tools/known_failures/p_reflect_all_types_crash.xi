// p_reflect_all_types_crash.xi -- xiom.reflect.all_types() heap-corrupts
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Open finding (official v0.62.3 and the m187 dev build): calling
// `reflect.all_types()` crashes with 0xC0000374 (STATUS_HEAP_CORRUPTION,
// run rc -1073740940) from any program, including an otherwise-empty one.
// The other RTTI entry points pass (type_count, type_name_by_id,
// type_id_by_name, type_field_count, and type_info_by_name's single-TypeInfo
// return), and a user-module replication of all_types' exact build loop
// (Vec[TypeInfo] of nested Vec fields, 40 iterations) runs green -- so the
// crash is specific to the catalog function's return path, not the shape.
// Found while landing the wave-64 reflect clauses; all_types() is the only
// reflect pub fn that stays clause-free and probe-excluded.
// Expected: rc 0 once fixed; rc -1073740940 while open.
module p_reflect_all_types_crash

use xiom.reflect;

fn main() -> Int {
  let all = reflect.all_types();
  if all.len() < 0 {
    return 2;
  }
  return 0;
}
