// XIOM stdlib smoke test - xiom.collect.dag
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_collect_dag
use xiom.collect.dag;
use xiom.io;

fn main() -> Int {
  var g = dag_new();
  var n0 = dag_add_node(&mut g);
  var n1 = dag_add_node(&mut g);
  var n2 = dag_add_node(&mut g);
  var n3 = dag_add_node(&mut g);
  var n4 = dag_add_node(&mut g);
  var n5 = dag_add_node(&mut g);
  if n0 != 0 || n1 != 1 || n2 != 2 || n3 != 3 || n4 != 4 || n5 != 5 {
    io.println("dag: node ids");
    return 1;
  }
  if !dag_add_edge(&mut g, 0, 1) { io.println("dag: edge 0->1"); return 2; }
  if !dag_add_edge(&mut g, 0, 2) { io.println("dag: edge 0->2"); return 3; }
  if !dag_add_edge(&mut g, 1, 3) { io.println("dag: edge 1->3"); return 4; }
  if !dag_add_edge(&mut g, 2, 3) { io.println("dag: edge 2->3"); return 5; }
  if !dag_add_edge(&mut g, 3, 4) { io.println("dag: edge 3->4"); return 6; }
  if dag_add_edge(&mut g, 0, 1) { io.println("dag: dup edge"); return 7; }
  if !dag_has_edge(&g, 0, 1) { io.println("dag: has edge"); return 8; }
  if dag_has_edge(&g, 4, 0) { io.println("dag: has edge neg"); return 9; }
  // adding 4->0 would create a cycle (0->...->4 exists)
  if dag_add_edge(&mut g, 4, 0) { io.println("dag: cycle rejected"); return 10; }
  // self loop is rejected
  if dag_add_edge(&mut g, 2, 2) { io.println("dag: self loop"); return 11; }
  // out-of-range ids rejected
  if dag_add_edge(&mut g, 0, 99) { io.println("dag: oob edge"); return 12; }
  if dag_has_edge(&g, 0, 99) { io.println("dag: oob has edge"); return 13; }
  // descendants / ancestors
  var desc = dag_descendants(&g, 0);
  if desc.len() != 4 { io.println("dag: descendants count"); return 14; }
  if dag_descendants(&g, 4).len() != 0 { io.println("dag: descendants leaf"); return 15; }
  var anc = dag_ancestors(&g, 4);
  if anc.len() != 4 { io.println("dag: ancestors count"); return 16; }
  var anc3 = dag_ancestors(&g, 3);
  if anc3.len() != 3 { io.println("dag: ancestors of 3"); return 17; }
  if dag_ancestors(&g, 0).len() != 0 { io.println("dag: ancestors of 0"); return 18; }
  // topological order: 0 before 1,2,3,4; 1,2 before 3; 3 before 4
  var topo = dag_topological_order(&g);
  if topo.len() != 6 { io.println("dag: topo count"); return 19; }
  var pos0 = -1;
  var pos1 = -1;
  var pos2 = -1;
  var pos3 = -1;
  var pos4 = -1;
  var i: Int = 0;
  while i < topo.len() {
    if topo[i] == 0 { pos0 = i; }
    if topo[i] == 1 { pos1 = i; }
    if topo[i] == 2 { pos2 = i; }
    if topo[i] == 3 { pos3 = i; }
    if topo[i] == 4 { pos4 = i; }
    i = i + 1;
  }
  if pos0 < 0 || pos1 < 0 || pos2 < 0 || pos3 < 0 || pos4 < 0 { io.println("dag: topo missing"); return 20; }
  if !(pos0 < pos1 && pos0 < pos2 && pos0 < pos3 && pos0 < pos4) { io.println("dag: topo 0 first"); return 21; }
  if !(pos1 < pos3 && pos2 < pos3 && pos3 < pos4) { io.println("dag: topo order"); return 22; }
  if dag_has_cycle(&g) { io.println("dag: has cycle"); return 23; }
  // extend: 4 -> 5
  if !dag_add_edge(&mut g, 4, 5) { io.println("dag: edge 4->5"); return 24; }
  var desc2 = dag_descendants(&g, 0);
  if desc2.len() != 5 { io.println("dag: descendants extended"); return 25; }
  if dag_has_cycle(&g) { io.println("dag: cycle after extend"); return 26; }

  io.println("smoke_collect_dag: OK");
  return 0;
}
