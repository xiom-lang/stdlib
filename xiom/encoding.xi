// XIOM — Encoding Utilities
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.encoding

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
  fn free(ptr: *UInt8);
}

// === Helpers ===

fn base64_index(c: Char) -> Int {
  if c == '+' { return 62; };
  if c == '/' { return 63; };
  let code = c as UInt8 as Int;
  if code >= 65 && code <= 90 { return code - 65; };
  if code >= 97 && code <= 122 { return code - 71; };
  if code >= 48 && code <= 57 { return code + 4; };
  -1
}

fn base64url_index(c: Char) -> Int {
  if c == '-' { return 62; };
  if c == '_' { return 63; };
  let code = c as UInt8 as Int;
  if code >= 65 && code <= 90 { return code - 65; };
  if code >= 97 && code <= 122 { return code - 71; };
  if code >= 48 && code <= 57 { return code + 4; };
  -1
}

fn hex_value(c: Char) -> Int {
  let code = c as UInt8 as Int;
  if code >= 48 && code <= 57 { return code - 48; };
  if code >= 97 && code <= 102 { return code - 87; };
  if code >= 65 && code <= 70 { return code - 55; };
  -1
}

fn hex_char_upper(nibble: Int) -> UInt8 {
  if nibble < 10 {
    return (48 + nibble) as UInt8;
  };
  (55 + nibble) as UInt8
}

fn hex_char_lower(nibble: Int) -> UInt8 {
  if nibble < 10 {
    return (48 + nibble) as UInt8;
  };
  (87 + nibble) as UInt8
}

fn is_url_safe(c: Char) -> Bool {
  let code = c as UInt8 as Int;
  if code >= 65 && code <= 90 { return true; };
  if code >= 97 && code <= 122 { return true; };
  if code >= 48 && code <= 57 { return true; };
  if c == '-' || c == '_' || c == '.' || c == '~' { return true; };
  false
}

fn write_hex_byte_upper(dst: *UInt8, dst_idx: Int, byte: UInt8)
  requires: dst_idx >= 0  // dst must have capacity for dst_idx + 1
{
  let b = byte as Int;
  unsafe {
    dst[dst_idx] = hex_char_upper((b >> 4) & 15);
    dst[dst_idx + 1] = hex_char_upper(b & 15);
  };
}

fn write_hex_byte_lower(dst: *UInt8, dst_idx: Int, byte: UInt8)
  requires: dst_idx >= 0  // dst must have capacity for dst_idx + 1
{
  let b = byte as Int;
  unsafe {
    dst[dst_idx] = hex_char_lower((b >> 4) & 15);
    dst[dst_idx + 1] = hex_char_lower(b & 15);
  };
}

fn write_base64_triplet(dst: *UInt8, dst_idx: Int, b0: UInt8, b1: UInt8, b2: UInt8, pad1: Bool, pad2: Bool)
  requires: dst_idx >= 0  // dst must have capacity for dst_idx + 3
{
  let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  let i0 = b0 as Int;
  let i1 = b1 as Int;
  let i2 = b2 as Int;
  unsafe {
    dst[dst_idx]     = alphabet.char_at((i0 >> 2) & 63) as UInt8;
    dst[dst_idx + 1] = alphabet.char_at(((i0 << 4) | (i1 >> 4)) & 63) as UInt8;
    if pad1 {
      dst[dst_idx + 2] = 61;
      dst[dst_idx + 3] = 61;
    } elif pad2 {
      dst[dst_idx + 2] = alphabet.char_at(((i1 << 2) | (i2 >> 6)) & 63) as UInt8;
      dst[dst_idx + 3] = 61;
    } else {
      dst[dst_idx + 2] = alphabet.char_at(((i1 << 2) | (i2 >> 6)) & 63) as UInt8;
      dst[dst_idx + 3] = alphabet.char_at(i2 & 63) as UInt8;
    };
  };
}

fn write_base64url_triplet(dst: *UInt8, dst_idx: Int, b0: UInt8, b1: UInt8, b2: UInt8, has_one: Bool, has_two: Bool)
  requires: dst_idx >= 0  // dst must have capacity: 2 bytes if no continuation, 3 if has_one, 4 if has_two
{
  let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
  let i0 = b0 as Int;
  let i1 = b1 as Int;
  let i2 = b2 as Int;
  unsafe {
    dst[dst_idx]     = alphabet.char_at((i0 >> 2) & 63) as UInt8;
    dst[dst_idx + 1] = alphabet.char_at(((i0 << 4) | (i1 >> 4)) & 63) as UInt8;
    if !has_one {
      return;
    };
    dst[dst_idx + 2] = alphabet.char_at(((i1 << 2) | (i2 >> 6)) & 63) as UInt8;
    if !has_two {
      return;
    };
    dst[dst_idx + 3] = alphabet.char_at(i2 & 63) as UInt8;
  };
}

