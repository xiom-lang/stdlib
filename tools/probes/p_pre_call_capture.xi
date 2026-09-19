// p_pre_call_capture.xi -- minimal repro: `@pre` on a CALL EXPRESSION in an
// `ensures` clause reads the POST-state instead of the pre-state.
//
// Found 2026-09-18 while adding a Fenwick contract on compiler main R46
// (12148d43) and R46b (504fcc1e); both fail identically. The clause below
// violates at runtime even though `total(b)` went 0 -> 1 and the math holds
// (1 == 0 + 1). Field @pre (`b.v[0] == b.v[0]@pre`) DOES work; the bug is
// specific to call expressions with @pre.
//
// Consequence: tools/probes/p_wave8_shapes.xi line 75
// (`int_map_size(m) == int_map_size(m)@pre - 1` in s_imap_remove) is red on
// R46/R46b, and any contract of the form `f(x) == f(x)@pre + delta` must be
// avoided until this is fixed.
module p_pre_call_capture

type Box = { v: Vec[Int]; }

fn total(b: &Box) -> Int {
  return b.v[0];
}

fn bump(b: &mut Box)
  ensures: total(b) == total(b)@pre + 1
{
  b.v[0] = b.v[0] + 1;
}

fn main() -> Int {
  var b = Box{ v: Vec[Int].new() };
  b.v.push(0);
  bump(&mut b);
  return 0;
}
