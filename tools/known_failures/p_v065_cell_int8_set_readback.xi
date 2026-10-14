// p_v065_cell_int8_set_readback.xi -- v0.64.5 candidate regression
// (REL-20261014-2123-stdlib): Cell[Int8].set() followed by get() reads
// pointer-shaped garbage instead of the stored value. Expected rc 0;
// observed rc 2 on the v0.64.5 dry-run archive 5/5 (compile rc 0), and
// rc 0 5/5 on the v0.64.4 release archive. Source smoke:
// tests/smoke/smoke_cell_narrow.xi (exit 2). The Int16 leg (new/get
// only) is correct on both.

module p_v065_cell_int8_set_readback

use xiom.cell;

fn main() -> Int {
  var c8 = cell.Cell.new(100 as Int8);
  if c8.get() != 100 as Int8 { return 1; }
  c8.set(127 as Int8);
  if c8.get() != 127 as Int8 { return 2; }
  c8.set(42 as Int8);
  if c8.get() != 42 as Int8 { return 3; }
  return 0
}
