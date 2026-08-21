// XIOM - Conversion: Punycode
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.convert.punycode

// Depends on: xiom.string, xiom.convert

// ============================================================================
// Punycode (RFC 3492) and IDNA (RFC 5891) conversions for internationalized
// domain names. The encode/decode engine implements the RFC 3492 bootstring
// algorithm (base-36 with bias adaptation); code points are collected with a
// byte decoder. Domain helpers split labels at dots; ASCII-only labels pass
// through unchanged.
// ============================================================================

use xiom.string;

const _INITIAL_N: Int = 128;
const _INITIAL_BIAS: Int = 72;
const _BASE: Int = 36;
const _TMIN: Int = 1;
const _TMAX: Int = 26;
const _SKEW: Int = 38;
const _DAMP: Int = 700;

/// Encode a Unicode label to Punycode (with the "xn--" prefix).
/// Parameters: s -- the Unicode label (no dots).
/// Returns: Ok("xn--...") for a label with non-ASCII code points; Ok(s)
///          unchanged when the label is entirely ASCII.
/// Complexity: O(n^2) worst case, O(n) typical.
pub fn punycode_encode(s: Str) -> Result[Str, Str] {
  var cps = _collect_cps(s);
  var n = cps.len();
  if n == 0 {
    return Ok("");
  }
  var has_nonbasic = false;
  var i: Int = 0;
  while i < n {
    if cps[i] >= 0x80 {
      has_nonbasic = true;
    }
    i = i + 1;
  }
  if !has_nonbasic {
    var ascii_out = _cps_to_str(&cps, n);
    return Ok(ascii_out);
  }
  var output = "xn--";
  var basic: Int = 0;
  var k: Int = 0;
  while k < n {
    if cps[k] < 0x80 {
      output = string.str_concat(output, _cp_to_str(cps[k]));
      basic = basic + 1;
    }
    k = k + 1;
  }
  var h = basic;
  if basic > 0 {
    output = string.str_concat(output, "-");
  }
  var cp = _INITIAL_N;
  var delta: Int = 0;
  var bias = _INITIAL_BIAS;
  while h < n {
    var m = 0x110000;
    var j: Int = 0;
    while j < n {
      if cps[j] >= cp && cps[j] < m {
        m = cps[j];
      }
      j = j + 1;
    }
    delta = delta + (m - cp) * (h + 1);
    cp = m;
    var j2: Int = 0;
    while j2 < n {
      if cps[j2] < cp {
        delta = delta + 1;
      }
      if cps[j2] == cp {
        var q = delta;
        var k2 = _BASE;
        loop {
          var t = _bias_t(k2, bias);
          if q < t {
            break;
          }
          output = string.str_concat(output, _encode_digit(t + (q - t) % (_BASE - t)));
          q = (q - t) / (_BASE - t);
          k2 = k2 + _BASE;
        }
        output = string.str_concat(output, _encode_digit(q));
        bias = _adapt(delta, h + 1, h == basic);
        delta = 0;
        h = h + 1;
      }
      j2 = j2 + 1;
    }
    delta = delta + 1;
    cp = cp + 1;
  }
  return Ok(output);
}

