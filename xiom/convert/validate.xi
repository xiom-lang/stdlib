// XIOM - Conversion: Validate
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.convert.validate

// Depends on: xiom.string

// ============================================================================
// Format validation helpers for common structured identifiers and values.
// Covers email, phone, credit card (Luhn), IBAN, SWIFT/BIC, hex colors, and
// semantic versioning. All checks are pure and return Boolean results.
// ============================================================================

use xiom.string;

/// Check the basic email shape (local@domain).
/// Parameters: s — the candidate address.
/// Returns: true when there is exactly one '@', a non-empty local part, a
///          non-empty domain containing a dot, and no whitespace.
/// Complexity: O(n).
pub fn is_valid_email(s: Str) -> Bool {
  var len = string.str_len(s);
  if len < 3 {
    return false;
  }
  var at: Int = -1;
  var i: Int = 0;
  while i < len {
    var b = string.byte_at(s, i);
    if b == 64 {
      if at >= 0 {
        return false;
      }
      at = i;
    } elif _is_ws(b) {
      return false;
    }
    i = i + 1;
  }
  if at <= 0 || at >= len - 1 {
    return false;
  }
  var domain = string.str_slice(s, at + 1, len);
  if _index_of(domain, ".") < 0 {
    return false;
  }
  return true;
}

/// Check an email against stricter RFC 5322-shaped rules: local part up to 64
/// chars, domain labels 1..63 chars, no leading/trailing dots.
/// Parameters: s — the candidate address.
/// Returns: true for a well-formed address.
/// Complexity: O(n).
pub fn is_valid_email_strict(s: Str) -> Bool {
  var at = _index_of(s, "@");
  if at <= 0 {
    return false;
  }
  if _index_of(string.str_slice(s, at + 1, string.str_len(s)), "@") >= 0 {
    return false;
  }
  var local = string.str_slice(s, 0, at);
  var domain = string.str_slice(s, at + 1, string.str_len(s));
  if string.str_len(local) > 64 {
    return false;
  }
  if string.str_len(local) == 0 {
    return false;
  }
  if string.byte_at(local, 0) == 46 || string.byte_at(local, string.str_len(local) - 1) == 46 {
    return false;
  }
  var i: Int = 0;
  while i < string.str_len(local) {
    var b = string.byte_at(local, i);
    if !_email_local_char(b) {
      return false;
    }
    i = i + 1;
  }
  var labels = _split(domain, ".");
  if labels.len() < 2 {
    return false;
  }
  var j: Int = 0;
  while j < labels.len() {
    var lab = labels[j];
    var llen = string.str_len(lab);
    if llen < 1 || llen > 63 {
      return false;
    }
    var k: Int = 0;
    while k < llen {
      var c = string.byte_at(lab, k);
      if !_email_domain_char(c) {
        return false;
      }
      k = k + 1;
    }
    j = j + 1;
  }
  return true;
}

/// Check a phone number for a recognizable format (digits, spaces, + - ( )).
/// Parameters: s — the candidate number.
/// Returns: true when the number contains 7..15 digits with only allowed
///          separator characters.
/// Complexity: O(n).
pub fn is_valid_phone(s: Str) -> Bool {
  var len = string.str_len(s);
  if len == 0 {
    return false;
  }
  var digits: Int = 0;
  var i: Int = 0;
  while i < len {
    var b = string.byte_at(s, i);
    var v = b as Int;
    v = v & 0xFF;
    if v >= 48 && v <= 57 {
      digits = digits + 1;
    } elif v == 43 || v == 40 || v == 41 || v == 45 || v == 46 || v == 32 || v == 9 {
      // allowed separator
    } else {
      return false;
    }
    i = i + 1;
  }
  return digits >= 7 && digits <= 15;
}

