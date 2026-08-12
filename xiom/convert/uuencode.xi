// XIOM - Conversion: UUencode
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.convert.uuencode

// Depends on: xiom.string

// ============================================================================
// UUencode and XXencode binary-to-text encodings, plus their decoders.
// Classic UU: each line carries a length character (byte count + 32) followed
// by 6-bit groups rendered as (value + 32); a line with length 0 (the "`"
// character) terminates the stream. XXencode uses the
// "+-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
// alphabet with no offset. Decoders skip "begin"/"end" wrapper lines.
// ============================================================================

use xiom.string;

/// Encode arbitrary bytes to classic UU format (data lines only).
/// Parameters: data — the raw bytes.
/// Returns: the UU-encoded text (each line ends with a newline).
/// Complexity: O(n).
pub fn uuencode(data: &Vec[UInt8]) -> Str {
  var result = "";
  var n = data.len();
  var i: Int = 0;
  while i < n {
    var chunk = Vec[UInt8].new();
    var take = 45;
    if n - i < take {
      take = n - i;
    }
    var k: Int = 0;
    while k < take {
      chunk.push(data[i + k]);
      k = k + 1;
    }
    var line = uuencode_line(&chunk);
    result = string.str_concat(result, line);
    result = string.str_concat(result, "\n");
    i = i + take;
  }
  return result;
}

/// Decode a UU-encoded string to bytes.
/// Parameters: s — the UU text (data lines; "begin"/"end" wrappers ignored).
/// Returns: Ok(bytes) on success; Err on malformed input.
/// Complexity: O(n).
pub fn uudecode(s: Str) -> Result[Vec[UInt8], Str] {
  var result = Vec[UInt8].new();
  var lines = _split_lines(s);
  var i: Int = 0;
  while i < lines.len() {
    var line = lines[i];
    var trimmed = _trim(line);
    var llen = string.str_len(trimmed);
    if llen == 0 {
      i = i + 1;
      continue;
    }
    var first = string.byte_at(trimmed, 0);
    if first == 98 {
      if _starts_with(trimmed, "begin") {
        i = i + 1;
        continue;
      }
    }
    if first == 101 {
      if _starts_with(trimmed, "end") {
        i = i + 1;
        continue;
      }
    }
    var count = (first as Int) - 32;
    if count < 0 || count > 45 {
      return Err("uudecode: invalid line length");
    }
    if count == 0 {
      break;
    }
    var payload = string.str_slice(trimmed, 1, llen);
    var decoded = uudecode_line(string.str_concat(_length_char(count), payload));
    if !decoded.is_ok {
      return Err(decoded.error);
    }
    var k: Int = 0;
    while k < decoded.value.len() {
      result.push(decoded.value[k]);
      k = k + 1;
    }
    i = i + 1;
  }
  return Ok(result);
}

/// Encode a single UU line of at most 45 bytes (length char + encoded data).
/// Parameters: data — up to 45 bytes.
/// Returns: the encoded line (without a trailing newline).
/// Complexity: O(1).
pub fn uuencode_line(data: &Vec[UInt8]) -> Str {
  var n = data.len();
  if n > 45 {
    n = 45;
  }
  var result = _length_char(n);
  var i: Int = 0;
  while i < n {
    var b0 = data[i] as Int;
    var b1: Int = 0;
    var b2: Int = 0;
    if i + 1 < n {
      b1 = data[i + 1] as Int;
    }
    if i + 2 < n {
      b2 = data[i + 2] as Int;
    }
    result = string.str_concat(result, _uu_char((b0 >> 2) & 0x3F));
    result = string.str_concat(result, _uu_char(((b0 << 4) | (b1 >> 4)) & 0x3F));
    if i + 1 < n {
      result = string.str_concat(result, _uu_char(((b1 << 2) | (b2 >> 6)) & 0x3F));
    } else {
      result = string.str_concat(result, " ");
    }
    if i + 2 < n {
      result = string.str_concat(result, _uu_char(b2 & 0x3F));
    } else {
      result = string.str_concat(result, " ");
    }
    i = i + 3;
  }
  return result;
}

