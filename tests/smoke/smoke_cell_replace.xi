module smoke_cell_replace
use xiom.cell;

fn main() -> Int {
  var c = cell.Cell.new(10);
  var old = c.replace(20);
  if old != 10 { return 1; }
  if c.get() != 20 { return 2; }

  var old2 = c.replace(30);
  if old2 != 20 { return 3; }
  if c.get() != 30 { return 4; }

  return 0;
}
