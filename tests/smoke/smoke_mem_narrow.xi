module smoke_mem_narrow
use xiom.mem;

fn main() -> Int {
  if mem.size_of[Int8]() != 1 { return 1; }
  if mem.size_of[Int16]() != 2 { return 2; }
  if mem.size_of[Int32]() != 4 { return 3; }
  if mem.size_of[Int64]() != 8 { return 0; }

  return 0;
}
