// XIOM stdlib smoke — xiom.collect.map (open-addressing Int→Int map)
// Returns 0 on success, nonzero (and a tag) on failure.

module smoke_collections_map
use xiom.collect.map;
use xiom.io;
use xiom.convert;

fn fail(tag: Str) -> Int {
  io.println("smoke_collections_map FAIL: " + tag);
  return 1;
}

fn main() -> Int {
  var m = map.map_new();
  if !map.map_is_empty(m) { return fail("empty"); }
  if map.map_size(m) != 0 { return fail("size0"); }
  let miss = map.map_get(&m, 42);
  if miss.is_some { return fail("get-miss"); }
  if map.map_contains(&m, 42) { return fail("contains-miss"); }

  map.map_put(&m, 1, 100);
  map.map_put(&m, 2, 200);
  map.map_put(&m, 3, 300);
  if map.map_size(m) != 3 { return fail("size3"); }
  if map.map_is_empty(m) { return fail("not-empty"); }
  let g1 = map.map_get(&m, 1);
  match g1 {
    Some(v) => {
      if v != 100 { return fail("get-1"); }
    };
    None => { return fail("get-1-none"); }
  }
  let g3 = map.map_get(&m, 3);
  match g3 {
    Some(v) => {
      if v != 300 { return fail("get-3"); }
    };
    None => { return fail("get-3-none"); }
  }
  if !map.map_contains(&m, 2) { return fail("contains-2"); }

  // overwrite
  map.map_put(&m, 2, 250);
  let g2 = map.map_get(&m, 2);
  match g2 {
    Some(v) => {
      if v != 250 { return fail("overwrite"); }
    };
    None => { return fail("overwrite-none"); }
  }
  if map.map_size(m) != 3 { return fail("size-after-overwrite"); }

  // remove
  let rm = map.map_remove(&m, 2);
  if !rm { return fail("remove-present"); }
  if map.map_contains(&m, 2) { return fail("contains-after-remove"); }
  let rm2 = map.map_remove(&m, 2);
  if rm2 { return fail("remove-absent"); }
  if map.map_size(m) != 2 { return fail("size2"); }

  // keys
  let keys = map.map_keys(&m);
  if keys.len() != 2 { return fail("keys-len"); }
  var sum: Int = 0;
  var i: Int = 0;
  while i < keys.len() {
    sum = sum + keys[i];
    i = i + 1;
  };
  if sum != 4 { return fail("keys-sum"); }

  // growth (forces resize past capacity 16)
  var big = map.map_new();
  var k: Int = 0;
  while k < 100 {
    map.map_put(&big, k, k * 10);
    k = k + 1;
  };
  if map.map_size(big) != 100 { return fail("big-size"); }
  let g50 = map.map_get(&big, 50);
  match g50 {
    Some(v) => {
      if v != 500 { return fail("big-get"); }
    };
    None => { return fail("big-get-none"); }
  }
  let g99 = map.map_get(&big, 99);
  match g99 {
    Some(v) => {
      if v != 990 { return fail("big-get-99"); }
    };
    None => { return fail("big-get-99-none"); }
  }
  let miss99 = map.map_get(&big, 9999);
  if miss99.is_some { return fail("big-miss"); }

  // clear
  map.map_clear(&big);
  if !map.map_is_empty(big) { return fail("big-clear"); }
  if map.map_size(big) != 0 { return fail("big-size-clear"); }

  // negative keys
  var neg = map.map_new();
  map.map_put(&neg, -5, 55);
  let gneg = map.map_get(&neg, -5);
  match gneg {
    Some(v) => {
      if v != 55 { return fail("neg-get"); }
    };
    None => { return fail("neg-get-none"); }
  }

  io.println("smoke_collections_map OK");
  return 0;
}
