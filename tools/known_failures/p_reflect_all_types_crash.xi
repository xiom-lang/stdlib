// p_reflect_all_types_crash.xi -- REGRESSION LOCK (RESOLVED v0.64.0/m195)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// History: xiom.reflect.all_types() heap-corrupted with 0xC0000374
// (STATUS_HEAP_CORRUPTION, run rc -1073740940) on v0.61.3, v0.62.3, v0.62.4,
// v0.63.0 and the m187+ dev builds. Compiler v0.64.0 m195 keeps
// angle-bracket generic receivers' type args, fixing the catalog return
// path; all_types() now carries `ensures: result.len() == type_count()` and
// this lock exits 0. Found while landing the wave-64 reflect clauses.
// Expected: rc 0.
module p_reflect_all_types_crash

use xiom.reflect;

fn main() -> Int {
  let all = reflect.all_types();
  if all.len() < 0 {
    return 2;
  }
  return 0;
}
