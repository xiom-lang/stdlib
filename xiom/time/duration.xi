// XIOM - Time: Duration
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.time.duration

// Depends on: xiom.time

// ============================================================================
// Span-of-time arithmetic and conversion between time units.
// Delegates to the parent xiom.time.Duration implementation (all entry-point
// names here differ from the parent's method names, so every function is a
// thin wrapper around the real Duration API).
// ============================================================================

use xiom.time;

/// A duration of `n` whole seconds.
/// Params: n - the number of seconds.
/// Returns: a Duration of exactly `n` seconds.
/// Complexity: O(1).
pub fn duration_secs(n: Int) -> Duration {
  return time.Duration.from_secs(n);
}

/// A duration of `n` milliseconds.
/// Params: n - the number of milliseconds.
/// Returns: a Duration of exactly `n` milliseconds.
/// Complexity: O(1).
pub fn duration_millis(n: Int) -> Duration {
  return time.Duration.from_millis(n);
}

/// A duration of `n` microseconds.
/// Params: n - the number of microseconds.
/// Returns: a Duration of exactly `n` microseconds.
/// Complexity: O(1).
pub fn duration_micros(n: Int) -> Duration {
  return time.Duration.from_micros(n);
}

/// A duration of `n` nanoseconds.
/// Params: n - the number of nanoseconds.
/// Returns: a Duration of exactly `n` nanoseconds.
/// Complexity: O(1).
pub fn duration_nanos(n: Int) -> Duration {
  return time.Duration.from_nanos(n);
}

/// A duration from a fractional seconds value.
/// Params: f - the fractional seconds value.
/// Returns: a Duration equal to `f` seconds.
/// Complexity: O(1).
pub fn duration_from_secs_f64(f: Float64) -> Duration {
  return time.Duration.from_secs_f64(f);
}

/// The sum of two durations.
/// Params: a - the left operand; b - the right operand.
/// Returns: a + b.
/// Complexity: O(1).
pub fn duration_add(a: Duration, b: Duration) -> Duration {
  return a.add(b);
}

/// The difference of two durations.
/// Params: a - the left operand; b - the right operand.
/// Returns: a - b.
/// Complexity: O(1).
pub fn duration_sub(a: Duration, b: Duration) -> Duration {
  return a.sub(b);
}

/// `a` scaled by the integer `n`.
/// Params: a - the duration; n - the scale factor.
/// Returns: a * n.
/// Complexity: O(1).
pub fn duration_mul(a: Duration, n: Int) -> Duration {
  return a.mul(n);
}

/// `a` divided by the integer `n`.
/// Params: a - the duration; n - the divisor.
/// Returns: a / n, or a zero duration if `n` is zero.
/// Complexity: O(1).
pub fn duration_div(a: Duration, n: Int) -> Duration {
  if n == 0 {
    return time.Duration.from_secs(0);
  }
  return a.div(n);
}

/// The whole seconds of `d`.
/// Params: d - the duration.
/// Returns: the seconds component.
/// Complexity: O(1).
pub fn duration_as_secs(d: Duration) -> Int {
  return d.as_secs();
}

/// `d` in whole milliseconds.
/// Params: d - the duration.
/// Returns: the duration truncated to milliseconds.
/// Complexity: O(1).
pub fn duration_as_millis(d: Duration) -> Int {
  return d.as_millis();
}

/// `d` in whole microseconds.
/// Params: d - the duration.
/// Returns: the duration truncated to microseconds.
/// Complexity: O(1).
pub fn duration_as_micros(d: Duration) -> Int {
  return d.as_micros();
}

/// `d` in whole nanoseconds.
/// Params: d - the duration.
/// Returns: the duration truncated to nanoseconds.
/// Complexity: O(1).
pub fn duration_as_nanos(d: Duration) -> Int {
  return d.as_nanos();
}

/// Compare two durations.
/// Params: a - the left operand; b - the right operand.
/// Returns: negative, zero, or positive for a before, equal, after b.
/// Complexity: O(1).
pub fn duration_compare(a: Duration, b: Duration) -> Int {
  var sa = a.as_secs();
  var sb = b.as_secs();
  if sa < sb {
    return -1;
  }
  if sa > sb {
    return 1;
  }
  var na = a.subsec_nanos();
  var nb = b.subsec_nanos();
  if na < nb {
    return -1;
  }
  if na > nb {
    return 1;
  }
  return 0;
}

/// True if `d` is exactly zero.
/// Params: d - the duration.
/// Returns: whether both components are zero.
/// Complexity: O(1).
pub fn duration_is_zero(d: Duration) -> Bool {
  return d.as_secs() == 0 && d.subsec_nanos() == 0;
}
