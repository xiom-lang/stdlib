// XIOM - String: UTF-8 Code Points
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.codepoint

// Depends on: xiom.string

// ============================================================================
// UTF-8 code-point helpers (2026-10-02 intake row 30; requester l10n-unicode:
// "code-point iteration over Str byte offsets + code-point-vector -> Str").
// Strict RFC 3629 decoding: malformed leads, truncated sequences, invalid
// continuation bytes, overlong forms, surrogates (U+D800-U+DFFF) and values
// above U+10FFFF are rejected (None / Err) rather than masked. The cursor
// carries the cached (base, len) view so iteration is one pass; the
// stateless accessors bind c_str() per call. Str representability: a Str is
// NUL-terminated, so U+0000 cannot round-trip through str_from_codepoints
// (rejected explicitly); codepoint_encode into a Vec[UInt8] does allow it.
// ============================================================================

use xiom.string;

// Raw byte at `i` over a cached pointer (T007 confinement; callers bound i).
fn _cp_raw(base: *UInt8, i: Int) -> UInt8
  requires: true
{
  unsafe { return *(base + i); }
}

/// Decoded code point plus its position: `value` is the scalar value,
/// `start` the byte offset in the source, `byte_len` the encoded length
/// (1-4).
pub type CodePoint = { value: Int; start: Int; byte_len: Int; }

/// Iteration cursor: `base`/`len` cache the source view, `pos` is the next
/// byte offset to decode. On malformed input `codepoint_next` returns None
/// and the cursor stays put (use codepoints_valid for a whole-input verdict).
pub type CodePointCursor = { base: *UInt8; len: Int; pos: Int; }

/// True iff `cp` is a Unicode scalar value (0..=U+10FFFF excluding the
/// surrogate range U+D800-U+DFFF). Complexity: O(1).
pub fn codepoint_valid(cp: Int) -> Bool
  ensures: result == ((cp >= 0 && cp <= 0x10FFFF) && !(cp >= 0xD800 && cp <= 0xDFFF))
{
  if cp < 0 || cp > 0x10FFFF {
    return false;
  };
  if cp >= 0xD800 && cp <= 0xDFFF {
    return false;
  };
  true
}

/// Encoded UTF-8 byte length of `cp` (1-4); 0 when `cp` is not a scalar
/// value. Complexity: O(1).
pub fn codepoint_byte_len(cp: Int) -> Int
  ensures: (!codepoint_valid(cp)) => (result == 0)
  ensures: (codepoint_valid(cp) && cp <= 0x7F) => (result == 1)
  ensures: (codepoint_valid(cp) && cp > 0x7F && cp <= 0x7FF) => (result == 2)
  ensures: (codepoint_valid(cp) && cp > 0x7FF && cp <= 0xFFFF) => (result == 3)
  ensures: (codepoint_valid(cp) && cp > 0xFFFF) => (result == 4)
{
  if !codepoint_valid(cp) {
    return 0;
  };
  if cp <= 0x7F {
    return 1;
  };
  if cp <= 0x7FF {
    return 2;
  };
  if cp <= 0xFFFF {
    return 3;
  };
  4
}

// Strict step: byte length of the code point at `pos` within the cached
// (base, len) view, or 0 when the sequence is malformed. `out_value` gets
// the decoded value and `out_len` the byte length on success; both are left
// untouched on failure.
fn _cp_step(base: *UInt8, len: Int, pos: Int, out_value: &mut Int, out_len: &mut Int) -> Bool {
  if pos < 0 || pos >= len {
    return false;
  };
  let b0 = (_cp_raw(base, pos) as Int) & 0xFF;
  var n = 0;
  var cp = 0;
  if b0 <= 0x7F {
    n = 1;
    cp = b0;
  } elif (b0 & 0xE0) == 0xC0 {
    n = 2;
    cp = b0 & 0x1F;
  } elif (b0 & 0xF0) == 0xE0 {
    n = 3;
    cp = b0 & 0x0F;
  } elif (b0 & 0xF8) == 0xF0 {
    n = 4;
    cp = b0 & 0x07;
  } else {
    return false;
  };
  if pos + n > len {
    return false;
  };
  var i = 1;
  while i < n {
    let cb = (_cp_raw(base, pos + i) as Int) & 0xFF;
    if (cb & 0xC0) != 0x80 {
      return false;
    };
    cp = (cp << 6) | (cb & 0x3F);
    i = i + 1;
  };
  if n == 2 && cp < 0x80 {
    return false;
  };
  if n == 3 && cp < 0x800 {
    return false;
  };
  if n == 4 && cp < 0x10000 {
    return false;
  };
  if cp >= 0xD800 && cp <= 0xDFFF {
    return false;
  };
  if cp > 0x10FFFF {
    return false;
  };
  *out_value = cp;
  *out_len = n;
  true
}

/// Strict decode of the code point starting at byte `pos`, or None when the
/// sequence is malformed or truncated. Complexity: O(1) plus the c_str()
/// bind; iterate with a CodePointCursor to avoid the per-call bind.
pub fn codepoint_at(s: Str, pos: Int) -> Option[CodePoint]
  requires: true  // c_str() read confined to the decode (T007)
{
  var value = 0;
  var byte_len = 0;
  if !_cp_step(s.c_str(), s.len(), pos, &mut value, &mut byte_len) {
    return None;
  };
  Some(CodePoint{ value: value; start: pos; byte_len: byte_len; })
}

