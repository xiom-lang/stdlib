// XIOM - Conversion: Bytes
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.convert.bytes

// Depends on: none

// ============================================================================
// Byte-vector helpers: integer <-> big-endian byte round-trips, hex rendering,
// concatenation, and reversal. Hex rendering/parsing delegates to the
// canonical xiom.encoding codec.
// ============================================================================

use xiom.string;
use xiom.encoding;

/// Little-endian byte representation of `n` (8 bytes).
pub fn to_bytes(n: Int) -> Vec[UInt8]
  ensures: result.len() == 8
{
  var result = Vec[UInt8].new();
  var i = 7;
  while i >= 0 {
    var b = (n >> (i * 8)) & 0xFF;
    result.push(b as UInt8);
    i = i - 1;
  };
  result
}

/// TODO(compiler): `from_bytes` collides with a compiler-builtin name. Any
/// call to a module function named `from_bytes` taking a `&Vec[T]` (or Str)
/// parameter produces invalid LLVM IR ("invalid getelementptr indices" on
/// %struct.Vec) -- verified by minimal probe. The real algorithm is kept below
/// (it is correct once the name collision is fixed); callers must avoid it
/// until then.
pub fn from_bytes(bytes: &Vec[UInt8]) -> Int
  ensures: ((bytes.len() == 0 || bytes.len() > 8) => (result == 0))
{
  var len = bytes.len();
  if len == 0 || len > 8 {
    return 0;
  };
  var result: Int = 0;
  var i: Int = 0;
  while i < len {
    var b = bytes[i] as Int;
    b = b & 0xFF;
    result = result * 256 + b;
    i = i + 1;
  };
  result
}

/// Lowercase hex encoding of the bytes.
pub fn bytes_to_hex(bytes: &Vec[UInt8]) -> Str
  ensures: (bytes.len() == 0) => (result.len() == 0)
{
  encoding.hex_encode(bytes)
}

/// Decode hex (either case) to bytes. Requires an even-length string (the
/// canonical decoder's precondition); Err on a bad digit.
pub fn hex_to_bytes(s: Str) -> Result[Vec[UInt8], Str]
  requires: s.len() % 2 == 0
  ensures: (s.len() == 0) => (result.is_ok == true)
{
  encoding.hex_decode(s)
}

/// Concatenation of `a` followed by `b`.
pub fn bytes_concat(a: &Vec[UInt8], b: &Vec[UInt8]) -> Vec[UInt8]
  ensures: result.len() == a.len() + b.len()
{
  var result = Vec[UInt8].new();
  var i: Int = 0;
  while i < a.len() {
    result.push(a[i]);
    i = i + 1;
  };
  var j: Int = 0;
  while j < b.len() {
    result.push(b[j]);
    j = j + 1;
  };
  result
}

/// Copy of the bytes in reverse order.
pub fn bytes_reverse(bytes: &Vec[UInt8]) -> Vec[UInt8]
  ensures: result.len() == bytes.len()
{
  var result = Vec[UInt8].new();
  var i = bytes.len() - 1;
  while i >= 0 {
    result.push(bytes[i]);
    i = i - 1;
  };
  result
}

// ============================================================================
// Wave 166 (2026-10-02 intake row 44; requesters consul (ConsulSpan), puppet,
// audio-meta): non-owning byte-span windows over Vec[UInt8] for zero-copy
// parsing. A ByteSpan is a plain (start, len) handle the caller pairs with
// the vector; nothing is copied until *_to_vec / *_to_str / *_copy_into.
// Validated windows come from bytes_span_checked; the accessors clamp into
// the span/vector, bytes_span_to_str is the strict materializer.
// ============================================================================

/// struct ByteSpan { start: Int; len: Int } -- a window over a Vec[UInt8].
pub type ByteSpan = { start: Int; len: Int; }

/// Raw constructor: negative inputs clamp to 0; no end validation (the
/// vector is not known here) -- prefer bytes_span_checked for user data.
pub fn bytes_span_new(start: Int, len: Int) -> ByteSpan
  ensures: result.start >= 0
  ensures: result.len >= 0
{
  var s = start;
  var l = len;
  if s < 0 {
    s = 0;
  };
  if l < 0 {
    l = 0;
  };
  ByteSpan{ start: s; len: l }
}

/// Strict window over a vector of `n` bytes: Some only when
/// 0 <= start <= n, 0 <= len and start + len <= n -- otherwise None.
pub fn bytes_span_checked(n: Int, start: Int, len: Int) -> Option[ByteSpan]
  ensures: true
{
  if n < 0 || start < 0 || len < 0 {
    return None;
  };
  if start > n || start + len > n {
    return None;
  };
  Some(ByteSpan{ start: start; len: len })
}

