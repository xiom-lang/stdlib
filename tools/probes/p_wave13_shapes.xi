// p_wave13_shapes.xi -- contract shape validation for wave 13.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the clause shapes wave 13 actually applies to the stdlib:
// 1. bare `result is Ok` across Result payload types in one module
//    (Str / Vec[UInt8] / Unit) -- no payload read, safe by construction
// 2. `result is Ok => w.buf.len() == 0` (mutation-visible param field)
// 3. `result == param.field` (result vs param field, post-state)
// 4. `s.len() == 0 => result.len() == 0` (empty-input implication)
//
// NOTE: the *payload-reading* Result forms are BLOCKED by the compiler
// interaction reproduced in tools/known_failures/p_result_payload_contract.xi
// (scalar payload contract + Vec payload contract in one module -> clang
// type mismatch), so this wave does not use them.
// Returns 0 when every shape compiles and holds at runtime.

module p_wave13_shapes

type EBox = {
  inner: Int;
}

type EWriter = {
  buf: Vec[Int];
}

// Shape 1: bare `result is Ok` on three different payload types.
fn b_str() -> Result[Str, Str]
  ensures: result is Ok
{
  return Ok("ok");
}

fn b_vec() -> Result[Vec[UInt8], Str]
  ensures: result is Ok
{
  return Ok(Vec[UInt8].new());
}

fn b_unit() -> Result[Unit, Str]
  ensures: result is Ok
{
  return Ok(());
}

// Shape 2: param field relation after mutation.
fn e_flush(w: &mut EWriter) -> Result[Unit, Str]
  ensures: result is Ok => w.buf.len() == 0
{
  while w.buf.len() > 0 {
    w.buf.pop();
  }
  return Ok(());
}

// Shape 3: result equals a param field.
fn e_inner(b: &EBox) -> Int
  ensures: result == b.inner
{
  return b.inner;
}

// Shape 4: empty input implies empty result.
fn e_empty(s: Str) -> Str
  ensures: s.len() == 0 => result.len() == 0
{
  return s;
}

fn main() -> Int {
  match b_str() { Ok(v) => { if v.len() != 2 { return 1; } }, Err(e) => { return 2; } }
  match b_vec() { Ok(v) => { if v.len() != 0 { return 3; } }, Err(e) => { return 4; } }
  match b_unit() { Ok(()) => {}, Err(e) => { return 5; } }

  var w = EWriter{ buf: Vec[Int].new() };
  w.buf.push(1);
  w.buf.push(2);
  match e_flush(&mut w) { Ok(()) => {}, Err(e) => { return 6; } }
  if w.buf.len() != 0 { return 7; }

  var b = EBox{ inner: 5 };
  if e_inner(&b) != 5 { return 8; }
  if e_empty("").len() != 0 { return 9; }
  return 0;
}
