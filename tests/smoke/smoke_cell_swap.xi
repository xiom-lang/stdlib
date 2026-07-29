module smoke_cell_swap
use xiom.cell;

fn main() -> Int {
  var a = cell.Cell.new(1);
  var b = cell.Cell.new(2);

  a.swap(&b);
  if a.get() != 2 { return 1; }
  if b.get() != 1 { return 2; }

  return 0;
}
