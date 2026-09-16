// q1_probe2.xi -- io wrapper surface without io.sleep (Windows link bug, see
// probe log). Exercises print/println/time_now/rename + thread.yield_now.
module q1_probe2
use xiom.io;
use xiom.thread;

fn main() -> Int {
  io.print("x");
  io.println("y");
  if io.time_now() < 0 { return 1; }
  thread.yield_now();
  // rename round-trip on two scratch files in the current dir
  var a = "q1_p2_a.tmp";
  var b = "q1_p2_b.tmp";
  var w1 = io.write_file(a, "hello");
  if w1 is Err { return 2; }
  var r1 = io.rename(a, b);
  if r1 is Err { return 3; }
  var exists = io.file_exists(b);
  if !exists { return 4; }
  var w2 = io.remove_file(b);
  if w2 is Err { return 5; }
  return 0;
}
