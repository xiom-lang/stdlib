// XIOM - Conversion: Base32
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.convert.base32

// Depends on: xiom.encoding.base32

// ============================================================================
// DEPRECATED (dedup wave, 2026-09-15): thin delegating shim over
// xiom.encoding.base32 (canonical: RFC 4648 base32 + base32hex + str
// wrappers). Import xiom.encoding.base32 for new code. The 4-fn legacy
// surface is preserved for compatibility.
//
// Same-leaf + same-name delegation is safe since the R20 fix (a2a456c4,
// m75 lock); the `enc32` alias avoids the R9 leaf-shadowing hazard.
// ============================================================================

use xiom.encoding.base32 as enc32;

/// Encodes bytes as a base32 string (RFC 4648 alphabet A-Z, 2-7), padded
/// with '=' to a multiple of 8 characters. Complexity: O(n).
pub fn base32_encode(data: &Vec[UInt8]) -> Str {
  return enc32.base32_encode(data);
}

/// Decodes a base32 string to bytes. Returns Err on invalid input.
pub fn base32_decode(s: Str) -> Result[Vec[UInt8], Str] {
  return enc32.base32_decode(s);
}

/// Encodes bytes as a base32hex string (RFC 4648 S7, alphabet 0-9, A-V),
/// padded with '='. Complexity: O(n).
pub fn base32hex_encode(data: &Vec[UInt8]) -> Str {
  return enc32.base32hex_encode(data);
}

/// Decodes a base32hex string to bytes. Returns Err on invalid input.
pub fn base32hex_decode(s: Str) -> Result[Vec[UInt8], Str] {
  return enc32.base32hex_decode(s);
}
