module smoke_cell_multi
use xiom.cell;

fn main() -> Int {
  var a = cell.Cell.new(1);
  var b = cell.Cell.new(2);
  var c = cell.Cell.new(3);

  a.swap(&b);
  b.swap(&c);

  if a.get() != 2 { return 1; }
  if b.get() != 3 { return 2; }
  if c.get() != 1 { return 3; }

  a.set(10);
  var old = b.replace(20);
  if old != 3 { return 4; }
  if b.get() != 20 { return 5; }

  return 0;
}
