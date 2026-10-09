// p_wave98_tostring_shapes.xi -- wave 98 companion: to_string_char contracts
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Companion to p_wave98_shapes.xi. Kept separate because importing
// xiom.convert.tostring corrupts closure predicate dispatch in iter
// adapters on v0.64.2 (filed as
// tools/known_failures/p_tostring_import_breaks_adapters.xi); this probe
// avoids iter entirely.
//
// Exercises the wave-98 to_string_char clauses:
//   - every non-NUL code point yields a >= 1 byte string ('A' -> "A",
//     '9' -> "9");
//   - U+0000 yields "" (documented NUL truncation of the string backend,
//     replacing the old false `result.len() >= 1` claim).
// Values returned from the module surface are bound before comparing.
// Returns 0 when every case holds.

module p_wave98_tostring_shapes

use xiom.convert.tostring as tostring;

fn main() -> Int {
  let ca = tostring.to_string_char('A');
  if ca.len() != 1 { return 1; }
  if ca != "A" { return 2; }
  let ci = tostring.to_string_char('9');
  if ci.len() != 1 { return 3; }
  if ci != "9" { return 4; }
  let cz = tostring.to_string_char('\0');
  if cz.len() != 0 { return 5; }
  return 0;
}
