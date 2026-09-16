// XIOM - Time: ISO8601
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.time.iso8601

// Depends on: xiom.time

// ============================================================================
// ISO-8601 and RFC-3339 date/time formatting and parsing.
// Uses the parent xiom.time types and helpers (date_from_iso8601, the
// weekday/day-of-year queries). Formatting pads decimal fields locally;
// parsing is byte-based over ASCII digits. Timezone suffixes are accepted
// and treated as UTC.
// ============================================================================

use xiom.time;
use xiom.convert;

// days since 1970-01-01 for a proleptic Gregorian date (Howard Hinnant).
fn days_from_civil_i(y: Int, m: Int, d: Int) -> Int {
  var y2 = y;
  var m2 = m;
  if m2 <= 2 {
    y2 = y2 - 1;
    m2 = m2 + 12;
  }
  m2 = m2 - 3;
  let serial = 365 * y2 + y2 / 4 - y2 / 100 + y2 / 400 + (153 * m2 + 2) / 5 + d - 1;
  return serial - 719468;
}

// (year, month, day) from a day count (Howard Hinnant).
fn civil_from_days_i(z: Int) -> (Int, Int, Int) {
  let shifted = z + 719468;
  let era = shifted / 146097;
  let doe = shifted - era * 146097;
  let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
  var year = yoe + era * 400;
  let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
  let mp = (5 * doy + 2) / 153;
  let day = doy - (153 * mp + 2) / 5 + 1;
  var month = mp + 3;
  if month > 12 {
    month = month - 12;
    year = year + 1;
  }
  return (year, month, day);
}

// Decompose a Unix timestamp (UTC) into a DateTime.
fn decompose_i(epoch: Int) -> DateTime {
  var days = epoch / 86400;
  var tod = epoch - days * 86400;
  if tod < 0 {
    days = days - 1;
    tod = tod + 86400;
  }
  let hour = tod / 3600;
  let minute = (tod - hour * 3600) / 60;
  let second = tod - hour * 3600 - minute * 60;
  let (year, month, day) = civil_from_days_i(days);
  let weekday = time.date_day_of_week(year, month, day);
  return DateTime{ year: year; month: month; day: day; hour: hour; minute: minute; second: second; weekday: weekday; }
}

// Zero-pad `n` to at least `width` decimal characters.
fn pad_i(n: Int, width: Int) -> Str {
  var s = convert.int_to_string(n);
  while s.len() < width {
    s = "0" + s;
  }
  return s;
}

type DigitParse = { is_ok: Bool; value: Int; }

type TimeParse = { is_ok: Bool; hour: Int; minute: Int; second: Int; }

fn digit_fail() -> DigitParse {
  return DigitParse{ is_ok: false; value: 0; }
}

fn time_fail() -> TimeParse {
  return TimeParse{ is_ok: false; hour: 0; minute: 0; second: 0; }
}

// Parse `count` ASCII digits from `s` starting at `start`.
fn parse_digits_i(s: Str, start: Int, count: Int) -> DigitParse {
  if start + count > s.len() {
    return digit_fail();
  }
  var v: Int = 0;
  var i: Int = 0;
  while i < count {
    let b = s.byte_at(start + i);
    if b < 48 || b > 57 {
      return digit_fail();
    }
    v = v * 10 + (b as Int - 48);
    i = i + 1;
  }
  return DigitParse{ is_ok: true; value: v; }
}

// Parse an optional "T HH:MM:SS" time tail after the date.
fn parse_time_tail_i(s: Str, pos: Int) -> TimeParse {
  if pos >= s.len() {
    return TimeParse{ is_ok: true; hour: 0; minute: 0; second: 0; }
  }
  let sep = s.byte_at(pos);
  if sep != 84 && sep != 32 {
    return TimeParse{ is_ok: true; hour: 0; minute: 0; second: 0; }
  }
  var p = pos + 1;
  let hour_r = parse_digits_i(s, p, 2);
  if !hour_r.is_ok {
    return time_fail();
  }
  if p + 2 >= s.len() || s.byte_at(p + 2) != 58 {
    return time_fail();
  }
  let minute_r = parse_digits_i(s, p + 3, 2);
  if !minute_r.is_ok {
    return time_fail();
  }
  if hour_r.value > 23 || minute_r.value > 59 {
    return time_fail();
  }
  if p + 5 >= s.len() || s.byte_at(p + 5) != 58 {
    return TimeParse{ is_ok: true; hour: hour_r.value; minute: minute_r.value; second: 0; }
  }
  let second_r = parse_digits_i(s, p + 6, 2);
  if !second_r.is_ok {
    return time_fail();
  }
  if second_r.value > 60 {
    return time_fail();
  }
  return TimeParse{ is_ok: true; hour: hour_r.value; minute: minute_r.value; second: second_r.value; }
}

/// Format `d` as YYYY-MM-DD.
/// Params: d - the date.
/// Returns: the zero-padded ISO date string.
/// Complexity: O(1).
pub fn date_iso8601(d: &Date) -> Str {
  return pad_i(d.year, 4) + "-" + pad_i(d.month, 2) + "-" + pad_i(d.day, 2);
}

