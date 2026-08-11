// XIOM - SIMD: Masks
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.simd.mask

// Depends on: none

// ============================================================================
// Bit-packed SIMD comparison masks with per-lane access, counting, logic and
// vector conversion. NOTE: current implementation lives in simd.xi - move the
// functions here during the implementation phase. TODO(compiler): implement.
// ============================================================================

// type Mask - a SIMD comparison mask holding one bit per lane.
// fn mask_new(bits: Int) -> Mask - build a mask from an integer bit pattern. TODO(compiler): implement.
// fn mask_get(m, i) -> Bool - read lane i of a mask. TODO(compiler): implement.
// fn mask_set(m, i, on: Bool) - set lane i of a mask and return it. TODO(compiler): implement.
// fn mask_count(m) -> Int - the number of set lanes. TODO(compiler): implement.
// fn mask_all(m) -> Bool - whether every lane is set. TODO(compiler): implement.
// fn mask_any(m) -> Bool - whether any lane is set. TODO(compiler): implement.
// fn mask_and(a, b) -> Mask - lane-wise logical AND. TODO(compiler): implement.
// fn mask_or(a, b) -> Mask - lane-wise logical OR. TODO(compiler): implement.
// fn mask_xor(a, b) -> Mask - lane-wise logical XOR. TODO(compiler): implement.
// fn mask_not(m) -> Mask - lane-wise logical NOT. TODO(compiler): implement.
// fn mask_to_bits(m) -> Int - the integer bit pattern of a mask. TODO(compiler): implement.
// fn mask_from_bits(bits: Int) -> Mask - build a mask from an integer bit pattern. TODO(compiler): implement.
// fn mask_from_vec(v: &Vec[Bool]) -> Mask - build a mask from a boolean vector. TODO(compiler): implement.
// fn mask_to_vec(m) -> Vec[Bool] - expand a mask to a boolean vector. TODO(compiler): implement.
