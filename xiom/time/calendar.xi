// XIOM - Time: Calendar
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.time.calendar

// Depends on: xiom.time

// ============================================================================
// Calendar utilities: month/weekday names, month grids, and epoch days.
// Uses the parent xiom.time date/weekday helpers where the names differ;
// day-count, Easter, and month-grid math is implemented locally.
// ============================================================================

use xiom.time;

// days since 1970-01-01 for a proleptic Gregorian date (Howard Hinnant).
fn days_from_civil_cl(y: Int, m: Int, d: Int) -> Int {
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
fn civil_from_days_cl(z: Int) -> (Int, Int, Int) {
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

fn is_leap_cl(year: Int) -> Bool {
  if year % 400 == 0 {
    return true;
  }
  if year % 100 == 0 {
    return false;
  }
  return year % 4 == 0;
}

fn days_in_month_cl(year: Int, month: Int) -> Int {
  if month == 2 {
    if is_leap_cl(year) {
      return 29;
    }
    return 28;
  }
  if month == 4 || month == 6 || month == 9 || month == 11 {
    return 30;
  }
  return 31;
}

/// The full English month name (1 = January).
/// Params: month - the month number.
/// Returns: "January".."December"; an out-of-range month yields "Unknown".
/// Complexity: O(1).
pub fn calendar_month_name(month: Int) -> Str
  ensures: ((month == 1) => (result == "January")) && ((month == 2) => (result == "February")) && ((month == 3) => (result == "March")) && ((month == 4) => (result == "April")) && ((month == 5) => (result == "May")) && ((month == 6) => (result == "June")) && ((month == 7) => (result == "July")) && ((month == 8) => (result == "August")) && ((month == 9) => (result == "September")) && ((month == 10) => (result == "October")) && ((month == 11) => (result == "November")) && ((month == 12) => (result == "December")) && ((month < 1 || month > 12) => (result == "Unknown"))
{
  if month == 1 { return "January"; }
  if month == 2 { return "February"; }
  if month == 3 { return "March"; }
  if month == 4 { return "April"; }
  if month == 5 { return "May"; }
  if month == 6 { return "June"; }
  if month == 7 { return "July"; }
  if month == 8 { return "August"; }
  if month == 9 { return "September"; }
  if month == 10 { return "October"; }
  if month == 11 { return "November"; }
  if month == 12 { return "December"; }
  return "Unknown";
}

/// The three-letter month abbreviation.
/// Params: month - the month number.
/// Returns: "Jan".."Dec"; an out-of-range month yields "Unk".
/// Complexity: O(1).
pub fn calendar_month_name_short(month: Int) -> Str
  ensures: ((month == 1) => (result == "Jan")) && ((month == 2) => (result == "Feb")) && ((month == 3) => (result == "Mar")) && ((month == 4) => (result == "Apr")) && ((month == 5) => (result == "May")) && ((month == 6) => (result == "Jun")) && ((month == 7) => (result == "Jul")) && ((month == 8) => (result == "Aug")) && ((month == 9) => (result == "Sep")) && ((month == 10) => (result == "Oct")) && ((month == 11) => (result == "Nov")) && ((month == 12) => (result == "Dec")) && ((month < 1 || month > 12) => (result == "Unk"))
{
  if month == 1 { return "Jan"; }
  if month == 2 { return "Feb"; }
  if month == 3 { return "Mar"; }
  if month == 4 { return "Apr"; }
  if month == 5 { return "May"; }
  if month == 6 { return "Jun"; }
  if month == 7 { return "Jul"; }
  if month == 8 { return "Aug"; }
  if month == 9 { return "Sep"; }
  if month == 10 { return "Oct"; }
  if month == 11 { return "Nov"; }
  if month == 12 { return "Dec"; }
  return "Unk";
}

/// The full English weekday name (0 = Sunday).
/// Params: weekday - 0 for Sunday through 6 for Saturday.
/// Returns: "Sunday".."Saturday"; out of range yields "Unknown".
/// Complexity: O(1).
pub fn calendar_weekday_name(weekday: Int) -> Str
  ensures: ((weekday == 0) => (result == "Sunday")) && ((weekday == 1) => (result == "Monday")) && ((weekday == 2) => (result == "Tuesday")) && ((weekday == 3) => (result == "Wednesday")) && ((weekday == 4) => (result == "Thursday")) && ((weekday == 5) => (result == "Friday")) && ((weekday == 6) => (result == "Saturday")) && ((weekday < 0 || weekday > 6) => (result == "Unknown"))
{
  if weekday == 0 { return "Sunday"; }
  if weekday == 1 { return "Monday"; }
  if weekday == 2 { return "Tuesday"; }
  if weekday == 3 { return "Wednesday"; }
  if weekday == 4 { return "Thursday"; }
  if weekday == 5 { return "Friday"; }
  if weekday == 6 { return "Saturday"; }
  return "Unknown";
}

/// The three-letter weekday abbreviation.
/// Params: weekday - 0 for Sunday through 6 for Saturday.
/// Returns: "Sun".."Sat"; out of range yields "Unk".
/// Complexity: O(1).
pub fn calendar_weekday_name_short(weekday: Int) -> Str
  ensures: ((weekday == 0) => (result == "Sun")) && ((weekday == 1) => (result == "Mon")) && ((weekday == 2) => (result == "Tue")) && ((weekday == 3) => (result == "Wed")) && ((weekday == 4) => (result == "Thu")) && ((weekday == 5) => (result == "Fri")) && ((weekday == 6) => (result == "Sat")) && ((weekday < 0 || weekday > 6) => (result == "Unk"))
{
  if weekday == 0 { return "Sun"; }
  if weekday == 1 { return "Mon"; }
  if weekday == 2 { return "Tue"; }
  if weekday == 3 { return "Wed"; }
  if weekday == 4 { return "Thu"; }
  if weekday == 5 { return "Fri"; }
  if weekday == 6 { return "Sat"; }
  return "Unk";
}

/// The number of days in that month.
/// Params: year, month - the calendar fields.
/// Returns: 28-31 days.
/// Complexity: O(1).
pub fn calendar_days_in_month(year: Int, month: Int) -> Int
  ensures: ((month == 2) => (result == 28 || result == 29)) && ((month == 4 || month == 6 || month == 9 || month == 11) => (result == 30)) && ((month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) => (result == 31)) && ((month < 1 || month > 12) => (result == 31))
{
  return time.date_days_in_month(year, month);
}

/// The weekday of the first day of the month.
/// Params: year, month - the calendar fields.
/// Returns: 0 for Sunday through 6 for Saturday.
/// Complexity: O(1).
pub fn calendar_first_weekday(year: Int, month: Int) -> Int
  ensures: (0 <= result && result < 7) && ((year == 1970 && month == 1) => (result == 4))
{
  return time.date_day_of_week(year, month, 1);
}

/// The number of ISO weeks in that year.
/// Params: year - the year.
/// Returns: 52, or 53 when the ISO year has 53 weeks.
/// Complexity: O(1).
pub fn calendar_weeks_in_year(year: Int) -> Int
  ensures: result == 52 || result == 53
{
  let jan1 = time.date_day_of_week(year, 1, 1);
  if jan1 == 4 {
    return 53;
  }
  if jan1 == 3 && time.date_is_leap_year(year) {
    return 53;
  }
  return 52;
}

/// The date of Easter Sunday in that year.
/// Params: year - the year.
/// Returns: the Easter Sunday date (Meeus/Jones/Butcher computus).
/// Complexity: O(1).
pub fn calendar_easter(year: Int) -> Date
  ensures: (year >= 1583) => (result.year == year && ((result.month == 3 && 22 <= result.day && result.day <= 31) || (result.month == 4 && 1 <= result.day && result.day <= 25)))
{
  let a = year % 19;
  let b = year / 100;
  let c = year % 100;
  let d = b / 4;
  let e = b % 4;
  let f = (b + 8) / 25;
  let g = (b - f + 1) / 3;
  let h = (19 * a + b - d - g + 15) % 30;
  let i = c / 4;
  let k = c % 4;
  let l = (32 + 2 * e + 2 * i - h - k) % 7;
  let m = (a + 11 * h + 22 * l) / 451;
  let month = (h + l - 7 * m + 114) / 31;
  let day = (h + l - 7 * m + 114) % 31 + 1;
  return Date{ year: year; month: month; day: day; }
}

/// The Julian Day Number of the date.
/// Params: year, month, day - the calendar fields.
/// Returns: the astronomical Julian Day Number.
/// Complexity: O(1).
pub fn calendar_julian_day(year: Int, month: Int, day: Int) -> Int
  ensures: result == days_from_civil_cl(year, month, day) + 2440588
{
  let days = days_from_civil_cl(year, month, day);
  return days + 2440588;
}

/// The calendar date for a Julian Day Number.
/// Params: jd - the Julian Day Number.
/// Returns: the corresponding Date.
/// Complexity: O(1).
pub fn calendar_from_julian_day(jd: Int) -> Date
  ensures: (jd >= 2440588 - 719468) => (calendar_julian_day(result.year, result.month, result.day) == jd)
{
  let (y, m, d) = civil_from_days_cl(jd - 2440588);
  return Date{ year: y; month: m; day: d; }
}

/// The weekday slots of the month, 0 for empty cells.
/// Params: year, month - the calendar fields.
/// Returns: a 42-slot grid starting on the first day's weekday.
/// Complexity: O(1).
pub fn calendar_month_grid(year: Int, month: Int) -> Vec[Int]
  ensures: (result.len() == 42) && ((year == 1970 && month == 1) => (result[0] == 0 && result[4] == 1))
{
  var grid: Vec[Int] = Vec[Int].new();
  var i: Int = 0;
  while i < 42 {
    grid.push(0);
    i = i + 1;
  }
  let first = time.date_day_of_week(year, month, 1);
  let total = time.date_days_in_month(year, month);
  var day: Int = 1;
  while day <= total {
    grid[first + day - 1] = day;
    day = day + 1;
  }
  return grid;
}

/// True if `d` falls on a Saturday or Sunday.
/// Params: d - the date.
/// Returns: whether the weekday is 0 (Sunday) or 6 (Saturday).
/// Complexity: O(1).
pub fn calendar_is_weekend(d: &Date) -> Bool
  ensures: result == (time.date_day_of_week(d.year, d.month, d.day) == 0 || time.date_day_of_week(d.year, d.month, d.day) == 6)
{
  let wd = time.date_day_of_week(d.year, d.month, d.day);
  if wd == 0 {
    return true;
  }
  return wd == 6;
}

/// `d` advanced by `n` months, clamping the day.
/// Params: d - the base date; n - the month offset.
/// Returns: the shifted date with the day clamped to the target month.
/// Complexity: O(1).
pub fn calendar_add_months_overflow_safe(d: &Date, n: Int) -> Date
  ensures: (1 <= result.month && result.month <= 12) && (result.day <= 31) && (result.day <= d.day) && ((1 <= d.day) => (1 <= result.day)) && ((n == 0 && 1 <= d.month && d.month <= 12 && 1 <= d.day && d.day <= 28) => (result.year == d.year && result.month == d.month && result.day == d.day))
{
  var total = d.month - 1 + n;
  var y = d.year;
  var m = d.month;
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
  var max_day = days_in_month_cl(y, m);
  var day = d.day;
  if day > max_day {
    day = max_day;
  }
  return Date{ year: y; month: m; day: day; }
}
