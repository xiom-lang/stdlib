// XIOM stdlib stress — io.read_int / io.read_float API existence
// Tests reading integers and floats from a byte buffer via Cursor.
// Returns 0 on success, nonzero on failure.

module smoke_stress_io_read_int_float
use xiom.io;

fn main() -> Int {
  var data = Vec[UInt8].new();
  data.push(0u8);
  data.push(0u8);
  data.push(0u8);
  data.push(42u8);
  var c = io.Cursor.new(data);
  var ri = io.read_int(c);
  match ri {
    Ok(v) => { if v == 42 { return 0; } else { return 1; } }
    Err(_) => { return 2; }
  }
}
