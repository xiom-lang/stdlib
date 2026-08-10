// Phase 6 smoke: Transient Fault Retry (requirement h) — Unsafe Confinement.
// A transient fault (faults on first run, succeeds on retry) is retried ONCE
// on a fresh memory slot and the block's value is delivered. A permanent fault
// faults twice → Err (recoverable, process survives). `#[unsafe_no_retry]`
// skips the retry entirely (faults once → Err).
// Returns 0 on success.
use xiom.io;

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

// Permanent fault: retries once, faults again → Err (returns 0, survives).
fn retry_permanent() -> Int
  requires: true
{
  unsafe {
    var v = xiom_fault_permanent();
    return v;
  }
  return 0;
}

// #[unsafe_no_retry]: skips the retry — a single fault → Err immediately.
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
  // (1) Transient fault is retried once and succeeds → value 42 delivered.
  io.println("before-transient");
  var r1 = retry_transient();
  io.println("after-transient");
  if r1 != 42 { return 1; }

  // (2) Permanent fault is retried once, faults again → recoverable Err (0).
  io.println("before-permanent");
  var r2 = retry_permanent();
  io.println("after-permanent");
  if r2 != 0 { return 2; }

  // (3) #[unsafe_no_retry] skips retry → single fault → Err (0).
  io.println("before-no-retry");
  var r3 = no_retry_av();
  io.println("after-no-retry");
  if r3 != 0 { return 3; }

  io.println("RETRY-OK");
  return 0;
}
