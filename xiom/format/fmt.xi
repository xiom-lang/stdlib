// XIOM -- Formatting & Display
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.fmt

use xiom.format.table;
use xiom.format.units;
use xiom.format.ansi;
use xiom.format.text;
use xiom.format.markup;

use xiom.string;
use xiom.convert;
use xiom.io;
use xiom.num;

pub interface Display {
  fn fmt(self, f: &mut Formatter) -> Result[Unit, FmtError];
}

pub type Formatter = { buf: Str; width: Int; precision: Int; align: Int; } derive[Clone]
pub type FmtError = { message: Str; } derive[Clone]

pub fn Formatter.new() -> Formatter
  ensures: result.buf == ""
  ensures: result.width == 0
  ensures: result.precision == 6
{
  Formatter { buf: ""; width: 0; precision: 6; align: 0; }
}

pub fn Formatter.write_str(self, s: Str) -> Result[Unit, FmtError]
  ensures: true
{
  self.buf = string.str_concat(self.buf, s);
  Result[Unit, FmtError] { is_ok: true; value: (); error: FmtError { message: ""; }; }
}

pub fn Formatter.write_int(self, n: Int) -> Result[Unit, FmtError]
  ensures: result.is_ok
{
  let s = convert.int_to_string(n);
  self.buf = string.str_concat(self.buf, s);
  Result[Unit, FmtError] { is_ok: true; value: (); error: FmtError { message: ""; }; }
}

pub fn Formatter.write_float(self, f: Float64) -> Result[Unit, FmtError]
  ensures: result.is_ok
{
  let s = convert.float_to_string(f);
  self.buf = string.str_concat(self.buf, s);
  Result[Unit, FmtError] { is_ok: true; value: (); error: FmtError { message: ""; }; }
}

pub fn Formatter.write_bool(self, b: Bool) -> Result[Unit, FmtError]
  ensures: result.is_ok
{
  let s = convert.bool_to_string(b);
  self.buf = string.str_concat(self.buf, s);
  Result[Unit, FmtError] { is_ok: true; value: (); error: FmtError { message: ""; }; }
}

pub fn Formatter.finish(self) -> Str
  ensures: result == self.buf@pre
{
  self.buf
}

// Alignment: 0=left, 1=right, 2=center

// === Display implementations for built-in types ===

pub fn Int.to_str() -> Str {
  convert.int_to_string(self)
}

pub fn Float64.to_str() -> Str {
  convert.float_to_string(self)
}

pub fn Bool.to_str() -> Str {
  convert.bool_to_string(self)
}

pub fn Str.to_str() -> Str {
  self
}

// === Format functions ===

pub fn format1[T](fmt: Str, arg: T) -> Str {
  let idx_opt = string.index_of(fmt, "{}");
  if idx_opt.is_some {
    let idx = idx_opt.value;
    let before = string.str_slice(fmt, 0, idx);
    let after = string.str_slice(fmt, idx + 2, string.str_len(fmt));
    let replacement = arg.to_str();
    string.str_concat(string.str_concat(before, replacement), after)
  } else {
    fmt
  }
}

pub fn format2[T, U](fmt: Str, arg1: T, arg2: U) -> Str {
  let s = format1(fmt, arg1);
  format1(s, arg2)
}

pub fn format3[T, U, V](fmt: Str, arg1: T, arg2: U, arg3: V) -> Str {
  let s = format1(fmt, arg1);
  let s2 = format1(s, arg2);
  format1(s2, arg3)
}

// === Print functions ===

pub fn print(s: Str) {
  io.print(s);
}

pub fn println(s: Str) {
  io.println(s);
}

// --------------------------------------------------
//  Extended Formatting Functions
// --------------------------------------------------

// -- Table --

// Formats a simple aligned-column table with `|` separators.
// O(r * c). No padding -- cells are left-aligned as-is.
/// Formats a simple aligned-column table with `|` separators.
/// O(r * c). No padding -- cells are left-aligned as-is.
pub fn format_table(headers: &Vec[Str], cells: &Vec[Str], col_count: Int) -> Str {
  if col_count <= 0 || headers.len() == 0 {
    return "";
  };
  var row_count = cells.len() / col_count;

  // Header: "| A | B |"
  var result = "| ";
  var ci: Int = 0;
  while ci < col_count {
    result = string.str_concat(result, headers[ci]);
    if ci < col_count - 1 {
      result = string.str_concat(result, " | ");
    } else {
      result = string.str_concat(result, " |");
    };
    ci = ci + 1;
  };

  // Separator
  result = string.str_concat(result, "\n");
  result = string.str_concat(result, "|");
  var ci2: Int = 0;
  while ci2 < col_count {
    result = string.str_concat(result, "---|");
    ci2 = ci2 + 1;
  };

  // Data rows
  var ri: Int = 0;
  while ri < row_count {
    result = string.str_concat(result, "\n| ");
    var cj: Int = 0;
    while cj < col_count {
      var cell = cells[ri * col_count + cj];
      result = string.str_concat(result, cell);
      if cj < col_count - 1 {
        result = string.str_concat(result, " | ");
      } else {
        result = string.str_concat(result, " |");
      };
      cj = cj + 1;
    };
    ri = ri + 1;
  };

  result
}

// -- Columns --

// Arranges `items` into multiple columns, wrapping at `width`.
// Items are placed column-by-column (top-to-bottom then left-to-right).
// O(n) where n = items.len().
/// Arranges `items` into multiple columns, wrapping at `width`.
/// Items are placed column-by-column (top-to-bottom then left-to-right).
/// O(n) where n = items.len().
pub fn format_columns(items: &Vec[Str], width: Int) -> Str {
  if items.len() == 0 {
    return "";
  };
  var col_width: Int = 0;
  var i: Int = 0;
  while i < items.len() {
    var il = items[i].len();
    if il > col_width { col_width = il; };
    i = i + 1;
  };
  col_width = col_width + 2;
  if col_width >= width {
    col_width = width - 2;
  };
  var cols_per_row = width / col_width;
  if cols_per_row < 1 { cols_per_row = 1; };
  var rows_needed = (items.len() + cols_per_row - 1) / cols_per_row;

  var result = "";
  var r: Int = 0;
  while r < rows_needed {
    var line = "";
    var c: Int = 0;
    while c < cols_per_row {
      var idx = c * rows_needed + r;
      if idx < items.len() {
        line = string.str_concat(line, items[idx]);
        var pad_len = col_width - items[idx].len();
        var p: Int = 0;
        while p < pad_len {
          line = string.str_concat(line, " ");
          p = p + 1;
        };
      };
      c = c + 1;
    };
    if r > 0 {
      result = string.str_concat(string.str_concat(result, "\n"), line);
    } else {
      result = line;
    };
    r = r + 1;
  };
  result
}

