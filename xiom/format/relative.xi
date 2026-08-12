// XIOM - Format: Relative
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.format.relative

// Depends on: xiom.time

use xiom.convert;

// ============================================================================
// Human-readable relative time: "5 minutes ago", "in 2 days", elapsed and
// remaining durations, ages, and decomposed relative-time parts. Pure
// computation over integer timestamps with zero external dependencies.
//
// Units: seconds, minutes (60 s), hours (3600 s), days (86400 s), weeks
// (7 d), months (30 d), years (365 d). relative_parts decomposes a signed
// offset into (magnitude, unit-name) pairs from largest to smallest using the
// same unit table.
// ============================================================================

const SEC_MIN: Int = 60;
const SEC_HOUR: Int = 3600;
const SEC_DAY: Int = 86400;
const SEC_WEEK: Int = 604800;
const SEC_MONTH: Int = 2592000;
const SEC_YEAR: Int = 31536000;

type RelUnit = {
  value: Int;
  name: Str;
}

/// Pick the largest whole unit <= |seconds|. Returns (value, name).
fn _pick_unit(seconds: Int) -> RelUnit {
  var s = seconds;
  if s < 0 {
    s = 0 - s;
  };
  if s >= SEC_YEAR {
    return RelUnit{ value: s / SEC_YEAR; name: "year"; };
  };
  if s >= SEC_MONTH {
    return RelUnit{ value: s / SEC_MONTH; name: "month"; };
  };
  if s >= SEC_WEEK {
    return RelUnit{ value: s / SEC_WEEK; name: "week"; };
  };
  if s >= SEC_DAY {
    return RelUnit{ value: s / SEC_DAY; name: "day"; };
  };
  if s >= SEC_HOUR {
    return RelUnit{ value: s / SEC_HOUR; name: "hour"; };
  };
  if s >= SEC_MIN {
    return RelUnit{ value: s / SEC_MIN; name: "minute"; };
  };
  return RelUnit{ value: s; name: "second"; };
}

/// Render "value unit(s)" with pluralization.
fn _unit_text(value: Int, name: Str) -> Str {
  var v = value;
  if v < 0 {
    v = 0 - v;
  };
  var result = convert.int_to_string(v) + " " + name;
  if v != 1 {
    result = result + "s";
  };
  return result;
}

/// Format a positive offset as "in N units".
pub fn format_relative_future(seconds: Int) -> Str {
  var s = seconds;
  if s < 0 {
    s = 0 - s;
  };
  if s < 30 {
    return "in a moment";
  };
  var u = _pick_unit(s);
  return "in " + _unit_text(u.value, u.name);
}

/// Format a negative offset as "N units ago".
pub fn format_relative_past(seconds: Int) -> Str {
  var s = seconds;
  if s < 0 {
    s = 0 - s;
  };
  if s < 30 {
    return "just now";
  };
  var u = _pick_unit(s);
  return _unit_text(u.value, u.name) + " ago";
}

/// Format a signed offset in seconds as a full relative phrase.
pub fn format_relative_time(seconds: Int) -> Str {
  if seconds < 0 {
    return format_relative_past(seconds);
  };
  if seconds < 30 {
    return "just now";
  };
  return format_relative_future(seconds);
}

/// Short unit label for a unit name.
fn _short_unit(name: Str) -> Str {
  if name == "year" {
    return "y";
  };
  if name == "month" {
    return "mo";
  };
  if name == "week" {
    return "w";
  };
  if name == "day" {
    return "d";
  };
  if name == "hour" {
    return "h";
  };
  if name == "minute" {
    return "m";
  };
  return "s";
}

/// Format a signed offset using the compact unit form ("5m", "2d", "now").
pub fn format_relative_time_short(seconds: Int) -> Str {
  var s = seconds;
  if s < 0 {
    s = 0 - s;
  };
  if s < 30 {
    return "now";
  };
  var u = _pick_unit(s);
  return convert.int_to_string(u.value) + _short_unit(u.name);
}

