// XIOM stdlib smoke test - xiom.collect.sparse + xiom.collect.dense
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_collect_sparse
use xiom.collect.sparse;
use xiom.collect.dense;
use xiom.io;

fn main() -> Int {
  // --- sparse set ---
  var s = sparse_set_new();
  if sparse_size(&s) != 0 { io.println("sparse: initial size"); return 1; }
  sparse_add(&mut s, 5);
  sparse_add(&mut s, 3);
  sparse_add(&mut s, 9);
  if !sparse_contains(&s, 5) { io.println("sparse: contains 5"); return 2; }
  if !sparse_contains(&s, 3) { io.println("sparse: contains 3"); return 3; }
  if sparse_contains(&s, 4) { io.println("sparse: contains 4"); return 4; }
  if sparse_size(&s) != 3 { io.println("sparse: size"); return 5; }
  sparse_add(&mut s, 5);
  if sparse_size(&s) != 3 { io.println("sparse: dup add"); return 6; }
  sparse_remove(&mut s, 3);
  if sparse_contains(&s, 3) { io.println("sparse: contains after remove"); return 7; }
  if !sparse_contains(&s, 9) { io.println("sparse: contains 9 after remove"); return 8; }
  if sparse_size(&s) != 2 { io.println("sparse: size after remove"); return 9; }
  sparse_add(&mut s, 3);
  if !sparse_contains(&s, 3) { io.println("sparse: re-add 3"); return 10; }
  if sparse_size(&s) != 3 { io.println("sparse: size after re-add"); return 11; }
  sparse_add(&mut s, 1000);
  if !sparse_contains(&s, 1000) { io.println("sparse: large value"); return 12; }
  sparse_remove(&mut s, 1000);
  if sparse_contains(&s, 1000) { io.println("sparse: large value removed"); return 13; }
  var it = sparse_iter(&s);
  if it.len() != 3 { io.println("sparse: iter size"); return 14; }

  // --- dense set ---
  var d = dense_set_new();
  if dense_size(&d) != 0 { io.println("dense: initial size"); return 15; }
  dense_add(&mut d, 5);
  dense_add(&mut d, 3);
  dense_add(&mut d, 9);
  dense_add(&mut d, 100);
  dense_add(&mut d, 200);
  if !dense_contains(&d, 5) { io.println("dense: contains 5"); return 16; }
  if !dense_contains(&d, 100) { io.println("dense: contains 100"); return 17; }
  if dense_contains(&d, 4) { io.println("dense: contains 4"); return 18; }
  if dense_size(&d) != 5 { io.println("dense: size"); return 19; }
  dense_add(&mut d, 5);
  if dense_size(&d) != 5 { io.println("dense: dup add"); return 20; }
  dense_remove(&mut d, 9);
  if dense_contains(&d, 9) { io.println("dense: contains after remove"); return 21; }
  if dense_size(&d) != 4 { io.println("dense: size after remove"); return 22; }
  var dit = dense_iter(&d);
  if dit.len() != 4 { io.println("dense: iter size"); return 23; }
  // ascending order: 3, 5, 100, 200
  if !(dit[0] == 3 && dit[1] == 5 && dit[2] == 100 && dit[3] == 200) { io.println("dense: iter order"); return 24; }

  io.println("smoke_collect_sparse: OK");
  return 0;
}
