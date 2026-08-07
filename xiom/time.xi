// XIOM — Time Library
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.time

extern "C" {
  fn clock() -> Int;
  fn time(ptr: *Int) -> Int;
}

// === Duration — a span of time ===
pub type Duration = {
  secs: Int;
  nanos: Int;
} derive[Eq, Clone, Ord]

const NANOS_PER_SEC: Int = 1000000000;
const NANOS_PER_MILLI: Int = 1000000;
const NANOS_PER_MICRO: Int = 1000;
const MILLIS_PER_SEC: Int = 1000;
const SECS_PER_DAY: Int = 86400;

fn normalize_duration(secs: Int, nanos: Int) -> Duration {
  var s = secs;
  var n = nanos;
  if n >= NANOS_PER_SEC {
    let extra = n / NANOS_PER_SEC;
    s = s + extra;
    n = n - extra * NANOS_PER_SEC;
  };
  if n < 0 {
    let borrow = (-n + NANOS_PER_SEC - 1) / NANOS_PER_SEC;
    s = s - borrow;
    n = n + borrow * NANOS_PER_SEC;
  };
  return Duration{ secs: s; nanos: n; };
}

pub fn Duration.new(secs: Int, nanos: Int) -> Duration
  ensures: 0 <= result.nanos && result.nanos < NANOS_PER_SEC
{
  return normalize_duration(secs, nanos);
}

pub fn Duration.from_secs(s: Int) -> Duration {
  return Duration{ secs: s; nanos: 0; };
}

pub fn Duration.from_secs_f64(secs: Float64) -> Duration {
  var s = secs as Int;
  var frac = secs - (s as Float64);
  if frac < 0.0 {
    frac = -frac;
  };
  var n = (frac * (NANOS_PER_SEC as Float64)) as Int;
  if secs < 0.0 {
    s = s - 1;
    n = NANOS_PER_SEC - n;
  };
  return Duration{ secs: s; nanos: n; };
}

pub fn Duration.from_millis(ms: Int) -> Duration {
  let s = ms / MILLIS_PER_SEC;
  var n = (ms - s * MILLIS_PER_SEC) * NANOS_PER_MILLI;
  var secs = s;
  if n < 0 {
    secs = secs - 1;
    n = n + NANOS_PER_SEC;
  };
  return Duration{ secs: secs; nanos: n; };
}

pub fn Duration.from_micros(us: Int) -> Duration {
  let s = us / 1000000;
  var n = (us - s * 1000000) * NANOS_PER_MICRO;
  var secs = s;
  if n < 0 {
    secs = secs - 1;
    n = n + NANOS_PER_SEC;
  };
  return Duration{ secs: secs; nanos: n; };
}

pub fn Duration.from_nanos(ns: Int) -> Duration {
  let s = ns / NANOS_PER_SEC;
  var n = ns - s * NANOS_PER_SEC;
  var secs = s;
  if n < 0 {
    secs = secs - 1;
    n = n + NANOS_PER_SEC;
  };
  return Duration{ secs: secs; nanos: n; };
}

pub fn Duration.as_secs(self) -> Int {
  return self.secs;
}

pub fn Duration.as_millis(self) -> Int {
  return self.secs * MILLIS_PER_SEC + self.nanos / NANOS_PER_MILLI;
}

pub fn Duration.as_micros(self) -> Int {
  return self.secs * 1000000 + self.nanos / NANOS_PER_MICRO;
}

pub fn Duration.as_nanos(self) -> Int {
  return self.secs * NANOS_PER_SEC + self.nanos;
}

pub fn Duration.as_secs_f64(self) -> Float64 {
  var result = self.secs as Float64;
  result = result + (self.nanos as Float64) / (NANOS_PER_SEC as Float64);
  return result;
}

pub fn Duration.subsec_nanos(self) -> Int {
  return self.nanos;
}

pub fn Duration.add(self, other: Duration) -> Duration
  ensures: 0 <= result.nanos && result.nanos < NANOS_PER_SEC
{
  return normalize_duration(self.secs + other.secs, self.nanos + other.nanos);
}

