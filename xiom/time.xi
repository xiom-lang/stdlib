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
