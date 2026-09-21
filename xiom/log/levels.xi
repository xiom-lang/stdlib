// XIOM - Log: Levels
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.log.levels

// Depends on: xiom.log

use xiom.string;

// ============================================================================
// Named log levels, threshold control, enablement queries and name mapping.
//
// Level constants (severity order): TRACE=0, DEBUG=1, INFO=2, WARN=3,
// ERROR=4, FATAL=5. The threshold is inclusive: a message is logged when its
// level is >= the threshold. The default threshold is INFO (2), matching the
// xiom.log default.
// ============================================================================

/// The minimum level that is logged (inclusive). Defaults to INFO.
var threshold: Int = 2;

/// The trace level constant (0).
pub fn log_level_trace() -> Int {
  0
}

/// The debug level constant (1).
pub fn log_level_debug() -> Int {
  1
}

/// The info level constant (2).
pub fn log_level_info() -> Int {
  2
}

/// The warn level constant (3).
pub fn log_level_warn() -> Int {
  3
}

/// The error level constant (4).
pub fn log_level_error() -> Int {
  4
}

/// The fatal level constant (5).
pub fn log_level_fatal() -> Int {
  5
}

/// The canonical name of a level: TRACE, DEBUG, INFO, WARN, ERROR or FATAL.
/// Unknown levels map to "UNKNOWN".
/// Complexity: O(1).
pub fn log_level_name(level: Int) -> Str {
  if level <= 0 {
    return "TRACE";
  };
  if level == 1 {
    return "DEBUG";
  };
  if level == 2 {
    return "INFO";
  };
  if level == 3 {
    return "WARN";
  };
  if level == 4 {
    return "ERROR";
  };
  if level >= 5 {
    return "FATAL";
  };
  "UNKNOWN"
}

/// The level for a name, if known. Matching is case-insensitive.
/// Complexity: O(1).
pub fn log_level_from_name(s: Str) -> Option[Int] {
  let up = string.str_upper(s);
  if up == "TRACE" {
    return Some(0);
  };
  if up == "DEBUG" {
    return Some(1);
  };
  if up == "INFO" {
    return Some(2);
  };
  if up == "WARN" || up == "WARNING" {
    return Some(3);
  };
  if up == "ERROR" {
    return Some(4);
  };
  if up == "FATAL" {
    return Some(5);
  };
  None
}

/// The current minimum level that is logged.
/// Complexity: O(1).
pub fn log_level_threshold() -> Int {
  threshold
}

/// Set the minimum level that is logged.
/// Complexity: O(1).
pub fn log_set_level(level: Int) {
  threshold = level;
}

/// Whether a level passes the threshold (level >= threshold).
/// Complexity: O(1).
pub fn log_enabled(level: Int) -> Bool {
  level >= threshold
}

/// All level constants in severity order: [TRACE, DEBUG, INFO, WARN, ERROR,
/// FATAL].
/// Complexity: O(1).
pub fn log_level_all() -> Vec[Int] {
  var levels = Vec[Int].new();
  levels.push(0);
  levels.push(1);
  levels.push(2);
  levels.push(3);
  levels.push(4);
  levels.push(5);
  levels
}
