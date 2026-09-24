// Smoke: xiom.math.set_theory.set_partition (implemented 2026-09-24 with the
// row-local nested-Vec read shape; the previous NOT-IMPLEMENTABLE stub is
// closed). Returns 0 on success, nonzero on failure.
module smoke_math_set_partition
use xiom.math.set_theory;
use xiom.io;

fn main() -> Int {
  var s: Vec[Int] = Vec[Int].new();
  s.push(1); s.push(2); s.push(3);

  var b1: Vec[Int] = Vec[Int].new();
  b1.push(1); b1.push(2);
  var b2: Vec[Int] = Vec[Int].new();
  b2.push(3);
  var good: Vec[Vec[Int]] = Vec[Vec[Int]].new();
  good.push(b1); good.push(b2);
  if !set_theory.set_partition(&s, &good) { io.println("sp:good"); return 1; }

  // overlapping blocks
  var c1: Vec[Int] = Vec[Int].new();
  c1.push(1); c1.push(2);
  var c2: Vec[Int] = Vec[Int].new();
  c2.push(2); c2.push(3);
  var overlap: Vec[Vec[Int]] = Vec[Vec[Int]].new();
  overlap.push(c1); overlap.push(c2);
  if set_theory.set_partition(&s, &overlap) { io.println("sp:overlap"); return 2; }

  // element of s missing from the blocks
  var d1: Vec[Int] = Vec[Int].new();
  d1.push(1); d1.push(2);
  var missing: Vec[Vec[Int]] = Vec[Vec[Int]].new();
  missing.push(d1);
  if set_theory.set_partition(&s, &missing) { io.println("sp:missing"); return 3; }

  // block carries an element outside s
  var e1: Vec[Int] = Vec[Int].new();
  e1.push(1); e1.push(2); e1.push(3); e1.push(9);
  var outside: Vec[Vec[Int]] = Vec[Vec[Int]].new();
  outside.push(e1);
  if set_theory.set_partition(&s, &outside) { io.println("sp:outside"); return 4; }

  // empty s: empty block list partitions it; a stray block does not
  var empty_s: Vec[Int] = Vec[Int].new();
  var empty_blocks: Vec[Vec[Int]] = Vec[Vec[Int]].new();
  if !set_theory.set_partition(&empty_s, &empty_blocks) { io.println("sp:empty"); return 5; }
  if set_theory.set_partition(&empty_s, &outside) { io.println("sp:emptyoutside"); return 6; }

  io.println("smoke_math_set_partition: OK");
  return 0;
}
