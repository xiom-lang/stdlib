// p_wave18_shapes.xi -- contract shape validation for wave 18 (sort + search).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the shapes wave 18 applies to xiom.sort / xiom.search:
// 1. cross-module predicate call in a postcondition: `intro.is_sorted(v)`
// 2. Option payload index bounds: `result is Some => result.value >= 0 &&
//    result.value < v.len()`
// 3. position bound: `result >= 0 && result <= v.len()`
// 4. tuple-return field bounds: `result.0 >= 0 && result.1 >= result.0 &&
//    result.1 <= v.len()`
// 5. Vec length sum across params: `result.len() == a.len() + b.len()`
// 6. Vec length bound: `result.len() <= v.len()`
// 7. `@pre` length on a `&mut Vec` parameter: `v.len() == v.len()@pre`
// 8. Str parameters in a clause: `result.value + pattern.len() <=
//    text.len()`
// main() also drives the real sort/search functions and asserts the runtime
// properties the clauses will require. Returns 0 when every shape compiles
// and holds.

module p_wave18_shapes

use xiom.sort.intro;
use xiom.sort.heap;
use xiom.sort.quick;
use xiom.sort.merge;
use xiom.search.binary;
use xiom.search.kmp;

// Shape 1: cross-module predicate in a postcondition.
fn s_sort(v: &mut Vec[Int])
  ensures: intro.is_sorted(v) == true
{
  intro.insertion_sort(v);
}

// Shape 2: Option payload index bounds.
fn s_find(v: &Vec[Int], target: Int) -> Option[Int]
  ensures: result is Some => result.value >= 0 && result.value < v.len()
{
  return binary.binary_search(v, target);
}

// Shape 3: position bound.
fn s_pos(v: &Vec[Int], target: Int) -> Int
  ensures: result >= 0 && result <= v.len()
{
  return binary.lower_bound(v, target);
}

// Shape 4: tuple-return field bounds.
fn s_range(v: &Vec[Int], target: Int) -> (Int, Int)
  ensures: result.0 >= 0 && result.1 >= result.0 && result.1 <= v.len()
{
  return binary.search_range(v, target);
}

// Shape 5: length sum across parameters.
fn s_merge(a: &Vec[Int], b: &Vec[Int]) -> Vec[Int]
  ensures: result.len() == a.len() + b.len()
{
  return merge.merge(a, b);
}

// Shape 6: length bound against a parameter.
fn s_all(v: &Vec[Int], target: Int) -> Vec[Int]
  ensures: result.len() <= v.len()
{
  var out = Vec[Int].new();
  var i = 0;
  while i < v.len() {
    if v[i] == target {
      out.push(i);
    }
    i = i + 1;
  }
  return out;
}

// Shape 7: @pre length on a &mut Vec parameter.
fn s_stable(v: &mut Vec[Int])
  ensures: v.len() == v.len()@pre
  ensures: intro.is_sorted(v) == true
{
  intro.sort_stable(v);
}

// Shape 8: Str parameters in a clause.
fn s_needle(text: Str, pattern: Str) -> Option[Int]
  ensures: result is Some => result.value >= 0 && result.value + pattern.len() <= text.len()
{
  return kmp.kmp_search(text, pattern);
}

fn main() -> Int {
  var v: Vec[Int] = Vec[Int].new();
  v.push(3); v.push(1); v.push(2); v.push(2); v.push(7);
  s_sort(&v);
  if !intro.is_sorted(&v) { return 1; }

  heap.heap_sort(&v);
  if !intro.is_sorted(&v) { return 2; }
  quick.quick_sort(&v);
  if !intro.is_sorted(&v) { return 3; }
  merge.merge_sort(&v);
  if !intro.is_sorted(&v) { return 4; }

  let f = s_find(&v, 2);
  if f is Some {
    if f.value < 0 || f.value >= v.len() { return 5; }
  }
  let p = s_pos(&v, 2);
  if p < 0 || p > v.len() { return 6; }
  let r = s_range(&v, 2);
  if r.0 < 0 || r.1 < r.0 || r.1 > v.len() { return 7; }

  var a: Vec[Int] = Vec[Int].new();
  a.push(5); a.push(1);
  var b: Vec[Int] = Vec[Int].new();
  b.push(4); b.push(0); b.push(9);
  let m = s_merge(&a, &b);
  if m.len() != a.len() + b.len() { return 8; }
  let all = s_all(&v, 2);
  if all.len() > v.len() { return 9; }

  s_stable(&v);
  if !intro.is_sorted(&v) { return 10; }

  let n = s_needle("hello world", "world");
  if n is Some {
    if n.value < 0 || n.value + 5 > 11 { return 11; }
  }

  let pi = kmp.kmp_prefix_table("ababaca");
  if pi.len() != 7 { return 12; }
  return 0;
}
