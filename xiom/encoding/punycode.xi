// XIOM - Encoding: Punycode
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.encoding.punycode

// Depends on: xiom.string

// ============================================================================
// RFC-3492 Punycode for hostname labels and full domains. Implements the
// standard generalized variable-length integer encoding: basic code points
// pass through, a delimiter is inserted, then each non-basic code point is
// encoded as a delta stream with adaptive bias.
// ============================================================================

use xiom.string;

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
  fn free(ptr: *UInt8);
  fn xiom_char_at(s: Str, pos: Int) -> Char;
}

const _BASE: Int = 36;
const _TMIN: Int = 1;
const _TMAX: Int = 26;
const _SKEW: Int = 38;
const _DAMP: Int = 700;
const _INITIAL_BIAS: Int = 72;
const _INITIAL_N: Int = 128;

/// True iff `cp` is a valid Unicode scalar value (no surrogates, <= 0x10FFFF).
fn _cp_valid(cp: Int) -> Bool {
  if cp < 0 || cp > 1114111 { return false; }
  if cp >= 55296 && cp <= 57343 { return false; }
  true
}

/// Appends the UTF-8 bytes of `cp` to `out`.
fn _push_cp(out: &mut Vec[UInt8], cp: Int) {
  var tmp = Vec[UInt8].new();
  xiom.char.encode_utf8(to_char(cp), &mut tmp);
  var i = 0;
  while i < tmp.len() {
    out.push(tmp[i]);
    i = i + 1;
  };
}

/// Builds a Str from UTF-8 bytes.
fn _vec_to_str(bytes: &Vec[UInt8]) -> Str {
  var len = bytes.len();
  if len == 0 {
    return "";
  };
  unsafe {
    var buf = malloc(len + 1);
    var i = 0;
    while i < len {
      buf[i] = bytes[i];
      i = i + 1;
    };
    buf[len] = 0;
    return Str.from_cstring(buf);
  }
}

