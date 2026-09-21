// p_wave7_shapes.xi -- contract shape validation for wave 7 (collect).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Validates every NEW clause shape before it is applied to the stdlib:
// 1. constructor field access + Vec.len() in ensures (result.keys.len() == 0)
// 2. Option.is_some == Bool query (non-mutating pair)
// 3. Option.is_some == (len > 0)
// 4. Vec result length == size query
// 5. post-remove absence (bool == false)
// 6. compound bounds expression (idx >= 0 && idx < len)
// 7. constructor param equality (result.cap == cap)
// 8. compound field equality on a returned struct (head/tail)
// Returns 0 when every shape compiles and holds at runtime.

module p_wave7_shapes

use xiom.collect.hash;
use xiom.collect.list;
use xiom.collect.queue;

fn s_ctor_field() -> LhMap
  ensures: result.keys.len() == 0
{
  return lhmap_new();
}

fn s_opt_bool(m: &LhMap, key: Int) -> Option[Int]
  ensures: result.is_some == lhmap_contains(m, key)
{
  return lhmap_get(m, key);
}

fn s_opt_len(l: &LinkedList) -> Option[Int]
  ensures: result.is_some == (ll_len(l) > 0)
{
  return ll_front(l);
}

fn s_len_eq(m: &LhMap) -> Vec[Int]
  ensures: result.len() == lhmap_size(m)
{
  return lhmap_keys_in_order(m);
}

fn s_remove_absent(m: &mut LhMap, key: Int)
  ensures: lhmap_contains(m, key) == false
{
  lhmap_remove(m, key);
}

fn s_bounds(l: &LinkedList, idx: Int) -> Option[Int]
  ensures: result.is_some == (idx >= 0 && idx < ll_len(l))
{
  return ll_get(l, idx);
}

fn s_param_eq(cap: Int) -> SpscRing
  ensures: result.cap == cap
{
  return spsc_ring_new(cap);
}

fn s_compound() -> Deque
  ensures: result.head == 0 && result.tail == 0
{
  return deque_new();
}

fn main() -> Int {
  var m = lhmap_new();
  lhmap_put(&m, 1, 10);
  var g = s_opt_bool(&m, 1);
  if !g.is_some { return 1; }
  var g2 = s_opt_bool(&m, 2);
  if g2.is_some { return 2; }
  s_remove_absent(&m, 1);
  if lhmap_contains(&m, 1) { return 3; }

  var l = linked_list_new();
  ll_push_back(&l, 5);
  var f = s_opt_len(&l);
  if !f.is_some { return 4; }
  var e = linked_list_new();
  var fe = s_opt_len(&e);
  if fe.is_some { return 5; }
  var b = s_bounds(&l, 0);
  if !b.is_some { return 6; }
  var bo = s_bounds(&l, 9);
  if bo.is_some { return 7; }

  var k = s_len_eq(&m);
  if k.len() != 0 { return 8; }
  var c = s_ctor_field();
  if c.keys.len() != 0 { return 9; }

  var r = s_param_eq(4);
  if r.cap != 4 { return 10; }
  var d = s_compound();
  if d.head != 0 || d.tail != 0 { return 11; }
  return 0;
}
