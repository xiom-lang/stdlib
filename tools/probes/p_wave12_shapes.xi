// p_wave12_shapes.xi -- contract shape validation for wave 12.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Validates the NEW clause shapes BEFORE they are applied to the stdlib:
// 1. bare `result is Ok` (no implication) on Result[Vec[UInt8], Str]
// 2. `ensures: sibling_fn(c, key)` with a &mut receiver (lfu_contains)
// 3. `ensures: sibling_fn(sk, key) >= 1` after a mutation (cms_estimate)
// 4. `ensures: result == (sibling_fn(f, key) >= frequency)`
// 5. `ensures: result.counts.len() == result.width * result.depth` (ctor)
// 6. `ensures: size(c) >= size(c)@pre` / `<= @pre + 1` via a sibling fn
// Returns 0 when every shape compiles and holds at runtime.

module p_wave12_shapes

use xiom.collect.lfu;
use xiom.collect.tinylfu;

// Shape 1: bare `result is Ok`.
fn s_ok_bytes(n: Int) -> Result[Vec[UInt8], Str]
  ensures: result is Ok
{
  var out = Vec[UInt8].new();
  var i = 0;
  while i < n {
    out.push(7);
    i = i + 1;
  }
  return Ok(out);
}

// Shape 2: ensures calls a sibling fn with a &mut receiver.
fn s_lfu_put(c: &mut LfuCache, key: Int, value: Int)
  ensures: lfu_contains(c, key)
{
  lfu_put(c, key, value);
}

// Shape 3: sibling-fn call bound after a mutation.
fn s_cms_add(sk: &mut CountMinSketch, key: Int)
  ensures: cms_estimate(sk, key) >= 1
{
  cms_add(sk, key);
}

// Shape 4: result equals a sibling-fn predicate.
fn s_admit(f: &TinyLfu, key: Int, frequency: Int) -> Bool
  ensures: result == (tinylfu_estimate(f, key) >= frequency)
{
  return tinylfu_admit(f, key, frequency);
}

// Shape 5: constructor result field-count arithmetic.
fn s_cms_new(w: Int, d: Int) -> CountMinSketch
  ensures: result.counts.len() == result.width * result.depth
{
  return count_min_sketch_new(w, d);
}

// Shape 6: @pre bounds through a sibling fn on a &mut param.
fn s_lfu_put_size(c: &mut LfuCache, key: Int, value: Int)
  ensures: lfu_size(c) >= lfu_size(c)@pre
  ensures: lfu_size(c) <= lfu_size(c)@pre + 1
{
  lfu_put(c, key, value);
}

fn main() -> Int {
  var r = s_ok_bytes(3);
  match r {
    Ok(v) => { if v.len() != 3 { return 1; } },
    Err(e) => { return 2; },
  }

  var c = lfu_new(2);
  s_lfu_put(&mut c, 1, 10);
  if !lfu_contains(&mut c, 1) { return 3; }

  var g = lfu_get(&mut c, 1);
  if !g.is_some { return 4; }
  if g.value != 10 { return 5; }

  var sk = count_min_sketch_new(4, 2);
  s_cms_add(&mut sk, 7);
  if cms_estimate(&sk, 7) < 1 { return 6; }

  var c2 = lfu_new(2);
  s_lfu_put_size(&mut c2, 2, 20);
  if lfu_size(&mut c2) != 1 { return 7; }
  s_lfu_put_size(&mut c2, 2, 21);
  if lfu_size(&mut c2) != 1 { return 8; }
  s_lfu_put_size(&mut c2, 3, 30);
  if lfu_size(&mut c2) != 2 { return 9; }

  var f = tinylfu_new(4);
  tinylfu_increment(&mut f, 3);
  var a = s_admit(&f, 3, 1);
  if !a { return 10; }

  return 0;
}
