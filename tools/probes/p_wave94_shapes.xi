// p_wave94_shapes.xi -- wave 94 shape validation: cmp + core + sync + terminal
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-94 clause guards:
//   (a) xiom.cmp: the Ordering.then_with self-mirror, min_by/max_by value
//       disjunctions, the Int/Float extrema and clamp branches,
//       min3/max3/median3/compare_ints pins, is_between pins, the
//       Reverse.new field mirror and the empty min_of_vec/max_of_vec guards;
//   (b) xiom.core: to_string zero pin, the parse empty/valid guards
//       (to_int_from_str/to_float_from_str/to_bool_from_str), the
//       min/max/abs/clamp/bool conversions, int_to_char_safe bounds, the
//       Option/Result standalone queries and result_unwrap_or's Err branch;
//   (c) xiom.sync: sem_new field mirrors, sem_try_acquire/sem_acquire/
//       sem_release pre-state guards, sem_available mirror, barrier_new
//       count mirror, cdl_new field mirror, cdl_count_down decrement/no-op
//       branches and cdl_is_zero pins;
//   (d) xiom.format.terminal: the 24 exact ANSI escape pins, the progress
//       constructor clamp/field mirrors, progress_finish, the
//       progress_percent total<=0 pin and the spinner struct pins.
// Values returned from the module surface are bound before comparing.
// Returns 0 when every case holds.

module p_wave94_shapes

use xiom.cmp;
use xiom.core;
use xiom.sync;
use xiom.format.terminal;