/// Decode a Punycode label to Unicode.
/// Parameters: s -- the label; "xn--" prefixed labels are decoded, plain
///          ASCII labels pass through unchanged.
/// Returns: Ok(Unicode label) on success; Err on malformed input.
/// Complexity: O(n^2) worst case.
pub fn punycode_decode(s: Str) -> Result[Str, Str] {
  var len = string.str_len(s);
  if len == 0 {
    return Ok("");
  }
  var prefixed = false;
  if _starts_with(s, "xn--") {
    prefixed = true;
  }
  var encoded = s;
  if prefixed {
    encoded = string.str_slice(s, 4, len);
  } else {
    if _is_ascii_only(s) {
      var ascii_out = _ascii_string(s);
      return Ok(ascii_out);
    }
    return Err("punycode_decode: label lacks the xn-- prefix");
  }
  var output = Vec[Int].new();
  var elen = string.str_len(encoded);
  var last_dash = _last_index_of(encoded, "-");
  var basic_end = elen;
  if last_dash >= 0 {
    basic_end = last_dash;
  }
  var pos: Int = 0;
  while pos < basic_end {
    var b = string.byte_at(encoded, pos);
    var v = b as Int;
    v = v & 0xFF;
    if v >= 0x80 {
      return Err("punycode_decode: non-ASCII in basic section");
    }
    output.push(v);
    pos = pos + 1;
  }
  var data_start = basic_end + 1;
  if last_dash < 0 {
    data_start = 0;
  }
  var cp = _INITIAL_N;
  var i2: Int = 0;
  var bias = _INITIAL_BIAS;
  pos = data_start;
  while pos < elen {
    var oldi = i2;
    var w: Int = 1;
    var k2 = _BASE;
    loop {
      if pos >= elen {
        return Err("punycode_decode: truncated encoded part");
      }
      var digit = _decode_digit(string.byte_at(encoded, pos));
      if digit < 0 {
        return Err("punycode_decode: invalid digit");
      }
      pos = pos + 1;
      i2 = i2 + digit * w;
      var t = _bias_t(k2, bias);
      if digit < t {
        break;
      }
      if w > 1073741823 {
        return Err("punycode_decode: overflow");
      }
      w = w * (_BASE - t);
      k2 = k2 + _BASE;
    }
    var out_len = output.len() + 1;
    bias = _adapt(i2 - oldi, out_len, oldi == 0);
    var ins = i2 % out_len;
    cp = cp + i2 / out_len;
    i2 = ins;
    if cp > 0x10FFFF {
      return Err("punycode_decode: code point exceeds maximum");
    }
    var inserted = Vec[Int].new();
    var idx: Int = 0;
    while idx < i2 {
      inserted.push(output[idx]);
      idx = idx + 1;
    }
    inserted.push(cp);
    while idx < output.len() {
      inserted.push(output[idx]);
      idx = idx + 1;
    }
    output = inserted;
    i2 = i2 + 1;
  }
  var dec_out = _cps_to_str(&output, output.len());
  return Ok(dec_out);
}

/// Encode each label of a full domain to Punycode.
/// Parameters: domain -- a dotted domain (labels separated by '.').
/// Returns: Ok(encoded domain) on success; Err for an empty label.
/// Complexity: O(n) labels x encode cost.
pub fn punycode_encode_domain(domain: Str) -> Result[Str, Str] {
  var labels = _split(domain, ".");
  var result = "";
  var i: Int = 0;
  while i < labels.len() {
    if i > 0 {
      result = string.str_concat(result, ".");
    }
    var enc = punycode_encode(labels[i]);
    if !enc.is_ok {
      return Err(enc.error);
    }
    result = string.str_concat(result, enc.value);
    i = i + 1;
  }
  return Ok(result);
}

/// Decode each label of an A-label domain to Unicode.
/// Parameters: domain -- a dotted domain.
/// Returns: Ok(Unicode domain) on success; Err for a malformed label.
/// Complexity: O(n) labels x decode cost.
pub fn punycode_decode_domain(domain: Str) -> Result[Str, Str] {
  var labels = _split(domain, ".");
  var result = "";
  var i: Int = 0;
  while i < labels.len() {
    if i > 0 {
      result = string.str_concat(result, ".");
    }
    var dec = punycode_decode(labels[i]);
    if !dec.is_ok {
      return Err(dec.error);
    }
    result = string.str_concat(result, dec.value);
    i = i + 1;
  }
  return Ok(result);
}

/// Convert an internationalized domain to its ASCII A-label form.
/// Parameters: s -- the Unicode domain.
/// Returns: Ok(A-label domain) on success; Err for invalid input.
/// Complexity: O(n).
pub fn idna_to_ascii(s: Str) -> Result[Str, Str] {
  var low = _lower(s);
  var enc = punycode_encode_domain(low);
  if !enc.is_ok {
    return Err(enc.error);
  }
  var ascii = enc.value;
  if string.str_len(ascii) > 253 {
    return Err("idna_to_ascii: domain too long");
  }
  return Ok(ascii);
}

/// Convert an ASCII A-label domain to its Unicode U-label form.
/// Parameters: s -- the A-label domain.
/// Returns: Ok(U-label domain) on success; Err for invalid input.
/// Complexity: O(n).
pub fn idna_to_unicode(s: Str) -> Result[Str, Str] {
  var dec = punycode_decode_domain(s);
  if !dec.is_ok {
    return Err(dec.error);
  }
  return Ok(dec.value);
}