/// Decode a single UU line, validating length and padding.
/// Parameters: s — the encoded line (length char + data, no newline).
/// Returns: Ok(bytes) on success; Err on invalid input.
/// Complexity: O(1).
pub fn uudecode_line(s: Str) -> Result[Vec[UInt8], Str] {
  var len = string.str_len(s);
  if len == 0 {
    return Err("uudecode_line: empty line");
  }
  var first = string.byte_at(s, 0);
  var count = (first as Int) - 32;
  if count < 0 || count > 45 {
    return Err("uudecode_line: invalid length character");
  }
  var result = Vec[UInt8].new();
  var pos: Int = 1;
  while result.len() < count {
    if pos + 3 >= len + 1 {
      if pos + 3 > len {
        return Err("uudecode_line: truncated line");
      }
    }
    if pos + 3 > len {
      return Err("uudecode_line: truncated line");
    }
    var c0 = _uu_val(string.byte_at(s, pos));
    var c1 = _uu_val(string.byte_at(s, pos + 1));
    var c2 = _uu_val(string.byte_at(s, pos + 2));
    var c3 = _uu_val(string.byte_at(s, pos + 3));
    if c0 < 0 || c1 < 0 {
      return Err("uudecode_line: invalid character");
    }
    result.push((((c0 << 2) | (c1 >> 4)) & 0xFF) as UInt8);
    if result.len() < count {
      if c2 < 0 {
        return Err("uudecode_line: invalid character");
      }
      result.push((((c1 << 4) | (c2 >> 2)) & 0xFF) as UInt8);
      if result.len() < count {
        if c3 < 0 {
          return Err("uudecode_line: invalid character");
        }
        result.push((((c2 << 6) | c3) & 0xFF) as UInt8);
      }
    }
    pos = pos + 4;
  }
  return Ok(result);
}

/// Encode arbitrary bytes to XXencode format (data lines only).
/// Parameters: data — the raw bytes.
/// Returns: the XX-encoded text.
/// Complexity: O(n).
pub fn xxencode(data: &Vec[UInt8]) -> Str {
  var result = "";
  var n = data.len();
  var i: Int = 0;
  while i < n {
    var take = 45;
    if n - i < take {
      take = n - i;
    }
    var chunk = Vec[UInt8].new();
    var k: Int = 0;
    while k < take {
      chunk.push(data[i + k]);
      k = k + 1;
    }
    result = string.str_concat(result, _xx_length_char(take));
    var j: Int = 0;
    while j < take {
      var b0 = chunk[j] as Int;
      var b1: Int = 0;
      var b2: Int = 0;
      if j + 1 < take {
        b1 = chunk[j + 1] as Int;
      }
      if j + 2 < take {
        b2 = chunk[j + 2] as Int;
      }
      result = string.str_concat(result, _xx_char((b0 >> 2) & 0x3F));
      result = string.str_concat(result, _xx_char(((b0 << 4) | (b1 >> 4)) & 0x3F));
      if j + 1 < take {
        result = string.str_concat(result, _xx_char(((b1 << 2) | (b2 >> 6)) & 0x3F));
      } else {
        result = string.str_concat(result, "+");
      }
      if j + 2 < take {
        result = string.str_concat(result, _xx_char(b2 & 0x3F));
      } else {
        result = string.str_concat(result, "+");
      }
      j = j + 3;
    }
    result = string.str_concat(result, "\n");
    i = i + take;
  }
  return result;
}