// === Base64 ===

pub fn base64_encode(data: &Vec[UInt8]) -> Str
  ensures: result.len() == ((data.len() + 2) / 3) * 4
{
  let len = data.len();
  let out_len = ((len + 2) / 3) * 4;
  unsafe {
    var buf = malloc(out_len + 1);
    var i = 0;
    var out = 0;
    while i + 2 < len {
      write_base64_triplet(buf, out, data.get(i).value, data.get(i + 1).value, data.get(i + 2).value, false, false);
      out = out + 4;
      i = i + 3;
    };
    if i < len {
      var b0 = data.get(i).value;
      var b1: UInt8 = 0;
      var b2: UInt8 = 0;
      var pad1 = false;
      var pad2 = false;
      if i + 1 < len {
        b1 = data.get(i + 1).value;
        pad2 = true;
      } else {
        pad1 = true;
      };
      write_base64_triplet(buf, out, b0, b1, b2, pad1, pad2);
      out = out + 4;
    };
    buf[out_len] = 0;
    return Str.from_cstring(buf);
  }
}

pub fn base64_decode(encoded: Str) -> Result[Vec[UInt8], Str]
  requires: encoded.len() % 4 == 0
  ensures:  result is Ok => result.len() <= (encoded.len() / 4) * 3
{
  var result = Vec[UInt8].new();
  let len = encoded.len();
  var i = 0;
  var pad = 0;
  while i < len && encoded.char_at(i) != '=' {
    i = i + 1;
  };
  while i < len && encoded.char_at(i) == '=' {
    pad = pad + 1;
    i = i + 1;
  };
  let data_len = len - pad;
  i = 0;
  while i + 3 < data_len {
    let v0 = base64_index(encoded.char_at(i));
    let v1 = base64_index(encoded.char_at(i + 1));
    let v2 = base64_index(encoded.char_at(i + 2));
    let v3 = base64_index(encoded.char_at(i + 3));
    if v0 < 0 || v1 < 0 || v2 < 0 || v3 < 0 {
      return Err("invalid base64 character");
    };
    result.push(((v0 << 2) | (v1 >> 4)) as UInt8);
    result.push(((v1 << 4) | (v2 >> 2)) as UInt8);
    result.push(((v2 << 6) | v3) as UInt8);
    i = i + 4;
  };
  if i < data_len {
    let v0 = base64_index(encoded.char_at(i));
    let v1 = base64_index(encoded.char_at(i + 1));
    if v0 < 0 || v1 < 0 {
      return Err("invalid base64 character");
    };
    result.push(((v0 << 2) | (v1 >> 4)) as UInt8);
    if pad < 2 {
      let v2 = base64_index(encoded.char_at(i + 2));
      if v2 < 0 {
        return Err("invalid base64 character");
      };
      result.push(((v1 << 4) | (v2 >> 2)) as UInt8);
      if pad == 0 {
        let v3 = base64_index(encoded.char_at(i + 3));
        if v3 < 0 {
          return Err("invalid base64 character");
        };
        result.push(((v2 << 6) | v3) as UInt8);
      };
    };
  };
  Ok(result)
}

pub fn base64url_encode(data: &Vec[UInt8]) -> Str
  ensures: result.len() >= 0
{
  let len = data.len();
  let out_len = ((len + 2) / 3) * 4;
  var actual_len = out_len;
  let rem = len % 3;
  if rem == 1 { actual_len = out_len - 2; };
  if rem == 2 { actual_len = out_len - 1; };
  unsafe {
    var buf = malloc(actual_len + 1);
    var i = 0;
    var out = 0;
    while i + 2 < len {
      write_base64url_triplet(buf, out, data.get(i).value, data.get(i + 1).value, data.get(i + 2).value, true, true);
      out = out + 4;
      i = i + 3;
    };
    if i < len {
      var b0 = data.get(i).value;
      var b1: UInt8 = 0;
      var b2: UInt8 = 0;
      var has_one = i + 1 < len;
      var has_two = i + 2 < len;
      if has_one {
        b1 = data.get(i + 1).value;
      };
      if has_two {
        b2 = data.get(i + 2).value;
      };
      write_base64url_triplet(buf, out, b0, b1, b2, has_one, has_two);
      out = out + 4;
    };
    buf[actual_len] = 0;
    return Str.from_cstring(buf);
  }
}

