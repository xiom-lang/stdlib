// XIOM - Conversion: Swap
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.convert.swap

// Depends on: none

// ============================================================================
// Fixed-width byte swapping. Each function delegates to the canonical
// xiom.bits.byte_swapN implementation (different function names, so
// delegation is safe from the same-name miscompile).
// ============================================================================

use xiom.bits;

/// Swaps the two bytes of a 16-bit value stored in the low 16 bits of an Int.
/// Complexity: O(1).
pub fn swap16(n: Int) -> Int {
  bits.byte_swap16(n)
}

/// Swaps the four bytes of a 32-bit value stored in the low 32 bits of an Int.
/// Complexity: O(1).
pub fn swap32(n: Int) -> Int {
  bits.byte_swap32(n)
}

/// Swaps the eight bytes of a 64-bit value.
/// Complexity: O(1).
pub fn swap64(n: Int) -> Int {
  bits.byte_swap64(n)
}
