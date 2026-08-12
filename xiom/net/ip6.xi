// XIOM — IPv6 Address Helpers (xiom.net.ip6)
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.
//
// Pure IPv6 address parsing, formatting, and classification helpers.
// No network I/O; all functions operate on strings and byte vectors.

module xiom.net.ip6

use xiom.string;

// idx_of returns the byte index of needle in hay, or -1 if not found.
fn idx_of(hay: Str, needle: Str) -> Int {
  let hlen = hay.len();
  let nlen = needle.len();
  if nlen == 0 { return 0; }
  if nlen > hlen { return -1; }
  var i = 0;
  while i <= hlen - nlen {
    if string.str_slice(hay, i, i + nlen) == needle {
      return i;
    }
    i = i + 1;
  }
  -1
}

// split splits s on every occurrence of delim.
fn split(s: Str, delim: Str) -> Vec[Str] {
  var result: Vec[Str] = Vec[Str]::new();
  let dlen = delim.len();
  if dlen == 0 {
    var i = 0;
    while i < s.len() {
      result.push(string.str_slice(s, i, i + 1));
      i = i + 1;
    }
    return result;
  }
  var start = 0;
  var pos = 0;
  let slen = s.len();
  while pos < slen {
    if pos + dlen <= slen && string.str_slice(s, pos, pos + dlen) == delim {
      result.push(string.str_slice(s, start, pos));
      pos = pos + dlen;
      start = pos;
    } else {
      pos = pos + 1;
    }
  }
  result.push(string.str_slice(s, start, slen));
  result
}

// hex_digit_value returns the numeric value of a hex digit byte, or -1.
fn hex_digit_value(b: UInt8) -> Int {
  let c = b as Int;
  if c >= 48 && c <= 57 { return c - 48; }
  if c >= 97 && c <= 102 { return c - 87; }
  if c >= 65 && c <= 70 { return c - 55; }
  -1
}

// parse_hex_group parses one 1-4 digit hex group, or None.
fn parse_hex_group(seg: Str) -> Option[Int] {
  let len = seg.len();
  if len == 0 || len > 4 {
    return None;
  }
  var value = 0;
  var i = 0;
  while i < len {
    let v = hex_digit_value(seg.byte_at(i));
    if v < 0 {
      return None;
    }
    value = value * 16 + v;
    i = i + 1;
  }
  Some(value)
}

// parse_groups splits a hex-group string on ':' and validates each
// group. A group value of -1 signals an invalid group.
fn parse_groups(s: Str) -> Vec[Int] {
  var result: Vec[Int] = Vec[Int]::new();
  if s.len() == 0 {
    return result;
  }
  let parts = split(s, ":");
  var i = 0;
  while i < parts.len() {
    let v = parse_hex_group(parts[i]);
    if v.is_none {
      result.push(-1);
      return result;
    }
    result.push(v.value);
    i = i + 1;
  }
  result
}

// has_bad_group returns true if any group marker is -1.
fn has_bad_group(g: &Vec[Int]) -> Bool {
  var i = 0;
  while i < g.len() {
    if g[i] == -1 {
      return true;
    }
    i = i + 1;
  }
  false
}

// push_hex16 appends a 16-bit group as two big-endian bytes.
fn push_hex16(dst: &mut Vec[UInt8], group: Int) {
  dst.push(((group >> 8) & 0xFF) as UInt8);
  dst.push((group & 0xFF) as UInt8);
}

// ip6_parse parses an IPv6 string (full form or with a single "::"
// compression) into 16 bytes. Invalid input returns Err.
// Complexity: O(n). Pure.
pub fn ip6_parse(s: Str) -> Result[Vec[UInt8], Str] {
  let len = s.len();
  if len < 2 {
    return Err("invalid IPv6 address: too short");
  }
  var result: Vec[UInt8] = Vec[UInt8]::new();
  var ok = true;
  let double = idx_of(s, "::");
  if double >= 0 {
    let after = string.str_slice(s, double + 2, len);
    if idx_of(after, "::") >= 0 {
      ok = false;
    } else {
      let left = string.str_slice(s, 0, double);
      let right = string.str_slice(s, double + 2, len);
      let lg = parse_groups(left);
      let rg = parse_groups(right);
      if has_bad_group(&lg) || has_bad_group(&rg) || lg.len() + rg.len() >= 8 {
        ok = false;
      } else {
        var i = 0;
        while i < lg.len() {
          push_hex16(&mut result, lg[i]);
          i = i + 1;
        }
        var zeros = 8 - lg.len() - rg.len();
        var z = 0;
        while z < zeros {
          result.push(0 as UInt8);
          result.push(0 as UInt8);
          z = z + 1;
        }
        var j = 0;
        while j < rg.len() {
          push_hex16(&mut result, rg[j]);
          j = j + 1;
        }
      }
    }
  } else {
    let g = parse_groups(s);
    if has_bad_group(&g) || g.len() != 8 {
      ok = false;
    } else {
      var i = 0;
      while i < 8 {
        push_hex16(&mut result, g[i]);
        i = i + 1;
      }
    }
  }
  if !ok {
    return Err("invalid IPv6 address");
  }
  Ok(result)
}