/// Number of bytes in the span.
pub fn bytes_span_len(sp: &ByteSpan) -> Int
  ensures: result >= 0
{
  sp.len
}

/// True when the span has zero bytes.
pub fn bytes_span_is_empty(sp: &ByteSpan) -> Bool
  ensures: true
{
  sp.len == 0
}

/// Sub-window relative to `sp`, clamped into it (view_slice convention).
pub fn bytes_span_slice(sp: &ByteSpan, start: Int, len: Int) -> ByteSpan
  ensures: result.len >= 0
{
  var s = start;
  var l = len;
  if s < 0 {
    s = 0;
  };
  if l < 0 {
    l = 0;
  };
  if s > sp.len {
    s = sp.len;
  };
  if s + l > sp.len {
    l = sp.len - s;
  };
  ByteSpan{ start: sp.start + s; len: l }
}

/// Byte at offset `i` within the span, or 0 when out of the span or out of
/// the vector (string.byte_at convention). Complexity: O(1).
pub fn bytes_span_get(data: &Vec[UInt8], sp: &ByteSpan, i: Int) -> UInt8
  ensures: true
{
  if i < 0 || i >= sp.len {
    return 0u8;
  };
  let at = sp.start + i;
  if at < 0 || at >= data.len() {
    return 0u8;
  };
  data[at]
}

/// Copy of the window's bytes; the copy clamps to the vector's end.
pub fn bytes_span_to_vec(data: &Vec[UInt8], sp: &ByteSpan) -> Vec[UInt8]
  ensures: result.len() <= sp.len
{
  var out: Vec[UInt8] = Vec[UInt8].new();
  var i = 0;
  while i < sp.len && sp.start + i < data.len() {
    out.push(data[sp.start + i]);
    i = i + 1;
  };
  out
}

/// Append the window's bytes to `out` (clamped to the vector's end).
pub fn bytes_span_copy_into(data: &Vec[UInt8], sp: &ByteSpan, out: &mut Vec[UInt8])
  ensures: true
{
  var i = 0;
  while i < sp.len && sp.start + i < data.len() {
    out.push(data[sp.start + i]);
    i = i + 1;
  };
}

/// Byte-wise equality of two windows (possibly over different vectors):
/// length first, then bytes. Complexity: O(min lengths).
pub fn bytes_span_eq(a: &Vec[UInt8], sa: &ByteSpan, b: &Vec[UInt8], sb: &ByteSpan) -> Bool
  ensures: true
{
  if sa.len != sb.len {
    return false;
  };
  var i = 0;
  while i < sa.len {
    if bytes_span_get(a, sa, i) != bytes_span_get(b, sb, i) {
      return false;
    };
    i = i + 1;
  };
  true
}

/// True when the window starts with the bytes of `prefix` (an empty prefix
/// always matches). Complexity: O(|prefix|).
pub fn bytes_span_starts_with(data: &Vec[UInt8], sp: &ByteSpan, prefix: &Vec[UInt8]) -> Bool
  ensures: true
{
  let plen = prefix.len();
  if plen > sp.len {
    return false;
  };
  var i = 0;
  while i < plen {
    if bytes_span_get(data, sp, i) != prefix[i] {
      return false;
    };
    i = i + 1;
  };
  true
}

/// Offset (relative to the span start) of the first `byte` in the window, or
/// None. `byte` is masked to 8 bits. Complexity: O(span length).
pub fn bytes_span_find_byte(data: &Vec[UInt8], sp: &ByteSpan, byte: Int) -> Option[Int]
  ensures: true
{
  let target = (byte & 0xFF) as UInt8;
  var i = 0;
  while i < sp.len {
    if bytes_span_get(data, sp, i) == target {
      return Some(i);
    };
    i = i + 1;
  };
  None
}

/// NUL-free Str from the window: Err when the span does not lie fully inside
/// the vector ("byte span out of bounds") or when any byte is 0x00 (a Str is
/// NUL-terminated and cannot represent it); otherwise one runtime copy
/// through Str::from_utf8. UTF-8 validity is the caller's concern (same
/// policy as base32_decode_str). Complexity: O(window length).
pub fn bytes_span_to_str(data: &Vec[UInt8], sp: &ByteSpan) -> Result[Str, Str]
  ensures: true
{
  if sp.start < 0 || sp.len < 0 || sp.start + sp.len > data.len() {
    return Err("byte span out of bounds");
  };
  var out: Vec[UInt8] = Vec[UInt8].new();
  var i = 0;
  while i < sp.len {
    let b = data[sp.start + i];
    if b == 0 {
      return Err("byte span contains NUL");
    };
    out.push(b);
    i = i + 1;
  };
  Ok(Str::from_utf8(out))
}
