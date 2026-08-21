// XIOM - Conversion: Date
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.convert.date

// Depends on: xiom.time

// ============================================================================
// Calendar date helpers and ISO 8601 formatting/parsing. The reference
// implementation lives in xiom.time; where a function name matches one in
// xiom.time (same-name delegation miscompiles -- BUG 25 #1) the logic is
// reimplemented locally on top of the time/string primitives.
// ============================================================================

use xiom.time;
use xiom.string;

/// Build a calendar date from year, month and day. No validation is
/// performed (out-of-range fields are carried as-is by the Date type).
/// Parameters: year (proleptic Gregorian), month 1..12, day 1..31.
/// Returns: the constructed Date.
/// Complexity: O(1).
pub fn date_new(year: Int, month: Int, day: Int) -> Date {
  return Date{ year: year; month: month; day: day; };
}

/// The current calendar date, computed from the Unix clock.
/// Returns: today's Date (UTC).
/// Complexity: O(1).
pub fn date_now() -> Date {
  let ts = time.unix_timestamp();
  return time.timestamp_to_date(ts);
}

/// Format a date as ISO 8601 "YYYY-MM-DD", zero-padded.
/// Parameters: d -- the date to format.
/// Returns: the formatted string (always 10 bytes).
/// Complexity: O(1).
pub fn date_iso8601(d: &Date) -> Str {
  var r = _pad4(d.year);
  r = string.str_concat(r, "-");
  r = string.str_concat(r, _pad2(d.month));
  r = string.str_concat(r, "-");
  r = string.str_concat(r, _pad2(d.day));
  return r;
}

/// Parse an ISO 8601 "YYYY-MM-DD" string into a Date.
/// Parameters: s -- the date string.
/// Returns: Some(Date) when well-formed and within calendar range,
///          None otherwise (malformed layout or out-of-range fields).
/// Complexity: O(1).
pub fn date_from_iso8601(s: Str) -> Option[Date] {
  if string.str_len(s) != 10 {
    return None;
  }
  if string.byte_at(s, 4) != 45 {
    return None;
  }
  if string.byte_at(s, 7) != 45 {
    return None;
  }
  let y_res = string.str_to_int(string.str_slice(s, 0, 4));
  let m_res = string.str_to_int(string.str_slice(s, 5, 7));
  let d_res = string.str_to_int(string.str_slice(s, 8, 10));
  if y_res.is_err || m_res.is_err || d_res.is_err {
    return None;
  }
  let year = y_res.value;
  let month = m_res.value;
  let day = d_res.value;
  if month < 1 || month > 12 {
    return None;
  }
  if day < 1 || day > time.date_days_in_month(year, month) {
    return None;
  }
  return Some(Date{ year: year; month: month; day: day; });
}

/// Day of the week for a date: 0 = Sunday .. 6 = Saturday.
/// Parameters: d -- the date.
/// Returns: weekday index.
/// Complexity: O(1).
pub fn date_weekday(d: &Date) -> Int {
  return time.date_day_of_week(d.year, d.month, d.day);
}

/// Ordinal day of the year for a date (1..366, leap-aware).
/// Parameters: d -- the date.
/// Returns: the day-of-year index.
/// Complexity: O(month) in the worst case (small constant).
pub fn date_day_of_year(d: &Date) -> Int {
  var result = d.day;
  var m: Int = 1;
  while m < d.month {
    result = result + time.date_days_in_month(d.year, m);
    m = m + 1;
  }
  return result;
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
