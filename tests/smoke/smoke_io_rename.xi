module smoke_io_rename
use xiom.io;

fn main() -> Int {
  let old = "__smoke_io_rename_old.txt";
  let new = "__smoke_io_rename_new.txt";

  io.write_file(old, "rename me");

  match io.rename(old, new) {
    Ok(_) => {},
    Err(_) => { return 1; },
  };

  if io.file_exists(old) {
    io.remove_file(old);
    return 2;
  }

  if !io.file_exists(new) { return 3; }

  match io.read_file(new) {
    Ok(content) => { if content != "rename me" { return 4; } },
    Err(_) => { return 5; },
  };

  io.remove_file(new);
  return 0;
}
