// p_e001_borrow_conservatism.xi -- EVIDENCE (compiler, warning-only), 2026-09-24.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Minimal pattern for the E001 borrow-checker conservatism relayed by the
// packages lane: after a value is passed as `&local`, a later `&mut local`
// call warns "cannot borrow '<x>' as mutable while immutably borrowed" even
// though the immutable borrows are complete. Warning-only: this file
// compiles (exit 0) and runs green on compiler v0.61.3.
//
// Deterministic repro through the smoke runner on v0.61.3 (verified twice):
//   powershell -NoProfile -File tools/run_smokes.ps1 -Compiler <v0.61.3 exe>
//     -Filter smoke_collect_sparse
//   -> logs/smoke_collect_sparse.compile.log contains 7 warnings:
//      warning[E001]: 22:14 / 24:17 / 28:14 / 31:14 / 33:17 / 50:13 / 52:16
//      (each `&mut s` / `&mut d` call after preceding `&s` / `&d` calls)
//   The same pattern appears in smoke_collect2a (line 63) and
//   smoke_collect_threadpool (line 28).
//
// Kept in tools/probes/evidence/ (not part of the probe gate): it is green,
// and it exists as the compiler-lane intake pattern for the E001 fix.

module p_e001_borrow_conservatism

fn has(v: &Vec[Int], x: Int) -> Bool {
  var i = 0;
  while i < v.len() {
    if v[i] == x { return true; }
    i = i + 1;
  }
  return false;
}

fn addv(v: &mut Vec[Int], x: Int) { v.push(x); }

fn main() -> Int {
  var v: Vec[Int] = Vec[Int].new();
  v.push(5);
  if !has(&v, 5) { return 1; }
  addv(&mut v, 6);
  addv(&mut v, 7);
  if !has(&v, 6) { return 2; }
  return 0;
}