// -- Wrap --

// Wraps `text` at word boundaries to fit within `width` characters.
// Words longer than `width` are placed on their own line.
// O(n) where n = |text|.
/// Wraps `text` at word boundaries to fit within `width` characters.
/// Words longer than `width` are placed on their own line.
/// O(n) where n = |text|.
pub fn format_wrap(text: Str, width: Int) -> Str {
  if width <= 0 || string.str_len(text) == 0 {
    return text;
  };
  var words = string.words(text);
  if words.len() == 0 {
    return "";
  };
  var result = "";
  var current_line = "";
  var wi: Int = 0;
  while wi < words.len() {
    var w = words[wi];
    if current_line.len() == 0 {
      current_line = w;
    } elif current_line.len() + 1 + w.len() <= width {
      current_line = string.str_concat(string.str_concat(current_line, " "), w);
    } else {
      if result.len() == 0 {
        result = current_line;
      } else {
        result = string.str_concat(string.str_concat(result, "\n"), current_line);
      };
      current_line = w;
    };
    wi = wi + 1;
  };
  if result.len() == 0 {
    result = current_line;
  } else {
    result = string.str_concat(string.str_concat(result, "\n"), current_line);
  };
  result
}

// -- Indent --

// Adds `spaces` spaces at the beginning of each line in `text`.
// O(n + lines * spaces).
/// Adds `spaces` spaces at the beginning of each line in `text`.
/// O(n + lines * spaces).
pub fn format_indent(text: Str, spaces: Int) -> Str {
  if spaces <= 0 {
    return text;
  };
  var prefix = "";
  var si: Int = 0;
  while si < spaces {
    prefix = string.str_concat(prefix, " ");
    si = si + 1;
  };
  var lines = string.lines(text);
  var result = "";
  var li: Int = 0;
  while li < lines.len() {
    var indented = string.str_concat(prefix, lines[li]);
    if li == 0 {
      result = indented;
    } else {
      result = string.str_concat(string.str_concat(result, "\n"), indented);
    };
    li = li + 1;
  };
  result
}

// -- Hexdump --

// Formats a byte buffer as a classic hexdump: offset, hex bytes, ASCII preview.
// `width` controls bytes per line (default 16). Returns multi-line string.
// O(n) where n = data.len().
/// Formats a byte buffer as a classic hexdump: offset, hex bytes, ASCII preview.
/// `width` controls bytes per line (default 16). Returns multi-line string.
/// O(n) where n = data.len().
pub fn format_hexdump(data: &Vec[UInt8], width: Int) -> Str {
  if data.len() == 0 {
    return "";
  };
  var per_line = width;
  if per_line <= 0 { per_line = 16; };
  var result = "";
  var pos: Int = 0;
  while pos < data.len() {
    var offset_str = convert.int_to_string(pos);
    var offset_pad = string.str_pad_left(offset_str, 8, '0');

    var hex_part = "";
    var ascii_part = "";
    var bi: Int = 0;
    while bi < per_line && (pos + bi) < data.len() {
      var byte_val = data[pos + bi];
      var hi_opt = xiom.char.from_digit(byte_val / 16, 16);
      var lo_opt = xiom.char.from_digit(byte_val % 16, 16);
      var hi = '0';
      var lo = '0';
      if hi_opt.is_some { hi = hi_opt.value; };
      if lo_opt.is_some { lo = lo_opt.value; };
      if bi > 0 {
        hex_part = string.str_concat(hex_part, " ");
      };
      if bi == 8 {
        hex_part = string.str_concat(hex_part, " ");
      };
      unsafe {
        var hbuf = malloc(3);
        hbuf[0] = hi as UInt8;
        hbuf[1] = lo as UInt8;
        hbuf[2] = 0;
        hex_part = string.str_concat(hex_part, Str.from_cstring(hbuf));
      };
      if byte_val >= 32 && byte_val <= 126 {
        unsafe {
          var abuf = malloc(2);
          abuf[0] = byte_val as UInt8;
          abuf[1] = 0;
          ascii_part = string.str_concat(ascii_part, Str.from_cstring(abuf));
        };
      } else {
        ascii_part = string.str_concat(ascii_part, ".");
      };
      bi = bi + 1;
    };
    while bi < per_line {
      hex_part = string.str_concat(hex_part, "   ");
      bi = bi + 1;
    };
    var line = offset_pad;
    line = string.str_concat(string.str_concat(line, "  "), hex_part);
    line = string.str_concat(string.str_concat(line, "  |"), ascii_part);
    line = string.str_concat(line, "|");
    if result.len() == 0 {
      result = line;
    } else {
      result = string.str_concat(string.str_concat(result, "\n"), line);
    };
    pos = pos + per_line;
  };
  result
}

// -- Number Formatting --

// Zero-pads integer `n` to `width` digits. Negative numbers are handled
// (the sign is not counted in the width). Returns the string representation.
/// Zero-pads integer `n` to `width` digits. Negative numbers are handled
/// (the sign is not counted in the width). Returns the string representation.
pub fn format_pad_number(n: Int, width: Int) -> Str {
  if width <= 0 {
    return convert.int_to_string(n);
  };
  var neg = n < 0;
  var abs_n = n;
  if neg { abs_n = -n; };
  var s = convert.int_to_string(abs_n);
  if s.len() >= width {
    return convert.int_to_string(n);
  };
  var pad = width - s.len();
  var prefix = "";
  if neg { prefix = "-"; };
  var p: Int = 0;
  while p < pad {
    prefix = string.str_concat(prefix, "0");
    p = p + 1;
  };
  string.str_concat(prefix, s)
}