/// Report whether a domain conforms to IDNA requirements.
/// Parameters: s -- the candidate domain (A-label or U-label).
/// Returns: true when every label is a valid IDNA label.
/// Complexity: O(n).
pub fn idna_is_valid(s: Str) -> Bool {
  var labels = _split(s, ".");
  var i: Int = 0;
  while i < labels.len() {
    var label = labels[i];
    if string.str_len(label) == 0 {
      return false;
    }
    if _starts_with(label, "xn--") {
      var dec = punycode_decode(label);
      if !dec.is_ok {
        return false;
      }
    } else {
      var j: Int = 0;
      var llen = string.str_len(label);
      while j < llen {
        var b = string.byte_at(label, j);
        var v = b as Int;
        v = v & 0xFF;
        if v >= 0x80 {
          return false;
        }
        if !_idna_char(v) {
          return false;
        }
        j = j + 1;
      }
    }
    i = i + 1;
  }
  return true;
}

/// Apply UTS-46 mapping and normalization to a domain string: case folding
/// (lowercasing) plus IDNA character validation.
/// Parameters: s -- the raw domain.
/// Returns: Ok(normalized) on success; Err when an invalid character remains.
/// Complexity: O(n).
pub fn idna_uts46_normalize(s: Str) -> Result[Str, Str] {
  var low = _lower(s);
  var len = string.str_len(low);
  var i: Int = 0;
  while i < len {
    var b = string.byte_at(low, i);
    var v = b as Int;
    v = v & 0xFF;
    if v < 0x80 && !_idna_char(v) && v != 46 {
      return Err("idna_uts46_normalize: disallowed character");
    }
    i = i + 1;
  }
  return Ok(low);
}

// RFC 3492 bias adaptation.
fn _adapt(delta_in: Int, numpoints: Int, firsttime: Bool) -> Int {
  var delta = delta_in;
  if firsttime {
    delta = delta / _DAMP;
  } else {
    delta = delta / 2;
  }
  delta = delta + delta / numpoints;
  var k: Int = 0;
  while delta > ((_BASE - _TMIN) * _TMAX) / 2 {
    delta = delta / (_BASE - _TMIN);
    k = k + _BASE;
  }
  return k + ((_BASE - _TMIN + 1) * delta) / (delta + _SKEW);
}

// Threshold t for a given loop counter and bias.
fn _bias_t(k: Int, bias: Int) -> Int {
  if k <= bias {
    return _TMIN;
  }
  if k >= bias + _TMAX {
    return _TMAX;
  }
  return k - bias;
}

// Encode a digit 0..35 as 'a'..'z' then '0'..'9'.
fn _encode_digit(d: Int) -> Str {
  var buf = Vec[UInt8].new();
  if d < 26 {
    buf.push((97 + d) as UInt8);
  } else {
    buf.push((48 + d - 26) as UInt8);
  }
  return Str::from_utf8(buf);
}

// Decode a Punycode digit: 'a'..'z'/'A'..'Z' -> 0..25, '0'..'9' -> 26..35.
fn _decode_digit(b: UInt8) -> Int {
  var v = b as Int;
  v = v & 0xFF;
  if v >= 97 && v <= 122 {
    return v - 97;
  }
  if v >= 65 && v <= 90 {
    return v - 65;
  }
  if v >= 48 && v <= 57 {
    return v - 48 + 26;
  }
  return -1;
}

fn _idna_char(v: Int) -> Bool {
  if v >= 97 && v <= 122 {
    return true;
  }
  if v >= 48 && v <= 57 {
    return true;
  }
  if v == 45 {
    return true;
  }
  return false;
}