pub fn base64url_decode(encoded: Str) -> Result[Vec[UInt8], Str]
  ensures: result is Ok => result.len() <= (encoded.len() / 4) * 3
{
  var result = Vec[UInt8].new();
  let len = encoded.len();
  var i = 0;
  while i + 3 < len {
    let v0 = base64url_index(encoded.char_at(i));
    let v1 = base64url_index(encoded.char_at(i + 1));
    let v2 = base64url_index(encoded.char_at(i + 2));
    let v3 = base64url_index(encoded.char_at(i + 3));
    if v0 < 0 || v1 < 0 || v2 < 0 || v3 < 0 {
      return Err("invalid base64url character");
    };
    result.push(((v0 << 2) | (v1 >> 4)) as UInt8);
    result.push(((v1 << 4) | (v2 >> 2)) as UInt8);
    result.push(((v2 << 6) | v3) as UInt8);
    i = i + 4;
  };
  if i + 1 < len {
    let v0 = base64url_index(encoded.char_at(i));
    let v1 = base64url_index(encoded.char_at(i + 1));
    if v0 < 0 || v1 < 0 {
      return Err("invalid base64url character");
    };
    result.push(((v0 << 2) | (v1 >> 4)) as UInt8);
    if i + 2 < len {
      let v2 = base64url_index(encoded.char_at(i + 2));
      if v2 < 0 {
        return Err("invalid base64url character");
      };
      result.push(((v1 << 4) | (v2 >> 2)) as UInt8);
      if i + 3 < len {
        let v3 = base64url_index(encoded.char_at(i + 3));
        if v3 < 0 {
          return Err("invalid base64url character");
        };
        result.push(((v2 << 6) | v3) as UInt8);
      };
    };
  };
  Ok(result)
}

// === Hex ===

pub fn hex_encode(data: &Vec[UInt8]) -> Str
  ensures: result.len() == data.len() * 2
{
  let len = data.len();
  let out_len = len * 2;
  unsafe {
    var buf = malloc(out_len + 1);
    var i = 0;
    while i < len {
      write_hex_byte_lower(buf, i * 2, data.get(i).value);
      i = i + 1;
    };
    buf[out_len] = 0;
    return Str.from_cstring(buf);
  }
}

pub fn hex_decode(encoded: Str) -> Result[Vec[UInt8], Str]
  requires: encoded.len() % 2 == 0
  ensures:  result is Ok => result.len() == encoded.len() / 2
{
  let len = encoded.len();
  if len % 2 != 0 {
    return Err("hex string must have even length");
  };
  var result = Vec[UInt8].new();
  var i = 0;
  while i < len {
    let hi = hex_value(encoded.char_at(i));
    let lo = hex_value(encoded.char_at(i + 1));
    if hi < 0 || lo < 0 {
      return Err("invalid hex character");
    };
    result.push(((hi << 4) | lo) as UInt8);
    i = i + 2;
  };
  Ok(result)
}

pub fn hex_encode_upper(data: &Vec[UInt8]) -> Str
  ensures: result.len() == data.len() * 2
{
  let len = data.len();
  let out_len = len * 2;
  unsafe {
    var buf = malloc(out_len + 1);
    var i = 0;
    while i < len {
      write_hex_byte_upper(buf, i * 2, data.get(i).value);
      i = i + 1;
    };
    buf[out_len] = 0;
    return Str.from_cstring(buf);
  }
}

// === URL encoding ===

pub fn url_encode(data: Str) -> Str
  ensures: result.len() >= data.len()
{
  let s_len = data.len();
  var i = 0;
  var out_len = 0;
  while i < s_len {
    let c = data.char_at(i);
    let clen = xiom.char.len_utf8(c);
    if is_url_safe(c) {
      out_len = out_len + clen;
    } else {
      out_len = out_len + clen * 3;
    };
    i = i + clen;
  };
  unsafe {
    var buf = malloc(out_len + 1);
    i = 0;
    var out = 0;
    while i < s_len {
      let c = data.char_at(i);
      let clen = xiom.char.len_utf8(c);
      if is_url_safe(c) {
        var tmp = Vec[UInt8].new();
        xiom.char.encode_utf8(c, &tmp);
        var j = 0;
        while j < tmp.len() {
          buf[out] = tmp.get(j).value;
          out = out + 1;
          j = j + 1;
        };
      } else {
        var tmp = Vec[UInt8].new();
        xiom.char.encode_utf8(c, &tmp);
        var j = 0;
        while j < tmp.len() {
          buf[out] = '%' as UInt8;
          write_hex_byte_upper(buf, out + 1, tmp.get(j).value);
          out = out + 3;
          j = j + 1;
        };
      };
      i = i + clen;
    };
    buf[out_len] = 0;
    return Str.from_cstring(buf);
  }
}

