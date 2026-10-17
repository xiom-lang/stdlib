// Phase 6 smoke: Transient Fault Retry (requirement h) -- Unsafe Confinement.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// A transient GUARD-PAGE first touch (faults on first run, succeeds on retry)
// is retried ONCE on a fresh memory slot and the block's value is delivered.
// m351 (B-33): deterministic faults (AV/SIGILL) are NOT retried -- side
// effects run once; they surface as a typed fault that must be acknowledged
// with take_fault() (the only exit-0 path after a fault).
// Returns 0 on success.
use xiom.io;
use xiom.error;

extern "C" {
  fn xiom_fault_transient() -> Int;  // faults first call, returns 42 on retry
  fn xiom_fault_permanent() -> Int;  // faults on every call
  fn xiom_fault_av() -> Int;         // faults on every call
}

// Transient fault: the trampoline retries once and delivers the value 42.
fn retry_transient() -> Int
  requires: true
{
  unsafe {
    var v = xiom_fault_transient();
    return v;
  }
  return 0;
}

// Permanent fault: deterministic -> NOT retried -> typed fault (returns 0).
fn retry_permanent() -> Int
  requires: true
{
  unsafe {
    var v = xiom_fault_permanent();
    return v;
  }
  return 0;
}

// #[unsafe_no_retry]: skips the retry -- a single fault -> Err immediately.
#[unsafe_no_retry]
fn no_retry_av() -> Int
  requires: true
{
  unsafe {
    var v = xiom_fault_av();
    return v;
  }
  return 0;
}

fn main() -> Int {
  // (1) Transient fault is retried once and succeeds -> value 42 delivered.
  io.println("before-transient");
  var r1 = retry_transient();
  io.println("after-transient");
  if r1 != 42 { return 1; }
  if error.faulted() { return 4; }

  // (2) Permanent fault is deterministic -> not retried -> typed fault (0).
  io.println("before-permanent");
  var r2 = retry_permanent();
  io.println("after-permanent");
  if r2 != 0 { return 2; }
  if !error.faulted() { return 5; }
  error.take_fault();

  // (3) #[unsafe_no_retry] keeps the single-fault policy explicit.
  io.println("before-no-retry");
  var r3 = no_retry_av();
  io.println("after-no-retry");
  if r3 != 0 { return 3; }
  if !error.faulted() { return 6; }
  error.take_fault();

  io.println("RETRY-OK");
  return 0;
}