// Formats a float with `decimals` decimal places, ROUNDED half away from zero
// (2026-08-11: previously truncated via the old float_to_string, which itself
// was fptosi-garbage -- see convert.xi; now delegates to the exact
// scaled-integer formatter).
/// Formats a float with `decimals` decimal places, ROUNDED half away from zero
/// (2026-08-11: previously truncated via the old float_to_string, which itself
/// was fptosi-garbage -- see convert.xi; now delegates to the exact
/// scaled-integer formatter).
pub fn format_float_fixed(f: Float64, decimals: Int) -> Str {
  if decimals < 0 { return convert.float_to_string(f); }
  return convert.float_to_fixed_str(f, decimals);
}

// -- Simple Formatting --

// Converts a boolean to "true" or "false".
/// Converts a boolean to "true" or "false".
pub fn format_bool(b: Bool) -> Str {
  convert.bool_to_string(b)
}

// Left-aligns `s` within a field of `width` characters by right-padding with spaces.
/// Left-aligns `s` within a field of `width` characters by right-padding with spaces.
pub fn format_align_left(s: Str, width: Int) -> Str {
  string.str_pad_right(s, width, ' ')
}

// Right-aligns `s` within a field of `width` characters by left-padding with spaces.
/// Right-aligns `s` within a field of `width` characters by left-padding with spaces.
pub fn format_align_right(s: Str, width: Int) -> Str {
  string.str_pad_left(s, width, ' ')
}

// Joins `items` into a single string separated by `sep`.
// O(n * |sep|) where n = items.len().
/// Joins `items` into a single string separated by `sep`.
/// O(n * |sep|) where n = items.len().
pub fn format_join(items: &Vec[Str], sep: Str) -> Str {
  if items.len() == 0 {
    return "";
  };
  var result = items[0];
  var i: Int = 1;
  while i < items.len() {
    result = string.str_concat(string.str_concat(result, sep), items[i]);
    i = i + 1;
  };
  result
}

// Repeats `s` `n` times. Delegates to string.str_repeat.
/// Repeats `s` `n` times. Delegates to string.str_repeat.
pub fn format_repeat(s: Str, n: Int) -> Str {
  string.str_repeat(s, n)
}

// Formats a line with a prefix and body, separated by ": ".
// Useful for key-value display: format_line("Name", "Alice") -> "Name: Alice"
/// Formats a line with a prefix and body, separated by ": ".
/// Useful for key-value display: format_line("Name", "Alice") -> "Name: Alice"
pub fn format_line(prefix: Str, body: Str) -> Str {
  string.str_concat(string.str_concat(prefix, ": "), body)
}

// ============================================================================
//  printf-style formatting -- sprintf / sscanf (G13, 2026-08-11)
// ============================================================================
// Pure-XIOM C-style format engine. Conversions:
//   %d %i signed decimal - %u unsigned decimal - %x/%X hex (negatives wrap
//   to 64-bit two's complement, C-style) - %o octal - %b binary - %f fixed -
//   %e/%E scientific - %g/%G C-style shortest - %s string - %% literal '%'.
// Flags: `-` left-align, `0` zero-pad, `+` force sign, ` ` space sign.
// Width: minimum field width (digits after flags). Precision `.N`: minimum
// digit count for ints, fraction digits for %f/%e, significant digits for
// %g, max chars for %s. All errors are returned as Err -- no silent failures
// (wrong conversion family, missing args, malformed spec). XIOM has no
// variadics, so the typed families sprintf_i* / sprintf_f* / sprintf_s* are
// provided; the shared engine rejects mixed families at runtime.

// ---- private helpers ------------------------------------------------------

// Codepoint at byte index i (-1 if out of range).
fn _code(s: Str, i: Int) -> Int {
  let ch = string.char_at(s, i);
  if ch.is_some {
    return convert.char_to_int(ch.value);
  }
  return -1;
}

fn _is_digit(c: Int) -> Bool {
  return c >= 48 && c <= 57;
}

fn _is_hex_digit(c: Int) -> Bool {
  return (c >= 48 && c <= 57) || (c >= 97 && c <= 102) || (c >= 65 && c <= 70);
}

fn _hex_val(c: Int) -> Int {
  if c >= 48 && c <= 57 { return c - 48; }
  if c >= 97 && c <= 102 { return c - 87; }
  if c >= 65 && c <= 70 { return c - 55; }
  return -1;
}

fn _digit_str(d: Int, upper: Bool) -> Str {
  var alpha = "0123456789abcdef";
  if upper { alpha = "0123456789ABCDEF"; }
  return string.str_slice(alpha, d, d + 1);
}

// Unsigned 64-bit -> base-N digit string (exact for 0..2^64-1; uses the
// unsigned division helpers from xiom.num because UInt64 `/` lowers signed).
fn _u64_to_base(v: UInt64, base: Int, upper: Bool) -> Str {
  if v == 0 { return "0"; }
  var out = "";
  var b = base as UInt64;
  while v != 0 {
    var d = xiom.num.u64_mod_euclid(v, b);
    out = string.str_concat(_digit_str(d as Int, upper), out);
    v = xiom.num.u64_div_floor(v, b);
  }
  return out;
}

// Non-negative i64 -> base-N digit string (digit-abs trick keeps INT_MIN safe).
fn _i64_to_base(val: Int, base: Int, upper: Bool) -> Str {
  if val == 0 { return "0"; }
  var out = "";
  var n = val;
  while n != 0 {
    var d = n % base;
    if d < 0 { d = 0 - d; }
    out = string.str_concat(_digit_str(d, upper), out);
    n = n / base;
  }
  return out;
}

// Named struct instead of a (Str, Bool) tuple -- mixed-primitive tuples in
// catalog modules collide in codegen type resolution (COMPILER_BUGS.md quirk
// family; pure-Int tuples like bits.unpack_u16_le are proven safe).
type IntRepr = { digits: Str; neg: Bool; }

// Token-matcher result (same rationale as IntRepr).
type MatchTok = { text: Str; next: Int; ok: Bool; }

