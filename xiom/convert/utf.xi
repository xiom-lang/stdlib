// XIOM - Conversion: UTF-16/UTF-32
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.convert.utf

// ============================================================================
// UTF-16 and UTF-32 conversion helpers on top of the core utf8 module.
// Covers code-unit vectors, little/big-endian byte serialization, code point
// arithmetic, and surrogate pair handling.
// ============================================================================

// fn utf16_encode(s: Str) -> Vec[UInt16] - Encode a string to native-order UTF-16 code units. TODO(compiler): implement.
// fn utf16_decode(bytes: &Vec[UInt16]) -> Result[Str, Str] - Decode native-order UTF-16 code units to a string. TODO(compiler): implement.
// fn utf16le_to_bytes(s: Str) -> Vec[UInt8] - Encode a string to little-endian UTF-16 bytes including BOM. TODO(compiler): implement.
// fn utf16be_to_bytes(s: Str) -> Vec[UInt8] - Encode a string to big-endian UTF-16 bytes including BOM. TODO(compiler): implement.
// fn utf16_decode_le(bytes: &Vec[UInt8]) -> Result[Str, Str] - Decode little-endian UTF-16 bytes to a string. TODO(compiler): implement.
// fn utf16_decode_be(bytes: &Vec[UInt8]) -> Result[Str, Str] - Decode big-endian UTF-16 bytes to a string. TODO(compiler): implement.
// fn utf32_encode(s: Str) -> Vec[UInt32] - Encode a string to UTF-32 code points. TODO(compiler): implement.
// fn utf32_decode(code_points: &Vec[UInt32]) -> Result[Str, Str] - Decode UTF-32 code points to a string. TODO(compiler): implement.
// fn utf32le_to_bytes(s: Str) -> Vec[UInt8] - Encode a string to little-endian UTF-32 bytes including BOM. TODO(compiler): implement.
// fn utf32be_to_bytes(s: Str) -> Vec[UInt8] - Encode a string to big-endian UTF-32 bytes including BOM. TODO(compiler): implement.
// fn utf16_is_valid(s: Str) -> Bool - Report whether every code point fits within UTF-16. TODO(compiler): implement.
// fn utf32_is_valid(s: Str) -> Bool - Report whether a string contains no surrogate or invalid code points. TODO(compiler): implement.
// fn code_point_to_utf16(cp: Int) -> (UInt16, UInt16) - Split a code point into a UTF-16 surrogate pair. TODO(compiler): implement.
// fn surrogate_pair_to_code_point(hi: UInt16, lo: UInt16) -> Int - Combine a UTF-16 surrogate pair into a code point. TODO(compiler): implement.