pub fn url_decode(encoded: Str) -> Result[Str, Str]
  ensures: result is Ok => result.len() <= encoded.len()
{
  let len = encoded.len();
  if len == 0 { return Ok(""); };
  unsafe {
    var buf = malloc(len + 1);
    var i = 0;
    var out = 0;
    while i < len {
      let c = encoded.char_at(i);
      if c == '%' {
        if i + 2 >= len {
          return Err("truncated percent escape");
        };
        let hi = hex_value(encoded.char_at(i + 1));
        let lo = hex_value(encoded.char_at(i + 2));
        if hi < 0 || lo < 0 {
          return Err("invalid percent escape");
        };
        buf[out] = ((hi << 4) | lo) as UInt8;
        out = out + 1;
        i = i + 3;
      } elif c == '+' {
        buf[out] = 32;
        out = out + 1;
        i = i + 1;
      } else {
        let clen = xiom.char.len_utf8(c);
        var tmp = Vec[UInt8].new();
        xiom.char.encode_utf8(c, &tmp);
        var j = 0;
        while j < tmp.len() {
          buf[out] = tmp.get(j).value;
          out = out + 1;
          j = j + 1;
        };
        i = i + clen;
      };
    };
    buf[out] = 0;
    return Ok(Str.from_cstring(buf));
  }
}

// === Percent encoding ===

pub fn percent_encode(data: Str) -> Str
  ensures: result.len() >= data.len()
{
  url_encode(data)
}

pub fn percent_decode(encoded: Str) -> Result[Str, Str]
  ensures: result is Ok => result.len() <= encoded.len()
{
  url_decode(encoded)
}

// === UTF-8 ===

pub fn utf8_encode(s: Str) -> Vec[UInt8]
  ensures: result.len() >= s.len()
{
  var result = Vec[UInt8].new();
  let len = s.len();
  var i = 0;
  while i < len {
    let c = s.char_at(i);
    xiom.char.encode_utf8(c, &result);
    i = i + xiom.char.len_utf8(c);
  };
  result
}

