module smoke_io
use xiom.io;

fn main() -> Int {
  // 1. Write file
  io.write_file("__smoke_io_test.txt", "hello io");

  // 2. file_exists
  if not io.file_exists("__smoke_io_test.txt") { return 2; }

  // 3. Remove file  
  io.remove_file("__smoke_io_test.txt");

  // 4. Verify removed
  if io.file_exists("__smoke_io_test.txt") { return 4; }

  return 0;
}
