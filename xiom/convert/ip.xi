// XIOM - Conversion: Ip
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.convert.ip

// Depends on: xiom.net

// ============================================================================
// IPv4/IPv6 validation, parsing, and serialization helpers. The reference
// implementation lives in xiom.net; because the function names collide
// (BUG 25 #1: same-name delegation miscompiles) the logic is reimplemented
// locally. IPv4 addresses are dotted decimals; IPv6 addresses support the
// "::" compression and are canonicalized with longest-zero-run elision.
// ============================================================================

use xiom.string;

/// Check that a string is a valid IPv4 address.
/// Parameters: s — the candidate address.
/// Returns: true for a dotted-quad with four octets in 0..255.
/// Complexity: O(n).
pub fn is_valid_ipv4(s: Str) -> Bool {
  var opt = _parse_v4(s);
  return opt.is_some;
}

/// Check that a string is a valid IPv6 address (with optional "::"
/// compression; IPv4-mapped forms are not accepted).
/// Parameters: s — the candidate address.
/// Returns: true for a well-formed IPv6 address.
/// Complexity: O(n).
pub fn is_valid_ipv6(s: Str) -> Bool {
  var groups = Vec[Int].new();
  return _parse_v6(s, &groups);
}

/// Format four octets as a dotted IPv4 address.
/// Parameters: octets — at least four octets (only the first four are used).
/// Returns: the "a.b.c.d" representation.
/// Complexity: O(1).
pub fn ipv4_to_string(octets: &Vec[UInt8]) -> Str {
  var result = "";
  var i: Int = 0;
  while i < 4 && i < octets.len() {
    if i > 0 {
      result = string.str_concat(result, ".");
    }
    var b = octets[i] as Int;
    b = b & 0xFF;
    result = string.str_concat(result, to_string(b));
    i = i + 1;
  }
  return result;
}

/// Parse a dotted IPv4 address into four octets.
/// Parameters: s — the address string.
/// Returns: Some(four octets) for a valid address, None otherwise.
/// Complexity: O(n).
pub fn string_to_ipv4(s: Str) -> Option[Vec[UInt8]] {
  var opt = _parse_v4(s);
  if !opt.is_some {
    return None;
  }
  var bytes = Vec[UInt8].new();
  match opt {
    Some(octets) => {
      var i: Int = 0;
      while i < octets.len() {
        bytes.push(octets[i] as UInt8);
        i = i + 1;
      }
    },
    None => {
    },
  }
  return Some(bytes);
}

/// Parse an IP address, returning its canonical text form (IPv4 dotted-quad
/// or IPv6 with "::" compression).
/// Parameters: s — the address string.
/// Returns: Some(canonical) for a valid address, None otherwise.
/// Complexity: O(n).
pub fn ip_parse(s: Str) -> Option[Str] {
  var v4 = _parse_v4(s);
  if v4.is_some {
    var result = "";
    match v4 {
      Some(octets) => {
        result = _v4_canonical(&octets);
      },
      None => {
      },
    }
    return Some(result);
  }
  var groups = Vec[Int].new();
  if _parse_v6(s, &groups) {
    return Some(_v6_canonical(&groups));
  }
  return None;
}

/// Parse an IP address into its raw bytes (4 for IPv4, 16 for IPv6).
/// Parameters: s — the address string.
/// Returns: Some(bytes) for a valid address, None otherwise.
/// Complexity: O(n).
pub fn ip_to_bytes(s: Str) -> Option[Vec[UInt8]] {
  var v4 = _parse_v4(s);
  if v4.is_some {
    var bytes = Vec[UInt8].new();
    match v4 {
      Some(octets) => {
        var i: Int = 0;
        while i < octets.len() {
          bytes.push(octets[i] as UInt8);
          i = i + 1;
        }
      },
      None => {
      },
    }
    return Some(bytes);
  }
  var groups = Vec[Int].new();
  if _parse_v6(s, &groups) {
    var bytes = Vec[UInt8].new();
    var i2: Int = 0;
    while i2 < groups.len() {
      var g = groups[i2];
      bytes.push(((g >> 8) & 0xFF) as UInt8);
      bytes.push((g & 0xFF) as UInt8);
      i2 = i2 + 1;
    }
    return Some(bytes);
  }
  return None;
}

// Parse a dotted-quad IPv4 into four integer octets.
fn _parse_v4(s: Str) -> Option[Vec[Int]] {
  var len = string.str_len(s);
  if len < 7 || len > 15 {
    return None;
  }
  var result = Vec[Int].new();
  var octet: Int = 0;
  var digits: Int = 0;
  var i: Int = 0;
  while i < len {
    var b = string.byte_at(s, i);
    if b == 46 {
      if digits == 0 || octet > 255 {
        return None;
      }
      result.push(octet);
      octet = 0;
      digits = 0;
    } elif b >= 48 && b <= 57 {
      octet = octet * 10 + ((b as Int) - 48);
      digits = digits + 1;
      if octet > 255 {
        return None;
      }
    } else {
      return None;
    }
    i = i + 1;
  }
  if digits == 0 || octet > 255 {
    return None;
  }
  result.push(octet);
  if result.len() != 4 {
    return None;
  }
  return Some(result);
}

fn _v4_canonical(octets: &Vec[Int]) -> Str {
  var result = "";
  var i: Int = 0;
  while i < octets.len() {
    if i > 0 {
      result = string.str_concat(result, ".");
    }
    result = string.str_concat(result, to_string(octets[i]));
    i = i + 1;
  }
  return result;
}