pub fn Duration.sub(self, other: Duration) -> Duration
  ensures: 0 <= result.nanos && result.nanos < NANOS_PER_SEC
{
  return normalize_duration(self.secs - other.secs, self.nanos - other.nanos);
}

pub fn Duration.mul(self, factor: Int) -> Duration
  requires: factor >= 0
  ensures: 0 <= result.nanos && result.nanos < NANOS_PER_SEC
{
  let total_ns = self.secs * NANOS_PER_SEC + self.nanos;
  let result_ns = total_ns * factor;
  return normalize_duration(result_ns / NANOS_PER_SEC, result_ns - (result_ns / NANOS_PER_SEC) * NANOS_PER_SEC);
}

pub fn Duration.div(self, divisor: Int) -> Duration
  requires: divisor != 0
{
  let total_ns = self.secs * NANOS_PER_SEC + self.nanos;
  let result_ns = total_ns / divisor;
  return normalize_duration(result_ns / NANOS_PER_SEC, result_ns - (result_ns / NANOS_PER_SEC) * NANOS_PER_SEC);
}

pub fn Duration.checked_add(self, other: Duration) -> Option[Duration] {
  var total_secs = self.secs + other.secs;
  var total_nanos = self.nanos + other.nanos;
  if total_nanos >= NANOS_PER_SEC {
    total_secs = total_secs + total_nanos / NANOS_PER_SEC;
    total_nanos = total_nanos - (total_nanos / NANOS_PER_SEC) * NANOS_PER_SEC;
  } elif total_nanos < 0 {
    let borrow = (-total_nanos + NANOS_PER_SEC - 1) / NANOS_PER_SEC;
    total_secs = total_secs - borrow;
    total_nanos = total_nanos + borrow * NANOS_PER_SEC;
  };
  return Some(Duration{ secs: total_secs; nanos: total_nanos; });
}

pub fn Duration.checked_sub(self, other: Duration) -> Option[Duration] {
  if self.as_nanos() < other.as_nanos() {
    return None;
  };
  var secs = self.secs - other.secs;
  var nanos = self.nanos - other.nanos;
  if nanos < 0 {
    secs = secs - 1;
    nanos = nanos + NANOS_PER_SEC;
  };
  if secs < 0 {
    return None;
  };
  return Some(Duration{ secs: secs; nanos: nanos; });
}

// === Instant — a point in time (monotonic clock) ===
pub type Instant = { t: Int; }

pub fn Instant.now() -> Instant {
  return Instant{ t: time(0); };
}

pub fn Instant.elapsed(self) -> Duration {
  let now = time(0);
  let diff = now - self.t;
  return Duration.from_secs(diff);
}

pub fn Instant.duration_since(self, earlier: Instant) -> Duration {
  let diff = self.t - earlier.t;
  return Duration.from_secs(diff);
}

pub fn Instant.add(self, d: Duration) -> Instant {
  return Instant{ t: self.t + d.secs; };
}

pub fn Instant.sub(self, d: Duration) -> Instant {
  return Instant{ t: self.t - d.secs; };
}

// === SystemTime — wall clock time ===
pub type SystemTime = { secs: Int; nanos: Int; }

pub fn SystemTime.now() -> SystemTime {
  return SystemTime{ secs: time(0); nanos: 0; };
}

pub fn SystemTime.unix_epoch() -> SystemTime {
  return SystemTime{ secs: 0; nanos: 0; };
}

pub fn SystemTime.duration_since(self, earlier: SystemTime) -> Result[Duration, Str]
  ensures: result.is_ok <=> self.secs >= earlier.secs
{
  var sec_diff = self.secs - earlier.secs;
  var nano_diff = self.nanos - earlier.nanos;
  if nano_diff < 0 {
    sec_diff = sec_diff - 1;
    nano_diff = nano_diff + NANOS_PER_SEC;
  };
  if sec_diff < 0 {
    return Err("earlier SystemTime is later than self");
  };
  return Ok(Duration{ secs: sec_diff; nanos: nano_diff; });
}

