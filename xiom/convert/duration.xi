// XIOM - Conversion: Duration
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.convert.duration

// Depends on: xiom.time

// ============================================================================
// Duration construction and conversion helpers. All functions delegate to the
// canonical xiom.time Duration constructors/accessors (function names differ
// here, so delegation is safe from the same-name miscompile).
// ============================================================================

use xiom.time;

/// Build a Duration from whole seconds.
/// Parameters: n -- the number of seconds (may be negative).
/// Returns: a normalized Duration (nanos in [0, 1e9)).
/// Complexity: O(1).
pub fn duration_seconds(n: Int) -> Duration {
  return time.Duration.from_secs(n);
}

/// Build a Duration from whole milliseconds.
/// Parameters: n -- the number of milliseconds (may be negative).
/// Returns: a normalized Duration.
/// Complexity: O(1).
pub fn duration_millis(n: Int) -> Duration {
  return time.Duration.from_millis(n);
}

/// Build a Duration from whole microseconds.
/// Parameters: n -- the number of microseconds (may be negative).
/// Returns: a normalized Duration.
/// Complexity: O(1).
pub fn duration_micros(n: Int) -> Duration {
  return time.Duration.from_micros(n);
}

/// Build a Duration from whole nanoseconds.
/// Parameters: n -- the number of nanoseconds (may be negative).
/// Returns: a normalized Duration.
/// Complexity: O(1).
pub fn duration_nanos(n: Int) -> Duration {
  return time.Duration.from_nanos(n);
}

/// Whole seconds contained in a Duration.
/// Parameters: d -- the duration.
/// Returns: the seconds field (sub-second parts dropped).
/// Complexity: O(1).
pub fn duration_as_secs(d: Duration) -> Int {
  return d.as_secs();
}

/// Whole milliseconds contained in a Duration.
/// Parameters: d -- the duration.
/// Returns: the total milliseconds (sub-millisecond parts dropped).
/// Complexity: O(1).
pub fn duration_as_ms(d: Duration) -> Int {
  return d.as_millis();
}
