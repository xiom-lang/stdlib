// XIOM - Encoding: IDNA
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.encoding.idna

// Depends on: xiom.string

// ============================================================================
// Internationalized Domain Names: UTS-46 processing and nameprep checks.
// The A-label/U-label conversions delegate to xiom.encoding.punycode (RFC
// 3492); this module supplies the IDNA layer: label splitting/joining, LDH
// validation, length checks, a simplified UTS-46 mapping (case, fullwidth and
// space mapping; NFC omitted) and the IDNA bidi rule.
// ============================================================================

use xiom.string;
use xiom.encoding.punycode.punycode_encode;
use xiom.encoding.punycode.punycode_decode;

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
  fn free(ptr: *UInt8);
  fn xiom_char_at(s: Str, pos: Int) -> Char;
}

/// Splits a domain at the dot separators. Empty labels (e.g. a trailing dot)
/// are preserved. Complexity: O(n).
pub fn idna_split_labels(domain: Str) -> Vec[Str] {
  string.str_split(domain, ".")
}

/// Joins labels back into a domain with '.' separators.
/// Complexity: O(n * total length).
pub fn idna_join_labels(labels: &Vec[Str]) -> Str {
  var result = "";
  var n = 0;
  while n < labels.len() {
    if n > 0 {
      result = string.str_concat(result, ".");
    };
    result = string.str_concat(result, labels[n]);
    n = n + 1;
  };
  result
}

/// True iff `cp` is an IDNA LDH character (ASCII letter, digit, or hyphen).
fn _ldh(cp: Int) -> Bool {
  if cp >= 65 && cp <= 90 { return true; }
  if cp >= 97 && cp <= 122 { return true; }
  if cp >= 48 && cp <= 57 { return true; }
  if cp == 45 { return true; }
  false
}

/// Unsigned byte value at index `i` of `s`.
fn _byte(s: Str, i: Int) -> Int {
  (string.byte_at(s, i) as Int) & 0xFF
}

