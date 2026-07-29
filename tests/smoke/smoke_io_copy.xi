module smoke_io_copy
use xiom.io;

fn main() -> Int {
  let src = "__smoke_io_copy_src.txt";
  let dst = "__smoke_io_copy_dst.txt";

  io.write_file(src, "copy me");

  match io.copy_file(src, dst) {
    Ok(_) => {},
    Err(_) => { return 1; },
  };

  if !io.file_exists(dst) { return 2; }

  match io.read_file(dst) {
    Ok(content) => { if content != "copy me" { return 3; } },
    Err(_) => { return 4; },
  };

  io.remove_file(src);
  io.remove_file(dst);
  return 0;
}