// ip6_validate returns true if s is a valid IPv6 address.
// Complexity: O(n). Pure.
pub fn ip6_validate(s: Str) -> Bool {
  let parsed = ip6_parse(s);
  parsed.is_ok
}

// hex_char returns the lowercase hex byte for a nibble (0-15).
fn hex_char(nib: Int) -> UInt8 {
  if nib < 10 {
    return (48 + nib) as UInt8;
  }
  (87 + nib) as UInt8
}

// hex4 formats a 16-bit group without leading zeros (0 -> "0").
fn hex4(group: Int) -> Str {
  if group == 0 {
    return "0";
  }
  var buf: Vec[UInt8] = Vec[UInt8]::new();
  var started = false;
  var shift = 12;
  while shift >= 0 {
    let nib = (group >> shift) & 0xF;
    if nib != 0 || started {
      started = true;
      buf.push(hex_char(nib));
    }
    shift = shift - 4;
  }
  let s = Str::from_utf8(buf);
  s
}

// ip6_to_str formats 16 bytes as a full-form IPv6 address (eight
// 16-bit groups, no "::" compression). Returns Err if the length is
// not 16. Complexity: O(n). Pure.
pub fn ip6_to_str(bytes: &Vec[UInt8]) -> Result[Str, Str] {
  if bytes.len() != 16 {
    return Err("invalid IPv6 address: expected 16 bytes");
  }
  var result = "";
  var i = 0;
  while i < 16 {
    if i > 0 {
      result = result + ":";
    }
    let hi = bytes[i] as Int;
    let lo = bytes[i + 1] as Int;
    let group = (hi << 8) | lo;
    result = result + hex4(group);
    i = i + 2;
  }
  Ok(result)
}

// pad4 returns the four-digit hex form of a 16-bit group.
fn pad4(group: Int) -> Str {
  var s = hex4(group);
  let missing = 4 - s.len();
  var pad = "";
  var i = 0;
  while i < missing {
    pad = pad + "0";
    i = i + 1;
  }
  pad + s
}

// ip6_expand returns the full eight-group form of an IPv6 string,
// expanding "::" and zero-padding each group to four hex digits.
// Returns Err on invalid input. Complexity: O(n). Pure.
pub fn ip6_expand(s: Str) -> Result[Str, Str] {
  let parsed = ip6_parse(s);
  match parsed {
    Ok(bytes) => {
      var result = "";
      var i = 0;
      while i < 16 {
        if i > 0 {
          result = result + ":";
        }
        let hi = bytes[i] as Int;
        let lo = bytes[i + 1] as Int;
        let group = (hi << 8) | lo;
        result = result + pad4(group);
        i = i + 2;
      }
      Ok(result)
    }
    Err(e) => Err(e);
  }
}

// ip6_is_loopback returns true for ::1.
// Complexity: O(n). Pure.
pub fn ip6_is_loopback(s: Str) -> Bool {
  let parsed = ip6_parse(s);
  match parsed {
    Ok(bytes) => {
      var all_zero = true;
      var i = 0;
      while i < 15 {
        if bytes[i] != 0 as UInt8 {
          all_zero = false;
        }
        i = i + 1;
      }
      all_zero && bytes[15] == 1 as UInt8
    }
    Err(_) => false;
  }
}

// ip6_is_unspecified returns true for ::
// Complexity: O(n). Pure.
pub fn ip6_is_unspecified(s: Str) -> Bool {
  let parsed = ip6_parse(s);
  match parsed {
    Ok(bytes) => {
      var all_zero = true;
      var i = 0;
      while i < 16 {
        if bytes[i] != 0 as UInt8 {
          all_zero = false;
        }
        i = i + 1;
      }
      all_zero
    }
    Err(_) => false;
  }
}

// ip6_is_multicast returns true for ff00::/8.
// Complexity: O(n). Pure.
pub fn ip6_is_multicast(s: Str) -> Bool {
  let parsed = ip6_parse(s);
  match parsed {
    Ok(bytes) => bytes[0] == 0xFF as UInt8;
    Err(_) => false;
  }
}

// ip6_is_link_local returns true for fe80::/10.
// Complexity: O(n). Pure.
pub fn ip6_is_link_local(s: Str) -> Bool {
  let parsed = ip6_parse(s);
  match parsed {
    Ok(bytes) => {
      let b0 = bytes[0] as Int;
      b0 == 0xFE && (bytes[1] as Int & 0xC0) == 0x80
    }
    Err(_) => false;
  }
}
