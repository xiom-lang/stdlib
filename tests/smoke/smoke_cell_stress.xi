module smoke_cell_stress
use xiom.cell;

fn main() -> Int {
  var c = cell.Cell.new(0);
  var i: Int = 0;
  while i < 100 {
    c.set(i);
    if c.get() != i { return 1; }
    i = i + 1;
  }
  return 0;
}
