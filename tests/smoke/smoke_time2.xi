module smoke_time2
use xiom.io;
use xiom.time;

// strftime / strptime (G13 batch). Kept separate from smoke_str2 (string +
// text.similarity): combining string + text.similarity + time in one
// program crashes at startup — COMPILER_BUGS.md BUG 18.

fn main() -> Int {
  var d = xiom.time.date_new(2026, 8, 11);
  if xiom.time.strftime("%Y-%m-%d", &d) != "2026-08-11" { return 1; }
  if xiom.time.strftime("%Y/%m/%d %H:%M:%S", &d) != "2026/08/11 00:00:00" { return 2; }
  if xiom.time.strftime("%y-%j", &d) != "26-223" { return 3; }  // Aug 11 = day 223
  if xiom.time.strftime("%w", &d) != "2" { return 4; }  // 2026-08-11 is Tuesday
  if xiom.time.strftime("%u", &d) != "2" { return 5; }
  if xiom.time.strftime("100%%", &d) != "100%" { return 6; }
  var d2 = xiom.time.date_new(2020, 2, 29);
  if xiom.time.strftime("%Y-%m-%d", &d2) != "2020-02-29" { return 7; }  // leap
  var p = xiom.time.strptime("2026-08-11", "%Y-%m-%d");
  if !p.is_ok { return 8; }
  if p.date.year != 2026 || p.date.month != 8 || p.date.day != 11 { return 9; }
  var p2 = xiom.time.strptime("2026/08/11 10:30:00", "%Y/%m/%d %H:%M:%S");
  if !p2.is_ok { return 10; }
  if p2.date.year != 2026 || p2.date.month != 8 || p2.date.day != 11 { return 11; }
  var p3 = xiom.time.strptime("2026-13-01", "%Y-%m-%d");
  if p3.is_ok { return 12; }  // month 13 invalid
  var p4 = xiom.time.strptime("2021-02-29", "%Y-%m-%d");
  if p4.is_ok { return 13; }  // 2021 not a leap year
  var p5 = xiom.time.strptime("2026-08-11", "%Y-%m");
  if p5.is_ok { return 14; }  // missing %d
  var p7 = xiom.time.strptime("x2026-08-11", "%Y-%m-%d");
  if p7.is_ok { return 16; }  // literal mismatch
  var p8 = xiom.time.strptime(xiom.time.strftime("%Y-%m-%d", &d), "%Y-%m-%d");
  if !p8.is_ok { return 17; }
  if p8.date.year != 2026 || p8.date.month != 8 || p8.date.day != 11 { return 18; }

  io.println("smoke_time2: all 17 checks passed");
  return 0;
}