/// Check a phone number against the E.164 specification: optional leading
/// '+', then 1..15 digits.
/// Parameters: s — the candidate number.
/// Returns: true for an E.164-compliant number.
/// Complexity: O(n).
pub fn is_valid_phone_e164(s: Str) -> Bool {
  var len = string.str_len(s);
  if len < 1 || len > 16 {
    return false;
  }
  var i: Int = 0;
  var first = string.byte_at(s, 0);
  if first == 43 {
    i = 1;
    if i >= len {
      return false;
    }
  }
  var digits: Int = 0;
  while i < len {
    var b = string.byte_at(s, i);
    if b < 48 || b > 57 {
      return false;
    }
    digits = digits + 1;
    i = i + 1;
  }
  return digits >= 1 && digits <= 15;
}

/// Check a card number for length (13-19 digits) and Luhn validity.
/// Parameters: s — the candidate card number (digits, optional spaces).
/// Returns: true for a valid card number.
/// Complexity: O(n).
pub fn is_valid_credit_card(s: Str) -> Bool {
  var digits = _digit_string(s);
  var dlen = digits.len();
  if dlen < 13 || dlen > 19 {
    return false;
  }
  return luhn_check(digits);
}

/// Validate a digit string with the Luhn algorithm.
/// Parameters: s — a string of digits.
/// Returns: true when the Luhn checksum passes.
/// Complexity: O(n).
pub fn luhn_check(s: Str) -> Bool {
  var len = string.str_len(s);
  if len == 0 {
    return false;
  }
  var total: Int = 0;
  var i = len - 1;
  var parity = (len - 1) % 2;
  while i >= 0 {
    var b = string.byte_at(s, i);
    var v = b as Int;
    v = v & 0xFF;
    if v < 48 || v > 57 {
      return false;
    }
    var d = v - 48;
    if i % 2 != parity {
      d = d * 2;
      if d > 9 {
        d = d - 9;
      }
    }
    total = total + d;
    i = i - 1;
  }
  return total % 10 == 0;
}

/// Validate an IBAN structure, country format, and mod-97 checksum.
/// Parameters: s — the candidate IBAN (spaces allowed).
/// Returns: true for a valid IBAN.
/// Complexity: O(n).
pub fn is_valid_iban(s: Str) -> Bool {
  var clean = _strip_spaces(s);
  var len = string.str_len(clean);
  if len < 15 || len > 34 {
    return false;
  }
  var first = string.byte_at(clean, 0);
  var second = string.byte_at(clean, 1);
  if !_is_alpha(first) || !_is_alpha(second) {
    return false;
  }
  var i: Int = 2;
  while i < len {
    var b = string.byte_at(clean, i);
    if !_is_alnum(b) {
      return false;
    }
    i = i + 1;
  }
  // mod-97 over the rotated digit expansion
  var rotated = string.str_concat(string.str_slice(clean, 4, len), string.str_slice(clean, 0, 4));
  var rem: Int = 0;
  var j: Int = 0;
  var rlen = string.str_len(rotated);
  while j < rlen {
    var b2 = string.byte_at(rotated, j);
    var v: Int = 0;
    if b2 >= 65 && b2 <= 90 {
      v = (b2 as Int) - 55;
    } else {
      v = (b2 as Int) - 48;
    }
    rem = (rem * 100 + v) % 97;
    j = j + 1;
  }
  return rem == 1;
}

/// Extract the two-letter country code from an IBAN.
/// Parameters: s — the IBAN.
/// Returns: the country code (uppercase) or "" when too short.
/// Complexity: O(1).
pub fn iban_country_code(s: Str) -> Str {
  if string.str_len(s) < 2 {
    return "";
  }
  var c0 = string.byte_at(s, 0);
  var c1 = string.byte_at(s, 1);
  var buf = Vec[UInt8].new();
  buf.push(_upper_byte(c0));
  buf.push(_upper_byte(c1));
  return Str::from_utf8(buf);
}

