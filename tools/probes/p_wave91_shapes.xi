// p_wave91_shapes.xi -- wave 91 shape validation: bench + numbering + units
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-91 clause guards: the bench structural claims
// (run_bench/run_bench_n fields, zero-iteration branch, analytics zero
// pins, human-ns unit pins, report lengths), the numbering word/ordinal/
// CJK/Indian/money exact pins and the units formatter pins (bytes/bits,
// percent, ratio, scientific/engineering, SI/binary prefixes, temperature,
// currency, durations, hertz). Values returned from the module surface are
// bound before comparing. Returns 0 when every case holds.

module p_wave91_shapes

use xiom.bench as bench;
use xiom.format.numbering as num;
use xiom.format.units as units;

fn zresult() -> BenchResult {
  return BenchResult{ name: "z"; iterations: 0; total_ns: 0; mean_ns: 0; min_ns: 0; max_ns: 0; stddev_ns: 0; };
}

fn main() -> Int {
  // ---- bench: timing harness structure
  let r1 = bench.run_bench("t", fn() { });
  if r1.iterations != 1 { return 1; }
  if r1.name != "t" { return 2; }
  if r1.total_ns != r1.mean_ns { return 3; }
  if r1.stddev_ns != 0 { return 4; }
  let r0 = bench.run_bench_n("n", 0, fn() { });
  if r0.iterations != 0 { return 5; }
  if r0.total_ns != 0 || r0.mean_ns != 0 || r0.min_ns != 0 { return 6; }
  if r0.max_ns != 0 || r0.stddev_ns != 0 { return 7; }
  let r2 = bench.run_bench_n("m", 2, fn() { });
  if r2.iterations != 2 { return 8; }
  if r2.name != "m" { return 9; }
  let c1 = bench.compare(r1, r2);
  if c1.len() < 1 { return 10; }
  let r3 = bench.bench_run_avg("a", 2, fn() { });
  if r3.iterations != 2 { return 11; }
  if bench.bench_black_box_int(7) != 7 { return 12; }
  let tfn = bench.bench_time_fn(fn() { });
  if tfn < 0 { return 13; }

  // ---- bench: analytics on synthetic results
  let zr = BenchResult{ name: "z"; iterations: 0; total_ns: 0; mean_ns: 0; min_ns: 0; max_ns: 0; stddev_ns: 0; };
  if bench.bench_ops_per_sec_ns(&zr) != 0 { return 14; }
  if bench.bench_faster_percent(&zr, &zr) != 0 { return 15; }
  let e1 = Vec[BenchResult].new();
  if bench.bench_min_ns(e1) != 0 { return 16; }
  let e2 = Vec[BenchResult].new();
  if bench.bench_max_ns(e2) != 0 { return 17; }
  let e3 = Vec[BenchResult].new();
  if bench.bench_total_ns(e3) != 0 { return 18; }
  let e4 = Vec[BenchResult].new();
  if bench.bench_median_ns(e4) != 0 { return 19; }
  var m1 = Vec[BenchResult].new();
  m1.push(zresult());
  if bench.bench_min_ns(m1) != 0 { return 20; }
  var m2 = Vec[BenchResult].new();
  m2.push(zresult());
  if bench.bench_max_ns(m2) != 0 { return 21; }
  var m3 = Vec[BenchResult].new();
  m3.push(zresult());
  if bench.bench_total_ns(m3) != 0 { return 22; }
  var m4 = Vec[BenchResult].new();
  m4.push(zresult());
  if bench.bench_median_ns(m4) != 0 { return 23; }
  let h1 = bench.bench_human_ns(1500000000);
  if h1 != "1.5s" { return 24; }
  let h2 = bench.bench_human_ns(1500000);
  if h2 != "1.5ms" { return 25; }
  let h3 = bench.bench_human_ns(1500);
  if h3 != "1.5us" { return 26; }
  let h4 = bench.bench_human_ns(999);
  if h4 != "999ns" { return 27; }
  let e5 = Vec[BenchResult].new();
  let rep0 = bench.bench_report(e5);
  if rep0.len() != 124 { return 28; }
  let e6 = Vec[BenchResult].new();
  let reps0 = bench.bench_report_simple(e6);
  if reps0 != "" { return 29; }
  var s1 = Vec[BenchResult].new();
  s1.push(zresult());
  let reps1 = bench.bench_report_simple(s1);
  if reps1.len() < 1 { return 30; }

  // ---- numbering
  let nw0 = num.number_to_words(0);
  if nw0 != "zero" { return 31; }
  let nw21 = num.number_to_words(21);
  if nw21 != "twenty-one" { return 32; }
  let nwneg = num.number_to_words(0 - 5);
  if nwneg != "minus five" { return 33; }
  let nwm = num.number_to_words(1000000);
  if nwm != "one million" { return 34; }
  let uk21 = num.number_to_words_uk(21);
  if uk21 != "twenty-one" { return 35; }
  let ukb = num.number_to_words_uk(1000000000);
  if ukb != "one milliard" { return 36; }
  let ord0 = num.number_to_ordinal_words(0);
  if ord0 != "zeroth" { return 37; }
  let ord1 = num.number_to_ordinal_words(1);
  if ord1 != "first" { return 38; }
  let ord2 = num.number_to_ordinal_words(2);
  if ord2 != "second" { return 39; }
  let ord21 = num.number_to_ordinal_words(21);
  if ord21 != "twenty-first" { return 40; }
  let cn0 = num.number_to_chinese(0);
  if cn0 != "\u{96f6}" { return 41; }
  let cn15 = num.number_to_chinese(15);
  if cn15 != "\u{5341}\u{4e94}" { return 42; }
  let cnneg = num.number_to_chinese(0 - 1);
  if cnneg != "\u{8d1f}\u{4e00}" { return 43; }
  let cs15 = num.number_to_chinese_simplified(15);
  if cs15 != "\u{5341}\u{4e94}" { return 44; }
  let ct10k = num.number_to_chinese_traditional(10000);
  if ct10k != "\u{4e00}\u{842c}" { return 45; }
  let jp0 = num.number_to_japanese(0);
  if jp0 != "\u{3007}" { return 46; }
  let kr0 = num.number_to_korean(0);
  if kr0 != "\u{c601}" { return 47; }
  let kr15 = num.number_to_korean(15);
  if kr15 != "\u{c2ed}\u{c624}" { return 48; }
  let iw21 = num.number_to_indian_words(21);
  if iw21 != "twenty-one" { return 49; }
  let ig = num.number_to_indian_grouping(1234567);
  if ig != "12,34,567" { return 50; }
  let ig0 = num.number_to_indian_grouping(0);
  if ig0 != "0" { return 51; }
  let ign = num.number_to_indian_grouping(0 - 1234567);
  if ign != "-12,34,567" { return 52; }
  let mw = num.money_to_words(12345, "USD");
  if mw != "one hundred twenty-three dollars and forty-five cents" { return 53; }
  let mj = num.money_to_words(0, "JPY");
  if mj != "zero yen" { return 54; }
  let mud = num.money_to_words(0, "USD");
  if mud != "zero dollars and zero cents" { return 55; }

  // ---- units
  let b0 = units.format_bytes(0);
  if b0 != "0 B" { return 56; }
  let b1 = units.format_bytes(1500);
  if b1 != "1.5 KB" { return 57; }
  let b2 = units.format_bytes(0 - 1000);
  if b2 != "1.0 KB" { return 58; }
  let bb = units.format_bytes_binary(1024);
  if bb != "1.0 KiB" { return 59; }
  let bit = units.format_bits(1500);
  if bit != "1.5 Kb" { return 60; }
  let p1 = units.format_percent(0.5, 1);
  if p1 != "50.0%" { return 61; }
  let p2 = units.format_percent(0.5, 0 - 3);
  if p2 != "50%" { return 62; }
  let ps = units.format_percent_sign(0.25);
  if ps != "25%" { return 63; }
  let ri = units.format_ratio(1, 0);
  if ri != "inf" { return 64; }
  let rn = units.format_ratio(0, 0);
  if rn != "NaN" { return 65; }
  let rneg = units.format_ratio(0 - 1, 0);
  if rneg != "-inf" { return 66; }
  let rr = units.format_ratio(3, 4);
  if rr != "3/4" { return 67; }
  let sc = units.format_scientific(1.5, 1);
  if sc != "1.5e+00" { return 68; }
  let sc0 = units.format_scientific(0.0, 2);
  if sc0 != "0.00" { return 69; }
  let en0 = units.format_engineering(0.0);
  if en0 != "0.00e+00" { return 70; }
  let en1 = units.format_engineering(1500.0);
  if en1 != "1.50e+03" { return 71; }
  let en2 = units.format_engineering(0.0 - 1500.0);
  if en2 != "-1.50e+03" { return 72; }
  let si1 = units.format_si(1500.0, "Hz");
  if si1 != "1.5 kHz" { return 73; }
  let si2 = units.format_si(0.5, "s");
  if si2 != "500.0 ms" { return 74; }
  let bp = units.format_binary_prefix(2048.0, "B");
  if bp != "2.0 KiB" { return 75; }
  let tc = units.format_temperature_celsius(21.5);
  if tc != "21.5\u{00b0}C" { return 76; }
  let tf = units.format_temperature_fahrenheit(72.0);
  if tf != "72.0\u{00b0}F" { return 77; }
  let cu = units.format_currency(123456, "USD");
  if cu != "$1,234.56" { return 78; }
  let cun = units.format_currency(0 - 123456, "USD");
  if cun != "-$1,234.56" { return 79; }
  let cj = units.format_currency(100, "JPY");
  if cj != "\u{00a5}1" { return 80; }
  let s0 = units.format_seconds(0);
  if s0 != "0s" { return 81; }
  let s1u = units.format_seconds(3661);
  if s1u != "1h 1m 1s" { return 82; }
  let sn = units.format_seconds(0 - 61);
  if sn != "1m 1s" { return 83; }
  let ms0 = units.format_ms(500);
  if ms0 != "500ms" { return 84; }
  let ms1 = units.format_ms(1500);
  if ms1 != "1s 500ms" { return 85; }
  let ms2 = units.format_ms(1000);
  if ms2 != "1s" { return 86; }
  let hz0 = units.format_hertz(999.0);
  if hz0 != "999.0 Hz" { return 87; }
  let hz1 = units.format_hertz(1500.0);
  if hz1 != "1.5 kHz" { return 88; }
  let hz2 = units.format_hertz(1500000000.0);
  if hz2 != "1.5 GHz" { return 89; }

  return 0;
}
