// XIOM - Collections: Linked List
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.collect.list

// Depends on: none

// ============================================================================
// Doubly linked list of Int elements with O(1) push/pop/peek at both ends.
// Flat-arena representation (the established collect/ pattern): nodes live in
// three parallel Vec[Int]s (`values`/`prevs`/`nexts`) addressed by index;
// -1 is the "no node" sentinel. `head`/`tail` index the two ends. Removed
// nodes become unreachable arena entries. Indexed access is O(n); all index
// arguments are bounds-checked.
// ============================================================================

pub type LinkedList = {
  head: Int;
  tail: Int;
  size: Int;
  values: Vec[Int];
  prevs: Vec[Int];
  nexts: Vec[Int];
}

/// Create a new empty linked list. O(1).
pub fn linked_list_new() -> LinkedList {
  return LinkedList{
    head: -1; tail: -1; size: 0;
    values: Vec[Int].new(); prevs: Vec[Int].new(); nexts: Vec[Int].new();
  };
}

/// Append a new node holding `value` and return its arena index. O(1).
fn ll_new_node(l: &mut LinkedList, value: Int) -> Int {
  l.values.push(value);
  l.prevs.push(-1);
  l.nexts.push(-1);
  return l.values.len() - 1;
}

/// Add `value` to the front of the list. O(1).
pub fn ll_push_front(l: &mut LinkedList, value: Int) {
  var id = ll_new_node(l, value);
  if l.size == 0 {
    l.head = id;
    l.tail = id;
  } else {
    l.nexts[id] = l.head;
    l.prevs[l.head] = id;
    l.head = id;
  }
  l.size = l.size + 1;
}

/// Add `value` to the back of the list. O(1).
pub fn ll_push_back(l: &mut LinkedList, value: Int) {
  var id = ll_new_node(l, value);
  if l.size == 0 {
    l.head = id;
    l.tail = id;
  } else {
    l.prevs[id] = l.tail;
    l.nexts[l.tail] = id;
    l.tail = id;
  }
  l.size = l.size + 1;
}

/// Remove and return the front value. None if the list is empty. O(1).
pub fn ll_pop_front(l: &mut LinkedList) -> Option[Int] {
  if l.size == 0 { return None; }
  var id = l.head;
  var value = l.values[id];
  l.head = l.nexts[id];
  if l.head == -1 {
    l.tail = -1;
  } else {
    l.prevs[l.head] = -1;
  }
  l.size = l.size - 1;
  return Some(value);
}

/// Remove and return the back value. None if the list is empty. O(1).
pub fn ll_pop_back(l: &mut LinkedList) -> Option[Int] {
  if l.size == 0 { return None; }
  var id = l.tail;
  var value = l.values[id];
  l.tail = l.prevs[id];
  if l.tail == -1 {
    l.head = -1;
  } else {
    l.nexts[l.tail] = -1;
  }
  l.size = l.size - 1;
  return Some(value);
}

/// Return the front value without removing it. None if empty. O(1).
pub fn ll_front(l: &LinkedList) -> Option[Int] {
  if l.size == 0 { return None; }
  return Some(l.values[l.head]);
}

/// Return the back value without removing it. None if empty. O(1).
pub fn ll_back(l: &LinkedList) -> Option[Int] {
  if l.size == 0 { return None; }
  return Some(l.values[l.tail]);
}

/// Number of elements in the list. O(1).
pub fn ll_len(l: &LinkedList) -> Int {
  return l.size;
}

/// True if the list holds no elements. O(1).
pub fn ll_is_empty(l: &LinkedList) -> Bool {
  return l.size == 0;
}

/// Value at index `idx` (0 = front). None when idx is out of bounds. O(n).
pub fn ll_get(l: &LinkedList, idx: Int) -> Option[Int] {
  if idx < 0 || idx >= l.size { return None; }
  var cur = l.head;
  var i: Int = 0;
  while i < idx {
    cur = l.nexts[cur];
    i = i + 1;
  }
  return Some(l.values[cur]);
}
