// Phase 5 smoke: Hardware Fault Trapping (requirement f, g) -- Unsafe Confinement.
// Deliberate hardware faults inside confined blocks must be caught by the SEH
// trampoline; the process must SURVIVE and continue (println after each).
// Returns 0 on success.
use xiom.io;

extern "C" {
  fn xiom_fault_av() -> Int;        // deliberate access violation (SIGSEGV)
  fn xiom_fault_ud2() -> Int;       // deliberate illegal instruction (SIGILL)
  fn xiom_fault_div0() -> Int;      // deliberate divide-by-zero (SIGFPE)
  fn xiom_fault_deref_ok() -> Int;  // benign: returns 42 (no fault)
}

fn confined_av() -> Int
  requires: true
{
  unsafe {
    var v = xiom_fault_av();
    return v;
  }
  return 0;
}

fn confined_ud2() -> Int
  requires: true
{
  unsafe {
    var v = xiom_fault_ud2();
    return v;
  }
  return 0;
}

fn confined_div0() -> Int
  requires: true
{
  unsafe {
    var v = xiom_fault_div0();
    return v;
  }
  return 0;
}

fn confined_ok() -> Int
  requires: true
{
  unsafe {
    var v = xiom_fault_deref_ok();
    return v;
  }
  return 0;
}

fn main() -> Int {
  // (1) Access violation inside a confined block -> process survives.
  io.println("before-av");
  var r1 = confined_av();
  io.println("after-av");
  if r1 != 0 { return 1; }

  // (2) Illegal instruction (ud2) inside a confined block -> process survives.
  io.println("before-ud2");
  var r2 = confined_ud2();
  io.println("after-ud2");
  if r2 != 0 { return 2; }

  // (3) Divide-by-zero inside a confined block -> process survives.
  io.println("before-div0");
  var r3 = confined_div0();
  io.println("after-div0");
  if r3 != 0 { return 3; }

  // (4) A benign confined block still returns its value correctly.
  var r4 = confined_ok();
  if r4 != 42 { return 4; }

  io.println("FAULT-OK");
  return 0;
}
