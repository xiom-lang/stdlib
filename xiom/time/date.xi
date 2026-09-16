// XIOM - Time: Date
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.time.date

// Depends on: xiom.time

// ============================================================================
// Proleptic Gregorian calendar dates with day arithmetic.
// Uses the parent xiom.time types; functions whose names differ from the
// parent's are delegated, and same-named entry points are implemented
// locally over the standard days_from_civil / civil_from_days pair (copied
// as private helpers; the parent's private copies do not leak).
// ============================================================================

use xiom.time;

// days since 1970-01-01 for a proleptic Gregorian date (Howard Hinnant).
fn days_from_civil_d(y: Int, m: Int, d: Int) -> Int {
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
fn civil_from_days_d(z: Int) -> (Int, Int, Int) {
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

fn is_leap_d(year: Int) -> Bool {
  if year % 400 == 0 {
    return true;
  }
  if year % 100 == 0 {
    return false;
  }
  return year % 4 == 0;
}

fn days_in_month_d(year: Int, month: Int) -> Int {
  if month == 2 {
    if is_leap_d(year) {
      return 29;
    }
    return 28;
  }
  if month == 4 || month == 6 || month == 9 || month == 11 {
    return 30;
  }
  return 31;
}

fn weekday_from_days_d(days: Int) -> Int {
  var d = (days + 4) % 7;
  if d < 0 {
    d = d + 7;
  }
  return d;
}

// (year, month, day) at a Unix timestamp (UTC), fully local.
fn date_from_ts_d(ts: Int) -> Date {
  var days = ts / 86400;
  var tod = ts - days * 86400;
  if tod < 0 {
    days = days - 1;
  }
  let (y, m, d) = civil_from_days_d(days);
  return Date{ year: y; month: m; day: d; }
}

/// Build a Date from its fields.
/// Params: year, month, day - the calendar fields.
/// Returns: a Date. Values are not validated.
/// Complexity: O(1).
pub fn date_new(year: Int, month: Int, day: Int) -> Date {
  return Date{ year: year; month: month; day: day; }
}

/// Today's date from the system clock.
/// Returns: the current date (UTC).
/// Complexity: O(1).
pub fn date_now() -> Date {
  let ts = time.unix_timestamp();
  return date_from_ts_d(ts);
}

/// The date at Unix timestamp `ts` (UTC).
/// Params: ts - seconds since the Unix epoch.
/// Returns: the calendar date at that instant.
/// Complexity: O(1).
pub fn date_from_timestamp(ts: Int) -> Date {
  return date_from_ts_d(ts);
}

/// The Unix timestamp at midnight UTC of `d`.
/// Params: d - the date.
/// Returns: seconds since the epoch at 00:00:00 UTC.
/// Complexity: O(1).
pub fn date_to_timestamp(d: &Date) -> Int {
  let days = days_from_civil_d(d.year, d.month, d.day);
  return days * 86400;
}

/// The day of the week of `d` (0 = Sunday).
/// Params: d - the date.
/// Returns: 0 for Sunday through 6 for Saturday.
/// Complexity: O(1).
pub fn date_weekday(d: &Date) -> Int {
  let days = days_from_civil_d(d.year, d.month, d.day);
  return weekday_from_days_d(days);
}

/// The ordinal day of the year (1-366).
/// Params: d - the date.
/// Returns: 1 for January 1st.
/// Complexity: O(month).
pub fn date_day_of_year(d: &Date) -> Int {
  var result = d.day;
  var m: Int = 1;
  while m < d.month {
    result = result + days_in_month_d(d.year, m);
    m = m + 1;
  }
  return result;
}

/// The day-of-month field of `d`.
/// Params: d - the date.
/// Returns: the day field.
/// Complexity: O(1).
pub fn date_day_of_month(d: &Date) -> Int {
  return d.day;
}

/// The number of days in that month.
/// Params: year, month - the calendar fields.
/// Returns: 28-31 days.
/// Complexity: O(1).
pub fn date_days_in_month(year: Int, month: Int) -> Int {
  return days_in_month_d(year, month);
}

/// True if `year` is a leap year.
/// Params: year - the year.
/// Returns: whether February has 29 days in that year.
/// Complexity: O(1).
pub fn date_is_leap(year: Int) -> Bool {
  return is_leap_d(year);
}

/// `d` offset by `n` days.
/// Params: d - the base date; n - the day offset (may be negative).
/// Returns: the shifted date.
/// Complexity: O(1).
pub fn date_add_days(d: &Date, n: Int) -> Date {
  let total = days_from_civil_d(d.year, d.month, d.day) + n;
  let (y, m, day) = civil_from_days_d(total);
  return Date{ year: y; month: m; day: day; }
}

/// `d` offset by `-n` days.
/// Params: d - the base date; n - the day offset to subtract.
/// Returns: the shifted date.
/// Complexity: O(1).
pub fn date_sub_days(d: &Date, n: Int) -> Date {
  let total = days_from_civil_d(d.year, d.month, d.day) - n;
  let (y, m, day) = civil_from_days_d(total);
  return Date{ year: y; month: m; day: day; }
}

/// The number of days between `a` and `b` (a - b).
/// Params: a - the minuend; b - the subtrahend.
/// Returns: a - b in days.
/// Complexity: O(1).
pub fn date_diff_days(a: &Date, b: &Date) -> Int {
  let da = days_from_civil_d(a.year, a.month, a.day);
  let db = days_from_civil_d(b.year, b.month, b.day);
  return da - db;
}

/// Compare two dates.
/// Params: a - the left operand; b - the right operand.
/// Returns: negative, zero, or positive for a before, equal, after b.
/// Complexity: O(1).
pub fn date_compare(a: &Date, b: &Date) -> Int {
  if a.year < b.year {
    return -1;
  }
  if a.year > b.year {
    return 1;
  }
  if a.month < b.month {
    return -1;
  }
  if a.month > b.month {
    return 1;
  }
  if a.day < b.day {
    return -1;
  }
  if a.day > b.day {
    return 1;
  }
  return 0;
}