fn _collect_cps(s: Str) -> Vec[Int] {
  var result = Vec[Int].new();
  var i: Int = 0;
  var len = s.len();
  while i < len {
    var b0 = s.byte_at(i) as Int;
    b0 = b0 & 0xFF;
    if b0 <= 0x7F {
      result.push(b0);
      i = i + 1;
    } elif (b0 & 0xE0) == 0xC0 {
      var b1 = s.byte_at(i + 1) as Int;
      b1 = b1 & 0xFF;
      result.push(((b0 & 0x1F) << 6) | (b1 & 0x3F));
      i = i + 2;
    } elif (b0 & 0xF0) == 0xE0 {
      var b1 = s.byte_at(i + 1) as Int;
      b1 = b1 & 0xFF;
      var b2 = s.byte_at(i + 2) as Int;
      b2 = b2 & 0xFF;
      result.push(((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F));
      i = i + 3;
    } else {
      var b1 = s.byte_at(i + 1) as Int;
      b1 = b1 & 0xFF;
      var b2 = s.byte_at(i + 2) as Int;
      b2 = b2 & 0xFF;
      var b3 = s.byte_at(i + 3) as Int;
      b3 = b3 & 0xFF;
      result.push(((b0 & 0x07) << 18) | ((b1 & 0x3F) << 12) | ((b2 & 0x3F) << 6) | (b3 & 0x3F));
      i = i + 4;
    }
  }
  return result;
}

fn _is_ascii_only(s: Str) -> Bool {
  var i: Int = 0;
  var len = string.str_len(s);
  while i < len {
    var b = string.byte_at(s, i);
    var v = b as Int;
    v = v & 0xFF;
    if v >= 0x80 {
      return false;
    }
    i = i + 1;
  }
  return true;
}

// Fresh copy of an ASCII string (avoids aliasing a function parameter).
fn _ascii_string(s: Str) -> Str {
  var result = "";
  var i: Int = 0;
  var len = string.str_len(s);
  while i < len {
    result = string.str_concat(result, string.str_slice(s, i, i + 1));
    i = i + 1;
  }
  return result;
}

fn _cps_to_str(cps: &Vec[Int], count: Int) -> Str {
  var buf = Vec[UInt8].new();
  var i: Int = 0;
  while i < count {
    _push_utf8(&buf, cps[i]);
    i = i + 1;
  }
  if buf.len() == 0 {
    return "";
  }
  return Str::from_utf8(buf);
}

fn _cp_to_str(cp: Int) -> Str {
  var buf = Vec[UInt8].new();
  _push_utf8(&buf, cp);
  return Str::from_utf8(buf);
}

fn _push_utf8(out: &mut Vec[UInt8], cp: Int) {
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
  }
}

fn _starts_with(s: Str, prefix: Str) -> Bool {
  var plen = string.str_len(prefix);
  if plen > string.str_len(s) {
    return false;
  }
  var sub = string.str_slice(s, 0, plen);
  return sub == prefix;
}

fn _last_index_of(s: Str, needle: Str) -> Int {
  var slen = string.str_len(s);
  var nlen = string.str_len(needle);
  if nlen == 0 {
    return slen;
  }
  if nlen > slen {
    return -1;
  }
  var i = slen - nlen;
  while i >= 0 {
    var sub = string.str_slice(s, i, i + nlen);
    if sub == needle {
      return i;
    }
    i = i - 1;
  }
  return -1;
}

fn _split(s: Str, delim: Str) -> Vec[Str] {
  var result = Vec[Str].new();
  var dlen = string.str_len(delim);
  var slen = string.str_len(s);
  var start: Int = 0;
  var pos: Int = 0;
  while pos < slen {
    if pos + dlen <= slen {
      var sub = string.str_slice(s, pos, pos + dlen);
      if sub == delim {
        result.push(string.str_slice(s, start, pos));
        pos = pos + dlen;
        start = pos;
      } else {
        pos = pos + 1;
      }
    } else {
      pos = pos + 1;
    }
  }
  result.push(string.str_slice(s, start, slen));
  return result;
}

fn _lower(s: Str) -> Str {
  var result = "";
  var i: Int = 0;
  var len = string.str_len(s);
  while i < len {
    var b = string.byte_at(s, i);
    if b >= 65 && b <= 90 {
      var buf = Vec[UInt8].new();
      buf.push(((b as Int) + 32) as UInt8);
      result = string.str_concat(result, Str::from_utf8(buf));
    } else {
      var c = string.str_slice(s, i, i + 1);
      result = string.str_concat(result, c);
    }
    i = i + 1;
  }
  return result;
}
