module smoke_mem_size_of
use xiom.mem;

fn main() -> Int {
  var si = mem.size_of[Int]();
  if si <= 0 { return 1; }

  var sb = mem.size_of[Bool]();
  if sb <= 0 { return 2; }

  var sf = mem.size_of[Float64]();
  if sf <= 0 { return 3; }

  var si8 = mem.size_of[Int8]();
  if si8 != 1 { return 4; }

  var si16 = mem.size_of[Int16]();
  if si16 != 2 { return 5; }

  var si32 = mem.size_of[Int32]();
  if si32 != 4 { return 6; }

  var ai = mem.align_of[Int]();
  if ai <= 0 { return 7; }

  var x: Int = 42;
  if mem.size_of_val(&x) != si { return 8; }

  return 0;
}
