// XIOM - Bits: Bitfield
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.
// Home: bits.xi - this sublib splits the fixed-width bitfield domain.

module xiom.bits.bitfield

// Depends on: none

// ============================================================================
// Fixed-width bitfield extraction and insertion split from bits.xi. TODO(compiler): implement.
// ============================================================================

// fn bitfield_get(value: Int, offset: Int, width: Int) -> Int - extract width bits at offset as an unsigned value.
// fn bitfield_set(value: Int, offset: Int, width: Int, val: Int) -> Int - insert val into the field at offset.
// fn bitfield_clear(value: Int, offset: Int, width: Int) -> Int - zero the width bits at offset.
// fn bitfield_sign_extend(value: Int, width: Int) -> Int - sign-extend a width-bit value.
// fn bitfield_mask(width: Int) -> Int - mask of width low bits set.
// fn bitfield_extract_u(value: Int, offset: Int, width: Int) -> Int - unsigned field extract, right-justified.
// fn bitfield_insert(base: Int, value: Int, offset: Int, width: Int) -> Int - place value into the field of base.
