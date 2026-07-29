module smoke_cell_set_get
use xiom.cell;

fn main() -> Int {
  var c = cell.Cell.new("hello");
  if c.get() != "hello" { return 1; }

  c.set("world");
  if c.get() != "world" { return 2; }

  c.set("world");
  if c.get() != "world" { return 3; }

  return 0;
}