// (digits, negative?) for conv codes: 0=d/i, 1=u, 2=x, 3=X, 4=o, 5=b.
fn _int_repr(val: Int, conv: Int, upper: Bool) -> IntRepr {
  if conv == 1 {
    return IntRepr{ digits: _u64_to_base(val as UInt64, 10, false); neg: false; };
  }
  if conv == 2 || conv == 3 {
    if val < 0 {
      return IntRepr{ digits: _u64_to_base(val as UInt64, 16, upper); neg: false; };
    }
    return IntRepr{ digits: _i64_to_base(val, 16, upper); neg: false; };
  }
  if conv == 4 {
    return IntRepr{ digits: _i64_to_base(val, 8, false); neg: false; };
  }
  if conv == 5 {
    return IntRepr{ digits: _i64_to_base(val, 2, false); neg: false; };
  }
  if val < 0 {
    return IntRepr{ digits: _i64_to_base(0 - val, 10, false); neg: true; };
  }
  return IntRepr{ digits: _i64_to_base(val, 10, false); neg: false; };
}

// Assemble a numeric field: sign (per flags) + zero-padding (min digits or
// `0` flag) + digits + space padding to width (left if `-` flag).
fn _fmt_numeric(digits: Str, neg: Bool, flags: Int, width: Int, prec: Int) -> Str {
  var sign = "";
  if neg { sign = "-"; }
  elif (flags & 4) == 4 { sign = "+"; }
  elif (flags & 8) == 8 { sign = " "; }
  var dlen = string.str_len(digits);
  var zeros: Int = 0;
  if prec > dlen { zeros = prec - dlen; }
  if (flags & 2) == 2 && (flags & 1) == 0 {
    var total = width - string.str_len(sign);
    if total > dlen + zeros { zeros = total - dlen; }
  }
  var body = sign;
  var k: Int = 0;
  while k < zeros {
    body = string.str_concat(body, "0");
    k = k + 1;
  }
  body = string.str_concat(body, digits);
  var blen = string.str_len(body);
  if width > blen {
    var pad = width - blen;
    var ps = "";
    var p: Int = 0;
    while p < pad {
      ps = string.str_concat(ps, " ");
      p = p + 1;
    }
    if (flags & 1) == 1 {
      body = string.str_concat(body, ps);
    } else {
      body = string.str_concat(ps, body);
    }
  }
  return body;
}

// %s field: precision caps the length, width pads (left with `-` flag).
fn _fmt_str(s: Str, flags: Int, width: Int, prec: Int) -> Str {
  var t = s;
  if prec >= 0 && string.str_len(t) > prec {
    t = string.str_slice(t, 0, prec);
  }
  var blen = string.str_len(t);
  if width <= blen { return t; }
  var pad = width - blen;
  var ps = "";
  var p: Int = 0;
  while p < pad {
    ps = string.str_concat(ps, " ");
    p = p + 1;
  }
  if (flags & 1) == 1 { return string.str_concat(t, ps); }
  return string.str_concat(ps, t);
}

// Remove trailing zeros in the fraction and any trailing '.' (for %g).
fn _strip_frac(s: Str) -> Str {
  var dot = string.index_of(s, ".");
  if dot.is_none {
    return s;
  }
  var i = string.str_len(s) - 1;
  while i >= 0 {
    var c = string.str_slice(s, i, i + 1);
    if c == "0" {
      i = i - 1;
    } else {
      break;
    }
  }
  if i >= 0 {
    var c2 = string.str_slice(s, i, i + 1);
    if c2 == "." {
      i = i - 1;
    }
  }
  if i < 0 { return "0"; }
  return string.str_slice(s, 0, i + 1);
}

// %e -> %E / %g -> %G: uppercase the exponent marker (mantissa has no letters).
fn _upper_e(s: Str) -> Str {
  return string.replace(s, "e", "E");
}

// %g/%G core for v >= 0: C semantics -- fixed when -4 <= exp10 < P, else
// scientific; trailing zeros stripped (matches C without the `#` flag).
fn _fmt_g(v: Float64, P: Int) -> Str {
  var e: Int = 0;
  if v != 0.0 {
    var t = v;
    while t >= 10.0 {
      t = t / 10.0;
      e = e + 1;
    }
    while t < 1.0 {
      t = t * 10.0;
      e = e - 1;
    }
  }
  if e >= -4 && e < P {
    var dec = P - 1 - e;
    if dec < 0 { dec = 0; }
    return _strip_frac(convert.float_to_fixed_str(v, dec));
  }
  var sci = convert.float_to_sci_str(v, P - 1);
  var idx = string.index_of(sci, "e");
  match idx {
    Some(ii) => {
      return string.str_concat(
        _strip_frac(string.str_slice(sci, 0, ii)),
        string.str_slice(sci, ii, string.str_len(sci)));
    };
    None => { return sci; };
  }
}

// Float conversions: conv 0=%f, 1=%F, 2=%e, 3=%E, 4=%g, 5=%G.
// prec < 0 -> default 6 (C default); %g maps 0 -> 1 (C rule).
fn _fmt_float(f: Float64, conv: Int, prec: Int, flags: Int, width: Int) -> Result[Str, Str] {
  var upper = conv == 3 || conv == 5;
  if f != f {
    var tok = "nan";
    if upper { tok = "NAN"; }
    return Ok(_fmt_str(tok, flags, width, -1));
  }
  if f > 1.7976931348623157e308 {
    return Ok(_fmt_str("inf", flags, width, -1));
  }
  if f < -1.7976931348623157e308 {
    return Ok(_fmt_str("-inf", flags, width, -1));
  }
  var neg = f < 0.0;
  var v = f;
  if neg { v = -f; }
  var p = prec;
  if p < 0 { p = 6; }
  var digits = "";
  if conv == 0 || conv == 1 {
    digits = convert.float_to_fixed_str(v, p);
  } elif conv == 2 || conv == 3 {
    if v == 0.0 {
      digits = string.str_concat(convert.float_to_fixed_str(0.0, p), "e+00");
    } else {
      digits = convert.float_to_sci_str(v, p);
    }
    if upper { digits = _upper_e(digits); }
  } else {
    var P = p;
    if P < 1 { P = 1; }
    digits = _fmt_g(v, P);
    if upper { digits = _upper_e(digits); }
  }
  return Ok(_fmt_numeric(digits, neg, flags, width, -1));
}

