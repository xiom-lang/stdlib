// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// R46b lock (compiler 1a918ae9+): cross-module generic methods called through
// a MODULE-QUALIFIED receiver. Pre-R46b, `module.Type` receivers resolved
// same-leaf types by hash order and could fall to erased zeroinitializer
// stubs; receiver-only type-arg inference (method type param comes only from
// the receiver) was missing on computed receivers. These are the direct
// stdlib-module forms of the compiler's m88 lock.
module p_r46b_qualified_generic

use xiom.cell;
use xiom.rc;
use xiom.io;

fn main() -> Int {
  // (a) arg-inferred qualified constructor + receiver-only method on the
  // computed receiver.
  let a = cell.Cell.new(42).get();
  if a != 42 { io.println("A FAIL"); return 1; }

  // (b) explicit type args on both the constructor and the method.
  let b = cell.Cell.new[Int](7).get[Int]();
  if b != 7 { io.println("B FAIL"); return 2; }

  // (c) Str payload through a module-qualified generic receiver.
  let s = cell.Cell.new("xiom").get();
  if s != "xiom" { io.println("C FAIL"); return 3; }

  // (d) receiver-only generic method (T from receiver) on an Rc temp.
  let n = rc.Rc.new(9).strong_count();
  if n != 1 { io.println("D FAIL"); return 4; }

  // (e) receiver-only generic payload read on an Rc temp.
  let v = rc.Rc.new(11).get();
  if v != 11 { io.println("E FAIL"); return 5; }

  io.println("P_R46B_QUALIFIED_GENERIC OK");
  return 0;
}
