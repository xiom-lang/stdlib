// XIOM stdlib smoke test - xiom.collect.unionfind
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_collect_unionfind
use xiom.collect.unionfind;
use xiom.io;

fn main() -> Int {
  var uf = uf_new(8);
  if uf_components(&uf) != 8 { io.println("uf: initial components"); return 1; }
  // union 3-5, then 5-7: all three share a root
  uf_union(&mut uf, 3, 5);
  uf_union(&mut uf, 5, 7);
  if !uf_connected(&uf, 3, 5) { io.println("uf: connected 3 5"); return 2; }
  if !uf_connected(&uf, 3, 7) { io.println("uf: connected 3 7"); return 3; }
  if uf_connected(&uf, 3, 1) { io.println("uf: not connected 3 1"); return 4; }
  var r1 = uf_find(&mut uf, 3);
  var r2 = uf_find(&mut uf, 5);
  var r3 = uf_find(&mut uf, 7);
  if r1 != r2 || r2 != r3 { io.println("uf: same root"); return 5; }
  if r1 < 0 || r1 >= 8 { io.println("uf: root range"); return 6; }
  if uf_component_size(&uf, 3) != 3 { io.println("uf: comp size"); return 7; }
  if uf_component_size(&uf, 7) != 3 { io.println("uf: comp size 7"); return 8; }
  if uf_components(&uf) != 6 { io.println("uf: components"); return 9; }
  // union 0-1 and 1-2
  uf_union(&mut uf, 0, 1);
  uf_union(&mut uf, 1, 2);
  if uf_component_size(&uf, 0) != 3 { io.println("uf: comp size 0"); return 10; }
  if uf_components(&uf) != 4 { io.println("uf: components 2"); return 11; }
  // union into each other
  uf_union(&mut uf, 7, 0);
  if uf_component_size(&uf, 3) != 6 { io.println("uf: merged comp"); return 12; }
  if uf_components(&uf) != 3 { io.println("uf: components 3"); return 13; }
  // out-of-range guards
  var oob = uf_find(&mut uf, 100);
  if oob != -1 { io.println("uf: oob find"); return 14; }
  if uf_connected(&uf, 100, 0) { io.println("uf: oob connected"); return 15; }
  if uf_component_size(&uf, 100) != 0 { io.println("uf: oob comp size"); return 16; }
  uf_union(&mut uf, 100, 0);
  if uf_components(&uf) != 3 { io.println("uf: oob union"); return 17; }

  io.println("smoke_collect_unionfind: OK");
  return 0;
}
