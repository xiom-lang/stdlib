// p_wave66_shapes.xi -- wave 66 shape validation: time core (duration/instant/date/iso8601)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-66 clauses on xiom.time.{duration (15), instant (6),
// date (12), iso8601 (6)} = 39 fns. date_now, instant_now and
// instant_elapsed stay clause-free (system clock); the three tuple-returning
// iso8601 helpers (week_date, ordinal_date) and iso8601_date_parse stay
// uncovered pending the catalog tuple-clause restriction. No network or
// socket I/O; 61 checks; returns 0 when every case holds.

module p_wave66_shapes

use xiom.time.duration;
use xiom.time.instant;
use xiom.time.date;
use xiom.time.iso8601;

fn main() -> Int {
  // ---- duration
  let d5 = duration.duration_secs(5);
  if d5.secs != 5 || d5.nanos != 0 { return 1; }
  let dm = duration.duration_millis(3000);
  if dm.secs != 3 || dm.nanos != 0 { return 2; }
  let dmu = duration.duration_micros(2000000);
  if dmu.secs != 2 || dmu.nanos != 0 { return 3; }
  let dn = duration.duration_nanos(3000000000);
  if dn.secs != 3 || dn.nanos != 0 { return 4; }
  let df0 = duration.duration_from_secs_f64(0.0);
  if df0.secs != 0 || df0.nanos != 0 { return 5; }
  let dsum = duration.duration_add(duration.duration_secs(1), duration.duration_millis(500));
  if dsum.nanos < 0 || dsum.nanos >= 1000000000 { return 6; }
  if dsum.secs != 1 || dsum.nanos != 500000000 { return 7; }
  let dsub = duration.duration_sub(duration.duration_secs(2), duration.duration_millis(500));
  if dsub.secs != 1 || dsub.nanos != 500000000 { return 8; }
  let dmul = duration.duration_mul(duration.duration_secs(2), 3);
  if dmul.secs != 6 || dmul.nanos != 0 { return 9; }
  let ddiv0 = duration.duration_div(duration.duration_secs(5), 0);
  if ddiv0.secs != 0 || ddiv0.nanos != 0 { return 10; }
  let ddiv = duration.duration_div(duration.duration_secs(5), 5);
  if ddiv.secs != 1 { return 11; }
  if duration.duration_as_secs(dm) != 3 { return 12; }
  if duration.duration_as_millis(d5) != 5000 { return 13; }
  if duration.duration_as_micros(d5) != 5000000 { return 14; }
  if duration.duration_as_nanos(d5) != 5000000000 { return 15; }
  if duration.duration_compare(d5, d5) != 0 { return 16; }
  if duration.duration_compare(d5, dm) != 1 { return 17; }
  if duration.duration_compare(dm, d5) != 0 - 1 { return 18; }
  if !duration.duration_is_zero(duration.duration_secs(0)) { return 19; }
  if duration.duration_is_zero(d5) { return 20; }

  // ---- instant
  let i5 = instant.instant_from_millis(5000);
  if i5.t != 5 { return 21; }
  if instant.instant_to_millis(i5) != 5000 { return 22; }
  if instant.instant_compare(i5, instant.instant_from_millis(5000)) != 0 { return 23; }
  let i2 = instant.instant_from_millis(2000);
  if instant.instant_compare(i2, i5) != 0 - 1 { return 24; }
  if instant.instant_compare(i5, i2) != 1 { return 25; }
  let i7 = instant.instant_add(i5, duration.duration_secs(2));
  if i7.t != 7 { return 26; }
  let i3 = instant.instant_sub(i5, duration.duration_secs(2));
  if i3.t != 3 { return 27; }
  let el = instant.instant_duration_since(i5, i2);
  if el.secs != 3 || el.nanos != 0 { return 28; }

  // ---- date
  let d2024 = date.date_new(2024, 2, 29);
  if d2024.year != 2024 || d2024.month != 2 || d2024.day != 29 { return 29; }
  let epoch = date.date_from_timestamp(0);
  if epoch.year != 1970 || epoch.month != 1 || epoch.day != 1 { return 30; }
  if date.date_to_timestamp(&epoch) != 0 { return 31; }
  if date.date_weekday(&epoch) != 4 { return 32; }
  let jan31 = date.date_new(2024, 1, 31);
  if date.date_day_of_year(&jan31) != 31 { return 33; }
  if date.date_day_of_month(&d2024) != 29 { return 34; }
  if date.date_days_in_month(2024, 2) != 29 { return 35; }
  if date.date_days_in_month(2023, 2) != 28 { return 36; }
  if date.date_days_in_month(2024, 4) != 30 { return 37; }
  if date.date_days_in_month(2024, 12) != 31 { return 38; }
  if !date.date_is_leap(2000) { return 39; }
  if date.date_is_leap(1900) { return 40; }
  if date.date_is_leap(2023) { return 41; }
  if !date.date_is_leap(2024) { return 42; }
  let same = date.date_add_days(&d2024, 0);
  if same.year != 2024 || same.month != 2 || same.day != 29 { return 43; }
  let same2 = date.date_sub_days(&d2024, 0);
  if same2.year != 2024 || same2.month != 2 || same2.day != 29 { return 44; }
  if date.date_diff_days(&d2024, &d2024) != 0 { return 45; }
  if date.date_compare(&d2024, &d2024) != 0 { return 46; }
  if date.date_compare(&epoch, &d2024) != 0 - 1 { return 47; }
  if date.date_compare(&d2024, &epoch) != 1 { return 48; }
  let feb1 = date.date_add_days(&jan31, 1);
  if feb1.month != 2 || feb1.day != 1 { return 49; }
  if date.date_diff_days(&date.date_new(2024, 3, 1), &date.date_new(2024, 2, 1)) != 29 { return 50; }

  // ---- iso8601
  let ds = iso8601.date_iso8601(&d2024);
  if ds.len() != 10 { return 51; }
  if !(ds == "2024-02-29") { return 52; }
  match iso8601.iso8601_parse("2024-02-09T12:34:56") {
    Some(dt) => {
      let out = iso8601.datetime_iso8601(&dt);
      if out.len() != 19 { return 53; }
      if !(out == "2024-02-09T12:34:56") { return 54; }
      let rf = iso8601.rfc3339_format(&dt);
      if rf.len() != 20 { return 55; }
      if !(rf == "2024-02-09T12:34:56Z") { return 56; }
    },
    None => { return 57; },
  }
  if iso8601.iso8601_parse("bad").is_some { return 58; }
  if iso8601.iso8601_parse("2024-02-30").is_some { return 59; }
  if !iso8601.rfc3339_parse("2024-02-09T12:34:56Z").is_some { return 60; }
  if !(iso8601.timestamp_iso8601(0) == "1970-01-01T00:00:00") { return 61; }

  return 0;
}
