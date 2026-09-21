// XIOM - Conversion: Base64
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.convert.base64

// Depends on: xiom.encoding.base64

// ============================================================================
// DEPRECATED (dedup wave, 2026-09-15): thin delegating shim over
// xiom.encoding.base64 (canonical: standard + url-safe + padded variants).
// Import xiom.encoding.base64 for new code. The 4-fn legacy surface is
// preserved for compatibility.
//
// Same-name delegation through the `enc_b64` alias is safe since the R20 fix
// (a2a456c4, m75 lock); the alias avoids the R9 leaf-shadowing hazard.
// ============================================================================

use xiom.encoding.base64 as enc_b64;

/// Encodes bytes as a standard base64 string with '=' padding.
/// Empty input yields "". Complexity: O(n).
pub fn base64_encode(data: &Vec[UInt8]) -> Str {
  return enc_b64.base64_encode(data);
}

/// Decodes a standard base64 string to bytes. Accepts optional '=' padding.
/// Returns Err on a non-multiple-of-4 length or an invalid character.
pub fn base64_decode(s: Str) -> Result[Vec[UInt8], Str] {
  return enc_b64.base64_decode(s);
}

/// Encodes a string's UTF-8 bytes as standard base64. Complexity: O(n).
pub fn base64_encode_str(s: Str) -> Str {
  return enc_b64.base64_encode_str(s);
}

/// Decodes base64 into a UTF-8 string (bytes copied verbatim; callers are
/// responsible for UTF-8 validity). Returns Err on invalid base64.
pub fn base64_decode_str(s: Str) -> Result[Str, Str] {
  return enc_b64.base64_decode_str(s);
}
