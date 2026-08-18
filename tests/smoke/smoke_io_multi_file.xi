module smoke_io_multi_file
use xiom.io;
use xiom.convert;

fn main() -> Int {
  var i: Int = 0;
  while i < 5 {
    var path = "__smoke_io_multi_" + convert.int_to_string(i) + ".txt";
    io.write_file(path, "data" + convert.int_to_string(i));
    if !io.file_exists(path) { return 1; }
    i = i + 1;
  }

  var j: Int = 0;
  while j < 5 {
    var path = "__smoke_io_multi_" + convert.int_to_string(j) + ".txt";
    match io.read_file(path) {
      Ok(c) => { if c != "data" + convert.int_to_string(j) { return 2; } },
      Err(_) => { return 3; },
    };
    io.remove_file(path);
    j = j + 1;
  }

  return 0;
}