/// Decode an XXencode string to bytes.
/// Parameters: s — the XX text.
/// Returns: Ok(bytes) on success; Err on malformed input.
/// Complexity: O(n).
pub fn xxdecode(s: Str) -> Result[Vec[UInt8], Str] {
  var result = Vec[UInt8].new();
  var lines = _split_lines(s);
  var i: Int = 0;
  while i < lines.len() {
    var line = _trim(lines[i]);
    var llen = string.str_len(line);
    if llen == 0 {
      i = i + 1;
      continue;
    }
    var count = _xx_val(string.byte_at(line, 0));
    if count < 0 || count > 45 {
      return Err("xxdecode: invalid line length");
    }
    var pos: Int = 1;
    var produced: Int = 0;
    while produced < count {
      if pos + 3 >= llen {
        return Err("xxdecode: truncated line");
      }
      if pos + 3 >= llen {
        return Err("xxdecode: truncated line");
      }
      if pos + 3 > llen - 1 {
        return Err("xxdecode: truncated line");
      }
      var c0 = _xx_val(string.byte_at(line, pos));
      var c1 = _xx_val(string.byte_at(line, pos + 1));
      var c2 = _xx_val(string.byte_at(line, pos + 2));
      var c3 = _xx_val(string.byte_at(line, pos + 3));
      if c0 < 0 || c1 < 0 {
        return Err("xxdecode: invalid character");
      }
      result.push((((c0 << 2) | (c1 >> 4)) & 0xFF) as UInt8);
      produced = produced + 1;
      if produced < count {
        if c2 < 0 {
          return Err("xxdecode: invalid character");
        }
        result.push((((c1 << 4) | (c2 >> 2)) & 0xFF) as UInt8);
        produced = produced + 1;
        if produced < count {
          if c3 < 0 {
            return Err("xxdecode: invalid character");
          }
          result.push((((c2 << 6) | c3) & 0xFF) as UInt8);
          produced = produced + 1;
        }
      }
      pos = pos + 4;
    }
    i = i + 1;
  }
  return Ok(result);
}

/// Compute the encoded length for a given input length: each 45-byte block
/// becomes a 61-character line (60 data chars + newline).
/// Parameters: len — the input byte count.
/// Returns: the UU-encoded text length.
/// Complexity: O(1).
pub fn uu_encoded_length(len: Int) -> Int {
  if len <= 0 {
    return 0;
  }
  var lines = (len + 44) / 45;
  return lines * 61;
}

// The length character for n bytes (n + 32).
fn _length_char(n: Int) -> Str {
  var buf = Vec[UInt8].new();
  buf.push((n + 32) as UInt8);
  return Str::from_utf8(buf);
}

// UU alphabet: value + 32 (space is value 0, "`" is 64 for empty).
fn _uu_char(v: Int) -> Str {
  var buf = Vec[UInt8].new();
  buf.push((v + 32) as UInt8);
  return Str::from_utf8(buf);
}

// UU value of a character (char - 32), or -1.
fn _uu_val(b: UInt8) -> Int {
  var v = b as Int;
  v = v & 0xFF;
  var value = v - 32;
  if value >= 0 && value <= 63 {
    return value;
  }
  return -1;
}

// XXencode alphabet.
fn _xx_alphabet() -> Str {
  return "+-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
}

fn _xx_char(v: Int) -> Str {
  return string.str_slice(_xx_alphabet(), v, v + 1);
}

fn _xx_val(b: UInt8) -> Int {
  var i: Int = 0;
  var alpha = _xx_alphabet();
  while i < 64 {
    var c = string.byte_at(alpha, i);
    if c == b {
      return i;
    }
    i = i + 1;
  }
  return -1;
}

fn _xx_length_char(n: Int) -> Str {
  return _xx_char(n);
}

// Split on newlines, keeping no empty trailing segment.
fn _split_lines(s: Str) -> Vec[Str] {
  var result = Vec[Str].new();
  var start: Int = 0;
  var i: Int = 0;
  var len = string.str_len(s);
  while i < len {
    var b = string.byte_at(s, i);
    if b == 10 {
      result.push(string.str_slice(s, start, i));
      start = i + 1;
    }
    i = i + 1;
  }
  if start < len {
    result.push(string.str_slice(s, start, len));
  }
  return result;
}

// Strip leading/trailing whitespace and carriage returns.
fn _trim(s: Str) -> Str {
  var len = string.str_len(s);
  var start: Int = 0;
  var end: Int = len;
  while start < end {
    var b = string.byte_at(s, start);
    if b == 32 || b == 9 || b == 13 || b == 10 {
      start = start + 1;
    } else {
      break;
    }
  }
  while end > start {
    var b2 = string.byte_at(s, end - 1);
    if b2 == 32 || b2 == 9 || b2 == 13 || b2 == 10 {
      end = end - 1;
    } else {
      break;
    }
  }
  return string.str_slice(s, start, end);
}

fn _starts_with(s: Str, prefix: Str) -> Bool {
  var plen = string.str_len(prefix);
  if plen > string.str_len(s) {
    return false;
  }
  var sub = string.str_slice(s, 0, plen);
  return sub == prefix;
}
