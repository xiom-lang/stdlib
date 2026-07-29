module smoke_io_metadata
use xiom.io;

fn main() -> Int {
  let path = "__smoke_io_meta.txt";
  io.write_file(path, "metadata test");

  match io.metadata(path) {
    Ok(m) => {
      if m.size <= 0 { return 1; }
      if !m.is_file { return 2; }
      if m.is_dir { return 3; }
    },
    Err(_) => { return 4; },
  };

  io.remove_file(path);
  return 0;
}
