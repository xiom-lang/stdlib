// p_wave199_mid_gaps.xi -- wave 199: mid-gap contract-clause lock.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the wave-199 clauses that carry real information:
// 1. alloc.Layout: size/align constructors and the padded-size bound law.
// 2. rc: unwrap_or_clone on the last handle and on a shared handle, plus
//    Weak.drop's live-weak precondition.
// 3. bench: black_box identity and the non-negative timing result.
// 4. ffi: errno_set non-negative domain and ffi_ok's zero result.
// 5. rand: ChaCha/MT/PCG structural state preconditions and output ranges,
//    seed_from_value's non-zero state, Xorshift64's non-zero stream.
// 6. thread: detach's positive spawn id.
// 7. async: async_spawn_delayed's non-negative delay.
// 8. time: Duration accessor domains, Date field ranges, leap-year law,
//    chrono weekday/offset, ISO week/ordinal ranges and date-parse payload.
//
// Top-level xiom.simd.Vec4f/Vec8f lane storage is NOT exercised at runtime:
// v0.64.8 miscompiles lane get/write (REL-20261019-2249-stdlib-2), so the
// new allocation clauses there are compile-checked by check_modules only.
// Every call re-evaluates the new runtime contracts; a violation aborts.
// Returns 0 when every case holds.

module p_wave199_mid_gaps

use xiom.alloc;
use xiom.rc;
use xiom.bench;
use xiom.ffi;
use xiom.ffi.errno;
use xiom.rand as rnd;
use xiom.rand.chacha;
use xiom.rand.mt19937;
use xiom.rand.pcg;
use xiom.thread.spawn as tspawn;
use xiom.async as asynclib;
use xiom.time as tm;
use xiom.time.chrono;
use xiom.time.iso8601;

fn noop() {
}

fn main() -> Int {
  // 1: alloc.Layout -- constructors and padded-size bound law.
  var l = alloc.Layout.new(64);
  if l.size != 64 || l.align != 8 { return 1; }
  var l2 = l.with_align(16);
  if l2.size != 64 || l2.align != 16 { return 2; }
  if l2.padded_size() != 64 { return 3; }
  var l3 = alloc.Layout.new(65).with_align(8);
  if l3.padded_size() != 72 { return 4; }
  if l3.padded_size() % 8 != 0 { return 5; }

  // 2: rc -- unwrap_or_clone last/shared paths and Weak.drop domain.
  var r1 = rc.Rc.new(7);
  if r1.unwrap_or_clone() != 7 { return 6; }
  var r2 = rc.Rc.new(11);
  var shared = r2.clone();
  if r2.unwrap_or_clone() != 11 { return 7; }
  if shared.strong_count() != 2 { return 8; }
  var r3 = rc.Rc.new(5);
  var w = r3.downgrade();
  w.drop();
  if r3.weak_count() != 0 { return 9; }

  // 3: bench -- identity and non-negative timing.
  if bench.black_box(42) != 42 { return 10; }
  if bench.bench_time_fn(noop) < 0 { return 11; }

  // 4: ffi -- errno domain and the success code.
  errno.errno_set(2);
  if errno.errno_get() != 2 { return 12; }
  errno.errno_set(0);
  if ffi.ffi_ok() != 0 { return 13; }

  // 5: rand -- ChaCha structural state and output ranges.
  var c = chacha.chacha_rng_new();
  let cw = chacha.chacha_rng_next_u32(&mut c);
  if (cw as Int) < 0 { return 14; }
  if chacha.chacha_rng_next_int(&mut c) < 0 { return 15; }
  var cf = chacha.chacha_rng_next_float(&mut c);
  if cf < 0.0 || cf >= 1.0 { return 16; }
  // MT19937 state length/index precondition.
  var mt = mt19937.mt19937_new();
  if mt19937.mt19937_next_int(&mut mt) < 0 { return 17; }
  // PCG output word range.
  var p = pcg.pcg_from_seed(12345 as UInt64);
  if pcg.pcg_next_int(&mut p) < 0 { return 18; }
  // Global seed normalization and Xorshift64 non-zero stream.
  rnd.seed_from_value(0);
  if rnd.state() == 0 { return 19; }
  var xs = rnd.Xorshift64.new(1);
  if xs.next_int() == 0 { return 20; }
  if xs.next_int() == 0 { return 21; }

  // 6: thread -- detach requires a positive spawn id.
  var t = tspawn.spawn(noop);
  tspawn.detach(t);

  // 7: async -- non-negative delay. Only the clause-carrying enqueue runs
  // here: driving the global executor through spawn()/run() hits a
  // pre-existing v0.64.8 0xC000001D crash (reproduced with unclaused
  // spawn/run alone); the per-executor drain paths stay covered by
  // smoke_async.
  asynclib.async_spawn_delayed(0, noop);

  // 8: time -- Duration accessor domains.
  var d = tm.Duration.new(2, 500000000);
  if d.as_millis() != 2500 { return 22; }
  if d.as_micros() != 2500000 { return 23; }
  if d.as_nanos() != 2500000000 { return 24; }
  if d.subsec_nanos() != 500000000 { return 25; }
  var df = d.as_secs_f64();
  if df < 2.49 || df > 2.51 { return 26; }

  // 8: time -- Date field ranges and the leap-year law.
  var jan = tm.date_new(2026, 1, 1);
  if tm.date_month(&jan) != 1 { return 27; }
  if tm.date_day(&jan) != 1 { return 28; }
  if tm.date_is_leap_year(2024) != true { return 29; }
  if tm.date_is_leap_year(2026) != false { return 30; }
  if tm.date_diff_days(&jan, &jan) != 0 { return 31; }

  // 8: time -- chrono weekday domain and UTC offset.
  var dt = tm.datetime_from_epoch(0);
  if chrono.chrono_weekday(&dt) != 4 { return 32; }
  if chrono.chrono_timezone_offset(&dt) != 0 { return 33; }

  // 8: time -- ISO week/ordinal ranges and date-parse payload.
  var wd = iso8601.iso8601_week_date(&jan);
  if wd.1 < 1 || wd.1 > 53 { return 34; }
  if wd.2 < 1 || wd.2 > 7 { return 35; }
  var od = iso8601.iso8601_ordinal_date(&jan);
  if od.1 != 1 { return 36; }
  match iso8601.iso8601_date_parse("2026-08-12") {
    Some(parsed) => {
      if parsed.month != 8 || parsed.day != 12 { return 37; }
    },
    None => { return 38; },
  };

  return 0;
}
