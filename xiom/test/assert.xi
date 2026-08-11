// XIOM - Test: Assertions
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.test.assert

// Depends on: xiom.test

// ============================================================================
// Test assertions: boolean, generic equality/ordering, near, contains,
// matches, Result/Option and panics checks. NOTE: current implementation
// lives in test.xi - move the functions here during the implementation phase.
// TODO(compiler): implement.
// ============================================================================

// fn assert(cond: Bool, msg: Str) - fail the test unless cond is true. TODO(compiler): implement.
// fn assert_eq[T](a, b, msg: Str) - fail unless a equals b. TODO(compiler): implement.
// fn assert_ne[T](a, b, msg: Str) - fail unless a differs from b. TODO(compiler): implement.
// fn assert_lt[T](a, b, msg) - fail unless a is less than b. TODO(compiler): implement.
// fn assert_le[T](a, b, msg) - fail unless a is less than or equal to b. TODO(compiler): implement.
// fn assert_gt[T](a, b, msg) - fail unless a is greater than b. TODO(compiler): implement.
// fn assert_ge[T](a, b, msg) - fail unless a is greater than or equal to b. TODO(compiler): implement.
// fn assert_true(cond, msg) - fail unless cond is true. TODO(compiler): implement.
// fn assert_false(cond, msg) - fail unless cond is false. TODO(compiler): implement.
// fn assert_near(a: Float64, b: Float64, eps: Float64, msg) - fail unless a and b are within eps. TODO(compiler): implement.
// fn assert_contains(haystack: Str, needle: Str, msg) - fail unless haystack contains needle. TODO(compiler): implement.
// fn assert_matches(s: Str, pattern: Str, msg) - fail unless s matches a regex pattern. TODO(compiler): implement.
// fn assert_ok[T](r: Result[T, Str], msg) -> T - fail on Err and return the Ok value. TODO(compiler): implement.
// fn assert_err[T](r: Result[T, Str], msg) - fail unless r is an Err. TODO(compiler): implement.
// fn assert_some[T](o: Option[T], msg) -> T - fail on None and return the value. TODO(compiler): implement.
// fn assert_none[T](o: Option[T], msg) - fail unless o is None. TODO(compiler): implement.
// fn assert_panics(f: fn(), msg) - fail unless calling f panics. TODO(compiler): implement.
// fn assert_throws(f: fn(), msg) - fail unless calling f raises an error. TODO(compiler): implement.
// fn assert_empty[T](v: &Vec[T], msg) - fail unless v has no elements. TODO(compiler): implement.
// fn assert_len[T](v: &Vec[T], n: Int, msg) - fail unless v has exactly n elements. TODO(compiler): implement.