/// Decodes the UTF-8 code point starting at byte `i` of `s`; -1 on invalid or
/// truncated input.
fn _decode_cp(s: Str, i: Int, slen: Int) -> Int {
  var b0 = _byte(s, i);
  if b0 < 0x80 {
    return b0;
  };
  if b0 >= 0xC0 && b0 <= 0xDF {
    if i + 1 >= slen { return -1; }
    var b1 = _byte(s, i + 1);
    return ((b0 & 0x1F) << 6) | (b1 & 0x3F);
  };
  if b0 >= 0xE0 && b0 <= 0xEF {
    if i + 2 >= slen { return -1; }
    var b1 = _byte(s, i + 1);
    var b2 = _byte(s, i + 2);
    return ((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F);
  };
  if b0 >= 0xF0 && b0 <= 0xF7 {
    if i + 3 >= slen { return -1; }
    var b1 = _byte(s, i + 1);
    var b2 = _byte(s, i + 2);
    var b3 = _byte(s, i + 3);
    return ((b0 & 0x07) << 18) | ((b1 & 0x3F) << 12) | ((b2 & 0x3F) << 6) | (b3 & 0x3F);
  };
  -1
}

/// Byte length of the UTF-8 sequence starting at byte `i` of `s` (1..4).
fn _char_len(s: Str, i: Int) -> Int {
  var b0 = _byte(s, i);
  if b0 < 0x80 { return 1; }
  if b0 <= 0xDF { return 2; }
  if b0 <= 0xEF { return 3; }
  4
}

/// True iff the label is a valid LDH label (letters/digits/hyphen only,
/// neither first nor last character is a hyphen).
fn _is_ldh_label(label: Str) -> Bool {
  var len = label.len();
  if len == 0 {
    return false;
  };
  var n = 0;
  while n < len {
    var cp = _byte(label, n);
    if !_ldh(cp) {
      return false;
    };
    n = n + 1;
  };
  var first = _byte(label, 0);
  var last = _byte(label, len - 1);
  if first == 45 || last == 45 {
    return false;
  };
  true
}

/// True iff the label contains any non-ASCII code point.
fn _has_non_ascii(label: Str) -> Bool {
  var len = label.len();
  var n = 0;
  while n < len {
    if _byte(label, n) >= 0x80 {
      return true;
    };
    n = n + 1;
  };
  false
}

/// True iff the label starts with the A-label prefix "xn--" (case-insensitive).
fn _is_alabel(label: Str) -> Bool {
  if string.str_len(label) <= 4 {
    return false;
  };
  var lower = string.str_lower(label);
  string.str_starts_with(lower, "xn--")
}

/// Maps one code point through the simplified UTS-46 mapping. Returns -1 for
/// a disallowed character.
fn _uts46_map(cp: Int) -> Int {
  if cp < 0 { return -1; }
  if cp <= 31 || cp == 127 { return -1; }
  if cp >= 55296 && cp <= 57343 { return -1; }
  if cp >= 65 && cp <= 90 { return cp + 32; }
  if cp == 0x3000 { return 32; }
  if cp >= 0xFF01 && cp <= 0xFF5E { return cp - 0xFEE0; }
  cp
}

/// Converts a Unicode domain to its ASCII A-label form: ASCII labels are
/// lowercased and kept; non-ASCII labels are Punycode-encoded with the
/// "xn--" prefix. Returns Err on an empty domain, an oversized label/domain,
/// or a punycode failure. Complexity: O(sum of label^2).
pub fn idna_to_ascii(s: Str) -> Result[Str, Str] {
  if string.str_len(s) == 0 {
    return Err("empty domain");
  };
  var labels = idna_split_labels(s);
  var result = "";
  var n = 0;
  while n < labels.len() {
    var label = string.str_lower(labels[n]);
    if n > 0 {
      result = string.str_concat(result, ".");
    };
    if string.str_len(label) > 63 {
      return Err("label exceeds 63 characters");
    };
    if _has_non_ascii(label) {
      var enc = punycode_encode(label);
      match enc {
        Err(e) => { return Err(e); },
        Ok(encoded) => {
          result = string.str_concat(result, string.str_concat("xn--", encoded));
        },
      };
    } elif _is_alabel(label) {
      var payload = string.str_slice(label, 4, string.str_len(label));
      var dec = punycode_decode(payload);
      match dec {
        Err(e) => { return Err(e); },
        Ok(_) => {
          result = string.str_concat(result, label);
        },
      };
    } else {
      if !_is_ldh_label(label) {
        return Err("invalid ASCII label");
      };
      result = string.str_concat(result, label);
    };
    n = n + 1;
  };
  if string.str_len(result) > 253 {
    return Err("domain exceeds 253 characters");
  };
  Ok(result)
}

/// Converts an A-label domain to Unicode: labels with the "xn--" prefix are
/// Punycode-decoded, all others pass through. Returns Err on a punycode
/// failure. Complexity: O(sum of label^2).
pub fn idna_to_unicode(s: Str) -> Result[Str, Str] {
  var labels = idna_split_labels(s);
  var result = "";
  var n = 0;
  while n < labels.len() {
    var label = labels[n];
    if n > 0 {
      result = string.str_concat(result, ".");
    };
    if _is_alabel(label) {
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

/// Reports whether a domain conforms to IDNA requirements: total length at
/// most 253 bytes, every label 1..63 bytes, ASCII-only, LDH-shaped (or a
/// valid "xn--" A-label whose payload decodes), and neither starting nor
/// ending with a hyphen. Returns false for any violation.
/// Complexity: O(total length + sum of label^2).
pub fn idna_is_valid(s: Str) -> Bool {
  if string.str_len(s) == 0 {
    return false;
  };
  if string.str_len(s) > 253 {
    return false;
  };
  var labels = idna_split_labels(s);
  var n = 0;
  while n < labels.len() {
    var label = labels[n];
    var llen = string.str_len(label);
    if llen == 0 {
      return false;
    };
    if llen > 63 {
      return false;
    };
    if _has_non_ascii(label) {
      return false;
    };
    if _is_alabel(label) {
      var payload = string.str_slice(label, 4, llen);
      var dec = punycode_decode(payload);
      match dec {
        Err(_) => { return false; },
        Ok(_) => {},
      };
    } else {
      if !_is_ldh_label(label) {
        return false;
      };
    };
    n = n + 1;
  };
  true
}

/// Applies the simplified UTS-46 mapping to a domain string: ASCII
/// uppercasing, fullwidth-to-ASCII and ideographic-space mapping, and
/// rejection of control/surrogate characters. (NFC normalization is omitted;
/// the code points are otherwise preserved.) Returns Err on a disallowed
/// character. Complexity: O(n).
pub fn idna_uts46_normalize(s: Str) -> Result[Str, Str] {
  var bytes = Vec[UInt8].new();
  var len = s.len();
  var i = 0;
  while i < len {
    var cp = _decode_cp(s, i, len);
    if cp < 0 {
      return Err("invalid utf-8 in UTS-46");
    };
    var mapped = _uts46_map(cp);
    if mapped < 0 {
      return Err("disallowed character in UTS-46");
    };
    var tmp = Vec[UInt8].new();
    xiom.char.encode_utf8(to_char(mapped), &mut tmp);
    var j = 0;
    while j < tmp.len() {
      bytes.push(tmp[j]);
      j = j + 1;
    };
    i = i + _char_len(s, i);
  };
  var blen = bytes.len();
  if blen == 0 {
    return Ok("");
  };
  unsafe {
    var buf = malloc(blen + 1);
    i = 0;
    while i < blen {
      buf[i] = bytes[i];
      i = i + 1;
    };
    buf[blen] = 0;
    return Ok(Str.from_cstring(buf));
  }
}

/// Applies the older Nameprep profile (RFC 3491 subset) to a domain string:
/// case folding (ASCII lowercase), rejection of whitespace, control and
/// surrogate characters. Returns Err on a disallowed character.
/// Complexity: O(n).
pub fn idna_nameprep(s: Str) -> Result[Str, Str] {
  var bytes = Vec[UInt8].new();
  var len = s.len();
  var i = 0;
  while i < len {
    var cp = _decode_cp(s, i, len);
    if cp < 0 {
      return Err("invalid utf-8 in nameprep");
    };
    if cp < 32 || cp == 127 {
      return Err("control character in nameprep");
    };
    if cp == 32 || cp == 9 || cp == 10 || cp == 13 {
      return Err("whitespace in nameprep");
    };
    if cp >= 55296 && cp <= 57343 {
      return Err("surrogate in nameprep");
    };
    var mapped = cp;
    if cp >= 65 && cp <= 90 {
      mapped = cp + 32;
    };
    var tmp = Vec[UInt8].new();
    xiom.char.encode_utf8(to_char(mapped), &mut tmp);
    var j = 0;
    while j < tmp.len() {
      bytes.push(tmp[j]);
      j = j + 1;
    };
    i = i + _char_len(s, i);
  };
  var blen = bytes.len();
  if blen == 0 {
    return Ok("");
  };
  unsafe {
    var buf = malloc(blen + 1);
    i = 0;
    while i < blen {
      buf[i] = bytes[i];
      i = i + 1;
    };
    buf[blen] = 0;
    return Ok(Str.from_cstring(buf));
  }
}

/// True iff `cp` falls in a right-to-left script (Hebrew, Arabic, Syriac,
/// Thaana, NKo, Samaritan, Mandaic, and the presentation forms).
fn _is_rtl(cp: Int) -> Bool {
  if cp >= 0x0590 && cp <= 0x05FF { return true; }
  if cp >= 0x0600 && cp <= 0x06FF { return true; }
  if cp >= 0x0700 && cp <= 0x074F { return true; }
  if cp >= 0x0750 && cp <= 0x077F { return true; }
  if cp >= 0x0780 && cp <= 0x07BF { return true; }
  if cp >= 0x07C0 && cp <= 0x07FF { return true; }
  if cp >= 0x0800 && cp <= 0x083F { return true; }
  if cp >= 0x0840 && cp <= 0x085F { return true; }
  if cp >= 0x0860 && cp <= 0x086F { return true; }
  if cp >= 0x08A0 && cp <= 0x08FF { return true; }
  if cp >= 0xFB1D && cp <= 0xFB4F { return true; }
  if cp >= 0xFB50 && cp <= 0xFDFF { return true; }
  if cp >= 0xFE70 && cp <= 0xFEFF { return true; }
  if cp >= 0x10800 && cp <= 0x10FFF { return true; }
  false
}

/// True iff `cp` is an LTR letter (Latin, Greek, Cyrillic, or any code point
/// below the first RTL block other than digits and hyphen).
fn _is_ltr(cp: Int) -> Bool {
  if cp >= 0x0041 && cp <= 0x005A { return true; }
  if cp >= 0x0061 && cp <= 0x007A { return true; }
  if cp >= 0x00C0 && cp <= 0x00FF { return true; }
  if cp >= 0x0100 && cp <= 0x017F { return true; }
  if cp >= 0x0370 && cp <= 0x03FF { return true; }
  if cp >= 0x0400 && cp <= 0x04FF { return true; }
  false
}

/// True iff `cp` is a European or Arabic-Indic digit (allowed inside RTL
/// labels by the bidi rule).
fn _is_number(cp: Int) -> Bool {
  if cp >= 48 && cp <= 57 { return true; }
  if cp >= 0x0660 && cp <= 0x0669 { return true; }
  if cp >= 0x06F0 && cp <= 0x06F9 { return true; }
  false
}

/// Reports whether `s` satisfies the IDNA bidi rule (RFC 5893 subset): a
/// label containing an RTL code point must start with an RTL code point, end
/// with an RTL code point or a digit, and contain no LTR letters; labels with
/// no RTL code point are always acceptable. Applies to every dot-separated
/// label. Complexity: O(n).
pub fn idna_is_bidi_valid(s: Str) -> Bool {
  var labels = idna_split_labels(s);
  var n = 0;
  while n < labels.len() {
    var label = labels[n];
    var len = label.len();
    if len == 0 {
      n = n + 1;
      continue;
    };
    var has_rtl = false;
    var first_cp = _decode_cp(label, 0, len);
    var last_cp = first_cp;
    var i = 0;
    while i < len {
      var cp = _decode_cp(label, i, len);
      if cp < 0 {
        return false;
      };
      last_cp = cp;
      if _is_rtl(cp) {
        has_rtl = true;
      };
      i = i + _char_len(label, i);
    };
    if has_rtl {
      if !_is_rtl(first_cp) {
        return false;
      };
      if !_is_rtl(last_cp) && !_is_number(last_cp) {
        return false;
      };
      i = 0;
      while i < len {
        var cp = _decode_cp(label, i, len);
        if _is_ltr(cp) {
          return false;
        };
        i = i + _char_len(label, i);
      };
    };
    n = n + 1;
  };
  true
}
