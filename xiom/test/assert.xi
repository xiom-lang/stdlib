// XIOM - Test: Assertions
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.test.assert

// Depends on: xiom.test

use xiom.string;
use xiom.regex.engine;

// ============================================================================
// Test assertions: boolean, generic equality/ordering, near, contains,
// matches, Result/Option and panics checks.
//
// A failing assertion aborts the program with a panic (there is no unwind
// mechanism in this build), so a test should return `Err` from its
// `Result[Unit, Str]` body to report a soft failure. `assert_panics` /
// `assert_throws` cannot observe a panic because panics terminate the
// process; they run `f` and panic with `msg` when `f` returns normally
// (documented limitation).
// ============================================================================

/// Fail the test unless `cond` is true.
/// Complexity: O(1).
pub fn assert(cond: Bool, msg: Str) {
  if !cond {
    xiom.core.panic(msg);
  };
}

/// Fail unless `a` equals `b`.
/// Complexity: O(1) for scalars; O(len) for content types.
pub fn assert_eq[T: Eq](a: T, b: T, msg: Str) {
  if !(a == b) {
    xiom.core.panic(msg);
  };
}

/// Fail unless `a` differs from `b`.
/// Complexity: O(1) for scalars; O(len) for content types.
pub fn assert_ne[T: Eq](a: T, b: T, msg: Str) {
  if a == b {
    xiom.core.panic(msg);
  };
}

/// Fail unless `a` is less than `b`.
/// Complexity: O(1).
pub fn assert_lt[T: Ord](a: T, b: T, msg: Str) {
  if !(a < b) {
    xiom.core.panic(msg);
  };
}

/// Fail unless `a` is less than or equal to `b`.
/// Complexity: O(1).
pub fn assert_le[T: Ord](a: T, b: T, msg: Str) {
  if !(a <= b) {
    xiom.core.panic(msg);
  };
}

/// Fail unless `a` is greater than `b`.
/// Complexity: O(1).
pub fn assert_gt[T: Ord](a: T, b: T, msg: Str) {
  if !(a > b) {
    xiom.core.panic(msg);
  };
}

/// Fail unless `a` is greater than or equal to `b`.
/// Complexity: O(1).
pub fn assert_ge[T: Ord](a: T, b: T, msg: Str) {
  if !(a >= b) {
    xiom.core.panic(msg);
  };
}

/// Fail unless `cond` is true.
/// Complexity: O(1).
pub fn assert_true(cond: Bool, msg: Str) {
  if !cond {
    xiom.core.panic(msg);
  };
}

/// Fail unless `cond` is false.
/// Complexity: O(1).
pub fn assert_false(cond: Bool, msg: Str) {
  if cond {
    xiom.core.panic(msg);
  };
}

/// Fail unless `a` and `b` are within `eps` of each other.
/// Complexity: O(1).
pub fn assert_near(a: Float64, b: Float64, eps: Float64, msg: Str) {
  var d = a - b;
  if d < 0.0 {
    d = -d;
  };
  if d > eps {
    xiom.core.panic(msg);
  };
}

/// Fail unless `haystack` contains `needle`.
/// Complexity: O(len(haystack) * len(needle)).
pub fn assert_contains(haystack: Str, needle: Str, msg: Str) {
  if !string.str_contains(haystack, needle) {
    xiom.core.panic(msg);
  };
}

/// Fail unless `s` matches the regex `pattern` (search semantics, via
/// xiom.regex.engine).
/// Complexity: O(len(s) * len(pattern)) worst case.
pub fn assert_matches(s: Str, pattern: Str, msg: Str) {
  if !engine.regex_is_match(pattern, s) {
    xiom.core.panic(msg);
  };
}

/// Fail on Err and return the Ok value.
/// Complexity: O(1).
pub fn assert_ok[T](r: Result[T, Str], msg: Str) -> T {
  if r.is_ok {
    return r.value;
  };
  xiom.core.panic(msg);
  r.value
}

/// Fail unless `r` is an Err.
/// Complexity: O(1).
pub fn assert_err[T](r: Result[T, Str], msg: Str) {
  if r.is_ok {
    xiom.core.panic(msg);
  };
}

/// Fail on None and return the value.
/// Complexity: O(1).
pub fn assert_some[T](o: Option[T], msg: Str) -> T {
  if o.is_some {
    return o.value;
  };
  xiom.core.panic(msg);
  o.value
}
}

/// Fail unless `o` is None.
/// Complexity: O(1).
pub fn assert_none[T](o: Option[T], msg: Str) {
  if o.is_some {
    xiom.core.panic(msg);
  };
}

/// Fail unless calling `f` panics. Panics terminate the process in this
/// build, so a panic cannot be observed: `f` is invoked and, if it returns
/// normally, this assertion panics with `msg`.
/// Complexity: O(cost of f).
pub fn assert_panics(f: fn(), msg: Str) {
  f();
  xiom.core.panic(msg);
}

/// Fail unless calling `f` raises an error. Same observable behaviour as
/// `assert_panics` in this build (no unwind support).
/// Complexity: O(cost of f).
pub fn assert_throws(f: fn(), msg: Str) {
  f();
  xiom.core.panic(msg);
}

/// Fail unless `v` has no elements.
/// Complexity: O(1).
pub fn assert_empty[T](v: &Vec[T], msg: Str) {
  if v.len() != 0 {
    xiom.core.panic(msg);
  };
}

/// Fail unless `v` has exactly `n` elements.
/// Complexity: O(1).
pub fn assert_len[T](v: &Vec[T], n: Int, msg: Str) {
  if v.len() != n {
    xiom.core.panic(msg);
  };
}
