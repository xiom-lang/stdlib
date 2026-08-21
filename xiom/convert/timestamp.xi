// XIOM - Conversion: Timestamp
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.convert.timestamp

// Depends on: xiom.time

// ============================================================================
// Unix timestamp conversions. Functions whose names collide with xiom.time
// (BUG 25 #1: same-name delegation miscompiles even when module-qualified)
// are reimplemented locally on the civil-date algorithm; different-named
// functions delegate safely.
// ============================================================================

use xiom.time;

/// Seconds since the Unix epoch (1970-01-01T00:00:00Z).
/// Returns: the current epoch seconds.
/// Complexity: O(1).
pub fn timestamp_now() -> Int {
  return time.unix_timestamp();
}

/// Convert a Unix timestamp (seconds since the epoch) to a calendar date.
/// Parameters: ts -- the timestamp.
/// Returns: the corresponding Date (UTC).
/// Complexity: O(1).
pub fn timestamp_to_date(ts: Int) -> Date {
  var days = ts / 86400;
  var tod = ts - days * 86400;
  if tod < 0 {
    days = days - 1;
  }
  let (y, m, d) = _civil_from_days(days);
  return Date{ year: y; month: m; day: d; };
}

/// Convert a Unix timestamp (seconds since the epoch) to a date-time value.
/// Parameters: ts -- the timestamp.
/// Returns: the corresponding DateTime (UTC) with weekday computed.
/// Complexity: O(1).
pub fn timestamp_to_datetime(ts: Int) -> DateTime {
  var days = ts / 86400;
  var tod = ts - days * 86400;
  if tod < 0 {
    days = days - 1;
    tod = tod + 86400;
  }
  let (y, m, d) = _civil_from_days(days);
  let hour = tod / 3600;
  let minute = (tod - hour * 3600) / 60;
  let second = tod - hour * 3600 - minute * 60;
  let w = time.date_day_of_week(y, m, d);
  return DateTime{ year: y; month: m; day: d; hour: hour; minute: minute; second: second; weekday: w; };
}

/// Convert a calendar date to the Unix timestamp of its midnight (UTC).
/// Parameters: d -- the date.
/// Returns: epoch seconds for 00:00:00Z of that date.
/// Complexity: O(1).
pub fn timestamp_from_date(d: &Date) -> Int {
  return time.date_to_timestamp(d);
}

/// Convert a date-time value to a Unix timestamp (UTC).
/// Parameters: dt -- the date-time value.
/// Returns: epoch seconds for that instant.
/// Complexity: O(1).
pub fn timestamp_from_datetime(dt: &DateTime) -> Int {
  let days = _days_from_civil(dt.year, dt.month, dt.day);
  var total = days * 86400;
  total = total + dt.hour * 3600;
  total = total + dt.minute * 60;
  total = total + dt.second;
  return total;
}

// Days since 1970-01-01 for a proleptic Gregorian date (Howard Hinnant's
// days_from_civil algorithm).
fn _days_from_civil(y: Int, m: Int, d: Int) -> Int {
  var y2 = y;
  var m2 = m;
  if m2 <= 2 {
    y2 = y2 - 1;
    m2 = m2 + 12;
  }
  m2 = m2 - 3;
  var serial = 365 * y2;
  serial = serial + y2 / 4;
  serial = serial - y2 / 100;
  serial = serial + y2 / 400;
  serial = serial + (153 * m2 + 2) / 5;
  serial = serial + d - 1;
  return serial - 719468;
}

// Inverse of days_from_civil: days since 1970-01-01 -> (year, month, day).
fn _civil_from_days(z: Int) -> (Int, Int, Int) {
  var shifted = z + 719468;
  var era = shifted / 146097;
  var doe = shifted - era * 146097;
  var yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
  var year = yoe + era * 400;
  var doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
  var mp = (5 * doy + 2) / 153;
  var day = doy - (153 * mp + 2) / 5 + 1;
  var month = mp + 3;
  if month > 12 {
    month = month - 12;
    year = year + 1;
  }
  return (year, month, day);
}
