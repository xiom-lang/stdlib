// XIOM stdlib stress — io.Cursor wrap data and into_inner
// Wraps a Vec[UInt8] in a Cursor, reads inner buffer, verifies length.
// Returns 0 on success, nonzero on failure.

module smoke_stress_io_cursor
use xiom.io;

fn main() -> Int {
  var data = Vec[UInt8].new();
  data.push(65u8);
  data.push(66u8);
  data.push(67u8);
  var c = io.Cursor.new(data);
  var inner = c.into_inner();
  if inner.len() == 3 { return 0; } else { return 1; }
}
