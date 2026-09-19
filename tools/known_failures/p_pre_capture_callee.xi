// p_pre_capture_callee.xi -- residual `@pre` bug after the R49 fix: entry
// snapshots of ref-param expressions do not capture SCALAR FIELDS (and
// computed-index Vec loops); only straight-line constant-index Vec element
// mutations are snapshotted.
//
// Verified on compiler main 306073ba:
// - FIXED: `p_pre_call_capture.xi` (`b.v[0] = b.v[0] + 1` with `total(b)@pre`)
//   exits 0; `tools/collections/collections.xi` (method receivers) and
//   `rc`/`sync` clone clauses pass in their smoke families.
// - STILL BROKEN: `xiom.collect.list.ll_pop*` (mutates the `size` field),
//   `xiom.collect.queue.workqueue_pop` (mutates `head` while a Vec len is
//   read), `fenwick_add` (`tree[i]` with runtime index, loop-sum in @pre),
//   rbtree/tree/hash/intmap/lfu/spatial remove/insert size clauses. All
//   abort with 2 == 2 - 1 style violations; the stdlib keeps the weaker
//   `@pre`-free clauses for those modules.
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
