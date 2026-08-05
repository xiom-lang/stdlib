// XIOM — Formatting & Display
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.fmt

use xiom.string;
use xiom.convert;

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
