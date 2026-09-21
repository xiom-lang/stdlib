// XIOM - Time: Instant
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.time.instant

// Depends on: xiom.time

// ============================================================================
// Monotonic timestamps for measuring elapsed wall time.
// Delegates to the parent xiom.time.Instant implementation; comparison and
// millisecond conversions read the instant's internal second value.
// ============================================================================

use xiom.time;

/// The current monotonic instant.
/// Returns: an Instant from the system monotonic clock.
/// Complexity: O(1).
pub fn instant_now() -> Instant {
  return time.Instant.now();
}

/// The time elapsed since `i`.
/// Params: i - the earlier instant.
/// Returns: now - i.
/// Complexity: O(1).
pub fn instant_elapsed(i: Instant) -> Duration {
  return i.elapsed();
}

/// The time between `a` and `b`.
/// Params: a - the later instant; b - the earlier instant.
/// Returns: a - b.
/// Complexity: O(1).
pub fn instant_duration_since(a: Instant, b: Instant) -> Duration {
  return a.duration_since(b);
}

/// `i` advanced by `d`.
/// Params: i - the instant; d - the duration to add.
/// Returns: i + d.
/// Complexity: O(1).
pub fn instant_add(i: Instant, d: Duration) -> Instant {
  return i.add(d);
}

/// `i` moved back by `d`.
/// Params: i - the instant; d - the duration to subtract.
/// Returns: i - d.
/// Complexity: O(1).
pub fn instant_sub(i: Instant, d: Duration) -> Instant {
  return i.sub(d);
}

/// Compare two instants.
/// Params: a - the left operand; b - the right operand.
/// Returns: negative, zero, or positive for a before, equal, after b.
/// Complexity: O(1).
pub fn instant_compare(a: Instant, b: Instant) -> Int {
  if a.t < b.t {
    return -1;
  }
  if a.t > b.t {
    return 1;
  }
  return 0;
}

/// `i` as milliseconds since an arbitrary origin.
/// Params: i - the instant.
/// Returns: the underlying second reading scaled to milliseconds.
/// Complexity: O(1).
pub fn instant_to_millis(i: Instant) -> Int {
  return i.t * 1000;
}

/// An instant from a millisecond reading.
/// Params: ms - a millisecond reading from the same arbitrary origin.
/// Returns: the corresponding Instant.
/// Complexity: O(1).
pub fn instant_from_millis(ms: Int) -> Instant {
  return Instant{ t: ms / 1000; }
}