/// Format `dt` with date and time components.
/// Params: dt - the date/time.
/// Returns: "YYYY-MM-DDTHH:MM:SS".
/// Complexity: O(1).
pub fn datetime_iso8601(dt: &DateTime) -> Str {
  let date = pad_i(dt.year, 4) + "-" + pad_i(dt.month, 2) + "-" + pad_i(dt.day, 2);
  let time = pad_i(dt.hour, 2) + ":" + pad_i(dt.minute, 2) + ":" + pad_i(dt.second, 2);
  return date + "T" + time;
}

/// Parse an ISO-8601 string into a DateTime.
/// Params: s - a "YYYY-MM-DD" or "YYYY-MM-DDTHH:MM:SS" string, optionally
///          suffixed with 'Z' or a numeric offset.
/// Returns: Some(DateTime) on success, None on malformed or out-of-range
///          input. Offsets are accepted and treated as UTC.
/// Complexity: O(1).
pub fn iso8601_parse(s: Str) -> Option[DateTime] {
  if s.len() < 10 {
    return None;
  }
  if s.byte_at(4) != 45 || s.byte_at(7) != 45 {
    return None;
  }
  let year_r = parse_digits_i(s, 0, 4);
  let month_r = parse_digits_i(s, 5, 2);
  let day_r = parse_digits_i(s, 8, 2);
  if !year_r.is_ok || !month_r.is_ok || !day_r.is_ok {
    return None;
  }
  if month_r.value < 1 || month_r.value > 12 {
    return None;
  }
  if day_r.value < 1 || day_r.value > time.date_days_in_month(year_r.value, month_r.value) {
    return None;
  }
  let tail = parse_time_tail_i(s, 10);
  if !tail.is_ok {
    return None;
  }
  let weekday = time.date_day_of_week(year_r.value, month_r.value, day_r.value);
  return Some(DateTime{ year: year_r.value; month: month_r.value; day: day_r.value; hour: tail.hour; minute: tail.minute; second: tail.second; weekday: weekday; });
}

/// Format `dt` as a full RFC-3339 timestamp.
/// Params: dt - the date/time.
/// Returns: "YYYY-MM-DDTHH:MM:SSZ" (UTC).
/// Complexity: O(1).
pub fn rfc3339_format(dt: &DateTime) -> Str {
  return datetime_iso8601(dt) + "Z";
}

/// Parse an RFC-3339 timestamp.
/// Params: s - a "YYYY-MM-DDTHH:MM:SS" string with a 'Z' or numeric offset.
/// Returns: Some(DateTime) on success, None on malformed input.
/// Complexity: O(1).
pub fn rfc3339_parse(s: Str) -> Option[DateTime] {
  return iso8601_parse(s);
}

/// Parse a YYYY-MM-DD string into a Date.
/// Params: s - the date string.
/// Returns: Some(Date) on success, None on malformed or out-of-range input.
/// Complexity: O(1).
pub fn iso8601_date_parse(s: Str) -> Option[Date] {
  return time.date_from_iso8601(s);
}

/// (year, week, weekday) in ISO week numbering.
/// Params: d - the date.
/// Returns: the ISO week year, ISO week number (1-53), and ISO weekday
///          (1 = Monday .. 7 = Sunday).
/// Complexity: O(1).
pub fn iso8601_week_date(d: &Date) -> (Int, Int, Int) {
  let wd = time.date_day_of_week(d.year, d.month, d.day);
  var iso_wd = wd;
  if iso_wd == 0 {
    iso_wd = 7;
  }
  let doy = time.date_day_of_year(d.year, d.month, d.day);
  var week = (doy - iso_wd + 10) / 7;
  var week_year = d.year;
  if week < 1 {
    week_year = d.year - 1;
    week = weeks_in_year_i(week_year);
  } else {
    var max_weeks = weeks_in_year_i(d.year);
    if week > max_weeks {
      week_year = d.year + 1;
      week = 1;
    }
  }
  return (week_year, week, iso_wd);
}

fn weeks_in_year_i(year: Int) -> Int {
  let jan1 = time.date_day_of_week(year, 1, 1);
  if jan1 == 4 {
    return 53;
  }
  if jan1 == 3 && time.date_is_leap_year(year) {
    return 53;
  }
  return 52;
}

/// (year, day_of_year) in ordinal form.
/// Params: d - the date.
/// Returns: the year and the day of the year (1-366).
/// Complexity: O(month).
pub fn iso8601_ordinal_date(d: &Date) -> (Int, Int) {
  let doy = time.date_day_of_year(d.year, d.month, d.day);
  return (d.year, doy);
}

/// Format the Unix timestamp `ts` as an ISO-8601 string.
/// Params: ts - seconds since the Unix epoch.
/// Returns: "YYYY-MM-DDTHH:MM:SS" in UTC.
/// Complexity: O(1).
pub fn timestamp_iso8601(ts: Int) -> Str {
  let dt = decompose_i(ts);
  return datetime_iso8601(&dt);
}