// Parse an IPv6 string into exactly 8 16-bit groups (zeros expanded).
// Returns false for malformed input.
fn _parse_v6(s: Str, groups: &mut Vec[Int]) -> Bool {
  var len = string.str_len(s);
  if len == 0 {
    return false;
  }
  if len > 39 {
    return false;
  }
  var has_dcolon = false;
  var i: Int = 0;
  while i + 1 < len {
    var b = string.byte_at(s, i);
    if b == 58 {
      var next = string.byte_at(s, i + 1);
      if next == 58 {
        if has_dcolon {
          return false;
        }
        has_dcolon = true;
        i = i + 1;
      }
    }
    i = i + 1;
  }
  var left = Vec[Int].new();
  var right = Vec[Int].new();
  if has_dcolon {
    var idx = _dcolon_index(s);
    var lpart = string.str_slice(s, 0, idx);
    var rpart = string.str_slice(s, idx + 2, len);
    if !_parse_groups(lpart, &left) {
      return false;
    }
    if !_parse_groups(rpart, &right) {
      return false;
    }
    var total = left.len() + right.len();
    if total >= 8 {
      return false;
    }
    var k: Int = 0;
    while k < left.len() {
      groups.push(left[k]);
      k = k + 1;
    }
    var missing = 8 - total;
    var z: Int = 0;
    while z < missing {
      groups.push(0);
      z = z + 1;
    }
    var j: Int = 0;
    while j < right.len() {
      groups.push(right[j]);
      j = j + 1;
    }
  } else {
    if !_parse_groups(s, groups) {
      return false;
    }
    if groups.len() != 8 {
      return false;
    }
  }
  return true;
}

// Parse a colon-separated run of 1..4-hex-digit groups into the vector.
fn _parse_groups(s: Str, out: &mut Vec[Int]) -> Bool {
  var len = string.str_len(s);
  if len == 0 {
    return true;
  }
  var i: Int = 0;
  while i < len {
    var digits: Int = 0;
    var value: Int = 0;
    while i < len {
      var b = string.byte_at(s, i);
      if b == 58 {
        break;
      }
      var d: Int = -1;
      if b >= 48 && b <= 57 {
        d = (b as Int) - 48;
      } elif b >= 97 && b <= 102 {
        d = (b as Int) - 87;
      } elif b >= 65 && b <= 70 {
        d = (b as Int) - 55;
      }
      if d < 0 {
        return false;
      }
      value = value * 16 + d;
      digits = digits + 1;
      if digits > 4 {
        return false;
      }
      i = i + 1;
    }
    if digits == 0 {
      return false;
    }
    out.push(value);
    if i < len {
      if i + 1 < len {
        var n2 = string.byte_at(s, i + 1);
        if n2 == 58 {
          return false;
        }
      }
      i = i + 1;
    }
  }
  return true;
}

fn _dcolon_index(s: Str) -> Int {
  var i: Int = 0;
  var len = string.str_len(s);
  while i + 1 < len {
    var b = string.byte_at(s, i);
    if b == 58 {
      var n = string.byte_at(s, i + 1);
      if n == 58 {
        return i;
      }
    }
    i = i + 1;
  }
  return -1;
}

// Canonical IPv6 text with longest-zero-run "::" compression and lowercase
// hex without leading zeros.
fn _v6_canonical(groups: &Vec[Int]) -> Str {
  var best_start = -1;
  var best_len = 0;
  var i: Int = 0;
  while i < groups.len() {
    if groups[i] == 0 {
      var j = i;
      while j < groups.len() && groups[j] == 0 {
        j = j + 1;
      }
      var run = j - i;
      if run > best_len && run >= 2 {
        best_len = run;
        best_start = i;
      }
      i = j;
    } else {
      i = i + 1;
    }
  }
  if best_start < 0 {
    return _join_groups(groups, 0, groups.len(), -1);
  }
  return _join_groups(groups, 0, groups.len(), best_start);
}

// Join groups[from, to) with ':' and elide the zero run starting at hole
// (when hole >= 0, that run is replaced by a "::" marker).
fn _join_groups(groups: &Vec[Int], from: Int, to: Int, hole: Int) -> Str {
  var segs = Vec[Str].new();
  var k = from;
  while k < to {
    if k == hole {
      segs.push("");
      k = k + best_run_len(groups, hole);
    } else {
      segs.push(_group_hex(groups[k]));
      k = k + 1;
    }
  }
  var result = "";
  var s: Int = 0;
  while s < segs.len() {
    if s > 0 {
      result = string.str_concat(result, ":");
    }
    var seg = segs[s];
    result = string.str_concat(result, seg);
    if string.str_len(seg) == 0 {
      if s == 0 {
        result = string.str_concat(result, ":");
      } elif s == segs.len() - 1 {
        result = string.str_concat(result, ":");
      }
    }
    s = s + 1;
  }
  if result == ":" {
    result = string.str_concat(result, ":");
  }
  return result;
}

fn best_run_len(groups: &Vec[Int], start: Int) -> Int {
  var len: Int = 0;
  var i = start;
  while i < groups.len() && groups[i] == 0 {
    len = len + 1;
    i = i + 1;
  }
  return len;
}

// Render a 16-bit group as lowercase hex without leading zeros.
fn _group_hex(v: Int) -> Str {
  if v == 0 {
    return "0";
  }
  var digits = Vec[Int].new();
  var x = v;
  while x > 0 {
    digits.push(x & 0x0F);
    x = x >> 4;
  }
  var result = "";
  var i = digits.len() - 1;
  while i >= 0 {
    result = string.str_concat(result, _hex_digit(digits[i]));
    i = i - 1;
  }
  return result;
}

fn _hex_digit(d: Int) -> Str {
  if d < 10 {
    return string.str_slice("0123456789", d, d + 1);
  }
  return string.str_slice("abcdef", d - 10, d - 9);
}