/// Extract the two-digit checksum from an IBAN.
/// Parameters: s — the IBAN.
/// Returns: the checksum digits or "" when too short.
/// Complexity: O(1).
pub fn iban_checksum(s: Str) -> Str {
  if string.str_len(s) < 6 {
    return "";
  }
  var c2 = string.byte_at(s, 2);
  var c3 = string.byte_at(s, 3);
  var buf = Vec[UInt8].new();
  buf.push(c2);
  buf.push(c3);
  return Str::from_utf8(buf);
}

/// Check a SWIFT/BIC code for the 8 or 11 character layout.
/// Parameters: s — the candidate code.
/// Returns: true for a valid layout (6 alphanumeric + 2 alpha + optional 3
///          alphanumeric).
/// Complexity: O(1).
pub fn is_valid_swift(s: Str) -> Bool {
  var len = string.str_len(s);
  if len != 8 && len != 11 {
    return false;
  }
  var i: Int = 0;
  while i < len {
    var b = string.byte_at(s, i);
    if i >= 4 && i <= 5 {
      if !_is_alpha(b) {
        return false;
      }
    } else {
      if !_is_alnum(b) {
        return false;
      }
    }
    i = i + 1;
  }
  return true;
}

/// Alias checking a BIC code for the 8 or 11 character layout.
/// Parameters: s — the candidate BIC.
/// Returns: true for a valid BIC.
/// Complexity: O(1).
pub fn is_valid_bic(s: Str) -> Bool {
  return is_valid_swift(s);
}

/// Check a hex color value in #RGB, #RRGGBB, or #RRGGBBAA form.
/// Parameters: s — the candidate color.
/// Returns: true for a well-formed hex color.
/// Complexity: O(1).
pub fn is_valid_hex_color(s: Str) -> Bool {
  var len = string.str_len(s);
  if len != 4 && len != 7 && len != 9 {
    return false;
  }
  var first = string.byte_at(s, 0);
  if first != 35 {
    return false;
  }
  var i: Int = 1;
  while i < len {
    var b = string.byte_at(s, i);
    if !_is_hex(b) {
      return false;
    }
    i = i + 1;
  }
  return true;
}

/// Check a semantic version string per SemVer 2.0.0
/// (major.minor.patch with optional -prerelease and +build).
/// Parameters: s — the candidate version.
/// Returns: true for a valid SemVer.
/// Complexity: O(n).
pub fn is_valid_semver(s: Str) -> Bool {
  var main = s;
  var build = "";
  var b_idx = _index_of(s, "+");
  if b_idx >= 0 {
    main = string.str_slice(s, 0, b_idx);
    build = string.str_slice(s, b_idx + 1, string.str_len(s));
    if !_valid_ident(build, false) {
      return false;
    }
  }
  var pre = "";
  var p_idx = _index_of(main, "-");
  if p_idx >= 0 {
    pre = string.str_slice(main, p_idx + 1, string.str_len(main));
    main = string.str_slice(main, 0, p_idx);
    if !_valid_ident(pre, true) {
      return false;
    }
  }
  var parts = _split(main, ".");
  if parts.len() != 3 {
    return false;
  }
  var i: Int = 0;
  while i < 3 {
    var part = parts[i];
    if !_valid_numeric(part) {
      return false;
    }
    i = i + 1;
  }
  return true;
}

// ---- helpers ----

fn _digit_string(s: Str) -> Str {
  var result = "";
  var i: Int = 0;
  var len = string.str_len(s);
  while i < len {
    var b = string.byte_at(s, i);
    if b >= 48 && b <= 57 {
      result = string.str_concat(result, _byte_str(b));
    }
    i = i + 1;
  }
  return result;
}

fn _strip_spaces(s: Str) -> Str {
  var result = "";
  var i: Int = 0;
  var len = string.str_len(s);
  while i < len {
    var b = string.byte_at(s, i);
    if b != 32 && b != 9 {
      result = string.str_concat(result, _byte_str(b));
    }
    i = i + 1;
  }
  return result;
}

