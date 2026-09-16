// XIOM - Collections: Radix Trie
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.collect.radix

// Depends on: xiom.string

use xiom.string;

// ============================================================================
// Compressed prefix tree over decimal digit strings mapping keys to Int
// values.
//
// Flat-arena style. Every node carries the label of its incoming edge
// (`labels[i]`, the empty string at the root), a terminal flag plus the stored
// key/value for nodes that end a key, and a child list threaded through
// `child_head[i]` / `sibling[i]` (linked list of child node ids). Insertion
// follows the classic radix-trie algorithm: match a child whose label shares
// a prefix with the remaining key, split that label at the divergence point,
// and re-link the pieces. Removal marks a terminal node non-terminal (the
// node itself and its labels stay, so no recompaction is needed). All string
// reads go through xiom.string; Vec[Str] elements are bound to locals before
// comparison (compiler BUG 8 workaround).
// ============================================================================

pub type RadixTrie = {
  root: Int;
  size: Int;
  labels: Vec[Str];
  terminal: Vec[Bool];
  keys: Vec[Str];
  values: Vec[Int];
  child_head: Vec[Int];
  sibling: Vec[Int];
}

fn _add_node(r: &mut RadixTrie, label: Str, term: Bool, key: Str, value: Int) -> Int {
  r.labels.push(label);
  r.terminal.push(term);
  r.keys.push(key);
  r.values.push(value);
  r.child_head.push(-1);
  r.sibling.push(-1);
  return r.labels.len() - 1;
}

fn _link_child(r: &mut RadixTrie, parent: Int, node: Int) {
  r.sibling[node] = r.child_head[parent];
  r.child_head[parent] = node;
}

// Remove `node` from the child list of `parent` (if present).
fn _unlink_child(r: &mut RadixTrie, parent: Int, node: Int) {
  var cur = r.child_head[parent];
  var prev = -1;
  while cur != -1 {
    if cur == node {
      if prev == -1 {
        r.child_head[parent] = r.sibling[node];
      } else {
        r.sibling[prev] = r.sibling[node];
      }
      return;
    }
    prev = cur;
    cur = r.sibling[cur];
  }
}

// First child of `node` whose label starts with the character `c`, or -1.
fn _find_child(r: &RadixTrie, node: Int, c: Char) -> Int {
  var n = r.child_head[node];
  while n != -1 {
    var lbl = r.labels[n];
    if string.str_len(lbl) > 0 {
      var c0 = string.char_at(lbl, 0);
      if c0.is_some {
        if c0.value == c {
          return n;
        }
      }
    }
    n = r.sibling[n];
  }
  return -1;
}

// Length of the common prefix of `a` and `b`.
fn _common_len(a: Str, b: Str) -> Int {
  var la = string.str_len(a);
  var lb = string.str_len(b);
  var m = la;
  if lb < m {
    m = lb;
  }
  var i = 0;
  while i < m {
    var ca = string.char_at(a, i);
    var cb = string.char_at(b, i);
    if !ca.is_some || !cb.is_some {
      break;
    }
    if ca.value != cb.value {
      break;
    }
    i = i + 1;
  }
  return i;
}

/// Create a new empty radix trie (root node only).
/// O(1).
pub fn radix_new() -> RadixTrie {
  var r = RadixTrie{ root: -1; size: 0; labels: Vec[Str].new(); terminal: Vec[Bool].new(); keys: Vec[Str].new(); values: Vec[Int].new(); child_head: Vec[Int].new(); sibling: Vec[Int].new(); };
  var root = _add_node(&mut r, "", false, "", 0);
  r.root = root;
  return r;
}

