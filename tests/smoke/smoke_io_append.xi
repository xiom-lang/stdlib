module smoke_io_append
use xiom.io;

fn main() -> Int {
  let path = "__smoke_io_append.txt";

  io.write_file(path, "first");
  match io.append_file(path, "second") {
    Ok(_) => {},
    Err(_) => { return 1; },
  };

  match io.read_file(path) {
    Ok(content) => { if content != "firstsecond" { return 2; } },
    Err(_) => { return 3; },
  };

  io.remove_file(path);
  return 0;
}