/// Format the span between two timestamps as elapsed time ("5 minutes").
pub fn format_elapsed(start: Int, end: Int) -> Str {
  var span = end - start;
  if span < 0 {
    span = 0 - span;
  };
  var u = _pick_unit(span);
  return _unit_text(u.value, u.name);
}

/// Format a millisecond span as a compact human duration ("1h 2m 3s").
pub fn format_elapsed_ms(ms: Int) -> Str {
  var m = ms;
  if m < 0 {
    m = 0 - m;
  };
  if m < 1000 {
    return convert.int_to_string(m) + "ms";
  };
  return format_seconds(m / 1000);
}

/// Format how long before `now` the timestamp lies ("5 minutes ago", or the
/// future form when `timestamp` is after `now`).
pub fn format_ago(timestamp: Int, now: Int) -> Str {
  var diff = now - timestamp;
  if diff < 0 {
    return format_relative_future(0 - diff);
  };
  return format_relative_past(diff);
}

/// Format how long after `now` the timestamp lies ("in 5 minutes", or the
/// past form when `timestamp` is before `now`).
pub fn format_until(timestamp: Int, now: Int) -> Str {
  var diff = timestamp - now;
  if diff < 0 {
    return format_relative_past(0 - diff);
  };
  return format_relative_future(diff);
}

/// Format an age in days as the largest whole unit ("400 days", "3 months").
pub fn format_age(days: Int) -> Str {
  var d = days;
  if d < 0 {
    d = 0 - d;
  };
  var u = _pick_unit(d * SEC_DAY);
  return _unit_text(u.value, u.name);
}

/// Decompose `seconds` into (magnitude, unit name) pairs from largest to
/// smallest, using only the non-zero parts (e.g. 3661 -> hour 1, minute 1,
/// second 1). The sign is ignored; the magnitude is always non-negative.
pub fn relative_parts(seconds: Int) -> Vec[(Int, Str)] {
  var result = Vec[(Int, Str)].new();
  var s = seconds;
  if s < 0 {
    s = 0 - s;
  };
  var years = s / SEC_YEAR;
  s = s % SEC_YEAR;
  var months = s / SEC_MONTH;
  s = s % SEC_MONTH;
  var weeks = s / SEC_WEEK;
  s = s % SEC_WEEK;
  var days = s / SEC_DAY;
  s = s % SEC_DAY;
  var hours = s / SEC_HOUR;
  s = s % SEC_HOUR;
  var minutes = s / SEC_MIN;
  s = s % SEC_MIN;
  var seconds_rem = s;
  if years > 0 {
    result.push((years, "year"));
  };
  if months > 0 {
    result.push((months, "month"));
  };
  if weeks > 0 {
    result.push((weeks, "week"));
  };
  if days > 0 {
    result.push((days, "day"));
  };
  if hours > 0 {
    result.push((hours, "hour"));
  };
  if minutes > 0 {
    result.push((minutes, "minute"));
  };
  if seconds_rem > 0 {
    result.push((seconds_rem, "second"));
  };
  if result.len() == 0 {
    result.push((0, "second"));
  };
  return result;
}

/// Format seconds as a compact human duration ("1h 2m 3s", "2m 5s", "45s").
pub fn format_seconds(secs: Int) -> Str {
  var s = secs;
  if s < 0 {
    s = 0 - s;
  };
  var result = "";
  var days = s / SEC_DAY;
  s = s % SEC_DAY;
  var hours = s / SEC_HOUR;
  s = s % SEC_HOUR;
  var minutes = s / SEC_MIN;
  s = s % SEC_MIN;
  if days > 0 {
    result = convert.int_to_string(days) + "d";
  };
  if hours > 0 {
    if result.len() > 0 {
      result = result + " ";
    };
    result = result + convert.int_to_string(hours) + "h";
  };
  if minutes > 0 {
    if result.len() > 0 {
      result = result + " ";
    };
    result = result + convert.int_to_string(minutes) + "m";
  };
  if s > 0 || result.len() == 0 {
    if result.len() > 0 {
      result = result + " ";
    };
    result = result + convert.int_to_string(s) + "s";
  };
  return result;
}
