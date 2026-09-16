// smoke_prop_collect_bloom.xi -- Bloom filter property smoke.
// Core properties: no false negatives for inserted keys, clear() empties the
// filter, and the estimated false-positive rate stays in [0, 1] and is
// non-decreasing across insert batches. Returns 0 on success.

module smoke_prop_collect_bloom
use xiom.collect.hash;
use xiom.io;

fn next_seed(s: Int) -> Int {
  (s * 1103515245 + 12345) % 2147483648
}

fn key_of(seed: Int) -> Vec[UInt8] {
  var k = Vec[UInt8].new();
  k.push((seed % 251) as UInt8);
  k.push(((seed / 251) % 251) as UInt8);
  k.push(((seed / 63001) % 251) as UInt8);
  k
}

fn main() -> Int {
  var b = bloom_new(4096, 4);
  let rate0 = bloom_false_positive_rate(&b);

  // Insert 500 deterministic keys; every one must report contains.
  var keys: [500]Int;
  var seed = 777001;
  var i = 0;
  while i < 500 {
    seed = next_seed(seed);
    keys[i] = seed;
    var k = key_of(seed);
    bloom_insert(&mut b, &k);
    if !bloom_maybe_contains(&b, &k) { io.println("bloom:false-negative"); return 1; };
    i = i + 1;
  };

  // Rate must remain in range and not decrease after inserts.
  let rate1 = bloom_false_positive_rate(&b);
  if rate1 < 0.0 { io.println("bloom:rate-negative"); return 2; };
  if rate1 > 1.0 { io.println("bloom:rate-over"); return 3; };
  if rate1 < rate0 { io.println("bloom:rate-decrease"); return 4; };

  // A second pass over the inserted keys still finds them all.
  i = 0;
  while i < 500 {
    var k = key_of(keys[i]);
    if !bloom_maybe_contains(&b, &k) { io.println("bloom:second-pass"); return 5; };
    i = i + 1;
  };

  // clear() must empty the filter: previously inserted keys are gone.
  bloom_clear(&mut b);
  i = 0;
  while i < 500 {
    var k = key_of(keys[i]);
    if bloom_maybe_contains(&b, &k) { io.println("bloom:clear"); return 6; };
    i = i + 1;
  };
  let rate2 = bloom_false_positive_rate(&b);
  if rate2 < 0.0 { io.println("bloom:rate-after-clear"); return 7; };

  io.println("smoke_prop_collect_bloom OK");
  return 0;
}