/// Insert `key` with its value. Empty keys are rejected. Inserting an
/// existing key is a no-op (the original value is kept).
/// O(L) where L is the key length (amortized).
pub fn radix_insert(r: &mut RadixTrie, key: Str, value: Int) {
  if string.str_len(key) == 0 {
    return;
  }
  var node = r.root;
  var rem = key;
  loop {
    var c0 = string.char_at(rem, 0);
    if !c0.is_some {
      return;
    }
    var child = _find_child(r, node, c0.value);
    if child == -1 {
      var leaf = _add_node(r, rem, true, key, value);
      _link_child(r, node, leaf);
      r.size = r.size + 1;
      return;
    }
    var lbl = r.labels[child];
    var lbl_len = string.str_len(lbl);
    var common = _common_len(lbl, rem);
    if common < lbl_len {
      var mid = _add_node(r, string.str_slice(lbl, 0, common), false, "", 0);
      r.labels[child] = string.str_slice(lbl, common, lbl_len);
      _unlink_child(r, node, child);
      _link_child(r, mid, child);
      _link_child(r, node, mid);
      var rem2 = string.str_slice(rem, common, string.str_len(rem));
      if string.str_len(rem2) == 0 {
        r.terminal[mid] = true;
        r.keys[mid] = key;
        r.values[mid] = value;
        r.size = r.size + 1;
        return;
      }
      var leaf2 = _add_node(r, rem2, true, key, value);
      _link_child(r, mid, leaf2);
      r.size = r.size + 1;
      return;
    }
    var rem2 = string.str_slice(rem, common, string.str_len(rem));
    if string.str_len(rem2) == 0 {
      if r.terminal[child] {
        return;
      }
      r.terminal[child] = true;
      r.keys[child] = key;
      r.values[child] = value;
      r.size = r.size + 1;
      return;
    }
    node = child;
    rem = rem2;
  }
}

/// Check whether `key` is stored (exact match). Empty keys are absent.
/// O(L).
pub fn radix_contains(r: &RadixTrie, key: Str) -> Bool {
  var node = r.root;
  var rem = key;
  loop {
    if string.str_len(rem) == 0 {
      return r.terminal[node];
    }
    var c0 = string.char_at(rem, 0);
    if !c0.is_some {
      return false;
    }
    var child = _find_child(r, node, c0.value);
    if child == -1 {
      return false;
    }
    var lbl = r.labels[child];
    var common = _common_len(lbl, rem);
    if common < string.str_len(lbl) {
      return false;
    }
    node = child;
    rem = string.str_slice(rem, common, string.str_len(rem));
  }
}

/// Remove `key`, returning whether it was present. The node is marked
/// non-terminal; its label and children remain in the arena.
/// O(L).
pub fn radix_remove(r: &mut RadixTrie, key: Str) -> Bool {
  var node = r.root;
  var rem = key;
  loop {
    if string.str_len(rem) == 0 {
      if r.terminal[node] {
        r.terminal[node] = false;
        r.size = r.size - 1;
        return true;
      }
      return false;
    }
    var c0 = string.char_at(rem, 0);
    if !c0.is_some {
      return false;
    }
    var child = _find_child(r, node, c0.value);
    if child == -1 {
      return false;
    }
    var lbl = r.labels[child];
    var common = _common_len(lbl, rem);
    if common < string.str_len(lbl) {
      return false;
    }
    node = child;
    rem = string.str_slice(rem, common, string.str_len(rem));
  }
}

/// Length of the longest stored key that is a prefix of `key` (0 if none).
/// O(L).
pub fn radix_longest_prefix(r: &RadixTrie, key: Str) -> Int
  ensures: result >= 0
{
  var node = r.root;
  var rem = key;
  var acc = 0;
  var best = 0;
  loop {
    if r.terminal[node] {
      if acc > best {
        best = acc;
      }
    }
    if string.str_len(rem) == 0 {
      break;
    }
    var c0 = string.char_at(rem, 0);
    if !c0.is_some {
      break;
    }
    var child = _find_child(r, node, c0.value);
    if child == -1 {
      break;
    }
    var lbl = r.labels[child];
    var common = _common_len(lbl, rem);
    if common < string.str_len(lbl) {
      break;
    }
    acc = acc + common;
    node = child;
    rem = string.str_slice(rem, common, string.str_len(rem));
  }
  return best;
}

/// Number of stored keys.
/// O(1).
pub fn radix_size(r: &RadixTrie) -> Int
  ensures: result >= 0
{
  return r.size;
}
