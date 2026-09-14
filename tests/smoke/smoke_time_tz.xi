// XIOM stdlib smoke test - xiom.time.tz (tzdata phase 1)
// Checks the OS-provided, DST-aware local offset: minute alignment, sane
// range, offset_at round-trip consistency, the is_dst probe, and a sane
// local wall-clock DateTime. Returns 0 on success, unique code on failure.

module smoke_time_tz
use xiom.time;
use xiom.time.tz;
use xiom.io;

fn main() -> Int {
  var off: Int = 0;
  match tz.tz_local_offset_secs() {
    Ok(o) => { off = o; },
    Err(e) => { io.println("offset err " + e); return 1; },
  }
  if off % 60 != 0 { io.println("offset not minute-aligned: " + off); return 2; }
  if off > 14 * 3600 || off < 0 - 12 * 3600 { io.println("offset out of range: " + off); return 3; }

  match tz.tz_is_dst() { Ok(_) => { }, Err(_) => { return 4; } }

  match tz.tz_local_epoch_secs() {
    Ok(le) => {
      match tz.tz_offset_secs_at(le - off) {
        Ok(o2) => { if o2 != off { io.println("offset_at " + o2 + " vs " + off); return 5; } },
        Err(_) => { return 6; },
      }
    },
    Err(_) => { return 7; },
  }

  match tz.tz_local_now() {
    Ok(dt) => {
      if dt.year() < 2020 || dt.year() > 2200 { io.println("year " + dt.year()); return 8; }
      if dt.month() < 1 || dt.month() > 12 { return 9; }
      if dt.day() < 1 || dt.day() > 31 { return 10; }
      if dt.hour() < 0 || dt.hour() > 23 { return 11; }
      if dt.minute() < 0 || dt.minute() > 59 { return 12; }
      if dt.second() < 0 || dt.second() > 60 { return 13; }
    },
    Err(e) => { io.println("local_now err " + e); return 14; },
  }

  io.println("OK");
  return 0;
}
