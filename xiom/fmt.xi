// XIOM — Formatting & Display
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.fmt

use xiom.string;
use xiom.convert;
use xiom.io;

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

// ──────────────────────────────────────────────────
//  Extended Formatting Functions
// ──────────────────────────────────────────────────

// ── Table ──

// Formats a simple aligned-column table with `|` separators.
// O(r * c). No padding — cells are left-aligned as-is.
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

// ── Columns ──

// Arranges `items` into multiple columns, wrapping at `width`.
// Items are placed column-by-column (top-to-bottom then left-to-right).
// O(n) where n = items.len().
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

// ── Wrap ──

// Wraps `text` at word boundaries to fit within `width` characters.
// Words longer than `width` are placed on their own line.
// O(n) where n = |text|.
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

// ── Indent ──

// Adds `spaces` spaces at the beginning of each line in `text`.
// O(n + lines * spaces).
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

// ── Hexdump ──

// Formats a byte buffer as a classic hexdump: offset, hex bytes, ASCII preview.
// `width` controls bytes per line (default 16). Returns multi-line string.
// O(n) where n = data.len().
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

// ── Number Formatting ──

// Zero-pads integer `n` to `width` digits. Negative numbers are handled
// (the sign is not counted in the width). Returns the string representation.
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

// Formats a float with `decimals` decimal places. Uses string manipulation
// of the output of float_to_string. If the float representation already has
// enough digits, it is truncated; otherwise zeros are appended.
pub fn format_float_fixed(f: Float64, decimals: Int) -> Str {
  var s = convert.float_to_string(f);
  if decimals <= 0 {
    var dot_idx = string.index_of(s, ".");
    match dot_idx {
      Some(dot) => { return string.str_slice(s, 0, dot); };
      None => { return s; };
    };
  };
  var dot_opt = string.index_of(s, ".");
  var int_part = s;
  var frac_part = "";
  match dot_opt {
    Some(dot) => {
      int_part = string.str_slice(s, 0, dot);
      frac_part = string.str_slice(s, dot + 1, s.len());
    };
    None => {};
  };
  if frac_part.len() > decimals {
    frac_part = string.str_slice(frac_part, 0, decimals);
  };
  var zi: Int = frac_part.len();
  while zi < decimals {
    frac_part = string.str_concat(frac_part, "0");
    zi = zi + 1;
  };
  string.str_concat(string.str_concat(int_part, "."), frac_part)
}

// ── Simple Formatting ──

// Converts a boolean to "true" or "false".
pub fn format_bool(b: Bool) -> Str {
  convert.bool_to_string(b)
}

// Left-aligns `s` within a field of `width` characters by right-padding with spaces.
pub fn format_align_left(s: Str, width: Int) -> Str {
  string.str_pad_right(s, width, ' ')
}

// Right-aligns `s` within a field of `width` characters by left-padding with spaces.
pub fn format_align_right(s: Str, width: Int) -> Str {
  string.str_pad_left(s, width, ' ')
}

// Joins `items` into a single string separated by `sep`.
// O(n * |sep|) where n = items.len().
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
pub fn format_repeat(s: Str, n: Int) -> Str {
  string.str_repeat(s, n)
}

// Formats a line with a prefix and body, separated by ": ".
// Useful for key-value display: format_line("Name", "Alice") -> "Name: Alice"
pub fn format_line(prefix: Str, body: Str) -> Str {
  string.str_concat(string.str_concat(prefix, ": "), body)
}
