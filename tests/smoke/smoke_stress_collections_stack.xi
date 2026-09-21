// XIOM stdlib stress -- Stack push, pop, peek
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Tests LIFO stack operations including empty stack behavior.
// Returns 0 on success, nonzero on failure.

module smoke_stress_collections_stack
use xiom.collections;

fn main() -> Int {
  var st = Stack[Int].new();
  if st.len() != 0 { return 1; }
  st.push(10);
  st.push(20);
  st.push(30);
  if st.len() != 3 { return 2; }
  match st.peek() {
    Some(v) => { if v != 30 { return 3; } }
    None => { return 4; }
  }
  match st.pop() {
    Some(v) => { if v != 30 { return 5; } }
    None => { return 6; }
  }
  match st.pop() {
    Some(v) => { if v != 20 { return 7; } }
    None => { return 8; }
  }
  match st.pop() {
    Some(v) => { if v != 10 { return 9; } }
    None => { return 10; }
  }
  if st.len() != 0 { return 11; }
  match st.pop() {
    Some(_) => { return 12; }
    None => { }
  }
  return 0;
}