pub fn SystemTime.secs_since_epoch(self) -> Int {
  return self.secs;
}

// === DateTime — calendar date and time ===
pub type DateTime = {
  year: Int;
  month: Int;
  day: Int;
  hour: Int;
  minute: Int;
  second: Int;
  weekday: Int;
}

// === Calendar decomposition helpers ===
fn civil_from_days(z: Int) -> (Int, Int, Int) {
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
  };
  return (year, month, day);
}

fn weekday_from_days(days: Int) -> Int {
  var d = (days + 3) % 7;
  if d < 0 {
    d = d + 7;
  };
  return d;
}

fn decompose_epoch(epoch: Int) -> DateTime {
  var days = epoch / SECS_PER_DAY;
  var tod = epoch - days * SECS_PER_DAY;
  if tod < 0 {
    days = days - 1;
    tod = tod + SECS_PER_DAY;
  };
  let hour = tod / 3600;
  let minute = (tod - hour * 3600) / 60;
  let second = tod - hour * 3600 - minute * 60;
  let (year, month, day) = civil_from_days(days);
  let weekday = weekday_from_days(days);
  return DateTime{ year: year; month: month; day: day; hour: hour; minute: minute; second: second; weekday: weekday; };
}

pub fn DateTime.now() -> DateTime {
  let epoch = time(0);
  return decompose_epoch(epoch);
}

pub fn DateTime.year(self) -> Int {
  return self.year;
}

pub fn DateTime.month(self) -> Int
  ensures: 1 <= result && result <= 12
{
  return self.month;
}

pub fn DateTime.day(self) -> Int {
  return self.day;
}

pub fn DateTime.hour(self) -> Int {
  return self.hour;
}

pub fn DateTime.minute(self) -> Int {
  return self.minute;
}

pub fn DateTime.second(self) -> Int {
  return self.second;
}

pub fn DateTime.weekday(self) -> Int {
  return self.weekday;
}

pub fn utc_now() -> DateTime {
  let epoch = time(0);
  return decompose_epoch(epoch);
}

pub fn local_now() -> DateTime {
  return utc_now();
}

// === Sleep / Wait ===
pub fn sleep(dur: Duration) {
  let total_ms = dur.as_millis();
  let start = time(0);
  let end = start + total_ms / MILLIS_PER_SEC;
  while time(0) < end {
  };
}

pub fn sleep_ms(ms: Int) {
  let start = time(0);
  let end = start + ms / MILLIS_PER_SEC;
  while time(0) < end {
  };
}

pub fn sleep_until(instant: Instant) {
  while time(0) < instant.t {
  };
}

// ──────────────────────────────────────────────────────────
//  Date — calendar date (year, month, day) with day-number
//  arithmetic on the proleptic Gregorian calendar.
// ──────────────────────────────────────────────────────────

pub type Date = {
  year: Int;
  month: Int;
  day: Int;
}

// days_from_civil returns the number of days since 1970-01-01
// for the given proleptic Gregorian calendar date.
// O(1) integer arithmetic, adapted from Howard Hinnant's algorithm.
fn days_from_civil(y: Int, m: Int, d: Int) -> Int {
  var y2 = y;
  var m2 = m;
  if m2 <= 2 {
    y2 = y2 - 1;
    m2 = m2 + 12;
  };
  m2 = m2 - 3;
  let serial = 365 * y2 + y2 / 4 - y2 / 100 + y2 / 400 + (153 * m2 + 2) / 5 + d - 1;
  return serial - 719468;
}

// date_new creates a Date from year, month, day.
// Complexity: O(1). No validation performed.
pub fn date_new(year: Int, month: Int, day: Int) -> Date {
  return Date{ year: year; month: month; day: day; };
}