// SemVer numeric identifier: digits without a leading zero (unless "0").
fn _valid_numeric(s: Str) -> Bool {
  var len = string.str_len(s);
  if len == 0 {
    return false;
  }
  if len > 1 && string.byte_at(s, 0) == 48 {
    return false;
  }
  var i: Int = 0;
  while i < len {
    var b = string.byte_at(s, i);
    if b < 48 || b > 57 {
      return false;
    }
    i = i + 1;
  }
  return true;
}

// SemVer alphanumeric identifier (pre-release: no leading zeros in numeric
// segments; build allows leading zeros).
fn _valid_ident(s: Str, pre: Bool) -> Bool {
  var len = string.str_len(s);
  if len == 0 {
    return !pre;
  }
  var segs = _split(s, ".");
  var i: Int = 0;
  while i < segs.len() {
    var seg = segs[i];
    var slen = string.str_len(seg);
    if slen == 0 {
      return false;
    }
    var numeric = true;
    var j: Int = 0;
    while j < slen {
      var b = string.byte_at(seg, j);
      if b < 48 || b > 57 {
        numeric = false;
        break;
      }
      j = j + 1;
    }
    if numeric && pre {
      if slen > 1 && string.byte_at(seg, 0) == 48 {
        return false;
      }
    }
    if !numeric {
      var k: Int = 0;
      while k < slen {
        var c = string.byte_at(seg, k);
        if !_is_alnum(c) && c != 45 {
          return false;
        }
        k = k + 1;
      }
    }
    i = i + 1;
  }
  return true;
}

fn _is_ws(b: UInt8) -> Bool {
  var v = b as Int;
  return v == 32 || v == 9 || v == 10 || v == 13;
}

fn _is_alpha(b: UInt8) -> Bool {
  var v = b as Int;
  return (v >= 65 && v <= 90) || (v >= 97 && v <= 122);
}

fn _is_alnum(b: UInt8) -> Bool {
  var v = b as Int;
  return (v >= 48 && v <= 57) || (v >= 65 && v <= 90) || (v >= 97 && v <= 122);
}

fn _is_hex(b: UInt8) -> Bool {
  var v = b as Int;
  return (v >= 48 && v <= 57) || (v >= 97 && v <= 102) || (v >= 65 && v <= 70);
}

fn _email_local_char(b: UInt8) -> Bool {
  var v = b as Int;
  if v >= 48 && v <= 57 { return true; }
  if v >= 65 && v <= 90 { return true; }
  if v >= 97 && v <= 122 { return true; }
  if v == 46 || v == 33 || v == 35 || v == 36 || v == 37 || v == 38 || v == 39 {
    return true;
  }
  if v == 42 || v == 43 || v == 45 || v == 47 || v == 61 || v == 63 || v == 94 {
    return true;
  }
  if v == 95 || v == 96 || v == 123 || v == 124 || v == 125 || v == 126 {
    return true;
  }
  return false;
}

fn _email_domain_char(b: UInt8) -> Bool {
  var v = b as Int;
  if v >= 48 && v <= 57 { return true; }
  if v >= 65 && v <= 90 { return true; }
  if v >= 97 && v <= 122 { return true; }
  if v == 45 { return true; }
  return false;
}

fn _upper_byte(b: UInt8) -> UInt8 {
  var v = b as Int;
  if v >= 97 && v <= 122 {
    return (v - 32) as UInt8;
  }
  return b;
}

fn _byte_str(b: UInt8) -> Str {
  var buf = Vec[UInt8].new();
  buf.push(b);
  return Str::from_utf8(buf);
}

fn _index_of(hay: Str, needle: Str) -> Int {
  var hlen = string.str_len(hay);
  var nlen = string.str_len(needle);
  if nlen == 0 {
    return 0;
  }
  if nlen > hlen {
    return -1;
  }
  var i: Int = 0;
  while i <= hlen - nlen {
    var sub = string.str_slice(hay, i, i + nlen);
    if sub == needle {
      return i;
    }
    i = i + 1;
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