fn main() -> Int {
  // ---- cmp: Ordering.then_with
  let tw0 = cmp.Ordering.Less.then_with(fn() -> cmp.Ordering { return cmp.Greater; });
  if tw0 != cmp.Less { return 1; }
  let tw1 = cmp.Ordering.Equal.then_with(fn() -> cmp.Ordering { return cmp.Greater; });
  if tw1 != cmp.Greater { return 2; }

  // ---- cmp: min_by / max_by
  let mb0 = cmp.min_by(10, 20, fn(a: &Int, b: &Int) -> cmp.Ordering {
    if *a < *b { return cmp.Less; }
    if *a > *b { return cmp.Greater; }
    return cmp.Equal;
  });
  if mb0 != 10 { return 3; }
  let mb1 = cmp.max_by(10, 20, fn(a: &Int, b: &Int) -> cmp.Ordering {
    if *a < *b { return cmp.Less; }
    if *a > *b { return cmp.Greater; }
    return cmp.Equal;
  });
  if mb1 != 20 { return 4; }

  // ---- cmp: Int extrema / compare_ints
  if cmp.max_int(3, 7) != 7 { return 5; }
  if cmp.max_int(7, 3) != 7 { return 6; }
  if cmp.min_int(3, 7) != 3 { return 7; }
  if cmp.compare_ints(1, 2) != -1 { return 8; }
  if cmp.compare_ints(2, 1) != 1 { return 9; }
  if cmp.compare_ints(2, 2) != 0 { return 10; }

  // ---- cmp: float extrema / clamp_float
  if cmp.max_float(1.5, 2.5) != 2.5 { return 11; }
  if cmp.min_float(1.5, 2.5) != 1.5 { return 12; }
  if cmp.clamp_float(0.5, 1.0, 2.0) != 1.0 { return 13; }
  if cmp.clamp_float(3.5, 1.0, 2.0) != 2.0 { return 14; }
  if cmp.clamp_float(1.5, 1.0, 2.0) != 1.5 { return 15; }

  // ---- cmp: Reverse / multi-value
  let rv = cmp.Reverse.new(9);
  if rv.value != 9 { return 16; }
  if cmp.min3(3, 1, 2) != 1 { return 17; }
  if cmp.max3(3, 1, 2) != 3 { return 18; }
  if cmp.median3(3, 1, 2) != 2 { return 19; }
  if cmp.is_between(2, 1, 3) == false { return 20; }
  if cmp.is_between(0, 1, 3) { return 21; }

  // ---- cmp: vec extrema
  var ce = Vec[Int].new();
  let mnv0 = cmp.min_of_vec(&ce);
  if mnv0.is_some { return 22; }
  let mxv0 = cmp.max_of_vec(&ce);
  if mxv0.is_some { return 23; }
  var cv = Vec[Int].new();
  cv.push(3); cv.push(1); cv.push(2);
  let mnv1 = cmp.min_of_vec(&cv);
  match mnv1 {
    Some(v) => { if v != 1 { return 24; } },
    None => { return 25; },
  }
  let mxv1 = cmp.max_of_vec(&cv);
  match mxv1 {
    Some(v2) => { if v2 != 3 { return 26; } },
    None => { return 27; },
  }

  // ---- core: to_string / parsers
  if core.to_string(0) != "0" { return 28; }
  if core.to_string(7) != "7" { return 29; }
  let pe = core.to_int_from_str("");
  if pe.is_err == false { return 30; }
  let pz = core.to_int_from_str("0");
  if pz.is_ok == false { return 31; }
  let fe = core.to_float_from_str("");
  if fe.is_err == false { return 32; }
  let fv = core.to_float_from_str("1.5");
  if fv.is_ok == false { return 33; }
  let bt = core.to_bool_from_str("true");
  if bt.is_ok == false { return 34; }
  let bf = core.to_bool_from_str("false");
  if bf.is_ok == false { return 35; }
  let bx = core.to_bool_from_str("yes");
  if bx.is_err == false { return 36; }

  // ---- core: extrema / clamp / bool / char
  if core.min_of(3, 7) != 3 { return 37; }
  if core.max_of(3, 7) != 7 { return 38; }
  if core.abs_int(-5) != 5 { return 39; }
  if core.abs_int(3) != 3 { return 40; }
  if core.clamp_int(0, 1, 3) != 1 { return 41; }
  if core.clamp_int(5, 1, 3) != 3 { return 42; }
  if core.clamp_int(2, 1, 3) != 2 { return 43; }
  if core.bool_to_int(true) != 1 { return 44; }
  if core.bool_to_int(false) != 0 { return 45; }
  if core.int_to_bool(0) { return 46; }
  if core.int_to_bool(1) == false { return 47; }
  let cs0 = core.int_to_char_safe(-1);
  if cs0.is_some { return 48; }
  let cs1 = core.int_to_char_safe(65);
  if cs1.is_none { return 49; }
  let cs2 = core.int_to_char_safe(1114112);
  if cs2.is_some { return 50; }

  // ---- core: Option / Result standalone surface (direct reads: the
  // &Option/&Result standalone queries are blocked by the generic
  // by-ref param defect, see tools/known_failures)
  var o1: Option[Int] = Some(4);
  if o1.is_some == false { return 51; }
  var o0: Option[Int] = None;
  if o0.is_some { return 52; }
  var r1: Result[Int, Str] = Ok(4);
  if r1.is_ok == false { return 53; }
  var r2: Result[Int, Str] = Err("x");
  if r2.is_err == false { return 54; }
  if core.result_unwrap_or(r1, 5) != 4 { return 55; }
  if core.result_unwrap_or(r2, 5) != 5 { return 56; }

  // ---- sync: semaphore
  var s3 = sync.sem_new(3);
  if s3.count != 3 { return 57; }
  if s3.max != 3 { return 58; }
  if sync.sem_available(&s3) != 3 { return 59; }
  let a1 = sync.sem_try_acquire(&s3);
  if a1 == false { return 60; }
  if s3.count != 2 { return 61; }
  let a2 = sync.sem_acquire(&s3);
  if a2 == false { return 62; }
  if s3.count != 1 { return 63; }
  sync.sem_release(&s3);
  if s3.count != 2 { return 64; }
  var s1 = sync.sem_new(1);
  let s1a = sync.sem_try_acquire(&s1);
  if s1a == false { return 65; }
  let z1 = sync.sem_try_acquire(&s1);
  if z1 { return 66; }
  let z2 = sync.sem_acquire(&s1);
  if z2 { return 66; }
  sync.sem_release(&s1);
  if s1.count != 1 { return 67; }
  sync.sem_release(&s1);
  if s1.count != 1 { return 68; }

  // ---- sync: barrier / cdl
  let bar = sync.barrier_new(2);
  if bar.count != 2 { return 69; }
  let cd0 = sync.cdl_new(2);
  if cd0.remaining != 2 { return 70; }
  var cd1 = sync.cdl_new(2);
  if sync.cdl_is_zero(&cd1) { return 71; }
  sync.cdl_count_down(&cd1);
  if cd1.remaining != 1 { return 72; }
  sync.cdl_count_down(&cd1);
  if sync.cdl_is_zero(&cd1) == false { return 73; }
  sync.cdl_count_down(&cd1);
  if cd1.remaining != 0 { return 74; }
  var cdn = sync.cdl_new(-3);
  sync.cdl_count_down(&cdn);
  if cdn.remaining != -3 { return 75; }
  if sync.cdl_is_zero(&cdn) { return 76; }

  // ---- terminal: exact ANSI pins
  if terminal.ansi_reset() != "\u{001b}[0m" { return 77; }
  if terminal.ansi_bold() != "\u{001b}[1m" { return 78; }
  if terminal.ansi_dim() != "\u{001b}[2m" { return 79; }
  if terminal.ansi_italic() != "\u{001b}[3m" { return 80; }
  if terminal.ansi_underline() != "\u{001b}[4m" { return 81; }
  if terminal.ansi_blink() != "\u{001b}[5m" { return 82; }
  if terminal.ansi_reverse() != "\u{001b}[7m" { return 83; }
  if terminal.ansi_strike() != "\u{001b}[9m" { return 84; }
  if terminal.ansi_fg_black() != "\u{001b}[30m" { return 85; }
  if terminal.ansi_fg_red() != "\u{001b}[31m" { return 86; }
  if terminal.ansi_fg_green() != "\u{001b}[32m" { return 87; }
  if terminal.ansi_fg_yellow() != "\u{001b}[33m" { return 88; }
  if terminal.ansi_fg_blue() != "\u{001b}[34m" { return 89; }
  if terminal.ansi_fg_magenta() != "\u{001b}[35m" { return 90; }
  if terminal.ansi_fg_cyan() != "\u{001b}[36m" { return 91; }
  if terminal.ansi_fg_white() != "\u{001b}[37m" { return 92; }
  if terminal.ansi_bg_black() != "\u{001b}[40m" { return 93; }
  if terminal.ansi_bg_red() != "\u{001b}[41m" { return 94; }
  if terminal.ansi_bg_green() != "\u{001b}[42m" { return 95; }
  if terminal.ansi_bg_yellow() != "\u{001b}[43m" { return 96; }
  if terminal.ansi_bg_blue() != "\u{001b}[44m" { return 97; }
  if terminal.ansi_bg_magenta() != "\u{001b}[45m" { return 98; }
  if terminal.ansi_bg_cyan() != "\u{001b}[46m" { return 99; }
  if terminal.ansi_bg_white() != "\u{001b}[47m" { return 100; }

  // ---- terminal: progress / spinner
  let p0 = terminal.progress_new(-5);
  if p0.total != 0 { return 101; }
  if p0.done != 0 { return 102; }
  if p0.width != 40 { return 103; }
  let p1 = terminal.progress_new(10);
  if p1.total != 10 { return 104; }
  if terminal.progress_percent(&p0) != 100 { return 105; }
  var p2 = terminal.progress_new(10);
  if terminal.progress_percent(&p2) != 0 { return 106; }
  terminal.progress_finish(&p2);
  if p2.done != 10 { return 107; }
  if terminal.progress_percent(&p2) != 100 { return 108; }
  var sp = terminal.spinner_new();
  if sp.index != 0 { return 109; }
  if sp.frames.len() != 4 { return 110; }
  if terminal.spinner_frame(&sp) != 0 { return 111; }

  return 0;
}
