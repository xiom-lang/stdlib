// XIOM stdlib property smoke -- xiom.collect.hash (LhMap)
// 512 distinct keys: put/get/overwrite/remove must keep size exact, values
// consistent, and keys_in_order strictly ascending after removals.
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_prop_collect_lhmap
use xiom.collect.hash;
use xiom.io;

fn main() -> Int {
  let n = 512;
  var m = lhmap_new();
  var i = 0;
  while i < n {
    lhmap_put(&mut m, i, i * 3);
    i = i + 1;
  };
  if lhmap_size(&m) != n { io.println("prop: size after inserts"); return 1; };

  // Overwrite even keys: size unchanged, values replaced.
  i = 0;
  while i < n {
    if i % 2 == 0 {
      lhmap_put(&mut m, i, i * 5);
    };
    i = i + 1;
  };
  if lhmap_size(&m) != n { io.println("prop: size after overwrite"); return 2; };

  let even = lhmap_get(&m, 42);
  if !even.is_some || even.value != 210 { io.println("prop: overwritten value"); return 3; };
  let odd = lhmap_get(&m, 41);
  if !odd.is_some || odd.value != 123 { io.println("prop: kept value"); return 4; };

  // Remove every key divisible by 4.
  var removed = 0;
  i = 0;
  while i < n {
    if i % 4 == 0 {
      if !lhmap_remove(&mut m, i) { io.println("prop: remove failed"); return 5; };
      removed = removed + 1;
    };
    i = i + 1;
  };
  if lhmap_size(&m) != n - removed { io.println("prop: size after removes"); return 6; };
  if lhmap_contains(&m, 0) { io.println("prop: removed key present"); return 7; };

  let keys = lhmap_keys_in_order(&m);
  if keys.len() != n - removed { io.println("prop: key count"); return 8; };
  var prev = -1;
  i = 0;
  while i < keys.len() {
    if keys[i] <= prev { io.println("prop: key order"); return 9; };
    prev = keys[i];
    i = i + 1;
  };

  io.println("smoke_prop_collect_lhmap OK");
  return 0;
}
