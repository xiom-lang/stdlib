// XIOM - Collections: Stack
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.collect.stack

// Depends on: none

// ============================================================================
// LIFO stack of Int elements backed by the built-in Vec[Int]. All operations
// are O(1); `stack_pop`/`stack_peek` return None on an empty stack.
// ============================================================================

pub type Stack = {
  items: Vec[Int];
}

/// Create a new empty stack. O(1).
pub fn stack_new() -> Stack {
  return Stack{ items: Vec[Int].new(); };
}

/// Push `value` onto the top of the stack. O(1).
pub fn stack_push(s: &mut Stack, value: Int) {
  s.items.push(value);
}

/// Remove and return the top value. None if the stack is empty. O(1).
pub fn stack_pop(s: &mut Stack) -> Option[Int] {
  if s.items.len() == 0 { return None; }
  var o = s.items.pop();
  match o {
    Some(x) => { return Some(x); },
    None => { return None; },
  }
}

/// Return the top value without removing it. None if empty. O(1).
pub fn stack_peek(s: &Stack) -> Option[Int] {
  if s.items.len() == 0 { return None; }
  var last = s.items.len() - 1;
  return Some(s.items[last]);
}

/// Number of elements on the stack. O(1).
pub fn stack_len(s: &Stack) -> Int
  ensures: result >= 0
{
  var len = s.items.len();
  return len;
}

/// True if the stack holds no elements. O(1).
pub fn stack_is_empty(s: &Stack) -> Bool
  ensures: result == (stack_len(s) == 0)
{
  return s.items.len() == 0;
}

/// Remove all elements. O(1) (capacity is retained).
pub fn stack_clear(s: &mut Stack)
  ensures: stack_len(s) == 0
{
  s.items.clear();
}
