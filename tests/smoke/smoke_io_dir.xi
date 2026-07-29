module smoke_io_dir
use xiom.io;

fn main() -> Int {
  let dir = "__smoke_io_dir";

  if io.is_dir(dir) {
    return 0;
  }

  match io.create_dir(dir) {
    Ok(_) => {},
    Err(_) => { return 1; },
  };

  if !io.is_dir(dir) { return 2; }

  io.write_file(io.join_paths(dir, "f1.txt"), "a");
  io.write_file(io.join_paths(dir, "f2.txt"), "b");

  match io.list_dir(dir) {
    Ok(entries) => {
      if entries.len() != 2 { return 3; }
    },
    Err(_) => { return 4; },
  };

  io.remove_file(io.join_paths(dir, "f1.txt"));
  io.remove_file(io.join_paths(dir, "f2.txt"));

  return 0;
}
