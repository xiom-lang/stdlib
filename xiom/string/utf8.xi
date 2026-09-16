// XIOM -- UTF-8 Codec (byte-level encode/decode/validate)
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Pure algorithm implementations of the UTF-8 encoding scheme (RFC 3629).
// Operates on raw bytes (Vec[UInt8]) and codepoints (Int), not on Str.
// Rejects overlong sequences, surrogates (U+D800-U+DFFF), and out-of-range
// codepoints (> U+10FFFF).
//
// Encoding scheme:
//   U+0000  - U+007F  : 0xxxxxxx
//   U+0080  - U+07FF  : 110xxxxx 10xxxxxx
//   U+0800  - U+FFFF  : 1110xxxx 10xxxxxx 10xxxxxx
//   U+10000 - U+10FFFF: 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx

module xiom.utf8

use xiom.char;
use xiom.core;

// -- Private helpers ----------------------------------------------------------

// Returns true if the byte is a UTF-8 continuation byte (10xxxxxx).
// Complexity: O(1).
fn is_cont(byte: Int) -> Bool {
    (byte & 0xC0) == 0x80
}

// Returns the byte length of a UTF-8 sequence given its leading byte.
// Complexity: O(1).
fn seq_len_from_lead(b0: Int) -> Int {
    if b0 <= 0x7F {
        return 1;
    };
    if (b0 & 0xE0) == 0xC0 {
        return 2;
    };
    if (b0 & 0xF0) == 0xE0 {
        return 3;
    };
    if (b0 & 0xF8) == 0xF0 {
        return 4;
    };
    1
}

