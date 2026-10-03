// p_struct_literal_field_order.xi -- out-of-declaration-order struct literals
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Open finding 2026-10-02 (compiler v0.61.3 and v0.62.1): a struct literal
// written with its fields in a different order than the type declaration
// compiles silently and stores each supplied value POSITIONALLY (codegen
// walks the supplied list and writes slot i), so the value lands in the
// wrong field. Expected: p.x == 1.0, p.y == 2.0, p.z == 3.0.
// Observed on both pins: p.x == 3.0, p.y == 2.0, p.z == 1.0 (the literal
// below supplies z first, then y, then x). The checker accepts the literal
// without a diagnostic; only the declaration-order spelling is safe.
// Found while landing the wave-54 geom clauses: xiom.geom.quat_from_euler
// returned Quaternion{ w; x; y; z; } (declaration order x; y; z; w), so
// every Euler-derived rotation was scrambled. The stdlib was reordered in
// wave 54; this file locks the compiler-side behavior for the compiler lane.
// Returns 1 (wrong fields) while the finding is open.

module p_regress_struct_literal_order

pub type P = { x: Float64; y: Float64; z: Float64; }

pub fn mk_reordered() -> P {
  return P{ z: 3.0; y: 2.0; x: 1.0; };
}

fn main() -> Int {
  var p = mk_reordered();
  if !(p.x == 1.0 && p.y == 2.0 && p.z == 3.0) { return 1; }
  return 0;
}