// ---- sprintf engine ---------------------------------------------------------
// mode: 0 = Int-only spec, 1 = Str-only spec, 2 = Float64-only spec.
// Floats arrive as two scalar params (fa/fb, fcount = 1 or 2) -- NOT a
// Vec[Float64]: element reads of float containers are broken in the current
// compiler (COMPILER_BUGS.md BUG 12: load i64 + sitofp). TODO(compiler):
// remove this note and restore a Vec[Float64] `sprintf_f` once BUG 12 lands.
// Returns Err on malformed specs, unknown conversions, wrong family or
// missing values (extra values are ignored, C-style).

// Parse "%[flags][width][.prec]" -> (flags, width, prec, next_index).
// Pure-Int tuple (proven shape, like bits.unpack_u32_le).
fn _parse_spec_head(spec: Str, j0: Int) -> (Int, Int, Int, Int) {
  var j = j0;
  var flags: Int = 0;
  var reading = true;
  while reading && j < string.str_len(spec) {
    var fc = _code(spec, j);
    if fc == 45 { flags = flags | 1; }
    elif fc == 48 { flags = flags | 2; }
    elif fc == 43 { flags = flags | 4; }
    elif fc == 32 { flags = flags | 8; }
    else { reading = false; }
    if reading { j = j + 1; }
  }
  var width: Int = 0;
  while j < string.str_len(spec) && _is_digit(_code(spec, j)) {
    width = width * 10 + (_code(spec, j) - 48);
    j = j + 1;
  }
  var prec: Int = -1;
  if j < string.str_len(spec) && _code(spec, j) == 46 {
    j = j + 1;
    prec = 0;
    while j < string.str_len(spec) && _is_digit(_code(spec, j)) {
      prec = prec * 10 + (_code(spec, j) - 48);
      j = j + 1;
    }
  }
  return (flags, width, prec, j);
}

fn _sprintf_engine(spec: Str, ints: &Vec[Int], strs: &Vec[Str], fa: Float64, fb: Float64, fcount: Int, mode: Int) -> Result[Str, Str] {
  var result = "";
  var i: Int = 0;
  var ii: Int = 0;
  var fi: Int = 0;
  var si: Int = 0;
  var len = string.str_len(spec);
  while i < len {
    var c = _code(spec, i);
    if c != 37 {
      result = string.str_concat(result, string.str_slice(spec, i, i + 1));
      i = i + 1;
    } else {
      var head = _parse_spec_head(spec, i + 1);
      var flags = head.0;
      var width = head.1;
      var prec = head.2;
      var j = head.3;
      if j >= len {
        return Err("sprintf: unterminated % conversion");
      }
      var conv = _code(spec, j);
      j = j + 1;
      if conv == 37 {
        result = string.str_concat(result, "%");
      } elif conv == 100 || conv == 105 || conv == 117 || conv == 120 || conv == 88 || conv == 111 || conv == 98 {
        if mode != 0 {
          return Err("sprintf: integer conversion needs an Int argument");
        }
        if ii >= ints.len() {
          return Err("sprintf: not enough Int arguments");
        }
        var ic: Int = 0;
        if conv == 117 { ic = 1; }
        elif conv == 120 { ic = 2; }
        elif conv == 88 { ic = 3; }
        elif conv == 111 { ic = 4; }
        elif conv == 98 { ic = 5; }
        var ir = _int_repr(ints[ii], ic, conv == 88);
        ii = ii + 1;
        result = string.str_concat(result, _fmt_numeric(ir.digits, ir.neg, flags, width, prec));
      } elif conv == 102 || conv == 70 || conv == 101 || conv == 69 || conv == 103 || conv == 71 {
        if mode != 2 {
          return Err("sprintf: float conversion needs a Float64 argument");
        }
        if fi >= fcount {
          return Err("sprintf: not enough Float64 arguments");
        }
        var fv = fa;
        if fi == 1 { fv = fb; }
        var fc2: Int = 0;
        if conv == 101 { fc2 = 2; }
        elif conv == 69 { fc2 = 3; }
        elif conv == 103 { fc2 = 4; }
        elif conv == 71 { fc2 = 5; }
        var ff = _fmt_float(fv, fc2, prec, flags, width);
        fi = fi + 1;
        match ff {
          Ok(v) => { result = string.str_concat(result, v); };
          Err(e) => { return Err(e); };
        }
      } elif conv == 115 {
        if mode != 1 {
          return Err("sprintf: %s needs a Str argument");
        }
        if si >= strs.len() {
          return Err("sprintf: not enough Str arguments");
        }
        result = string.str_concat(result, _fmt_str(strs[si], flags, width, prec));
        si = si + 1;
      } else {
        return Err("sprintf: unsupported conversion %" + string.str_slice(spec, j - 1, j));
      }
      i = j;
    }
  }
  return Ok(result);
}

// ---- sprintf public API -----------------------------------------------------

/// printf-style formatting of an Int-only spec. Supports %d/%i/%u/%x/%X/%o/%b
/// with flags/width/precision. Wrong conversion family or missing values -> Err.
pub fn sprintf_i(spec: Str, values: &Vec[Int]) -> Result[Str, Str] {
  return _sprintf_engine(spec, values, Vec[Str].new(), 0.0, 0.0, 0, 0);
}

/// printf-style formatting of a Str-only spec. Supports %s with width/
/// precision. Wrong conversion family or missing values -> Err.
pub fn sprintf_s(spec: Str, values: &Vec[Str]) -> Result[Str, Str] {
  return _sprintf_engine(spec, Vec[Int].new(), values, 0.0, 0.0, 0, 1);
}

/// sprintf_i with one Int argument: sprintf_i1("%05d", 42) == "00042".
pub fn sprintf_i1(spec: Str, a: Int) -> Result[Str, Str] {
  var v = Vec[Int].new();
  v.push(a);
  return _sprintf_engine(spec, &v, Vec[Str].new(), 0.0, 0.0, 0, 0);
}

/// sprintf_i with two Int arguments.
pub fn sprintf_i2(spec: Str, a: Int, b: Int) -> Result[Str, Str] {
  var v = Vec[Int].new();
  v.push(a);
  v.push(b);
  return _sprintf_engine(spec, &v, Vec[Str].new(), 0.0, 0.0, 0, 0);
}

