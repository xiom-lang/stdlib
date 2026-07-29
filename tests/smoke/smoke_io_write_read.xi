module smoke_io_write_read
use xiom.io;

fn main() -> Int {
  let path = "__smoke_io_rw.txt";

  match io.write_file(path, "hello io world") {
    Ok(_) => {},
    Err(_) => { return 1; },
  };

  if !io.file_exists(path) { return 2; }

  match io.read_file(path) {
    Ok(content) => { if content != "hello io world" { return 3; } },
    Err(_) => { return 4; },
  };

  io.remove_file(path);

  return 0;
}