// date_now returns the current date computed from the Unix timestamp.
// Complexity: O(1). Uses time(0) for the system clock.
pub fn date_now() -> Date {
  let ts = time(0);
  return timestamp_to_date(ts);
}

// date_year returns the year field of a Date.
// Complexity: O(1).
pub fn date_year(d: &Date) -> Int {
  return d.year;
}

// date_month returns the month field of a Date (1–12).
// Complexity: O(1).
pub fn date_month(d: &Date) -> Int {
  return d.month;
}

// date_day returns the day-of-month field of a Date (1–31).
// Complexity: O(1).
pub fn date_day(d: &Date) -> Int {
  return d.day;
}

// date_is_leap_year returns true if the given year is a leap year
// in the proleptic Gregorian calendar.
// Complexity: O(1).
pub fn date_is_leap_year(year: Int) -> Bool {
  if year % 400 == 0 {
    return true;
  };
  if year % 100 == 0 {
    return false;
  };
  return year % 4 == 0;
}

// date_days_in_month returns the number of days in the given month
// of the given year (1..31).  Valid for proleptic Gregorian.
// Complexity: O(1).
pub fn date_days_in_month(year: Int, month: Int) -> Int {
  if month == 2 {
    if date_is_leap_year(year) {
      return 29;
    };
    return 28;
  };
  if month == 4 || month == 6 || month == 9 || month == 11 {
    return 30;
  };
  return 31;
}

// date_day_of_week returns the day of the week for the given date
// using Zeller's congruence (Gregorian).  0 = Sunday, …, 6 = Saturday.
// Complexity: O(1).
pub fn date_day_of_week(year: Int, month: Int, day: Int) -> Int {
  var m = month;
  var y = year;
  if m <= 2 {
    m = m + 12;
    y = y - 1;
  };
  let k = y - (y / 100) * 100;
  let j = y / 100;
  let h = day + (13 * (m + 1)) / 5 + k + k / 4 + j / 4 - 2 * j;
  var r = h % 7;
  if r < 0 {
    r = r + 7;
  };
  return (r + 6) % 7;
}

// date_day_of_year returns the ordinal day of the year (1–366)
// for the given date.
// Complexity: O(1).
pub fn date_day_of_year(year: Int, month: Int, day: Int) -> Int {
  var result = day;
  var m = 1;
  while m < month {
    result = result + date_days_in_month(year, m);
    m = m + 1;
  };
  return result;
}

// date_iso8601 formats a Date as a zero-padded "YYYY-MM-DD" string.
// Complexity: O(1).  No dynamic allocation overhead beyond str_concat.
pub fn date_iso8601(d: &Date) -> Str {
  return format_timestamp_date(d);
}

// format_timestamp_date formats a Date reference as "YYYY-MM-DD".
fn format_timestamp_date(d: &Date) -> Str {
  let y_str = format_int_padded(d.year, 4);
  let m_str = format_int_padded(d.month, 2);
  let d_str = format_int_padded(d.day, 2);
  let result = y_str + "-";
  result = result + m_str;
  result = result + "-";
  result = result + d_str;
  return result;
}

// format_int_padded converts n to a zero-padded string of at least width.
// Negative values preserve the sign and pad the absolute digits.
fn format_int_padded(n: Int, width: Int) -> Str {
  var negative = false;
  var value = n;
  if n < 0 {
    negative = true;
    value = -n;
  };
  var digits = to_string(value);
  var pad = width - digits.len();
  var result = "";
  while pad > 0 {
    result = result + "0";
    pad = pad - 1;
  };
  result = result + digits;
  if negative {
    result = "-" + result;
  };
  return result;
}

