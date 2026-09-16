// smoke_prop_collect_hashchurn.xi -- hash-map churn property smoke.
// A 1000-key model (array, -1 = absent) vs LhMap through three phases:
// bulk insert, overwrite evens, remove every third key, then 2000 mixed
// LCG-driven put/get/remove ops; a full model comparison runs at the end of
// every phase and after the churn. Catches lost/duplicated/stale entries.
// Returns 0 on success.

module smoke_prop_collect_hashchurn
use xiom.collect.hash;
use xiom.io;

fn next_seed(s: Int) -> Int {
  (s * 1103515245 + 12345) % 2147483648
}

fn verify(m: &LhMap, model: &Vec[Int], n: Int) -> Int {
  if lhmap_size(m) < 0 { return 1; };
  var i = 0;
  while i < n {
    let want = model[i];
    let got = lhmap_get(m, i);
    if want < 0 {
      if got.is_some { return 2; };
    } else {
      if !got.is_some { return 3; };
      if got.value != want { return 4; };
    };
    i = i + 1;
  };
  0
}

fn main() -> Int {
  let n = 1000;
  var model = Vec[Int].new();
  var i = 0;
  while i < n {
    model.push(-1);
    i = i + 1;
  };

  var m = lhmap_new();

  // Phase 1: bulk insert.
  i = 0;
  while i < n {
    lhmap_put(&mut m, i, i * 7 + 1);
    model[i] = i * 7 + 1;
    i = i + 1;
  };
  var v = verify(&m, &model, n);
  if v != 0 { io.println("churn phase1"); return v; };

  // Phase 2: overwrite evens.
  i = 0;
  while i < n {
    if i % 2 == 0 {
      lhmap_put(&mut m, i, i * 5 + 2);
      model[i] = i * 5 + 2;
    };
    i = i + 1;
  };
  v = verify(&m, &model, n);
  if v != 0 { io.println("churn phase2"); return v; };

  // Phase 3: remove every third key.
  i = 0;
  while i < n {
    if i % 3 == 0 {
      let rem = lhmap_remove(&mut m, i);
      if !rem { io.println("churn remove"); return 10; };
      model[i] = -1;
    };
    i = i + 1;
  };
  v = verify(&m, &model, n);
  if v != 0 { io.println("churn phase3"); return v; };

  // Phase 4: 2000 mixed LCG ops, model-tracked.
  var seed = 13579;
  var ops = 0;
  while ops < 2000 {
    seed = next_seed(seed);
    let key = seed % n;
    let op = seed % 3;
    if op == 0 {
      let val = key * 11 + ops;
      lhmap_put(&mut m, key, val);
      model[key] = val;
    } elif op == 1 {
      let got = lhmap_get(&m, key);
      let want = model[key];
      if want < 0 {
        if got.is_some { io.println("churn stale"); return 11; };
      } else {
        if !got.is_some || got.value != want { io.println("churn mismatch"); return 12; };
      };
    } else {
      let rem = lhmap_remove(&mut m, key);
      let was = model[key] >= 0;
      if rem != was { io.println("churn remove mismatch"); return 13; };
      model[key] = -1;
    };
    ops = ops + 1;
  };
  v = verify(&m, &model, n);
  if v != 0 { io.println("churn final"); return v; };

  io.println("smoke_prop_collect_hashchurn OK");
  return 0;
}