/// sprintf_f with one Float64 argument: sprintf_f1("%.2f", 3.14159) == "3.14".
/// Supports %f/%F/%e/%E/%g/%G with flags/width/precision.
pub fn sprintf_f1(spec: Str, a: Float64) -> Result[Str, Str] {
  return _sprintf_engine(spec, Vec[Int].new(), Vec[Str].new(), a, 0.0, 1, 2);
}

/// sprintf_f with two Float64 arguments.
pub fn sprintf_f2(spec: Str, a: Float64, b: Float64) -> Result[Str, Str] {
  return _sprintf_engine(spec, Vec[Int].new(), Vec[Str].new(), a, b, 2, 2);
}

/// sprintf_s with one Str argument: sprintf_s1("%10s", "hi") == "        hi".
pub fn sprintf_s1(spec: Str, a: Str) -> Result[Str, Str] {
  var v = Vec[Str].new();
  v.push(a);
  return _sprintf_engine(spec, Vec[Int].new(), &v, 0.0, 0.0, 0, 1);
}

/// sprintf_s with two Str arguments.
pub fn sprintf_s2(spec: Str, a: Str, b: Str) -> Result[Str, Str] {
  var v = Vec[Str].new();
  v.push(a);
  v.push(b);
  return _sprintf_engine(spec, Vec[Int].new(), &v, 0.0, 0.0, 0, 1);
}

// ---- sscanf ------------------------------------------------------------------

// Captured tokens (parallel arrays: convs 0=int(%d/%i/%u), 1=hex(%x/%X),
// 2=float(%f/%e/%g), 3=str(%s), 4=char(%c)). Plain struct on purpose: the
// compiler's generic Result[Vec[struct], _] instantiation collides with
// Result[Int, _] in mono layout (docs/COMPILER_BUGS.md), so the engine
// returns a concrete named struct instead.
/// Captured tokens (parallel arrays: convs 0=int(%d/%i/%u), 1=hex(%x/%X),
/// 2=float(%f/%e/%g), 3=str(%s), 4=char(%c)). Plain struct on purpose: the
/// compiler's generic Result[Vec[struct], _] instantiation collides with
/// Result[Int, _] in mono layout (docs/COMPILER_BUGS.md), so the engine
/// returns a concrete named struct instead.
pub type ScanResult = { is_ok: Bool; convs: Vec[Int]; texts: Vec[Str]; error: Str; }

fn _skip_ws(s: Str, i: Int) -> Int {
  var j = i;
  while j < string.str_len(s) {
    var c = _code(s, j);
    if c == 32 || c == 9 || c == 10 || c == 13 || c == 11 || c == 12 {
      j = j + 1;
    } else {
      break;
    }
  }
  return j;
}

// Integer token (dec or hex): optional sign (+/-), then digits; hex also
// accepts an optional 0x/0X prefix. Width caps the characters consumed.
fn _match_int_tok(s: Str, i: Int, width: Int, hex: Bool) -> MatchTok {
  var len = string.str_len(s);
  var j = i;
  var n: Int = 0;
  var c = _code(s, j);
  if (c == 43 || c == 45) && (width == 0 || n < width) {
    j = j + 1;
    n = n + 1;
  }
  if hex && j + 1 < len && (width == 0 || n + 1 < width) && _code(s, j) == 48 && (_code(s, j + 1) == 120 || _code(s, j + 1) == 88) {
    j = j + 2;
    n = n + 2;
  }
  var any = false;
  while j < len && (width == 0 || n < width) {
    var c2 = _code(s, j);
    if hex {
      if !_is_hex_digit(c2) { break; }
    } elif !_is_digit(c2) {
      break;
    }
    any = true;
    j = j + 1;
    n = n + 1;
  }
  if !any { return MatchTok{ text: ""; next: i; ok: false; }; }
  return MatchTok{ text: string.str_slice(s, i, j); next: j; ok: true; };
}

// Float token (strtod-like): sign, digits, optional fraction, optional
// exponent; backs up over a dangling 'e' (C semantics). Width caps input.
fn _match_float_tok(s: Str, i: Int, width: Int) -> MatchTok {
  var len = string.str_len(s);
  var j = i;
  var n: Int = 0;
  var c = _code(s, j);
  if (c == 43 || c == 45) && (width == 0 || n < width) {
    j = j + 1;
    n = n + 1;
  }
  var before: Int = 0;
  while j < len && (width == 0 || n < width) && _is_digit(_code(s, j)) {
    j = j + 1;
    n = n + 1;
    before = before + 1;
  }
  if j < len && (width == 0 || n < width) && _code(s, j) == 46 {
    j = j + 1;
    n = n + 1;
  }
  var after: Int = 0;
  while j < len && (width == 0 || n < width) && _is_digit(_code(s, j)) {
    j = j + 1;
    n = n + 1;
    after = after + 1;
  }
  if before == 0 && after == 0 { return MatchTok{ text: ""; next: i; ok: false; }; }
  if j < len && (width == 0 || n < width) && (_code(s, j) == 101 || _code(s, j) == 69) {
    var save_j = j;
    var save_n = n;
    j = j + 1;
    n = n + 1;
    if j < len && (width == 0 || n < width) && (_code(s, j) == 43 || _code(s, j) == 45) {
      j = j + 1;
      n = n + 1;
    }
    var ed: Int = 0;
    while j < len && (width == 0 || n < width) && _is_digit(_code(s, j)) {
      j = j + 1;
      n = n + 1;
      ed = ed + 1;
    }
    if ed == 0 {
      j = save_j;
      n = save_n;
    }
  }
  return MatchTok{ text: string.str_slice(s, i, j); next: j; ok: true; };
}

// %s token: run of non-whitespace, width-capped.
fn _match_str_tok(s: Str, i: Int, width: Int) -> MatchTok {
  var j = i;
  var n: Int = 0;
  var len = string.str_len(s);
  while j < len && (width == 0 || n < width) {
    var c = _code(s, j);
    if c == 32 || c == 9 || c == 10 || c == 13 || c == 11 || c == 12 { break; }
    j = j + 1;
    n = n + 1;
  }
  if j == i { return MatchTok{ text: ""; next: i; ok: false; }; }
  return MatchTok{ text: string.str_slice(s, i, j); next: j; ok: true; };
}

