// p_wave191_time_async.xi -- wave 191: time/async contract locks.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Every call below evaluates the new runtime requires/ensures clauses (a
// violation aborts the probe). Cases:
// 1. Duration conversions: exact total-nanos value and normalized
//    nanoseconds for positive, negative, and fractional inputs.
// 2. Checked duration arithmetic: Option payloads and normalized nanos.
// 3. Instant/SystemTime: ordering, millisecond relations, Ok payload range,
//    whole-second wall-clock nanos.
// 4. DateTime/Date: civil field ranges, ISO-8601 lengths, parse payloads,
//    midnight-aligned timestamps, day-of-week/day-of-year ranges.
// 5. chrono: timestamp round-trips, second/day/month/year arithmetic,
//    diff/comparison sign and range.
// 6. tz: host offset bounds, DST probe, local-epoch/time payload ranges.
// 7. async: executor ready/timer length invariants, step/fire_due_timers
//    state transitions, channel cap/closed/length invariants, task ids.
// Returns 0 when every case holds.

module p_wave191_time_async

use xiom.time;
use xiom.time.chrono;
use xiom.time.tz;
use xiom.async;
use xiom.io;

var _fired: Int = 0;

fn bump() {
  _fired = _fired + 1;
}

fn main() -> Int {
  // ---- 1: duration conversions ----
  var ds = time.Duration.from_secs(3);
  if ds.secs != 3 || ds.nanos != 0 { return 1; }
  var dm = time.Duration.from_millis(0 - 1500);
  if dm.as_nanos() != (0 - 1500) * 1000000 { return 2; }
  if dm.nanos < 0 || dm.nanos >= 1000000000 { return 3; }
  var du = time.Duration.from_micros(0 - 1);
  if du.as_nanos() != (0 - 1) * 1000 { return 4; }
  if du.nanos < 0 || du.nanos >= 1000000000 { return 5; }
  var dn = time.Duration.from_nanos(0 - 1);
  if dn.as_nanos() != (0 - 1) { return 6; }
  if dn.secs != (0 - 1) || dn.nanos != 999999999 { return 7; }
  var df = time.Duration.from_secs_f64(1.5);
  if df.secs != 1 || df.nanos != 500000000 { return 8; }
  var dfn = time.Duration.from_secs_f64(0.0 - 1.5);
  if dfn.nanos < 0 || dfn.nanos >= 1000000000 { return 9; }

  // ---- 2: checked arithmetic ----
  var a5 = time.Duration.from_secs(5);
  var a2 = time.Duration.from_secs(2);
  match a5.checked_add(a2) {
    Some(s) => { if s.secs != 7 || s.nanos != 0 { return 10; } },
    None => { return 11; },
  }
  match a5.checked_sub(a2) {
    Some(s) => { if s.secs != 3 || s.nanos != 0 { return 12; } },
    None => { return 13; },
  }
  match a2.checked_sub(a5) {
    Some(_) => { return 14; },
    None => {},
  }

  // ---- 3: instants and wall clock ----
  var i1 = time.Instant{ t: 1000 };
  var i2 = time.Instant{ t: 2500 };
  if i2.duration_since(i1).as_nanos() != 1500 * 1000000 { return 15; }
  var i3 = time.Instant{ t: 2500 };
  if i3.add(a5).t != 7500 { return 16; }
  var i4 = time.Instant{ t: 2500 };
  if i4.sub(a5).t != 0 - 2500 { return 17; }
  var i5 = time.Instant{ t: 1000 };
  var i6 = time.Instant{ t: 2500 };
  if i5.duration_since(i6).as_nanos() != (0 - 1500) * 1000000 { return 18; }
  var i7 = time.Instant{ t: 2500 };
  var el = i7.elapsed();
  if el.nanos < 0 || el.nanos >= 1000000000 { return 19; }
  var future = time.Instant{ t: time.monotonic_ms() + 100000 };
  var fel = future.elapsed();
  if fel.nanos < 0 || fel.nanos >= 1000000000 { return 20; }

  var st = time.SystemTime.now();
  if st.nanos != 0 { return 21; }
  var st1 = time.SystemTime{ secs: 10; nanos: 500000000 };
  var st2 = time.SystemTime{ secs: 10; nanos: 200000000 };
  match st1.duration_since(st2) {
    Ok(d) => { if d.secs != 0 || d.nanos != 300000000 { return 22; } },
    Err(_) => { return 23; },
  }
  var st3 = time.SystemTime{ secs: 10; nanos: 200000000 };
  var st4 = time.SystemTime{ secs: 10; nanos: 500000000 };
  match st3.duration_since(st4) {
    Ok(_) => { return 24; },
    Err(_) => {},
  }

  // ---- 4: DateTime / Date ----
  var dt = time.datetime_from_epoch(0);
  if dt.year != 1970 || dt.month != 1 || dt.day != 1 { return 25; }
  if dt.hour != 0 || dt.minute != 0 || dt.second != 0 || dt.weekday != 4 { return 26; }
  var utc = time.utc_now();
  if utc.month < 1 || utc.month > 12 || utc.day < 1 || utc.day > 31 { return 27; }
  if utc.hour < 0 || utc.hour >= 24 || utc.minute < 0 || utc.minute >= 60 { return 28; }
  if utc.second < 0 || utc.second >= 60 || utc.weekday < 0 || utc.weekday >= 7 { return 29; }
  var loc = time.local_now();
  if loc.month < 1 || loc.month > 12 || loc.day < 1 || loc.day > 31 { return 30; }

  var dtx = time.DateTime{ year: 2026; month: 8; day: 11; hour: 10; minute: 30; second: 5; weekday: 2 };
  if dtx.month() != 8 || dtx.day() != 11 || dtx.hour() != 10 { return 31; }
  if dtx.minute() != 30 || dtx.second() != 5 || dtx.weekday() != 2 { return 32; }
  if dtx.year() != 2026 { return 33; }

  var dnow = time.date_now();
  if dnow.month < 1 || dnow.month > 12 || dnow.day < 1 || dnow.day > 31 { return 34; }
  var leap = time.date_new(2024, 2, 29);
  if time.date_days_in_month(2024, 2) != 29 { return 35; }
  if time.date_days_in_month(2023, 2) != 28 { return 36; }
  if time.date_day_of_week(2026, 8, 11) != 2 { return 37; }
  if time.date_day_of_year(2024, 12, 31) != 366 { return 38; }
  if time.date_iso8601(&leap).len() != 10 { return 39; }
  match time.date_from_iso8601("2026-08-11") {
    Some(pd) => { if pd.year != 2026 || pd.month != 8 || pd.day != 11 { return 40; } },
    None => { return 41; },
  }
  match time.date_from_iso8601("2026-13-01") {
    Some(_) => { return 42; },
    None => {},
  }
  var dnext = time.date_add_days(&leap, 1);
  if dnext.year != 2024 || dnext.month != 3 || dnext.day != 1 { return 43; }
  if time.date_compare(&leap, &dnext) != (0 - 1) { return 44; }
  if time.date_compare(&leap, &leap) != 0 { return 45; }
  if time.date_to_timestamp(&leap) % 86400 != 0 { return 46; }
  var tsd = time.timestamp_to_date(0 - 1);
  if tsd.year != 1969 || tsd.month != 12 || tsd.day != 31 { return 47; }
  if time.iso8601_now().len() < 10 { return 48; }
  if time.format_timestamp(0).len() < 19 { return 49; }
  if time.format_timestamp(0 - 1).len() < 19 { return 50; }
  if time.strftime("", &leap).len() != 0 { return 51; }
  var parsed = time.strptime("2026-08-11", "%Y-%m-%d");
  if !parsed.is_ok || parsed.date.month != 8 || parsed.date.day != 11 { return 52; }
  var bad_parse = time.strptime("2026-13-01", "%Y-%m-%d");
  if bad_parse.is_ok { return 53; }
  if bad_parse.date.month != 1 || bad_parse.date.day != 1 { return 54; }

  // ---- 5: chrono ----
  var cdt = chrono.chrono_from_timestamp(0);
  if cdt.year != 1970 || cdt.month != 1 || cdt.day != 1 { return 55; }
  if cdt.hour != 0 || cdt.minute != 0 || cdt.second != 0 || cdt.weekday != 4 { return 56; }
  if chrono.chrono_to_timestamp(&cdt) != 0 { return 57; }
  var ca = chrono.chrono_add_seconds(&cdt, 3661);
  if chrono.chrono_to_timestamp(&ca) != 3661 { return 58; }
  var cd = chrono.chrono_add_days(&cdt, 31);
  if chrono.chrono_to_timestamp(&cd) != 31 * 86400 { return 59; }
  var cm = chrono.chrono_add_months(&cdt, 13);
  if cm.year != 1971 || cm.month != 2 || cm.day != 1 { return 60; }
  if cm.hour != cdt.hour || cm.minute != cdt.minute || cm.second != cdt.second { return 61; }
  var cy = chrono.chrono_add_years(&cdt, 1);
  if cy.year != 1971 || cy.month != 1 || cy.day != 1 { return 62; }
  var cdiff = chrono.chrono_diff(&ca, &cdt);
  if cdiff.secs != 3661 || cdiff.nanos != 0 { return 63; }
  if chrono.chrono_compare(&ca, &cdt) != 1 { return 64; }
  if chrono.chrono_compare(&cdt, &ca) != (0 - 1) { return 65; }
  if chrono.chrono_compare(&cdt, &cdt) != 0 { return 66; }
  if chrono.chrono_weekday(&cdt) != 4 { return 67; }
  var cnow = chrono.chrono_now();
  if cnow.month < 1 || cnow.month > 12 || cnow.day < 1 || cnow.day > 31 { return 68; }
  var cutc = chrono.chrono_utc_now();
  if cutc.month < 1 || cutc.month > 12 || cutc.day < 1 || cutc.day > 31 { return 69; }

  // ---- 6: timezone offsets ----
  match tz.tz_local_offset_secs() {
    Ok(o) => {
      if o < (0 - 43200) || o > 50400 { return 70; }
      if o % 60 != 0 { return 71; }
    },
    Err(e) => { if e.len() == 0 { return 72; } return 73; },
  }
  match tz.tz_offset_secs_at(0) {
    Ok(o) => { if o < (0 - 43200) || o > 50400 { return 74; } },
    Err(e) => { if e.len() == 0 { return 75; } },
  }
  match tz.tz_is_dst() {
    Ok(_) => {},
    Err(e) => { if e.len() == 0 { return 76; } return 77; },
  }
  match tz.tz_local_epoch_secs() {
    Ok(_) => {},
    Err(e) => { if e.len() == 0 { return 78; } return 79; },
  }
  match tz.tz_local_now() {
    Ok(ldt) => {
      if ldt.month < 1 || ldt.month > 12 || ldt.day < 1 || ldt.day > 31 { return 80; }
    },
    Err(e) => { if e.len() == 0 { return 81; } return 82; },
  }

  // ---- 7: async executor / channel state ----
  var ex = xiom.async.AsyncExecutor.new();
  if ex.ready.len() != 0 || ex.timers.len() != 0 { return 83; }
  xiom.async.AsyncExecutor.spawn(&mut ex, bump);
  if ex.ready.len() != 1 { return 84; }
  if !xiom.async.AsyncExecutor.step(&mut ex) { return 85; }
  if _fired != 1 || ex.ready.len() != 0 { return 86; }
  if xiom.async.AsyncExecutor.step(&mut ex) { return 87; }
  xiom.async.AsyncExecutor.at(&mut ex, xiom.async.async_now_ms() - 1, bump);
  if ex.timers.len() != 1 { return 88; }
  xiom.async.AsyncExecutor.fire_due_timers(&mut ex);
  if ex.timers.len() != 0 || ex.ready.len() != 1 { return 89; }
  if !xiom.async.AsyncExecutor.step(&mut ex) || _fired != 2 { return 90; }
  xiom.async.AsyncExecutor.spawn(&mut ex, bump);
  xiom.async.AsyncExecutor.spawn(&mut ex, bump);
  xiom.async.AsyncExecutor.run(&mut ex);
  if _fired != 4 { return 91; }

  var ex2 = xiom.async.AsyncExecutor.new();
  xiom.async.AsyncExecutor.block_on(&mut ex2, bump);
  if _fired != 5 { return 92; }

  var ex3 = xiom.async.AsyncExecutor.new();
  xiom.async.AsyncExecutor.spawn(&mut ex3, bump);
  if !xiom.async.async_step_once(&mut ex3) { return 93; }
  if ex3.ready.len() != 0 { return 94; }
  xiom.async.AsyncExecutor.spawn(&mut ex3, bump);
  xiom.async.AsyncExecutor.at(&mut ex3, xiom.async.async_now_ms() - 1, bump);
  xiom.async.async_run_until_idle(&mut ex3);
  if ex3.ready.len() != 0 || ex3.timers.len() != 1 { return 95; }

  var ch = xiom.async.Channel.bounded(2);
  if ch.cap != 2 || ch.closed || ch.items.len() != 0 { return 96; }
  xiom.async.Channel.send[Int](&mut ch, 7);
  if ch.items.len() != 1 { return 97; }
  xiom.async.Channel.send[Int](&mut ch, 8);
  if ch.items.len() != 2 { return 98; }
  match xiom.async.Channel.try_recv[Int](&mut ch) {
    Some(v) => { if v != 7 { return 99; } },
    None => { return 100; },
  }
  if ch.items.len() != 1 { return 101; }
  match xiom.async.Channel.try_recv[Int](&mut ch) {
    Some(v) => { if v != 8 { return 102; } },
    None => { return 103; },
  }
  match xiom.async.Channel.try_recv[Int](&mut ch) {
    Some(_) => { return 104; },
    None => {},
  }
  xiom.async.Channel.close[Int](&mut ch);
  if !ch.closed { return 105; }
  var ub = xiom.async.Channel.unbounded();
  if ub.cap != 0 || ub.closed || ub.items.len() != 0 { return 106; }

  if xiom.async.async_now_ms() < 0 { return 107; }

  io.println("p_wave191_time_async: OK");
  return 0;
}

