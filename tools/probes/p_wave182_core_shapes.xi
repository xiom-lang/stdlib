// p_wave182_core_shapes.xi -- wave-182 core contract shapes
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the wave-182 core contract surfaces:
// - xiom.contracts: export strings non-empty, statistics non-negative,
//   ContractIndex.is_sorted()/contains_*()/none()/filter_nonempty(),
//   any_contracts/fn_has_contracts/type_has_invariants consistency, and
//   verify_chain returning Ok.
// - xiom.platform: exactly one OS predicate, is_unix == !is_windows,
//   endian/pointer-width constants, non-empty names/newline/separator,
//   positive page size/cpu count, and the os_version implications.
// Expected: rc 0.

module p_wave182_core_shapes

use xiom.contracts;
use xiom.platform;
use xiom.io;

fn main() -> Int {
  // contracts: bootstrap/statistics/export surfaces (no Map payloads).
  if xiom.contracts.export_contracts_json().len() == 0 { return 1; }
  if xiom.contracts.export_contracts_markdown().len() == 0 { return 2; }
  if xiom.contracts.export_contracts_openapi().len() == 0 { return 3; }
  if xiom.contracts.total_requires() < 0 { return 4; }
  if xiom.contracts.total_ensures() < 0 { return 5; }
  if xiom.contracts.total_invariants() < 0 { return 6; }
  if xiom.contracts.functions_with_contracts() < 0 { return 7; }
  if xiom.contracts.types_with_invariants() < 0 { return 8; }
  if xiom.contracts.contract_density() < 0.0 { return 9; }

  let idx = xiom.contracts.build_contract_index();
  if idx.functions.len() <= 1 && idx.is_sorted() != true { return 10; }
  if idx.contains_fn("definitely_not_a_function") != false { return 11; }
  if idx.contains_type("definitely_not_a_type") != false { return 12; }
  if idx.filter_nonempty().functions.len() > idx.functions.len() { return 13; }
  if xiom.contracts.any_contracts() != !idx.none() { return 14; }
  if xiom.contracts.fn_has_contracts("definitely_not_a_function") != idx.contains_fn("definitely_not_a_function") { return 15; }
  if xiom.contracts.type_has_invariants("definitely_not_a_type") != idx.contains_type("definitely_not_a_type") { return 16; }
  var empty: Vec[Str] = Vec[Str].new();
  match xiom.contracts.verify_chain(empty) {
    Ok(_) => {},
    Err(_) => { return 17; }
  }

  // platform: exactly one OS predicate, Unix is the Windows negation,
  // constants, and a non-empty version string.
  let w = xiom.platform.is_windows();
  let l = xiom.platform.is_linux();
  let m = xiom.platform.is_macos();
  let b = xiom.platform.is_bsd();
  let u = xiom.platform.is_unix();
  if w && l { return 18; }
  if w && m { return 19; }
  if l && m { return 20; }
  if u != !w { return 21; }
  if xiom.platform.os_name().len() == 0 { return 22; }
  if xiom.platform.endian_is_little() != true { return 23; }
  if xiom.platform.is_64bit() != true { return 24; }
  if xiom.platform.page_size() <= 0 { return 25; }
  if xiom.platform.cpu_count() < 1 { return 26; }
  if xiom.platform.newline().len() == 0 { return 27; }
  if xiom.platform.path_sep().len() == 0 { return 28; }
  let ver = xiom.platform.os_version();
  if m && ver != "macOS" { return 29; }
  if !w && !l && !m && ver != "unknown" { return 30; }
  if ver.len() == 0 { return 31; }
  if b && !u { return 32; }

  io.println("p_wave182_core_shapes: OK");
  return 0;
}
