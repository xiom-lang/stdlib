module smoke_cross_io_convert_fmt
use xiom.io;
use xiom.convert;
use xiom.fmt;
use xiom.core;

fn main() -> Int {
  let path = "__smoke_cross_icf.txt";

  var data = convert.int_to_string(12345);
  var msg = fmt.format1("data: {}", data);

  io.write_file(path, msg);

  match io.read_file(path) {
    Ok(content) => {
      if content != "data: 12345" { return 1; }
    },
    Err(_) => { return 2; },
  };

  io.remove_file(path);
  return 0;
}
