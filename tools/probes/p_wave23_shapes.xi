// p_wave23_shapes.xi -- contract shape validation for wave 23 (convert).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the shapes wave 23 applies to xiom.convert.escape and
// xiom.convert.validate:
// 1. escape length lower bound: `result.len() >= s.len()`
// 2. unescape length upper bound: `result.len() <= s.len()`
// 3. quoting wrapper arithmetic: `result.len() >= s.len() + 2`
// 4. short-circuit Boolean guards: `s.len() < 3 => result == false`
// 5. disjunctive length guards on a Bool result:
//    `s.len() != 8 && s.len() != 11 => result == false`
// 6. empty-string guard on a Str result: `s.len() < 2 => result.len() == 0`
// main() drives the real functions and asserts the properties the clauses
// will require. Returns 0 when every shape compiles and holds.

module p_wave23_shapes

use xiom.convert.escape;
use xiom.convert.validate;

// Shape 1: escape lower bound.
fn s_html_escape(s: Str) -> Str
  ensures: result.len() >= s.len()
{
  return escape.html_escape(s);
}

// Shape 2: unescape upper bound.
fn s_html_unescape(s: Str) -> Str
  ensures: result.len() <= s.len()
{
  return escape.html_unescape(s);
}

// Shape 2 + 1: token-level escape round-trip shapes.
fn s_tsv_escape(s: Str) -> Str
  ensures: result.len() >= s.len()
{
  return escape.tsv_escape_field(s);
}

fn s_tsv_unescape(s: Str) -> Str
  ensures: result.len() <= s.len()
{
  return escape.tsv_unescape_field(s);
}

// Shape 3: quoting wrapper arithmetic.
fn s_shell_quote(s: Str) -> Str
  ensures: result.len() >= s.len() + 2
{
  return escape.shell_quote(s);
}

fn s_cmd_quote(s: Str) -> Str
  ensures: result.len() >= s.len() + 2
{
  return escape.cmd_quote(s);
}

// Shape 4: short-circuit Boolean guard.
fn s_email(s: Str) -> Bool
  ensures: s.len() < 3 => result == false
{
  return validate.is_valid_email(s);
}

fn s_credit_card(s: Str) -> Bool
  ensures: s.len() < 13 => result == false
{
  return validate.is_valid_credit_card(s);
}

// Shape 5: disjunctive length guard.
fn s_swift(s: Str) -> Bool
  ensures: s.len() != 8 && s.len() != 11 => result == false
{
  return validate.is_valid_swift(s);
}

fn s_hex_color(s: Str) -> Bool
  ensures: s.len() != 4 && s.len() != 7 && s.len() != 9 => result == false
{
  return validate.is_valid_hex_color(s);
}

// Shape 6: empty-input guard on a Str result.
fn s_iban_country(s: Str) -> Str
  ensures: s.len() < 2 => result.len() == 0
{
  return validate.iban_country_code(s);
}

fn s_phone(s: Str) -> Bool
  ensures: s.len() == 0 => result == false
{
  return validate.is_valid_phone(s);
}

fn main() -> Int {
  let e1 = s_html_escape("<a>");
  if e1.len() < 3 { return 1; }
  let e2 = s_html_unescape("&lt;");
  if e2.len() > 4 { return 2; }
  let e3 = s_tsv_escape("a\tb");
  if e3.len() < 3 { return 3; }
  let e4 = s_tsv_unescape("a\\tb");
  if e4.len() > 4 { return 4; }
  let e5 = s_shell_quote("a'b");
  if e5.len() < 5 { return 5; }
  let e6 = s_cmd_quote("a\"b");
  if e6.len() < 5 { return 6; }
  if s_email("ab") { return 7; }
  if s_credit_card("123") { return 8; }
  if s_swift("ABCDEFG") { return 9; }
  if s_hex_color("#12345") { return 10; }
  let e11 = s_iban_country("X");
  if e11.len() != 0 { return 11; }
  if s_phone("") { return 12; }
  return 0;
}