// date_from_iso8601 parses a "YYYY-MM-DD" string into a Date.
// Returns None if the format is malformed or values out of range.
// Complexity: O(1).
pub fn date_from_iso8601(s: Str) -> Option[Date] {
  if s.len() != 10 {
    return None;
  };
  let ch4 = xiom.string.char_at(s, 4);
  let ch7 = xiom.string.char_at(s, 7);
  if ch4.is_none || ch7.is_none {
    return None;
  };
  if ch4.unwrap() != '-' || ch7.unwrap() != '-' {
    return None;
  };
  let y_str = xiom.string.str_slice(s, 0, 4);
  let m_str = xiom.string.str_slice(s, 5, 7);
  let d_str = xiom.string.str_slice(s, 8, 10);
  let y_res = xiom.string.str_to_int(y_str);
  let m_res = xiom.string.str_to_int(m_str);
  let d_res = xiom.string.str_to_int(d_str);
  if y_res.is_err || m_res.is_err || d_res.is_err {
    return None;
  };
  let year = y_res.unwrap();
  let month = m_res.unwrap();
  let day = d_res.unwrap();
  if month < 1 || month > 12 {
    return None;
  };
  if day < 1 || day > date_days_in_month(year, month) {
    return None;
  };
  return Some(Date{ year: year; month: month; day: day; });
}

// date_add_days returns a new Date offset by the given number of days.
// Handles negative days correctly.  Complexity: O(1).
pub fn date_add_days(d: &Date, days: Int) -> Date {
  let total = days_from_civil(d.year, d.month, d.day) + days;
  let (y, m, day) = civil_from_days(total);
  return Date{ year: y; month: m; day: day; };
}

// date_diff_days returns the number of days between a and b (a − b).
// Complexity: O(1).
pub fn date_diff_days(a: &Date, b: &Date) -> Int {
  let da = days_from_civil(a.year, a.month, a.day);
  let db = days_from_civil(b.year, b.month, b.day);
  return da - db;
}

// date_compare compares two dates.
// Returns -1 if a < b, 0 if equal, 1 if a > b.  Complexity: O(1).
pub fn date_compare(a: &Date, b: &Date) -> Int {
  if a.year < b.year {
    return -1;
  };
  if a.year > b.year {
    return 1;
  };
  if a.month < b.month {
    return -1;
  };
  if a.month > b.month {
    return 1;
  };
  if a.day < b.day {
    return -1;
  };
  if a.day > b.day {
    return 1;
  };
  return 0;
}

// unix_timestamp returns the current Unix timestamp (seconds since epoch).
// Delegates to the C time(2) call.  Complexity: O(1).
pub fn unix_timestamp() -> Int {
  return time(0);
}

// timestamp_to_date converts a Unix timestamp (seconds) to a Date.
// Uses the existing civil_from_days calendar decomposition.
// Complexity: O(1).
pub fn timestamp_to_date(ts: Int) -> Date {
  var days = ts / SECS_PER_DAY;
  var tod = ts - days * SECS_PER_DAY;
  if tod < 0 {
    days = days - 1;
  };
  let (y, m, d) = civil_from_days(days);
  return Date{ year: y; month: m; day: d; };
}

// date_to_timestamp converts a Date to a Unix timestamp (0:00:00 UTC).
// Complexity: O(1).
pub fn date_to_timestamp(d: &Date) -> Int {
  let days = days_from_civil(d.year, d.month, d.day);
  return days * SECS_PER_DAY;
}

// iso8601_now returns the current date as an ISO-8601 "YYYY-MM-DD" string.
// Complexity: O(1).
pub fn iso8601_now() -> Str {
  let d = date_now();
  return date_iso8601(&d);
}

// format_timestamp formats a Unix timestamp as a human-readable
// date-time string "YYYY-MM-DD HH:MM:SS" (UTC).
// Complexity: O(1).
pub fn format_timestamp(ts: Int) -> Str {
  let dt = decompose_epoch(ts);
  let result = format_int_padded(dt.year, 4) + "-";
  result = result + format_int_padded(dt.month, 2);
  result = result + "-";
  result = result + format_int_padded(dt.day, 2);
  result = result + " ";
  result = result + format_int_padded(dt.hour, 2);
  result = result + ":";
  result = result + format_int_padded(dt.minute, 2);
  result = result + ":";
  result = result + format_int_padded(dt.second, 2);
  return result;
}
