module smoke_io_edge
use xiom.io;

fn main() -> Int {
  io.write_file("__smoke_io_edge.txt", "");

  match io.read_file("__smoke_io_edge.txt") {
    Ok(content) => { if content != "" { return 1; } },
    Err(_) => { return 2; },
  };

  io.write_file("__smoke_io_edge.txt", "a");
  match io.read_file("__smoke_io_edge.txt") {
    Ok(content) => { if content != "a" { return 3; } },
    Err(_) => { return 4; },
  };

  io.remove_file("__smoke_io_edge.txt");

  match io.read_file("__nonexistent_xyz.xyz") {
    Ok(_) => { return 5; },
    Err(_) => {},
  };

  return 0;
}
