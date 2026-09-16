// XIOM - Error: Error Chaining
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.error.chain

// Depends on: xiom.error

use xiom.string;

// ============================================================================
// Linked ChainError chains with push/pop, message listing, root/top access and
// iteration.
//
// A chain is a list of messages ordered newest-first: `messages[0]` is the
// head (top), `messages[messages.len()-1]` is the root (the original cause).
// Values are immutable -- push/pop return new chains.
// ============================================================================

/// An ChainError node: `messages[0]` is the newest message (head), the last
/// element is the root. The chain is the full ordered list of messages.
pub type ChainError = {
  messages: Vec[Str];
} derive[Clone]

/// True when `a` and `b` hold the same bytes (content comparison; the `==`
/// operator on Vec[Str] elements compares pointers in this build).
fn str_eq(a: Str, b: Str) -> Bool {
  let la = a.len();
  let lb = b.len();
  if la != lb {
    return false;
  };
  var i: Int = 0;
  while i < la {
    if string.byte_at(a, i) != string.byte_at(b, i) {
      return false;
    };
    i = i + 1;
  };
  true
}

/// Create a chain with a single message.
/// Complexity: O(1).
pub fn error_chain_new(message: Str) -> ChainError {
  var messages = Vec[Str].new();
  messages.push(message);
  ChainError{ messages: messages; }
}

/// Add `message` onto the chain and return the new head. The previous chain
/// becomes the new chain's root portion.
/// Complexity: O(len(chain)).
pub fn error_chain_push(e: ChainError, message: Str) -> ChainError {
  var messages = Vec[Str].new();
  messages.push(message);
  var i: Int = 0;
  while i < e.messages.len() {
    let m = e.messages[i];
    messages.push(m);
    i = i + 1;
  };
  ChainError{ messages: messages; }
}

/// Remove and return the head, exposing the previous cause. Returns None when
/// the chain has only one message (nothing left beneath the head).
/// Complexity: O(len(chain)).
pub fn error_chain_pop(e: ChainError) -> Option[ChainError] {
  if e.messages.len() <= 1 {
    return None;
  };
  var messages = Vec[Str].new();
  var i: Int = 1;
  while i < e.messages.len() {
    let m = e.messages[i];
    messages.push(m);
    i = i + 1;
  };
  Some(ChainError{ messages: messages; })
}

/// The number of messages in the chain.
/// Complexity: O(1).
pub fn error_chain_len(e: ChainError) -> Int {
  e.messages.len()
}

/// All messages from head to root, newest first.
/// Complexity: O(len(chain)).
pub fn error_chain_messages(e: ChainError) -> Vec[Str] {
  let result = e.messages;
  result
}

/// The oldest (root) message.
/// Complexity: O(1).
pub fn error_chain_root(e: ChainError) -> Str {
  let root = e.messages[e.messages.len() - 1];
  root
}

/// The newest (head) message.
/// Complexity: O(1).
pub fn error_chain_top(e: ChainError) -> Str {
  let top = e.messages[0];
  top
}

/// All nodes from head to root. Node `i` is the chain whose head is message
/// `i`, i.e. an ChainError holding messages `i..len`.
/// Complexity: O(len(chain)^2) total for the sliced copies.
pub fn error_chain_iter(e: ChainError) -> Vec[ChainError] {
  var nodes = Vec[ChainError].new();
  let n = e.messages.len();
  var i: Int = 0;
  while i < n {
    var messages = Vec[Str].new();
    var j = i;
    while j < n {
      let m = e.messages[j];
      messages.push(m);
      j = j + 1;
    };
    nodes.push(ChainError{ messages: messages; });
    i = i + 1;
  };
  nodes
}

/// Whether any node in the chain carries `message`.
/// Complexity: O(len(chain) * len(message)) for the content comparison.
pub fn error_chain_has(e: ChainError, message: Str) -> Bool {
  var i: Int = 0;
  while i < e.messages.len() {
    let m = e.messages[i];
    if str_eq(m, message) {
      return true;
    };
    i = i + 1;
  };
  false
}
