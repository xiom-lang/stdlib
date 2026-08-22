// XIOM - Error: Error Context
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.error.context

// Depends on: xiom.error

use xiom.string;

// ============================================================================
// Attach and query key/value context on errors, wrap errors with messages,
// and render pretty error text.
//
// Layout: `messages` is the head-first chain (like xiom.error.chain), `free`
// holds one free-form context string per layer ("" when absent), and
// `keys`/`values` hold the key/value pairs of the HEAD layer only (documented
// below). Values are immutable -- attaching or wrapping returns new errors.
// ============================================================================

/// An error node with per-layer messages and free-form context, plus the
/// key/value pairs attached to the head layer. When an Error is wrapped, the
/// previous head's pairs become part of the (now non-head) cause.
pub type ContextError = {
  messages: Vec[Str];
  free: Vec[Str];
  keys: Vec[Str];
  values: Vec[Str];
} derive[Clone]

/// True when `a` and `b` hold the same bytes (content comparison; `==` on
/// Vec[Str] elements compares pointers in this build).
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

/// Build a single-layer Error carrying `message` and `context` (the free-form
/// context string; may be empty).
fn build(message: Str, context: Str) -> ContextError {
  var messages = Vec[Str].new();
  messages.push(message);
  var free = Vec[Str].new();
  free.push(context);
  ContextError{ messages: messages; free: free; keys: Vec[Str].new(); values: Vec[Str].new(); }
}

/// Create a single-layer Error with `message` and no context. Bootstrap
/// helper (the frozen stubs provide no constructor).
/// Complexity: O(1).
pub fn error_context_new(message: Str) -> ContextError {
  build(message, "")
}

/// Attach a free-form context string to an Error (head layer). Returns a new
/// Error; the original is unchanged.
/// Complexity: O(1).
pub fn error_with_context(e: ContextError, context: Str) -> ContextError {
  var messages = Vec[Str].new();
  var i: Int = 0;
  while i < e.messages.len() {
    let m = e.messages[i];
    messages.push(m);
    i = i + 1;
  };
  var free = Vec[Str].new();
  i = 0;
  while i < e.free.len() {
    let f = e.free[i];
    free.push(f);
    i = i + 1;
  };
  if free.len() == 0 {
    free.push(context);
  } else {
    free[0] = context;
  };
  ContextError{ messages: messages; free: free; keys: e.keys; values: e.values; }
}

/// The free-form context string of the head layer, if any.
/// Complexity: O(1).
pub fn error_context(e: ContextError) -> Option[Str] {
  if e.free.len() > 0 {
    let f = e.free[0];
    if f.len() > 0 {
      return Some(f);
    };
  };
  None
}

/// Wrap `e` with an outer message. The wrapped Error becomes the cause.
/// Complexity: O(len(chain)).
pub fn error_wrap(e: ContextError, message: Str) -> ContextError {
  var messages = Vec[Str].new();
  messages.push(message);
  var i: Int = 0;
  while i < e.messages.len() {
    let m = e.messages[i];
    messages.push(m);
    i = i + 1;
  };
  var free = Vec[Str].new();
  free.push("");
  i = 0;
  while i < e.free.len() {
    let f = e.free[i];
    free.push(f);
    i = i + 1;
  };
  ContextError{ messages: messages; free: free; keys: Vec[Str].new(); values: Vec[Str].new(); }
}

/// The underlying message of the Error (head layer).
/// Complexity: O(1).
pub fn error_unwrap(e: ContextError) -> Str {
  let m = e.messages[0];
  m
}

/// Attach a named key/value pair to the head layer. Returns a new Error.
/// Complexity: O(head pairs).
pub fn error_attach_context(e: ContextError, key: Str, value: Str) -> ContextError {
  var keys = Vec[Str].new();
  var i: Int = 0;
  while i < e.keys.len() {
    let k = e.keys[i];
    keys.push(k);
    i = i + 1;
  };
  var values = Vec[Str].new();
  i = 0;
  while i < e.values.len() {
    let v = e.values[i];
    values.push(v);
    i = i + 1;
  };
  keys.push(key);
  values.push(value);
  ContextError{ messages: e.messages; free: e.free; keys: keys; values: values; }
}

/// The value stored under `key` on the head layer, if any.
/// Complexity: O(head pairs).
pub fn error_context_get(e: ContextError, key: Str) -> Option[Str] {
  var i: Int = 0;
  while i < e.keys.len() {
    let k = e.keys[i];
    if str_eq(k, key) {
      let v = e.values[i];
      return Some(v);
    };
    i = i + 1;
  };
  None
}

/// All context keys of the head layer, in attach order.
/// Complexity: O(head pairs).
pub fn error_context_keys(e: ContextError) -> Vec[Str] {
  let keys = e.keys;
  keys
}

/// All context pairs of the head layer; each tuple is (key, value).
/// Complexity: O(head pairs).
pub fn error_context_all(e: ContextError) -> Vec[(Str, Str)] {
  var pairs = Vec[(Str, Str)].new();
  var i: Int = 0;
  while i < e.keys.len() {
    let k = e.keys[i];
    let v = e.values[i];
    pairs.push((k, v));
    i = i + 1;
  };
  pairs
}

/// Format an error for display: `message (context: <free>; k=v, ...)` when
/// context exists, or just `message` otherwise.
/// Complexity: O(len(message) + len(context)).
pub fn error_pretty_print(e: ContextError) -> Str {
  let msg = e.messages[0];
  var suffix = "";
  if e.free.len() > 0 {
    let head_free = e.free[0];
    if head_free.len() > 0 {
      suffix = string.str_concat(suffix, head_free);
    };
  };
  var i: Int = 0;
  while i < e.keys.len() {
    if suffix.len() > 0 {
      suffix = string.str_concat(suffix, "; ");
    };
    suffix = string.str_concat(suffix, e.keys[i]);
    suffix = string.str_concat(suffix, "=");
    suffix = string.str_concat(suffix, e.values[i]);
    i = i + 1;
  };
  if suffix.len() > 0 {
    return string.str_concat(msg, string.str_concat(" (context: ", string.str_concat(suffix, ")")));
  };
  msg
}

/// Format an Error and its full chain, head first, as
/// `"outer <- inner (context: ...) <- root"`.
/// Complexity: O(len(chain) * message lengths).
pub fn error_pretty_print_chain(e: ContextError) -> Str {
  var result = "";
  var i: Int = 0;
  let n = e.messages.len();
  while i < n {
    if i > 0 {
      result = string.str_concat(result, " <- ");
    };
    let msg = e.messages[i];
    result = string.str_concat(result, msg);
    if i < e.free.len() {
      let fi = e.free[i];
      if fi.len() > 0 {
        result = string.str_concat(result, string.str_concat(" (context: ", string.str_concat(fi, ")")));
      };
    };
    i = i + 1;
  };
  result
}
