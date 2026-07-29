module smoke_io_read_write_roundtrip
use xiom.io;

fn main() -> Int {
  let path = "__smoke_io_rwt.txt";

  match io.write_file(path, "roundtrip data") {
    Ok(_) => {},
    Err(_) => { return 1; },
  };

  if !io.file_exists(path) { return 2; }

  match io.read_file(path) {
    Ok(content) => {
      if content != "roundtrip data" { return 3; }
    },
    Err(_) => { return 4; },
  };

  io.remove_file(path);

  match io.read_file(path) {
    Ok(_) => { return 5; },
    Err(_) => {},
  };

  return 0;
}
