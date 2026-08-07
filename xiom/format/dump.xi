// XIOM — Hex/Octal/Binary Dump (xiom.format.dump)
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.
//
// Byte-buffer dump utilities. hexdump mirrors the output style of
// xiom.fmt.format_hexdump (lowercase hex, 8+8 grouping, ASCII column);
// octal_dump and binary_dump use the same layout with wider per-byte
// fields. All functions are pure.

module xiom.format.dump

use xiom.string;
use xiom.convert;
use xiom.fmt;

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
}

fn byte_to_hex(b: UInt8) -> Str {
  var v = b as Int;
  var hi = v / 16;
  var lo = v % 16;
  var s = "0123456789abcdef";
  string.str_slice(s, hi, hi + 1) + string.str_slice(s, lo, lo + 1)
}

fn byte_to_octal(b: UInt8) -> Str {
  var v = b as Int;
  var s = "01234567";
  var d2 = (v / 64) % 8;
  var d1 = (v / 8) % 8;
  var d0 = v % 8;
  string.str_slice(s, d2, d2 + 1) + string.str_slice(s, d1, d1 + 1) + string.str_slice(s, d0, d0 + 1)
}

fn byte_to_binary(b: UInt8) -> Str {
  var v = b as Int;
  var result = "";
  var bit: Int = 7;
  while bit >= 0 {
    if (v & (1 << bit)) == 0 {
      result = result + "0";
    } else {
      result = result + "1";
    }
    bit = bit - 1;
  }
  result
}

fn ascii_of(b: UInt8) -> Str {
  var v = b as Int;
  if v >= 32 && v <= 126 {
    unsafe {
      var buf = malloc(2);
      buf[0] = b;
      buf[1] = 0;
      return Str.from_cstring(buf);
    }
  }
  "."
}

/// Formats a single 16-byte hex dump line (same style as
/// xiom.fmt.format_hexdump): 8-digit hex offset, 16 hex bytes grouped
/// 8+8, then the ASCII column. Missing bytes are space-padded.
/// Complexity: O(len).
pub fn hexdump_line(data: &Vec[UInt8], offset: Int, start: Int, len: Int) -> Str {
  var offset_pad = string.str_pad_left(convert.int_to_string(offset), 8, '0');
  var hex_part = "";
  var ascii_part = "";
  var bi: Int = 0;
  while bi < len && (start + bi) < data.len() {
    var byte_val = data[start + bi];
    if bi > 0 {
      hex_part = hex_part + " ";
    }
    if bi == 8 {
      hex_part = hex_part + " ";
    }
    hex_part = hex_part + byte_to_hex(byte_val);
    ascii_part = ascii_part + ascii_of(byte_val);
    bi = bi + 1;
  }
  while bi < len {
    hex_part = hex_part + "   ";
    bi = bi + 1;
  }
  offset_pad + "  " + hex_part + "  |" + ascii_part + "|"
}

/// Formats a byte buffer as a classic 16-bytes-per-line hex dump. Each
/// line: 8-digit hex offset, 16 hex bytes grouped 8+8 (lowercase), then
/// the ASCII column (printable characters or '.'). The layout mirrors
/// xiom.fmt.format_hexdump with width 16. Empty input yields "".
/// Complexity: O(n).
pub fn hexdump(data: &Vec[UInt8]) -> Str {
  var result = "";
  if data.len() == 0 {
    return result;
  }
  var pos: Int = 0;
  while pos < data.len() {
    var line = hexdump_line(data, pos, pos, 16);
    if pos == 0 {
      result = line;
    } else {
      result = result + "\n" + line;
    }
    pos = pos + 16;
  }
  result
}

/// Formats a byte buffer as an 8-bytes-per-line octal dump. Each line:
/// 8-digit hex offset, 3-digit octal per byte, ASCII column. Empty input
/// yields "".
/// Complexity: O(n).
pub fn octal_dump(data: &Vec[UInt8]) -> Str {
  var result = "";
  if data.len() == 0 {
    return result;
  }
  var pos: Int = 0;
  while pos < data.len() {
    var offset_pad = string.str_pad_left(convert.int_to_string(pos), 8, '0');
    var oct_part = "";
    var ascii_part = "";
    var bi: Int = 0;
    while bi < 8 && pos + bi < data.len() {
      if bi > 0 {
        oct_part = oct_part + " ";
      }
      oct_part = oct_part + byte_to_octal(data[pos + bi]);
      ascii_part = ascii_part + ascii_of(data[pos + bi]);
      bi = bi + 1;
    }
    while bi < 8 {
      oct_part = oct_part + "    ";
      bi = bi + 1;
    }
    var line = offset_pad + "  " + oct_part + "  |" + ascii_part + "|";
    if pos == 0 {
      result = line;
    } else {
      result = result + "\n" + line;
    }
    pos = pos + 8;
  }
  result
}

/// Formats a byte buffer as a 4-bytes-per-line binary dump. Each line:
/// 8-digit hex offset, 8-bit binary per byte, ASCII column. Empty input
/// yields "".
/// Complexity: O(n).
pub fn binary_dump(data: &Vec[UInt8]) -> Str {
  var result = "";
  if data.len() == 0 {
    return result;
  }
  var pos: Int = 0;
  while pos < data.len() {
    var offset_pad = string.str_pad_left(convert.int_to_string(pos), 8, '0');
    var bin_part = "";
    var ascii_part = "";
    var bi: Int = 0;
    while bi < 4 && pos + bi < data.len() {
      if bi > 0 {
        bin_part = bin_part + " ";
      }
      bin_part = bin_part + byte_to_binary(data[pos + bi]);
      ascii_part = ascii_part + ascii_of(data[pos + bi]);
      bi = bi + 1;
    }
    while bi < 4 {
      bin_part = bin_part + "         ";
      bi = bi + 1;
    }
    var line = offset_pad + "  " + bin_part + "  |" + ascii_part + "|";
    if pos == 0 {
      result = line;
    } else {
      result = result + "\n" + line;
    }
    pos = pos + 4;
  }
  result
}
