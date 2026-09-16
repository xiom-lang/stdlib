// XIOM - Log: Color
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.log.color

// Depends on: xiom.log

use xiom.string;
use xiom.convert;

// ============================================================================
// Level-based ANSI coloring, enable/disable control, and color stripping
// for log output.
//
// Level colors: TRACE=90 (bright black), DEBUG=36 (cyan), INFO=32 (green),
// WARN=33 (yellow), ERROR=31 (red), FATAL=35 (magenta).
// ============================================================================

/// Whether colored output is enabled. Defaults to true.
var color_enabled: Bool = true;

/// The ANSI escape prefix.
fn esc() -> Str {
  "\u{001b}["
}

/// The ANSI color sequence for a level (see header for the mapping).
/// Unknown levels return the reset sequence.
/// Complexity: O(1).
pub fn log_color(level: Int) -> Str {
  let code = log_color_by_level(level);
  if code <= 0 {
    return "\u{001b}[0m";
  };
  "\u{001b}[" + convert.int_to_string(code) + "m"
}

/// The ANSI reset sequence.
/// Complexity: O(1).
pub fn log_color_reset() -> Str {
  "\u{001b}[0m"
}

/// Whether colored output is enabled.
/// Complexity: O(1).
pub fn log_color_enabled() -> Bool {
  color_enabled
}

/// Enable or disable colored output.
/// Complexity: O(1).
pub fn log_set_color_enabled(on: Bool) {
  color_enabled = on;
}

/// Wrap `msg` in its level color when colored output is enabled; otherwise
/// return `msg` unchanged.
/// Complexity: O(len(msg)).
pub fn log_colorize(level: Int, msg: Str) -> Str {
  if !color_enabled {
    return msg;
  };
  string.str_concat(log_color(level), string.str_concat(msg, "\u{001b}[0m"))
}

/// The numeric ANSI color code assigned to a level (31 for ERROR, 32 for
/// INFO, ...). Returns 0 for unknown levels.
/// Complexity: O(1).
pub fn log_color_by_level(level: Int) -> Int {
  if level <= 0 {
    return 90;
  };
  if level == 1 {
    return 36;
  };
  if level == 2 {
    return 32;
  };
  if level == 3 {
    return 33;
  };
  if level == 4 {
    return 31;
  };
  if level >= 5 {
    return 35;
  };
  0
}

/// Remove ANSI color (CSI) sequences from `s`. Handles sequences of the form
/// ESC [ params letter, including `ESC [ m`.
/// Complexity: O(len(s)).
pub fn log_strip_color(s: Str) -> Str {
  var result = "";
  let len = s.len();
  var i: Int = 0;
  while i < len {
    let b = string.byte_at(s, i);
    if b == 27 {
      if i + 1 < len && string.byte_at(s, i + 1) == 91 {
        var j = i + 2;
        while j < len {
          let c = string.byte_at(s, j);
          if (c >= 64 && c <= 126) || c == 90 || c == 89 {
            break;
          };
          j = j + 1;
        };
        i = j + 1;
      } else {
        i = i + 1;
      };
    } else {
      result = string.str_concat(result, string.str_slice(s, i, i + 1));
      i = i + 1;
    };
  };
  result
}

/// Whether `s` contains an ANSI color (CSI) sequence (`ESC [`).
/// Complexity: O(len(s)).
pub fn log_has_color(s: Str) -> Bool {
  let len = s.len();
  var i: Int = 0;
  while i + 1 < len {
    if string.byte_at(s, i) == 27 && string.byte_at(s, i + 1) == 91 {
      return true;
    };
    i = i + 1;
  };
  false
}