/// Collects the code points of `s` (validated), decoding UTF-8 manually via
/// byte access (the Str.char_at method is byte-based and cannot be used for
/// code points).
fn _str_to_cps(s: Str) -> Result[Vec[Int], Str] {
  var cps = Vec[Int].new();
  var len = s.len();
  var i = 0;
  while i < len {
    var b0 = (string.byte_at(s, i) as Int) & 0xFF;
    if b0 < 0x80 {
      cps.push(b0);
      i = i + 1;
    } elif b0 >= 0xC0 && b0 <= 0xDF {
      if i + 1 >= len {
        return Err("punycode: truncated utf-8");
      };
      var b1 = (string.byte_at(s, i + 1) as Int) & 0xFF;
      var cp = ((b0 & 0x1F) << 6) | (b1 & 0x3F);
      if !_cp_valid(cp) {
        return Err("punycode: invalid code point");
      };
      cps.push(cp);
      i = i + 2;
    } elif b0 >= 0xE0 && b0 <= 0xEF {
      if i + 2 >= len {
        return Err("punycode: truncated utf-8");
      };
      var b1 = (string.byte_at(s, i + 1) as Int) & 0xFF;
      var b2 = (string.byte_at(s, i + 2) as Int) & 0xFF;
      var cp = ((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F);
      if !_cp_valid(cp) {
        return Err("punycode: invalid code point");
      };
      cps.push(cp);
      i = i + 3;
    } elif b0 >= 0xF0 && b0 <= 0xF7 {
      if i + 3 >= len {
        return Err("punycode: truncated utf-8");
      };
      var b1 = (string.byte_at(s, i + 1) as Int) & 0xFF;
      var b2 = (string.byte_at(s, i + 2) as Int) & 0xFF;
      var b3 = (string.byte_at(s, i + 3) as Int) & 0xFF;
      var cp = ((b0 & 0x07) << 18) | ((b1 & 0x3F) << 12) | ((b2 & 0x3F) << 6) | (b3 & 0x3F);
      if !_cp_valid(cp) {
        return Err("punycode: invalid code point");
      };
      cps.push(cp);
      i = i + 4;
    } else {
      return Err("punycode: invalid utf-8 byte");
    };
  };
  Ok(cps)
}

/// The RFC-3492 bias adaptation function. Maps a delta to a new bias value.
/// Complexity: O(log delta).
pub fn punycode_adapt(delta: Int, numpoints: Int, firsttime: Bool) -> Int {
  var d = delta;
  if firsttime {
    d = d / _DAMP;
  } else {
    d = d / 2;
  };
  d = d + d / numpoints;
  var k = 0;
  while d > 455 {
    d = d / 35;
    k = k + _BASE;
  };
  k + (36 * d) / (d + _SKEW)
}

/// Maps a 0-35 value to its Punycode digit character (a-z, then 0-9).
/// Returns '\0' for a value outside 0..35. Complexity: O(1).
pub fn punycode_encode_digit(d: Int) -> Char {
  if d >= 0 && d <= 25 {
    return to_char(97 + d);
  };
  if d >= 26 && d <= 35 {
    return to_char(48 + (d - 26));
  };
  '\0'
}

/// Maps a Punycode digit character back to a 0-35 value; -1 for invalid.
/// Complexity: O(1).
pub fn punycode_decode_digit(c: Char) -> Int {
  var code = c as Int;
  if code >= 48 && code <= 57 { return code - 48 + 26; }
  if code >= 97 && code <= 122 { return code - 97; }
  if code >= 65 && code <= 90 { return code - 65; }
  -1
}

/// Encodes a single Unicode label to Punycode (RFC 3492 section 6.3).
/// Returns Err on an invalid code point or an arithmetic overflow.
/// Complexity: O(n^2), n = label length in code points.
pub fn punycode_encode(s: Str) -> Result[Str, Str] {
  var cps = _str_to_cps(s);
  match cps {
    Err(e) => { return Err(e); },
    Ok(cp_list) => { return _punycode_encode_cps(cp_list); },
  };
}

fn _punycode_encode_cps(cp_list: Vec[Int]) -> Result[Str, Str] {
  var out = Vec[UInt8].new();
  var b = 0;
  var n = 0;
  while n < cp_list.len() {
    if cp_list[n] < 0x80 {
      _push_cp(&mut out, cp_list[n]);
      b = b + 1;
    };
    n = n + 1;
  };
  var h = b;
  if b > 0 {
    _push_cp(&mut out, 45);
  };
  var delta = 0;
  var bias = _INITIAL_BIAS;
  var np = _INITIAL_N;
  while h < cp_list.len() {
    var m = 0x7FFFFFFF;
    n = 0;
    while n < cp_list.len() {
      if cp_list[n] >= np && cp_list[n] < m {
        m = cp_list[n];
      };
      n = n + 1;
    };
    var term = (m - np) * (h + 1);
    if term > 0x7FFFFFFF - delta {
      return Err("punycode overflow");
    };
    delta = delta + term;
    np = m;
    n = 0;
    while n < cp_list.len() {
      if cp_list[n] < np {
        delta = delta + 1;
      };
      if cp_list[n] == np {
        var q = delta;
        var k = _BASE;
        loop {
          var t = _tm(k, bias);
          if q < t {
            break;
          };
          var digit = t + (q - t) % (_BASE - t);
        var ch = punycode_encode_digit(digit);
        _push_cp(&mut out, ch as Int);
          q = (q - t) / (_BASE - t);
          k = k + _BASE;
        };
        var last_ch = punycode_encode_digit(q);
        _push_cp(&mut out, last_ch as Int);
        bias = punycode_adapt(delta, h + 1, h == b);
        delta = 0;
        h = h + 1;
      };
      n = n + 1;
    };
    delta = delta + 1;
    np = np + 1;
  };
  Ok(_vec_to_str(&out))
}

/// Threshold selector: t = tmin if k <= bias, tmax if k >= bias + tmax,
/// otherwise k - bias.
fn _tm(k: Int, bias: Int) -> Int {
  if k <= bias {
    return _TMIN;
  };
  if k >= bias + _TMAX {
    return _TMAX;
  };
  k - bias
}

/// Decodes a Punycode label to Unicode (RFC 3492 section 6.2).
/// Returns Err on an invalid digit, a truncated sequence, an overflow, a
/// basic decoded code point, or an invalid code point.
/// Complexity: O(n^2), n = encoded length.
pub fn punycode_decode(s: Str) -> Result[Str, Str] {
  var cps = Vec[Int].new();
  var len = s.len();
  var sep = -1;
  var n = 0;
  while n < len {
    var b = (string.byte_at(s, n) as Int) & 0xFF;
    if b == 45 {
      sep = n;
    };
    n = n + 1;
  };
  if sep >= 0 {
    n = 0;
    while n < sep {
      var b = (string.byte_at(s, n) as Int) & 0xFF;
      if b >= 0x80 {
        return Err("punycode: non-basic code point before delimiter");
      };
      cps.push(b);
      n = n + 1;
    };
  };
  var np = _INITIAL_N;
  var i = 0;
  var bias = _INITIAL_BIAS;
  var idx = sep + 1;
  while idx < len {
    var oldi = i;
    var w = 1;
    var k = _BASE;
    loop {
      if idx >= len {
        return Err("punycode: truncated encoded sequence");
      };
      var b = (string.byte_at(s, idx) as Int) & 0xFF;
      var digit = punycode_decode_digit(to_char(b));
      if digit < 0 {
        return Err("punycode: invalid digit");
      };
      idx = idx + 1;
      var add = digit * w;
      if add > 0x7FFFFFFF - i {
        return Err("punycode overflow");
      };
      i = i + add;
      var t = _tm(k, bias);
      if digit < t {
        break;
      };
      var wmult = _BASE - t;
      if w > 0x7FFFFFFF / wmult {
        return Err("punycode overflow");
      };
      w = w * wmult;
      k = k + _BASE;
    };
    var outlen = cps.len();
    bias = punycode_adapt(i - oldi, outlen + 1, oldi == 0);
    np = np + i / (outlen + 1);
    i = i % (outlen + 1);
    if np < 0x80 {
      return Err("punycode: decoded code point is basic");
    };
    if !_cp_valid(np) {
      return Err("punycode: invalid code point");
    };
    cps.insert(i, np);
    i = i + 1;
  };
  Ok(_cps_to_str(&cps))
}

/// Builds a Str from a code-point vector.
fn _cps_to_str(cps: &Vec[Int]) -> Str {
  var bytes = Vec[UInt8].new();
  var n = 0;
  while n < cps.len() {
    _push_cp(&mut bytes, cps[n]);
    n = n + 1;
  };
  _vec_to_str(&bytes)
}

/// True iff the label needs Punycode encoding (contains a non-ASCII code
/// point). Operates on the source string (byte values >= 0x80).
fn _has_non_ascii(label: Str) -> Bool {
  let len = label.len();
  var n = 0;
  while n < len {
    if ((string.byte_at(label, n) as Int) & 0xFF) >= 0x80 {
      return true;
    };
    n = n + 1;
  };
  false
}

/// Encodes every label of a full domain: ASCII labels pass through unchanged,
/// non-ASCII labels are Punycode-encoded and prefixed with "xn--" (RFC 3490
/// A-label form). Empty labels are preserved. Returns Err on a punycode
/// failure. Complexity: O(sum of label^2).
pub fn punycode_encode_domain(domain: Str) -> Result[Str, Str] {
  var labels = string.str_split(domain, ".");
  var result = "";
  var n = 0;
  while n < labels.len() {
    var label = labels[n];
    if n > 0 {
      result = string.str_concat(result, ".");
    };
    var cps = _str_to_cps(label);
    match cps {
      Err(e) => { return Err(e); },
      Ok(list) => {
        if _has_non_ascii(label) {
          var enc = _punycode_encode_cps(list);
          match enc {
            Err(e) => { return Err(e); },
            Ok(encoded) => {
              result = string.str_concat(result, string.str_concat("xn--", encoded));
            },
          };
        } else {
          result = string.str_concat(result, label);
        };
      },
    };
    n = n + 1;
  };
  Ok(result)
}

/// Decodes every label of an A-label domain: labels starting with "xn--"
/// (case-insensitive) are Punycode-decoded, all others pass through. Empty
/// labels are preserved. Returns Err on a punycode failure.
/// Complexity: O(sum of label^2).
pub fn punycode_decode_domain(domain: Str) -> Result[Str, Str] {
  var labels = string.str_split(domain, ".");
  var result = "";
  var n = 0;
  while n < labels.len() {
    var label = labels[n];
    if n > 0 {
      result = string.str_concat(result, ".");
    };
    var is_alabel = false;
    if string.str_len(label) > 4 {
      var lower = string.str_lower(label);
      if string.str_starts_with(lower, "xn--") {
        is_alabel = true;
      };
    };
    if is_alabel {
      var payload = string.str_slice(label, 4, string.str_len(label));
      var dec = punycode_decode(payload);
      match dec {
        Err(e) => { return Err(e); },
        Ok(decoded) => {
          result = string.str_concat(result, decoded);
        },
      };
    } else {
      result = string.str_concat(result, label);
    };
    n = n + 1;
  };
  Ok(result)
}