// Decode a single UTF-8 sequence starting at data[pos] into a codepoint.
// Returns Ok(codepoint) on success, Err(msg) on invalid data.
// Complexity: O(1).
fn decode_one(data: &Vec[UInt8], pos: Int) -> Result[Int, Str] {
    let len = data.len();
    if pos >= len {
        return Err("utf8_decode_at: position out of bounds");
    };
    let b0 = data[pos] as Int;
    let seq = seq_len_from_lead(b0);
    if pos + seq > len {
        return Err("utf8_decode_at: truncated UTF-8 sequence");
    };
    if seq == 1 {
        // ASCII: 0xxxxxxx
        return Ok(b0);
    };
    if seq == 2 {
        let b1 = data[pos + 1] as Int;
        if !is_cont(b1) {
            return Err("utf8_decode_at: invalid continuation byte in 2-byte sequence");
        };
        let cp = ((b0 & 0x1F) << 6) | (b1 & 0x3F);
        if cp < 0x80 {
            return Err("utf8_decode_at: overlong 2-byte encoding");
        };
        return Ok(cp);
    };
    if seq == 3 {
        let b1 = data[pos + 1] as Int;
        let b2 = data[pos + 2] as Int;
        if !is_cont(b1) || !is_cont(b2) {
            return Err("utf8_decode_at: invalid continuation byte in 3-byte sequence");
        };
        let cp = ((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F);
        if cp < 0x800 {
            return Err("utf8_decode_at: overlong 3-byte encoding");
        };
        if cp >= 0xD800 && cp <= 0xDFFF {
            return Err("utf8_decode_at: surrogate code point in 3-byte sequence");
        };
        return Ok(cp);
    };
    // seq == 4
    let b1 = data[pos + 1] as Int;
    let b2 = data[pos + 2] as Int;
    let b3 = data[pos + 3] as Int;
    if !is_cont(b1) || !is_cont(b2) || !is_cont(b3) {
        return Err("utf8_decode_at: invalid continuation byte in 4-byte sequence");
    };
    let cp = ((b0 & 0x07) << 18) | ((b1 & 0x3F) << 12) | ((b2 & 0x3F) << 6) | (b3 & 0x3F);
    if cp < 0x10000 {
        return Err("utf8_decode_at: overlong 4-byte encoding");
    };
    if cp > 0x10FFFF {
        return Err("utf8_decode_at: code point exceeds Unicode maximum (U+10FFFF)");
    };
    return Ok(cp);
}

// -- Public API ---------------------------------------------------------------

/// Encode a single Unicode codepoint (Int) into 1-4 UTF-8 bytes.
/// Returns a Vec[UInt8] containing exactly the encoded bytes.
/// Rejects codepoints outside the valid Unicode range [0, 0xD7FF] | [0xE000, 0x10FFFF].
/// Complexity: O(1).
pub fn utf8_encode(codepoint: Int) -> Result[Vec[UInt8], Str]
    requires: codepoint >= 0
    ensures:  result is Ok => result.len() >= 1 && result.len() <= 4
{
    if codepoint < 0 || codepoint > 0x10FFFF {
        return Err("utf8_encode: codepoint out of valid Unicode range (0-0x10FFFF)");
    };
    if codepoint >= 0xD800 && codepoint <= 0xDFFF {
        return Err("utf8_encode: surrogate code points are not valid Unicode scalar values");
    };
    var result = Vec[UInt8].new();
    if codepoint <= 0x7F {
        result.push(codepoint as UInt8);
    } elif codepoint <= 0x7FF {
        result.push((0xC0 | (codepoint >> 6)) as UInt8);
        result.push((0x80 | (codepoint & 0x3F)) as UInt8);
    } elif codepoint <= 0xFFFF {
        result.push((0xE0 | (codepoint >> 12)) as UInt8);
        result.push((0x80 | ((codepoint >> 6) & 0x3F)) as UInt8);
        result.push((0x80 | (codepoint & 0x3F)) as UInt8);
    } else {
        result.push((0xF0 | (codepoint >> 18)) as UInt8);
        result.push((0x80 | ((codepoint >> 12) & 0x3F)) as UInt8);
        result.push((0x80 | ((codepoint >> 6) & 0x3F)) as UInt8);
        result.push((0x80 | (codepoint & 0x3F)) as UInt8);
    };
    return Ok(result);
}

/// Decode a single UTF-8 codepoint from a byte slice at the given position.
/// Returns Ok(codepoint) on success, Err(msg) on invalid bytes.
/// Call utf8_seq_len on the first byte to know how many bytes to advance.
/// Complexity: O(1).
pub fn utf8_decode_at(data: &Vec[UInt8], pos: Int) -> Result[Int, Str]
    requires: pos >= 0
    ensures:  result is Ok => result >= 0 && result <= 0x10FFFF
{
    decode_one(data, pos)
}

/// Return the length (1-4) of a UTF-8 sequence given its first byte.
/// Returns 1 for any invalid leading byte (conservative fallback).
/// Complexity: O(1).
pub fn utf8_seq_len(first_byte: Int) -> Int
    ensures: result >= 1 && result <= 4
{
    let b = first_byte & 0xFF;
    if b <= 0x7F { return 1; };
    if (b & 0xE0) == 0xC0 { return 2; };
    if (b & 0xF0) == 0xE0 { return 3; };
    if (b & 0xF8) == 0xF0 { return 4; };
    1
}

/// Validate that a byte slice contains only well-formed UTF-8.
/// Complexity: O(n) where n = data.len().
pub fn utf8_validate(data: &Vec[UInt8]) -> Bool {
    let len = data.len();
    var i: Int = 0;
    while i < len {
        let b0 = data[i] as Int;
        let seq = seq_len_from_lead(b0);
        if seq < 1 || seq > 4 {
            return false;
        };
        if i + seq > len {
            return false;
        };
        if seq == 1 {
            // ASCII -- always valid
        } elif seq == 2 {
            let b1 = data[i + 1] as Int;
            if !is_cont(b1) { return false; };
            let cp = ((b0 & 0x1F) << 6) | (b1 & 0x3F);
            if cp < 0x80 { return false; };
        } elif seq == 3 {
            let b1 = data[i + 1] as Int;
            let b2 = data[i + 2] as Int;
            if !is_cont(b1) || !is_cont(b2) { return false; };
            let cp = ((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F);
            if cp < 0x800 { return false; };
            if cp >= 0xD800 && cp <= 0xDFFF { return false; };
        } else {
            let b1 = data[i + 1] as Int;
            let b2 = data[i + 2] as Int;
            let b3 = data[i + 3] as Int;
            if !is_cont(b1) || !is_cont(b2) || !is_cont(b3) { return false; };
            let cp = ((b0 & 0x07) << 18) | ((b1 & 0x3F) << 12) | ((b2 & 0x3F) << 6) | (b3 & 0x3F);
            if cp < 0x10000 { return false; };
            if cp > 0x10FFFF { return false; };
        };
        i = i + seq;
    };
    true
}

/// Count the number of Unicode codepoints in a UTF-8 byte slice.
/// Complexity: O(n) where n = data.len().
pub fn utf8_codepoint_count(data: &Vec[UInt8]) -> Int
    ensures: result >= 0
{
    let len = data.len();
    var count: Int = 0;
    var i: Int = 0;
    while i < len {
        let b0 = data[i] as Int;
        let seq = seq_len_from_lead(b0);
        i = i + seq;
        count = count + 1;
    };
    count
}

/// Encode a sequence of codepoints into a UTF-8 byte vector.
/// Returns Ok(Vec[UInt8]) on success, Err(msg) if any codepoint is invalid.
/// Complexity: O(n) where n = codepoints.len().
pub fn utf8_encode_str(codepoints: &Vec[Int]) -> Result[Vec[UInt8], Str]
    ensures: codepoints.len() > 0 => result is Ok => result.len() >= codepoints.len()
{
    var result = Vec[UInt8].new();
    let len = codepoints.len();
    var i: Int = 0;
    while i < len {
        let cp = codepoints[i];
        let encoded = utf8_encode(cp);
        match encoded {
            Ok(bytes) => {
                var j: Int = 0;
                while j < bytes.len() {
                    result.push(bytes[j]);
                    j = j + 1;
                };
            };
            Err(msg) => {
                return Err(msg);
            };
        };
        i = i + 1;
    };
    Ok(result)
}

/// Returns true if the byte is a UTF-8 continuation byte (10xxxxxx).
/// Complexity: O(1).
pub fn utf8_is_continuation(byte: Int) -> Bool {
    (byte & 0xC0) == 0x80
}

/// Return the number of UTF-8 bytes needed to encode a codepoint.
/// Complexity: O(1).
pub fn utf8_char_len(cp: Int) -> Int
    ensures: result >= 1 && result <= 4
{
    if cp < 0 { return 1; };
    if cp <= 0x7F { return 1; };
    if cp <= 0x7FF { return 2; };
    if cp <= 0xFFFF { return 3; };
    if cp <= 0x10FFFF { return 4; };
    1
}
