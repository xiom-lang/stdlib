// p_pre_capture_callee.xi -- ref-param `@pre` snapshots through a CALLEE
// mutation: the entry snapshot must be taken before the body runs even when
// the mutated state lives behind a helper (scalar fields, computed-index Vec
// loops).
//
// RESOLVED 2026-09-20 on compiler main R52 (R51 `c235b3fe`): the @pre
// walkers descend through Imply/Is so implication-wrapped clauses emit entry
// snapshots; `--run` exits 0, the nine collect/* modules carry their strong
// size relations again, and tools/probes/p_wave8_shapes.xi is green.
// History: RED on R46/R46b/R49 (R49 fixed the direct-mutation shape, this
// callee-mutation shape was the residual). Compiler-side lock: e2e_m104.
module p_pre_capture_callee

type Box = { n: Int; v: Vec[Int]; }

fn total(b: &Box) -> Int {
  return b.n;
}

fn pop_like(b: &mut Box) -> Option[Int] {
  if b.n == 0 { return None; }
  b.n = b.n - 1;
  b.v.pop();
  return Some(b.n);
}

fn wrapper(b: &mut Box) -> Option[Int]
  ensures: result is Some => total(b) == total(b)@pre - 1
  ensures: result is None => total(b) == total(b)@pre
{
  return pop_like(b);
}

fn main() -> Int {
  var b = Box{ n: 3; v: Vec[Int].new() };
  b.v.push(1);
  b.v.push(2);
  b.v.push(3);
  wrapper(&mut b);
  return 0;
}