fn _sscanf_engine(input: Str, spec: Str) -> ScanResult {
  var convs = Vec[Int].new();
  var texts = Vec[Str].new();
  var failed = false;
  var errmsg = "";
  var i: Int = 0;
  var j: Int = 0;
  var ilen = string.str_len(input);
  var slen = string.str_len(spec);
  while j < slen && !failed {
    var c = _code(spec, j);
    if c == 32 || c == 9 || c == 10 || c == 13 || c == 11 || c == 12 {
      while j < slen {
        var c2 = _code(spec, j);
        if c2 == 32 || c2 == 9 || c2 == 10 || c2 == 13 || c2 == 11 || c2 == 12 {
          j = j + 1;
        } else {
          break;
        }
      }
      i = _skip_ws(input, i);
    } elif c == 37 {
      j = j + 1;
      if j >= slen {
        failed = true;
        errmsg = "sscanf: unterminated % directive";
      } else {
        var width: Int = 0;
        while j < slen && _is_digit(_code(spec, j)) {
          width = width * 10 + (_code(spec, j) - 48);
          j = j + 1;
        }
        var suppress = false;
        if j < slen && _code(spec, j) == 42 {
          suppress = true;
          j = j + 1;
        }
        if j >= slen {
          failed = true;
          errmsg = "sscanf: missing conversion character";
        } else {
          var conv = _code(spec, j);
          j = j + 1;
          if conv == 37 {
            if i < ilen && _code(input, i) == 37 {
              i = i + 1;
            } else {
              failed = true;
              errmsg = "sscanf: expected '%%' at input offset " + convert.int_to_string(i);
            }
          } else {
            // C semantics: %d/%x/%f (numeric) skip leading whitespace;
            // %s/%c do not.
            if conv == 100 || conv == 105 || conv == 117 || conv == 120 || conv == 88 || conv == 102 || conv == 101 || conv == 103 {
              i = _skip_ws(input, i);
            }
            var matched: Str = "";
            var nxt: Int = i;
            var ok = false;
            var tok_conv: Int = 0;
            if conv == 100 || conv == 105 || conv == 117 {
              var r = _match_int_tok(input, i, width, false);
              matched = r.text;
              nxt = r.next;
              ok = r.ok;
              tok_conv = 0;
            } elif conv == 120 || conv == 88 {
              var r2 = _match_int_tok(input, i, width, true);
              matched = r2.text;
              nxt = r2.next;
              ok = r2.ok;
              tok_conv = 1;
            } elif conv == 102 || conv == 101 || conv == 103 {
              var r3 = _match_float_tok(input, i, width);
              matched = r3.text;
              nxt = r3.next;
              ok = r3.ok;
              tok_conv = 2;
            } elif conv == 115 {
              var r4 = _match_str_tok(input, i, width);
              matched = r4.text;
              nxt = r4.next;
              ok = r4.ok;
              tok_conv = 3;
            } elif conv == 99 {
              var w = width;
              if w == 0 { w = 1; }
              if i + w > ilen {
                failed = true;
                errmsg = "sscanf: %c needs " + convert.int_to_string(w) + " chars at input offset " + convert.int_to_string(i);
              } else {
                matched = string.str_slice(input, i, i + w);
                nxt = i + w;
                ok = true;
                tok_conv = 4;
              }
            } else {
              failed = true;
              errmsg = "sscanf: unsupported conversion at spec offset " + convert.int_to_string(j - 1);
            }
            if !failed {
              if !ok {
                failed = true;
                errmsg = "sscanf: no match for conversion at input offset " + convert.int_to_string(i);
              } else {
                if !suppress {
                  convs.push(tok_conv);
                  texts.push(matched);
                }
                i = nxt;
              }
            }
          }
        }
      }
    } else {
      if i >= ilen {
        failed = true;
        errmsg = "sscanf: input exhausted at spec offset " + convert.int_to_string(j);
      } elif _code(input, i) != c {
        failed = true;
        errmsg = "sscanf: literal mismatch at input offset " + convert.int_to_string(i);
      } else {
        i = i + 1;
        j = j + 1;
      }
    }
  }
  return ScanResult{ is_ok: !failed; convs: convs; texts: texts; error: errmsg; };
}

// Parse a signed decimal token with overflow checking (no silent wraparound).
fn _parse_dec_token(t: Str) -> Result[Int, Str] {
  var neg = false;
  var i: Int = 0;
  var len = string.str_len(t);
  if len == 0 { return Err("sscanf_ints: empty token"); }
  var c0 = _code(t, 0);
  if c0 == 43 {
    i = 1;
  } elif c0 == 45 {
    i = 1;
    neg = true;
  }
  var v: Int = 0;
  while i < len {
    var c = _code(t, i);
    if !_is_digit(c) { return Err("sscanf_ints: invalid digit in '" + t + "'"); }
    var d = c - 48;
    if v > 922337203685477580 {
      return Err("sscanf_ints: integer overflow in '" + t + "'");
    }
    if v == 922337203685477580 && d > 7 {
      return Err("sscanf_ints: integer overflow in '" + t + "'");
    }
    if v == 922337203685477580 && d == 8 && !neg {
      return Err("sscanf_ints: integer overflow in '" + t + "'");
    }
    v = v * 10 + d;
    i = i + 1;
  }
  if neg { v = 0 - v; }
  return Ok(v);
}

// Parse a signed hex token (optional 0x prefix) with overflow checking.
fn _parse_hex_token(t: Str) -> Result[Int, Str] {
  var neg = false;
  var i: Int = 0;
  var len = string.str_len(t);
  if len == 0 { return Err("sscanf_ints: empty token"); }
  var c0 = _code(t, 0);
  if c0 == 43 {
    i = 1;
  } elif c0 == 45 {
    i = 1;
    neg = true;
  }
  if i + 1 < len && _code(t, i) == 48 && (_code(t, i + 1) == 120 || _code(t, i + 1) == 88) {
    i = i + 2;
  }
  var v: Int = 0;
  var any = false;
  while i < len {
    var c = _code(t, i);
    var d = _hex_val(c);
    if d < 0 { return Err("sscanf_ints: invalid hex digit in '" + t + "'"); }
    any = true;
    if v > 576460752303423487 {
      return Err("sscanf_ints: integer overflow in '" + t + "'");
    }
    v = v * 16 + d;
    i = i + 1;
  }
  if !any { return Err("sscanf_ints: empty hex token"); }
  if neg { v = 0 - v; }
  return Ok(v);
}

