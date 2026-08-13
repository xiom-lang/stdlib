// XIOM stdlib smoke - xiom.time.duration / instant / date / chrono / calendar / iso8601
// Returns 0 on success with "OK" printed; nonzero + tag on failure.

module smoke_time
use xiom.time.duration;
use xiom.time.instant;
use xiom.time.date;
use xiom.time.chrono;
use xiom.time.calendar;
use xiom.time.iso8601;
use xiom.io;

fn main() -> Int {
  // duration: construct/convert/add/sub/mul/div/compare
  var d5 = duration.duration_secs(5);
  if duration.duration_as_secs(d5) != 5 { io.println("dur:secs"); return 1; }
  var dms = duration.duration_millis(1500);
  if duration.duration_as_millis(dms) != 1500 { io.println("dur:millis"); return 2; }
  var dus = duration.duration_micros(2000000);
  if duration.duration_as_secs(dus) != 2 { io.println("dur:micros"); return 3; }
  var dns = duration.duration_nanos(3000000000);
  if duration.duration_as_secs(dns) != 3 { io.println("dur:nanos"); return 4; }
  var sum = duration.duration_add(d5, dms);
  if duration.duration_as_millis(sum) != 6500 { io.println("dur:add"); return 5; }
  var diff = duration.duration_sub(dms, d5);
  if duration.duration_as_secs(diff) != -4 { io.println("dur:sub"); return 6; }
  var mul = duration.duration_mul(d5, 3);
  if duration.duration_as_secs(mul) != 15 { io.println("dur:mul"); return 7; }
  var dv = duration.duration_div(d5, 2);
  if duration.duration_as_secs(dv) != 2 { io.println("dur:div"); return 8; }
  if duration.duration_compare(d5, dms) <= 0 { io.println("dur:compare"); return 9; }
  if !duration.duration_is_zero(duration.duration_secs(0)) { io.println("dur:zero"); return 10; }
  var df = duration.duration_from_secs_f64(2.5);
  if duration.duration_as_millis(df) != 2500 { io.println("dur:f64"); return 11; }

  // date: fields, leap, days in month, add/sub/diff, weekday
  var dv = date.date_new(2026, 8, 13);
  if date.date_weekday(&dv) != 4 { io.println("date:weekday"); return 12; }
  if date.date_day_of_month(&dv) != 13 { io.println("date:dom"); return 13; }
  if date.date_days_in_month(2026, 2) != 28 { io.println("date:feb"); return 14; }
  if date.date_days_in_month(2024, 2) != 29 { io.println("date:feb_leap"); return 15; }
  if !date.date_is_leap(2024) { io.println("date:leap"); return 16; }
  if date.date_is_leap(2025) { io.println("date:leap2"); return 17; }
  var d20 = date.date_add_days(&dv, 20);
  if date.date_day_of_month(&d20) != 2 { io.println("date:add"); return 18; }
  if d20.month != 9 { io.println("date:add2"); return 19; }
  var d13 = date.date_sub_days(&dv, 13);
  if date.date_day_of_month(&d13) != 31 { io.println("date:sub"); return 20; }
  var djan = date.date_new(2026, 1, 1);
  if date.date_diff_days(&dv, &djan) != 224 { io.println("date:diff"); return 21; }
  if date.date_compare(&dv, &djan) <= 0 { io.println("date:compare"); return 22; }
  if date.date_day_of_year(&djan) != 1 { io.println("date:doy"); return 23; }
  var ts = date.date_to_timestamp(&dv);
  var back = date.date_from_timestamp(ts);
  if date.date_compare(&back, &dv) != 0 { io.println("date:roundtrip"); return 24; }

  // chrono: from/to timestamp, add, weekday, diff, compare
  var e0 = chrono.chrono_from_timestamp(0);
  if chrono.chrono_to_timestamp(&e0) != 0 { io.println("chrono:to_ts"); return 25; }
  if chrono.chrono_weekday(&e0) != 4 { io.println("chrono:weekday"); return 26; }
  var e1 = chrono.chrono_add_seconds(&e0, 3600);
  if chrono.chrono_to_timestamp(&e1) != 3600 { io.println("chrono:add_sec"); return 27; }
  var e2 = chrono.chrono_add_days(&e0, 1);
  if chrono.chrono_to_timestamp(&e2) != 86400 { io.println("chrono:add_day"); return 28; }
  var em = chrono.chrono_add_months(&e0, 1);
  if chrono.chrono_weekday(&em) != 0 { io.println("chrono:add_month"); return 29; }
  var ey = chrono.chrono_add_years(&e0, 1);
  if chrono.chrono_to_timestamp(&ey) != 31536000 { io.println("chrono:add_year"); return 30; }
  if chrono.chrono_compare(&e2, &e0) <= 0 { io.println("chrono:compare"); return 31; }
  if chrono.chrono_timezone_offset(&e0) != 0 { io.println("chrono:offset"); return 32; }
  var cd = chrono.chrono_diff(&e2, &e0);
  if duration.duration_as_secs(cd) != 86400 { io.println("chrono:diff"); return 33; }

  // instant: ordering, add/sub, millis
  var i0 = instant.instant_from_millis(1000);
  var i1 = instant.instant_add(i0, duration.duration_secs(1));
  if instant.instant_compare(i1, i0) <= 0 { io.println("inst:add"); return 34; }
  var i2 = instant.instant_sub(i0, duration.duration_secs(1));
  if instant.instant_compare(i2, i0) >= 0 { io.println("inst:sub"); return 35; }
  if instant.instant_to_millis(i0) != 1000 { io.println("inst:millis"); return 36; }
  var now = instant.instant_now();
  var el = instant.instant_elapsed(now);
  if duration.duration_compare(el, duration.duration_secs(0)) < 0 { io.println("inst:elapsed"); return 37; }

  // calendar: names, month lengths, weekday, weeks, easter, julian, grid
  if calendar.calendar_month_name(1) != "January" { io.println("cal:month1"); return 38; }
  if calendar.calendar_month_name(8) != "August" { io.println("cal:month8"); return 39; }
  if calendar.calendar_month_name_short(12) != "Dec" { io.println("cal:month_short"); return 40; }
  if calendar.calendar_weekday_name(0) != "Sunday" { io.println("cal:wd0"); return 41; }
  if calendar.calendar_weekday_name_short(4) != "Thu" { io.println("cal:wd_short"); return 42; }
  if calendar.calendar_days_in_month(2024, 2) != 29 { io.println("cal:days"); return 43; }
  if calendar.calendar_first_weekday(2026, 8) != 6 { io.println("cal:first_wd"); return 44; }
  var wk = calendar.calendar_weeks_in_year(2026);
  if wk != 53 && wk != 52 { io.println("cal:weeks"); return 45; }
  var easter = calendar.calendar_easter(2026);
  if calendar.calendar_month_name(easter.month) != "April" { io.println("cal:easter"); return 46; }
  if calendar.calendar_julian_day(1970, 1, 1) != 2440588 { io.println("cal:jd"); return 47; }
  var jd_date = calendar.calendar_from_julian_day(2440588);
  if jd_date.year != 1970 { io.println("cal:jd_back"); return 48; }
  var grid = calendar.calendar_month_grid(2026, 8);
  if grid.len() != 42 { io.println("cal:grid_len"); return 49; }
  if grid[6] != 1 { io.println("cal:grid_off"); return 50; }
  if calendar.calendar_is_weekend(&dv) { io.println("cal:weekend"); return 51; }
  var sat = date.date_new(2026, 8, 15);
  if !calendar.calendar_is_weekend(&sat) { io.println("cal:weekend2"); return 52; }
  var safe = calendar.calendar_add_months_overflow_safe(&dv, 6);
  if safe.month != 2 { io.println("cal:add_months"); return 53; }

  // iso8601: format + parse known answer "2026-08-13"
  var iso = iso8601.date_iso8601(&dv);
  if iso != "2026-08-13" { io.println("iso:format"); return 54; }
  var parsed = iso8601.iso8601_parse("2026-08-13");
  match parsed {
    Some(p) => {
      if p.year != 2026 { io.println("iso:year"); return 55; }
      if p.month != 8 { io.println("iso:month"); return 56; }
      if p.day != 13 { io.println("iso:day"); return 57; }
      if p.weekday != 4 { io.println("iso:weekday"); return 58; }
    }
    None => { io.println("iso:parse_none"); return 59; }
  }
  var bad = iso8601.iso8601_parse("2026-13-45");
  match bad {
    Some(_) => { io.println("iso:bad"); return 60; }
    None => {}
  }
  var dp = iso8601.iso8601_date_parse("2026-08-13");
  match dp {
    Some(v) => { if v.day != 13 { io.println("iso:date_parse"); return 61; } }
    None => { io.println("iso:date_parse_none"); return 62; }
  }
  var dtiso = iso8601.datetime_iso8601(&e1);
  if dtiso != "1970-01-01T01:00:00" { io.println("iso:datetime"); return 63; }
  var rf = iso8601.rfc3339_format(&e1);
  if rf != "1970-01-01T01:00:00Z" { io.println("iso:rfc"); return 64; }
  var rfp = iso8601.rfc3339_parse("1970-01-01T01:00:00Z");
  match rfp {
    Some(v) => { if v.hour != 1 { io.println("iso:rfc_parse"); return 65; } }
    None => { io.println("iso:rfc_none"); return 66; }
  }
  var wd = iso8601.iso8601_week_date(&djan);
  if wd.2 != 4 { io.println("iso:week"); return 67; }
  var od = iso8601.iso8601_ordinal_date(&djan);
  if od.1 != 1 { io.println("iso:ordinal"); return 68; }
  var tiso = iso8601.timestamp_iso8601(0);
  if tiso != "1970-01-01T00:00:00" { io.println("iso:timestamp"); return 69; }

  io.println("OK");
  return 0;
}
