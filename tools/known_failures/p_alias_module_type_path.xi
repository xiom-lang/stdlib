// p_alias_module_type_path.xi -- known-failure repro (compiler v0.64.0)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Alias-qualified TYPE paths do not resolve: with `use xiom.serialize as ser;`
// a struct literal `ser.SerializeError{...}` fails T001 "unknown type
// 'ser.SerializeError'", while the bare name `SerializeError{...}` (types are
// imported unqualified by the alias import) compiles clean. Found while
// landing the wave-89 serialize clauses in tools/probes/p_wave89_shapes.xi.
//
// Expected when fixed: rc 0. Currently: compile error T001.
// Variant B (recorded in the README): the full path
// `xiom.serialize.SerializeError{...}` compiles with a
// "unknown type ... defaulting to i64" warning (silent layout risk).

module p_alias_module_type_path

use xiom.serialize as ser;

fn main() -> Int {
  let e = ser.SerializeError{ kind: 0; message: ""; path: ""; line: 0; col: 0; };
  let s = e.format_error();
  if s.len() < 15 { return 1; }
  return 0;
}