// Normalize ".5"/"+.5"/"-.5" so the builtin float parser accepts them.
fn _normalize_float_token(t: Str) -> Str {
  var c0 = _code(t, 0);
  if c0 == 46 {
    return string.str_concat("0", t);
  }
  if (c0 == 43 || c0 == 45) && string.str_len(t) > 1 && _code(t, 1) == 46 {
    return string.str_concat(string.str_slice(t, 0, 1), string.str_concat("0", string.str_slice(t, 1, string.str_len(t))));
  }
  return t;
}

/// scanf-style scan of `s` per `spec`: literal chars match exactly, spec
/// whitespace skips any input whitespace run. Conversions: %d/%i/%u (dec),
/// %x/%X (hex, optional 0x), %f/%e/%g (float, optional exponent), %s (token),
/// %c (exact chars incl. whitespace), width caps, `*` suppresses, %% literal.
/// Returns the captured token strings in order, Err on any mismatch.
pub fn sscanf(s: Str, spec: Str) -> Result[Vec[Str], Str] {
  var res = _sscanf_engine(s, spec);
  if !res.is_ok {
    return Err(res.error);
  }
  return Ok(res.texts);
}

/// sscanf + typed integer extraction: converts %d/%i/%u (decimal) and %x/%X
/// (hex) tokens to Int with overflow checking. Non-integer conversions in the
/// spec -> Err. The returned Vec is in token order.
pub fn sscanf_ints(s: Str, spec: Str) -> Result[Vec[Int], Str] {
  var res = _sscanf_engine(s, spec);
  if !res.is_ok {
    return Err(res.error);
  }
  var out = Vec[Int].new();
  var k: Int = 0;
  while k < res.convs.len() {
    if res.convs[k] == 0 {
      var parsed = _parse_dec_token(res.texts[k]);
      match parsed {
        Err(e2) => { return Err(e2); };
        Ok(v) => { out.push(v); };
      }
    } elif res.convs[k] == 1 {
      var parsed2 = _parse_hex_token(res.texts[k]);
      match parsed2 {
        Err(e3) => { return Err(e3); };
        Ok(v2) => { out.push(v2); };
      }
    } else {
      return Err("sscanf_ints: conversion " + convert.int_to_string(res.convs[k]) + " is not an integer");
    }
    k = k + 1;
  }
  return Ok(out);
}

// Float results of sscanf_floats. Fixed 8 scalar slots instead of a
// Vec[Float64] (BUG 12: float container element reads broken -- TODO(compiler)
// restore a Vec-based API once fixed). Specs with more than 8 float
// conversions -> is_ok = false ("too many float conversions").
/// Float results of sscanf_floats. Fixed 8 scalar slots instead of a
/// Vec[Float64] (BUG 12: float container element reads broken -- TODO(compiler)
/// restore a Vec-based API once fixed). Specs with more than 8 float
/// conversions -> is_ok = false ("too many float conversions").
pub type FloatScan = {
  is_ok: Bool;
  count: Int;
  v0: Float64;
  v1: Float64;
  v2: Float64;
  v3: Float64;
  v4: Float64;
  v5: Float64;
  v6: Float64;
  v7: Float64;
  error: Str;
}

fn _scan_ok(count: Int, v0: Float64, v1: Float64, v2: Float64, v3: Float64, v4: Float64, v5: Float64, v6: Float64, v7: Float64) -> FloatScan {
  return FloatScan{ is_ok: true; count: count; v0: v0; v1: v1; v2: v2; v3: v3; v4: v4; v5: v5; v6: v6; v7: v7; error: ""; };
}

fn _scan_err(msg: Str) -> FloatScan {
  return FloatScan{ is_ok: false; count: 0; v0: 0.0; v1: 0.0; v2: 0.0; v3: 0.0; v4: 0.0; v5: 0.0; v6: 0.0; v7: 0.0; error: msg; };
}

/// sscanf + typed float extraction: converts %f/%e/%g tokens to Float64
/// (normalized ".5" -> "0.5" for the builtin parser). Non-float conversions
/// in the spec or more than 8 float conversions -> is_ok = false with error.
/// Values land in v0..v7 in token order; `count` says how many are valid.
pub fn sscanf_floats(s: Str, spec: Str) -> FloatScan {
  var res = _sscanf_engine(s, spec);
  if !res.is_ok {
    return _scan_err(res.error);
  }
  var n: Int = 0;
  var k: Int = 0;
  while k < res.convs.len() {
    if res.convs[k] == 2 {
      n = n + 1;
    }
    k = k + 1;
  }
  if n > 8 {
    return _scan_err("sscanf_floats: more than 8 float conversions");
  }
  var values: FloatScan = _scan_ok(0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
  var idx: Int = 0;
  var k2: Int = 0;
  while k2 < res.convs.len() {
    if res.convs[k2] != 2 {
      return _scan_err("sscanf_floats: conversion " + convert.int_to_string(res.convs[k2]) + " is not a float");
    }
    var norm = _normalize_float_token(res.texts[k2]);
    var parsed = xiom.num.parse_float(norm);
    match parsed {
      Err(e2) => { return _scan_err(e2); };
      Ok(v) => {
        if idx == 0 { values.v0 = v; }
        elif idx == 1 { values.v1 = v; }
        elif idx == 2 { values.v2 = v; }
        elif idx == 3 { values.v3 = v; }
        elif idx == 4 { values.v4 = v; }
        elif idx == 5 { values.v5 = v; }
        elif idx == 6 { values.v6 = v; }
        else { values.v7 = v; }
        idx = idx + 1;
      };
    }
    k2 = k2 + 1;
  }
  values.count = idx;
  return values;
}


