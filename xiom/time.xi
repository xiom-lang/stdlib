// XIOM — Time Library
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.time

// === Duration — a span of time ===
pub type Duration = {
  secs: Int;
  nanos: Int;
} derive[Eq, Clone, Ord]

pub fn Duration.from_secs(s: Int) -> Duration;
pub fn Duration.from_millis(ms: Int) -> Duration;
pub fn Duration.from_micros(us: Int) -> Duration;
pub fn Duration.from_nanos(ns: Int) -> Duration;
pub fn Duration.as_secs(self) -> Int;
pub fn Duration.as_millis(self) -> Int;
pub fn Duration.subsec_nanos(self) -> Int;
pub fn Duration.checked_add(self, other: Duration) -> Option[Duration];
pub fn Duration.checked_sub(self, other: Duration) -> Option[Duration];

// === Instant — a point in time (monotonic clock) ===
pub type Instant = { t: Int; }
pub fn Instant.now() -> Instant;
pub fn Instant.elapsed(self) -> Duration;
pub fn Instant.duration_since(self, earlier: Instant) -> Duration;

// === SystemTime — wall clock time ===
pub type SystemTime = { secs: Int; nanos: Int; }
pub fn SystemTime.now() -> SystemTime;
pub fn SystemTime.unix_epoch() -> SystemTime;
pub fn SystemTime.duration_since(self, earlier: SystemTime) -> Result[Duration, Str];
pub fn SystemTime.secs_since_epoch(self) -> Int;

// === Calendar ===
pub type DateTime = {
  year: Int;
  month: Int;
  day: Int;
  hour: Int;
  minute: Int;
  second: Int;
  weekday: Int;
}

pub fn utc_now() -> DateTime;
pub fn local_now() -> DateTime;

// === Sleep / Wait ===
pub fn sleep(dur: Duration);
pub fn sleep_ms(ms: Int);
pub fn sleep_until(instant: Instant);