pub fn utf8_decode(data: &Vec[UInt8]) -> Result[Str, Str]
  requires: data.len() > 0
  ensures:  result is Ok => result.len() <= data.len()
{
  let len = data.len();
  if len == 0 { return Ok(""); };
  var i = 0;
  var out_len = 0;
  while i < len {
    let b0 = data.get(i).value as Int;
    var clen = 0;
    if b0 <= 0x7F {
      clen = 1;
    } elif (b0 & 0xE0) == 0xC0 {
      clen = 2;
    } elif (b0 & 0xF0) == 0xE0 {
      clen = 3;
    } elif (b0 & 0xF8) == 0xF0 {
      clen = 4;
    } else {
      return Err("invalid UTF-8 leading byte");
    };
    if i + clen > len {
      return Err("truncated UTF-8 sequence");
    };
    var cp = 0;
    if clen == 1 {
      cp = b0;
    } elif clen == 2 {
      let b1 = data.get(i + 1).value as Int;
      if (b1 & 0xC0) != 0x80 { return Err("invalid UTF-8 continuation byte"); };
      cp = ((b0 & 0x1F) << 6) | (b1 & 0x3F);
      if cp < 0x80 { return Err("overlong UTF-8 encoding"); };
    } elif clen == 3 {
      let b1 = data.get(i + 1).value as Int;
      let b2 = data.get(i + 2).value as Int;
      if (b1 & 0xC0) != 0x80 || (b2 & 0xC0) != 0x80 { return Err("invalid UTF-8 continuation byte"); };
      cp = ((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F);
      if cp < 0x800 { return Err("overlong UTF-8 encoding"); };
      if cp >= 0xD800 && cp <= 0xDFFF { return Err("invalid surrogate code point"); };
    } else {
      let b1 = data.get(i + 1).value as Int;
      let b2 = data.get(i + 2).value as Int;
      let b3 = data.get(i + 3).value as Int;
      if (b1 & 0xC0) != 0x80 || (b2 & 0xC0) != 0x80 || (b3 & 0xC0) != 0x80 { return Err("invalid UTF-8 continuation byte"); };
      cp = ((b0 & 0x07) << 18) | ((b1 & 0x3F) << 12) | ((b2 & 0x3F) << 6) | (b3 & 0x3F);
      if cp < 0x10000 { return Err("overlong UTF-8 encoding"); };
      if cp > 0x10FFFF { return Err("code point exceeds maximum Unicode value"); };
    };
    out_len = out_len + clen;
    i = i + clen;
  };
  unsafe {
    var buf = malloc(out_len + 1);
    i = 0;
    out_len = 0;
    while i < len {
      let b0 = data.get(i).value as Int;
      var clen = 0;
      if b0 <= 0x7F {
        clen = 1;
      } elif (b0 & 0xE0) == 0xC0 {
        clen = 2;
      } elif (b0 & 0xF0) == 0xE0 {
        clen = 3;
      } else {
        clen = 4;
      };
      var j = 0;
      while j < clen {
        buf[out_len] = data.get(i + j).value;
        out_len = out_len + 1;
        j = j + 1;
      };
      i = i + clen;
    };
    buf[out_len] = 0;
    return Ok(Str.from_cstring(buf));
  }
}

pub fn utf8_valid(data: &Vec[UInt8]) -> Bool
  ensures: result == true => utf8_decode(data) is Ok
{
  let len = data.len();
  var i = 0;
  while i < len {
    let b0 = data.get(i).value as Int;
    var clen = 0;
    if b0 <= 0x7F {
      clen = 1;
    } elif (b0 & 0xE0) == 0xC0 {
      clen = 2;
    } elif (b0 & 0xF0) == 0xE0 {
      clen = 3;
    } elif (b0 & 0xF8) == 0xF0 {
      clen = 4;
    } else {
      return false;
    };
    if i + clen > len {
      return false;
    };
    if clen == 1 {
      // valid
    } elif clen == 2 {
      let b1 = data.get(i + 1).value as Int;
      if (b1 & 0xC0) != 0x80 { return false; };
      let cp = ((b0 & 0x1F) << 6) | (b1 & 0x3F);
      if cp < 0x80 { return false; };
    } elif clen == 3 {
      let b1 = data.get(i + 1).value as Int;
      let b2 = data.get(i + 2).value as Int;
      if (b1 & 0xC0) != 0x80 { return false; };
      if (b2 & 0xC0) != 0x80 { return false; };
      let cp = ((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F);
      if cp < 0x800 { return false; };
      if cp >= 0xD800 && cp <= 0xDFFF { return false; };
    } else {
      let b1 = data.get(i + 1).value as Int;
      let b2 = data.get(i + 2).value as Int;
      let b3 = data.get(i + 3).value as Int;
      if (b1 & 0xC0) != 0x80 { return false; };
      if (b2 & 0xC0) != 0x80 { return false; };
      if (b3 & 0xC0) != 0x80 { return false; };
      let cp = ((b0 & 0x07) << 18) | ((b1 & 0x3F) << 12) | ((b2 & 0x3F) << 6) | (b3 & 0x3F);
      if cp < 0x10000 { return false; };
      if cp > 0x10FFFF { return false; };
    };
    i = i + clen;
  };
  true
}

pub fn utf8_char_len(first_byte: UInt8) -> Int
  ensures: result >= 1 && result <= 4
{
  let b = first_byte as Int;
  if b <= 0x7F {
    return 1;
  };
  if (b & 0xE0) == 0xC0 {
    return 2;
  };
  if (b & 0xF0) == 0xE0 {
    return 3;
  };
  if (b & 0xF8) == 0xF0 {
    return 4;
  };
  1
}

// === Binary to text ===

pub fn binary_to_text(data: &Vec[UInt8], format: Int) -> Str
  requires: format >= 0 && format <= 2
  ensures:  format == 0 => result.len() == ((data.len() + 2) / 3) * 4
  ensures:  format == 1 => result.len() == data.len() * 2
  ensures:  result.len() >= 0
{
  if format == 0 {
    return base64_encode(data);
  };
  if format == 1 {
    return hex_encode(data);
  };
  if format == 2 {
    return base64url_encode(data);
  };
  base64_encode(data)
}

pub fn text_to_binary(text: Str, format: Int) -> Result[Vec[UInt8], Str]
  requires: format >= 0 && format <= 2
  ensures:  format == 0 => (result is Ok => result.len() <= (text.len() / 4) * 3)
  ensures:  format == 1 => (result is Ok => result.len() == text.len() / 2)
  ensures:  format == 2 => (result is Ok => result.len() <= (text.len() / 4) * 3)
{
  if format == 0 {
    return base64_decode(text);
  };
  if format == 1 {
    return hex_decode(text);
  };
  if format == 2 {
    return base64url_decode(text);
  };
  base64_decode(text)
}
