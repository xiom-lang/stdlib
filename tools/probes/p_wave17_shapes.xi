// p_wave17_shapes.xi -- contract shape validation for wave 17.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the payload-reading Result shapes wave 17 applies to the io modules:
// 1. `result is Err => result.value.len() > 0` (Str payload, non-empty error)
// 2. `result is Ok => result.value >= 0` (Int payload bound)
// 3. `result is Ok && n >= 0 => result.value.len() <= n` (Vec payload bound
//    against a parameter)
// 4. `result is Ok && n <= 0 => result.value.len() == 0` (Vec payload, zero
//    count)
// 5. bare `result is Ok` on a Result that never fails
// 6. `result == false` on a documented-simulation Bool
// The mixed Int + Vec + Str payload contracts in ONE module are exactly what
// R49-3 unlocked (repro history: tools/probes/p_result_payload_contract.xi);
// keep the combination. main() also drives the real io paths that will carry
// the clauses (Err payloads, bounded range reads, simulated tty flag).
// Returns 0 when every shape compiles and holds at runtime.

module p_wave17_shapes

use xiom.io.fs;
use xiom.io.pipe;
use xiom.io.console;

// Shape 1: Err payload is a non-empty Str.
fn s_err(p: Str) -> Result[Str, Str]
  ensures: result is Err => result.value.len() > 0
{
  return Err("failed: " + p);
}

// Shape 2: Ok payload Int bound (scalar payload in a mixed-payload module).
fn s_int(n: Int) -> Result[Int, Str]
  ensures: result is Ok => result.value >= 0
{
  if n < 0 { return Err("negative"); }
  return Ok(n);
}

// Shapes 3+4: Vec payload bounded by a parameter (both implication forms).
fn s_vec(n: Int) -> Result[Vec[UInt8], Str]
  ensures: result is Ok && n >= 0 => result.value.len() <= n
  ensures: result is Ok && n <= 0 => result.value.len() == 0
{
  var v: Vec[UInt8] = Vec[UInt8].new();
  var i = 0;
  while i < n {
    v.push(65 as UInt8);
    i = i + 1;
  }
  return Ok(v);
}

// Shape 5: bare Ok on a never-failing Result.
fn s_always_ok() -> Result[Str, Str]
  ensures: result is Ok
{
  return Ok("ok");
}

// Shape 6: documented-simulation Bool.
fn s_false() -> Bool
  ensures: result == false
{
  return false;
}

fn main() -> Int {
  let e = s_err("x");
  if e is Ok { return 1; }
  let a = s_int(5);
  if a is Err { return 2; }
  let b = s_vec(3);
  if b is Err { return 3; }
  let c = s_always_ok();
  if c is Err { return 4; }
  if s_false() { return 5; }

  // Real io paths backing the wave-17 clauses.
  let miss = fs.fs_read_range("xiom_no_such_file_p_wave17", 0, 8);
  if miss is Ok { return 6; }
  let sz = fs.fs_size("xiom_no_such_file_p_wave17");
  if sz is Ok { return 7; }
  if console.console_is_tty() { return 8; }
  // A real pipe round-trip (a bogus fd makes the MSVC CRT fast-fail with
  // 0xC0000409 inside _read, not a codegen path worth exercising here).
  var p = pipe.pipe_create();
  if p.0 < 0 { return 9; }
  var payload: Vec[UInt8] = Vec[UInt8].new();
  payload.push(65 as UInt8);
  let w = pipe.pipe_write(p.1, &payload);
  if w is Err { return 10; }
  var sink: Vec[UInt8] = Vec[UInt8].new();
  let pr = pipe.pipe_read(p.0, &mut sink);
  if pr is Err { return 11; }
  if sink.len() != 1 { return 12; }
  pipe.pipe_close(p.0);
  pipe.pipe_close(p.1);
  return 0;
}