/// New cursor at byte 0 of `s`. Complexity: O(1).
pub fn codepoint_cursor(s: Str) -> CodePointCursor
  requires: true  // c_str() read confined to the cursor fields (T007)
  ensures: result.len == s.len()
  ensures: result.pos == 0
{
  unsafe {
    return CodePointCursor{ base: s.c_str(), len: s.len(), pos: 0 };
  }
}

/// Next code point; advances the cursor on success. Returns None at the end
/// of the string AND on malformed input (the cursor does not advance on
/// malformed input). Complexity: O(1).
pub fn codepoint_next(c: &mut CodePointCursor) -> Option[CodePoint]
  ensures: (result.is_none) => (c.pos == c.pos@pre)
  ensures: (result.is_some) => (c.pos > c.pos@pre)
  ensures: (result.is_some) => (c.pos <= c.pos@pre + 4)
{
  var value = 0;
  var byte_len = 0;
  if !_cp_step(c.base, c.len, c.pos, &mut value, &mut byte_len) {
    return None;
  };
  let start = c.pos;
  c.pos = start + byte_len;
  Some(CodePoint{ value: value; start: start; byte_len: byte_len; })
}

/// Byte offsets of every code-point start under the strict walk, in source
/// order. Stops at the first malformed sequence (pair with codepoints_valid
/// to distinguish "walked to the end" from "stopped early").
/// Complexity: O(n).
pub fn codepoint_offsets(s: Str) -> Vec[Int]
  ensures: result.len() <= s.len()
  ensures: (s.len() == 0) => (result.len() == 0)
  ensures: (result.len() > 0) => (s.len() > 0)
{
  var result = Vec[Int].new();
  let len = s.len();
  let base = s.c_str();
  var pos = 0;
  while pos < len {
    var value = 0;
    var byte_len = 0;
    if !_cp_step(base, len, pos, &mut value, &mut byte_len) {
      break;
    };
    result.push(pos);
    pos = pos + byte_len;
  };
  result
}

/// True iff the whole string is well-formed UTF-8 (strict walk reaches the
/// end with no malformed sequence). Complexity: O(n).
pub fn codepoints_valid(s: Str) -> Bool
  ensures: (s.len() == 0) => (result == true)
  ensures: (s.len() > 0 && codepoint_at(s, 0).is_none) => (result == false)
{
  let len = s.len();
  let base = s.c_str();
  var pos = 0;
  while pos < len {
    var value = 0;
    var byte_len = 0;
    if !_cp_step(base, len, pos, &mut value, &mut byte_len) {
      return false;
    };
    pos = pos + byte_len;
  };
  true
}

/// Append the UTF-8 encoding of `cp` to `out`; Err when `cp` is not a
/// Unicode scalar value. U+0000 is allowed here (a Vec[UInt8] can carry it).
/// Complexity: O(1).
pub fn codepoint_encode(cp: Int, out: &mut Vec[UInt8]) -> Result[Unit, Str]
  ensures: (!codepoint_valid(cp)) => (result.is_err)
  ensures: (codepoint_valid(cp)) => (result.is_ok)
  ensures: (codepoint_valid(cp)) => (out.len() == out.len()@pre + codepoint_byte_len(cp))
{
  if !codepoint_valid(cp) {
    return Err("invalid code point");
  };
  if cp <= 0x7F {
    out.push(cp as UInt8);
  } elif cp <= 0x7FF {
    out.push((0xC0 | (cp >> 6)) as UInt8);
    out.push((0x80 | (cp & 0x3F)) as UInt8);
  } elif cp <= 0xFFFF {
    out.push((0xE0 | (cp >> 12)) as UInt8);
    out.push((0x80 | ((cp >> 6) & 0x3F)) as UInt8);
    out.push((0x80 | (cp & 0x3F)) as UInt8);
  } else {
    out.push((0xF0 | (cp >> 18)) as UInt8);
    out.push((0x80 | ((cp >> 12) & 0x3F)) as UInt8);
    out.push((0x80 | ((cp >> 6) & 0x3F)) as UInt8);
    out.push((0x80 | (cp & 0x3F)) as UInt8);
  };
  Ok(())
}

/// Build a Str from a code-point vector (the row-30 builder half). Every
/// entry must be a Unicode scalar value; U+0000 is rejected because a Str is
/// NUL-terminated and cannot represent it. Complexity: O(cps.len()).
pub fn str_from_codepoints(cps: &Vec[Int]) -> Result[Str, Str]
  ensures: (cps.len() == 0) => (result.is_ok)
  ensures: (result.is_err) => (cps.len() > 0)
{
  var out: Vec[UInt8] = Vec[UInt8].new();
  let n = cps.len();
  var i = 0;
  while i < n {
    let cp = cps[i];
    if !codepoint_valid(cp) {
      return Err("invalid code point");
    };
    if cp == 0 {
      return Err("NUL code point cannot be represented in Str");
    };
    let enc = codepoint_encode(cp, &mut out);
    if enc.is_err {
      return Err(enc.error);
    };
    i = i + 1;
  };
  Ok(Str::from_utf8(out))
}
