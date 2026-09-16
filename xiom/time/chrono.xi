// XIOM - Time: Chrono
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.time.chrono

// Depends on: xiom.time

// ============================================================================
// Calendar-aware DateTime values with civil arithmetic and timezones.
// Uses the parent xiom.time.DateTime type and weekday helpers. Timestamp
// round-trips decompose/recompose the civil calendar locally; month/year
// arithmetic clamps the day field to the target month.
// ============================================================================

use xiom.time;

// days since 1970-01-01 for a proleptic Gregorian date (Howard Hinnant).
fn days_from_civil_c(y: Int, m: Int, d: Int) -> Int {
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
fn civil_from_days_c(z: Int) -> (Int, Int, Int) {
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

fn is_leap_c(year: Int) -> Bool {
  if year % 400 == 0 {
    return true;
  }
  if year % 100 == 0 {
    return false;
  }
  return year % 4 == 0;
}

fn days_in_month_c(year: Int, month: Int) -> Int {
  if month == 2 {
    if is_leap_c(year) {
      return 29;
    }
    return 28;
  }
  if month == 4 || month == 6 || month == 9 || month == 11 {
    return 30;
  }
  return 31;
}

// Decompose a Unix timestamp (UTC) into a DateTime.
fn decompose_c(epoch: Int) -> DateTime {
  var days = epoch / 86400;
  var tod = epoch - days * 86400;
  if tod < 0 {
    days = days - 1;
    tod = tod + 86400;
  }
  let hour = tod / 3600;
  let minute = (tod - hour * 3600) / 60;
  let second = tod - hour * 3600 - minute * 60;
  let (year, month, day) = civil_from_days_c(days);
  let weekday = time.date_day_of_week(year, month, day);
  return DateTime{ year: year; month: month; day: day; hour: hour; minute: minute; second: second; weekday: weekday; }
}

// Days from civil, month/day clamping helper for civil arithmetic.
fn make_dt_c(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int) -> DateTime {
  var m = month;
  var y = year;
  var d = day;
  if m < 1 {
    m = 1;
  }
  if m > 12 {
    m = 12;
  }
  var max_day = days_in_month_c(y, m);
  if d < 1 {
    d = 1;
  }
  if d > max_day {
    d = max_day;
  }
  let weekday = time.date_day_of_week(y, m, d);
  return DateTime{ year: y; month: m; day: d; hour: hour; minute: minute; second: second; weekday: weekday; }
}

/// The current local date and time.
/// Returns: the current date/time (the runtime clock is UTC; local is a
///          documented alias in this build).
/// Complexity: O(1).
pub fn chrono_now() -> DateTime {
  return time.DateTime.now();
}

/// The DateTime at Unix timestamp `ts`.
/// Params: ts - seconds since the Unix epoch.
/// Returns: the UTC date/time at that instant.
/// Complexity: O(1).
pub fn chrono_from_timestamp(ts: Int) -> DateTime {
  return decompose_c(ts);
}

/// The Unix timestamp of `dt`.
/// Params: dt - the date/time.
/// Returns: seconds since the Unix epoch.
/// Complexity: O(1).
pub fn chrono_to_timestamp(dt: &DateTime) -> Int {
  let days = days_from_civil_c(dt.year, dt.month, dt.day);
  return days * 86400 + dt.hour * 3600 + dt.minute * 60 + dt.second;
}

/// `dt` advanced by `n` seconds.
/// Params: dt - the date/time; n - the second offset.
/// Returns: the shifted date/time.
/// Complexity: O(1).
pub fn chrono_add_seconds(dt: &DateTime, n: Int) -> DateTime {
  let ts = chrono_to_timestamp(dt) + n;
  return decompose_c(ts);
}

/// `dt` advanced by `n` days.
/// Params: dt - the date/time; n - the day offset.
/// Returns: the shifted date/time.
/// Complexity: O(1).
pub fn chrono_add_days(dt: &DateTime, n: Int) -> DateTime {
  let ts = chrono_to_timestamp(dt) + n * 86400;
  return decompose_c(ts);
}

/// `dt` advanced by `n` months, clamping the day.
/// Params: dt - the date/time; n - the month offset.
/// Returns: the shifted date/time with the day clamped to the target month.
/// Complexity: O(1).
pub fn chrono_add_months(dt: &DateTime, n: Int) -> DateTime {
  var total = dt.month - 1 + n;
  var y = dt.year;
  var m = dt.month;
  if total >= 0 {
    y = y + total / 12;
    m = total % 12 + 1;
  } else {
    var neg = -total;
    var borrow = (neg + 11) / 12;
    y = y - borrow;
    var rem = borrow * 12 - neg;
    m = rem + 1;
  }
  return make_dt_c(y, m, dt.day, dt.hour, dt.minute, dt.second);
}

/// `dt` advanced by `n` years, clamping Feb 29.
/// Params: dt - the date/time; n - the year offset.
/// Returns: the shifted date/time with the day clamped for non-leap years.
/// Complexity: O(1).
pub fn chrono_add_years(dt: &DateTime, n: Int) -> DateTime {
  return make_dt_c(dt.year + n, dt.month, dt.day, dt.hour, dt.minute, dt.second);
}

/// The elapsed time between `a` and `b`.
/// Params: a - the later date/time; b - the earlier date/time.
/// Returns: a - b as a Duration.
/// Complexity: O(1).
pub fn chrono_diff(a: &DateTime, b: &DateTime) -> Duration {
  let ta = chrono_to_timestamp(a);
  let tb = chrono_to_timestamp(b);
  return time.Duration.from_secs(ta - tb);
}

/// The day of the week of `dt`.
/// Params: dt - the date/time.
/// Returns: 0 for Sunday through 6 for Saturday.
/// Complexity: O(1).
pub fn chrono_weekday(dt: &DateTime) -> Int {
  return dt.weekday;
}

/// Compare two date/times.
/// Params: a - the left operand; b - the right operand.
/// Returns: negative, zero, or positive for a before, equal, after b.
/// Complexity: O(1).
pub fn chrono_compare(a: &DateTime, b: &DateTime) -> Int {
  var ta = chrono_to_timestamp(a);
  var tb = chrono_to_timestamp(b);
  if ta < tb {
    return -1;
  }
  if ta > tb {
    return 1;
  }
  return 0;
}

/// The UTC offset of `dt` in seconds.
/// Params: dt - the date/time.
/// Returns: 0 (the runtime clock is UTC).
/// Complexity: O(1).
pub fn chrono_timezone_offset(dt: &DateTime) -> Int {
  return 0;
}

/// The current UTC date and time.
/// Returns: the current date/time in UTC.
/// Complexity: O(1).
pub fn chrono_utc_now() -> DateTime {
  return time.utc_now();
}
