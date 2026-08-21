// Phase 3 smoke: Guard Heap (d) + Copy-Out (i) -- Unsafe Confinement.
// Returns 0 on success.
use xiom.io;

// Build a Str from arena-allocated data entirely inside an unsafe block.
// The Vec's buffer is allocated on the guard arena (routed via emit_alloc);
// Copy-Out must promote it to the main heap BEFORE the arena resets -- the
// caller uses it safely afterwards (UAF fix).
fn make_str() -> Str
  requires: true
{
  unsafe {
    var v = Vec[UInt8].new();
    v.push(72 as UInt8);
    v.push(69 as UInt8);
    v.push(76 as UInt8);
    v.push(76 as UInt8);
    v.push(79 as UInt8);
    return Str::from_utf8(v);
  }
}

// Heap isolation: allocate inside the guard arena and scribble it. The arena
// is discarded at block exit; the main heap must be untouched.
fn arena_scribble() -> Int
  requires: true
{
  unsafe {
    var v = Vec[Int].new();
    var i = 0;
    while i < 100 {
      v.push(i * 7);
      i = i + 1;
    }
    return v.len();
  }
}

fn main() -> Int {
  // Copy-Out: the returned Str survives the arena reset.
  var s = make_str();
  if s != "HELLO" { io.println("copyout-bad: " + s); return 1; }

  // Heap isolation: scribbling the arena doesn't corrupt main-heap values.
  var r = arena_scribble();
  if r != 100 { return 2; }

  // The Str is still valid after the arena scribble + reset.
  if s != "HELLO" { return 3; }

  return 0;
}
