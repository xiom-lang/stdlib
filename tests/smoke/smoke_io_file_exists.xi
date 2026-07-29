module smoke_io_file_exists
use xiom.io;

fn main() -> Int {
  let path = "__smoke_io_exists.txt";

  if io.file_exists(path) { return 1; }

  io.write_file(path, "data");

  if !io.file_exists(path) { return 2; }

  io.remove_file(path);

  if io.file_exists(path) { return 3; }

  if io.file_exists("") { return 4; }

  return 0;
}
