// XIOM -- Collections: Trie (prefix tree, lowercase a-z keys)
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.collect.trie

// TODO(compiler): combining this module with collect.skiplist in one program
// fast-fails at exit (0xC0000409) -- see docs/COMPILER_BUGS.md BUG 16.
// The modules are correct individually; keep them in separate smokes.


use xiom.string;
use xiom.convert;

// ============================================================================
// Trie (Str keys, lowercase a-z only; other chars are rejected)
// Flat-arena style (the established collect/ pattern -- tree.xi/graph.xi use
// parallel Vec[Int]s because Vec-of-struct instantiations collide at startup
// in combined programs, COMPILER_BUGS.md BUG 16). Node n's child for letter
// c is children[n * 26 + c] (-1 = none); ends[n] is 1 for a complete word.
// `trie_complete` returns all words with a prefix, in DFS lexicographic
// order. Node 0 is the root.
// ============================================================================

pub type Trie = { children: Vec[Int]; ends: Vec[Int]; size: Int; }

fn _slot(node: Int, letter: Int) -> Int {
  return node * 26 + letter;
}

// Returns the node index reached by `word` (creating nodes when creating =
// true), or -1 if the path is missing. Also returns the first offending char
// position via a negative node.
fn _walk(t: &mut Trie, word: Str, creating: Bool) -> Int {
  var node: Int = 0;
  var i: Int = 0;
  var len = string.str_len(word);
  while i < len {
    var c = string.char_at(word, i);
    var code: Int = -1;
    if c.is_some {
      code = convert.char_to_int(c.value);
    }
    if code < 97 || code > 122 {
      return -1;
    }
    var ci = code - 97;
    var child = t.children[_slot(node, ci)];
    if child == -1 {
      if !creating {
        return -1;
      }
      // add a new node: 26 children + 1 end marker
      var k: Int = 0;
      while k < 26 {
        t.children.push(-1);
        k = k + 1;
      }
      t.ends.push(0);
      child = t.ends.len() - 1;
      t.children[_slot(node, ci)] = child;
    }
    node = child;
    i = i + 1;
  }
  return node;
}

/// Create an empty trie (root node allocated).
pub fn trie_new() -> Trie {
  var children = Vec[Int].new();
  var ends = Vec[Int].new();
  var k: Int = 0;
  while k < 26 {
    children.push(-1);
    k = k + 1;
  }
  ends.push(0);
  return Trie{ children: children; ends: ends; size: 0; };
}

/// Insert a lowercase word. Returns false if the word already exists or
/// contains non a-z characters.
pub fn trie_insert(t: &mut Trie, word: Str) -> Bool {
  if string.str_len(word) == 0 {
    return false;
  }
  var node = _walk(t, word, true);
  if node == -1 {
    return false;
  }
  if t.ends[node] == 1 {
    return false;
  }
  t.ends[node] = 1;
  t.size = t.size + 1;
  return true;
}

/// True if `word` is stored (exact match).
pub fn trie_contains(t: &Trie, word: Str) -> Bool {
  if string.str_len(word) == 0 {
    return false;
  }
  var node = _walk(t, word, false);
  if node == -1 {
    return false;
  }
  return t.ends[node] == 1;
}

/// Number of words stored.
pub fn trie_size(t: &Trie) -> Int
  ensures: result >= 0
{
  return t.size;
}

// DFS over the subtree of `node`, appending `prefix` + completed words.
fn _collect(t: &Trie, node: Int, prefix: Str, out: &mut Vec[Str]) {
  if t.ends[node] == 1 {
    out.push(prefix);
  }
  var i: Int = 0;
  while i < 26 {
    var child = t.children[_slot(node, i)];
    if child != -1 {
      var ch = string.str_slice("abcdefghijklmnopqrstuvwxyz", i, i + 1);
      _collect(t, child, string.str_concat(prefix, ch), out);
    }
    i = i + 1;
  }
}

/// All stored words starting with `prefix` (lexicographic DFS order).
/// Returns an empty Vec if no word matches.
pub fn trie_complete(t: &Trie, prefix: Str) -> Vec[Str] {
  var out = Vec[Str].new();
  var node = _walk(t, prefix, false);
  if node == -1 {
    return out;
  }
  _collect(t, node, prefix, &mut out);
  return out;
}

/// True if any stored word starts with `prefix`.
pub fn trie_has_prefix(t: &Trie, prefix: Str) -> Bool {
  var node = _walk(t, prefix, false);
  return node != -1;
}

/// Remove `word`. Returns true if it was present.
pub fn trie_remove(t: &mut Trie, word: Str) -> Bool {
  var node = _walk(t, word, false);
  if node == -1 {
    return false;
  }
  if t.ends[node] != 1 {
    return false;
  }
  t.ends[node] = 0;
  t.size = t.size - 1;
  return true;
}

