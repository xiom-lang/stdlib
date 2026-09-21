// p_char_specs2.xi -- wave-5 contract-shape validation for the char alias /
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// classification family. Sweeps codes 0..0x2800 plus the emoji and separator
// blocks; every ensures mirrors the body and aborts on any disagreement.
module p_char_specs2
use xiom.char;
use xiom.io;

fn hit(c: Char) -> Int {
  var n = 0;
  if char.is_alphanumeric(c) { n = n + 1; };
  if char.is_letter(c) { n = n + 1; };
  if char.is_control_char(c) { n = n + 1; };
  if char.is_hex_digit(c) { n = n + 1; };
  if char.is_binary_digit(c) { n = n + 1; };
  if char.is_octal_digit(c) { n = n + 1; };
  if char.is_currency(c) { n = n + 1; };
  if char.is_math_symbol(c) { n = n + 1; };
  if char.is_emoji(c) { n = n + 1; };
  if char.is_combining_mark(c) { n = n + 1; };
  if char.is_symbol(c) { n = n + 1; };
  if char.is_ascii_letter(c) { n = n + 1; };
  if char.is_ascii_digit(c) { n = n + 1; };
  if char.is_ascii_hex_digit(c) { n = n + 1; };
  if char.is_ascii_punctuation(c) { n = n + 1; };
  if char.is_ascii_whitespace(c) { n = n + 1; };
  if char.is_ascii_control(c) { n = n + 1; };
  if char.is_ascii_graphic(c) { n = n + 1; };
  if char.is_ascii_printable(c) { n = n + 1; };
  if char.is_uppercase_ascii(c) { n = n + 1; };
  if char.is_lowercase_ascii(c) { n = n + 1; };
  if char.is_whitespace_or_separator(c) { n = n + 1; };
  var up = char.to_ascii_upper(c);
  var lo = char.to_ascii_lower(c);
  if up == lo && up != c { n = n + 1; };  // touch results; contract already validated
  n
}

fn main() -> Int {
  var total = 0;
  var code = 0;
  while code <= 0x2800 {
    total = total + hit(to_char(code));
    code = code + 1;
  };
  total = total + hit(to_char(0x1F300));
  total = total + hit(to_char(0x1F600));
  total = total + hit(to_char(0x1F680));
  total = total + hit(to_char(0x1F900));
  total = total + hit(to_char(0x2028));
  total = total + hit(to_char(0x2029));
  total = total + hit(to_char(0x20A0));
  total = total + hit(to_char(0x22FF));

  io.println("P_CHAR_SPECS2 OK");
  io.flush_stdout();
  0
}
