// XIOM - Conversion: Base16
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.convert.base16

// Depends on: xiom.encoding.hex

// ============================================================================
// DEPRECATED (dedup wave, 2026-09-15): thin delegating shim over
// xiom.encoding.hex (canonical: bytes/str/int hex codec, upper + lower).
// Import xiom.encoding.hex for new code. The 4-fn legacy surface is
// preserved for compatibility.
//
// Same-name delegation through the `enc_hex` alias is safe since the R20 fix
// (a2a456c4, m75 lock); the alias avoids the R9 leaf-shadowing hazard.
// ============================================================================

use xiom.encoding.hex as enc_hex;

/// Encodes bytes as a lowercase hexadecimal string (two hex digits per byte).
/// Empty input yields "". Complexity: O(n).
pub fn hex_encode(data: &Vec[UInt8]) -> Str {
  return enc_hex.hex_encode(data);
}

/// Decodes a hexadecimal string back into bytes. Accepts both digit cases.
/// Returns Err on an odd length or an invalid hex character.
pub fn hex_decode(s: Str) -> Result[Vec[UInt8], Str] {
  return enc_hex.hex_decode(s);
}

/// Encodes a string's UTF-8 bytes as a lowercase hex string.
pub fn hex_encode_str(s: Str) -> Str {
  return enc_hex.hex_encode_str(s);
}

/// Decodes a hex string into a UTF-8 string. The decoded bytes are copied
/// verbatim; callers are responsible for UTF-8 validity of their hex input.
/// Returns Err on invalid hex.
pub fn hex_decode_str(s: Str) -> Result[Str, Str] {
  return enc_hex.hex_decode_str(s);
}
