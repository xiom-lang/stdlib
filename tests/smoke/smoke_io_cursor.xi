module smoke_io_cursor
use xiom.io;

fn main() -> Int {
  var data = Vec[UInt8].new();
  data.push('h' as UInt8);
  data.push('i' as UInt8);

  var c = io.Cursor.new(data);
  var inner = c.into_inner();
  if inner.len() != 2 { return 1; }

  return 0;
}
