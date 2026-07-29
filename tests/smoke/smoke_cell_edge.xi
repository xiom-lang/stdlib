module smoke_cell_edge
use xiom.cell;

fn main() -> Int {
  var c = cell.Cell.new(0);
  c.set(0);
  if c.get() != 0 { return 1; }

  var old = c.replace(0);
  if old != 0 { return 2; }
  if c.get() != 0 { return 3; }

  var a = cell.Cell.new(0);
  var b = cell.Cell.new(0);
  a.swap(&b);
  if a.get() != 0 { return 4; }
  if b.get() != 0 { return 5; }

  return 0;
}
