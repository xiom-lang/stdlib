// XIOM - Conversion: DateTime
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.convert.datetime

// Depends on: xiom.time

// ============================================================================
// Date and time of day helpers and ISO 8601 formatting/parsing. The reference
// implementation lives in xiom.time; construction/formatting is built on the
// imported DateTime type and time primitives.
// ============================================================================

use xiom.time;
use xiom.string;

/// Build a date-time value from its calendar and clock fields.
/// Parameters: year, month, day, hour, minute, second (24-hour clock).
/// Returns: a DateTime whose weekday is computed from the calendar date.
/// No range validation is performed.
/// Complexity: O(1).
pub fn datetime_new(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int) -> DateTime {
  var w = time.date_day_of_week(year, month, day);
  return DateTime{ year: year; month: month; day: day; hour: hour; minute: minute; second: second; weekday: w; };
}

/// The current date-time value (UTC clock).
/// Returns: a DateTime for the current instant.
/// Complexity: O(1).
pub fn datetime_now() -> DateTime {
  return time.utc_now();
}

/// Format a date-time as ISO 8601 "YYYY-MM-DDTHH:MM:SS", zero-padded.
/// Parameters: dt -- the date-time value.
/// Returns: the formatted string (always 19 bytes).
/// Complexity: O(1).
pub fn datetime_iso8601(dt: &DateTime) -> Str {
  var r = _pad4(dt.year);
  r = string.str_concat(r, "-");
  r = string.str_concat(r, _pad2(dt.month));
  r = string.str_concat(r, "-");
  r = string.str_concat(r, _pad2(dt.day));
  r = string.str_concat(r, "T");
  r = string.str_concat(r, _pad2(dt.hour));
  r = string.str_concat(r, ":");
  r = string.str_concat(r, _pad2(dt.minute));
  r = string.str_concat(r, ":");
  r = string.str_concat(r, _pad2(dt.second));
  return r;
}

/// Parse an ISO 8601 "YYYY-MM-DDTHH:MM:SS" string into a DateTime.
/// Parameters: s -- the date-time string.
/// Returns: Some(DateTime) when well-formed and within range, None otherwise.
/// Complexity: O(1).
pub fn datetime_from_iso8601(s: Str) -> Option[DateTime] {
  if string.str_len(s) != 19 {
    return None;
  }
  if string.byte_at(s, 4) != 45 {
    return None;
  }
  if string.byte_at(s, 7) != 45 {
    return None;
  }
  if string.byte_at(s, 10) != 84 {
    return None;
  }
  if string.byte_at(s, 13) != 58 {
    return None;
  }
  if string.byte_at(s, 16) != 58 {
    return None;
  }
  let y_res = string.str_to_int(string.str_slice(s, 0, 4));
  let mo_res = string.str_to_int(string.str_slice(s, 5, 7));
  let d_res = string.str_to_int(string.str_slice(s, 8, 10));
  let h_res = string.str_to_int(string.str_slice(s, 11, 13));
  let mi_res = string.str_to_int(string.str_slice(s, 14, 16));
  let se_res = string.str_to_int(string.str_slice(s, 17, 19));
  if y_res.is_err || mo_res.is_err || d_res.is_err {
    return None;
  }
  if h_res.is_err || mi_res.is_err || se_res.is_err {
    return None;
  }
  let year = y_res.value;
  let month = mo_res.value;
  let day = d_res.value;
  let hour = h_res.value;
  let minute = mi_res.value;
  let second = se_res.value;
  if month < 1 || month > 12 {
    return None;
  }
  if day < 1 || day > time.date_days_in_month(year, month) {
    return None;
  }
  if hour < 0 || hour > 23 {
    return None;
  }
  if minute < 0 || minute > 59 {
    return None;
  }
  if second < 0 || second > 59 {
    return None;
  }
  var w = time.date_day_of_week(year, month, day);
  return Some(DateTime{ year: year; month: month; day: day; hour: hour; minute: minute; second: second; weekday: w; });
}

// Format n zero-padded to at least 2 digits.
fn _pad2(n: Int) -> Str {
  var s = to_string(n);
  while string.str_len(s) < 2 {
    s = string.str_concat("0", s);
  }
  return s;
}

// Format n zero-padded to at least 4 digits.
fn _pad4(n: Int) -> Str {
  var s = to_string(n);
  while string.str_len(s) < 4 {
    s = string.str_concat("0", s);
  }
  return s;
}
