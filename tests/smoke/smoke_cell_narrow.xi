module smoke_cell_narrow
use xiom.cell;

fn main() -> Int {
  var c8 = cell.Cell.new(100 as Int8);
  if c8.get() != 100 as Int8 { return 1; }
  c8.set(127 as Int8);
  if c8.get() != 127 as Int8 { return 2; }

  var c16 = cell.Cell.new(30000 as Int16);
  if c16.get() != 30000 as Int16 { return 3; }

  var c32 = cell.Cell.new(1000000 as Int32);
  if c32.get() != 1000000 as Int32 { return 4; }

  return 0;
}
