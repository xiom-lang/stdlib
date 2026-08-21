// XIOM stdlib smoke -- xiom.convert.{date,datetime,duration,time,timestamp}
// Returns 0 on success, nonzero on failure (process exit code).
module smoke_convert_time
use xiom.io;
use xiom.convert.date;
use xiom.convert.datetime;
use xiom.convert.duration;
use xiom.convert.time;
use xiom.convert.timestamp;

fn main() -> Int {
  var d = date.date_new(2026, 8, 12);
  var iso = date.date_iso8601(&d);
  if iso != "2026-08-12" {
    io.println("smoke_convert_time: date_iso8601 failed");
    return 1;
  }
  var parsed = date.date_from_iso8601("2026-08-12");
  if !parsed.is_some {
    io.println("smoke_convert_time: date_from_iso8601 failed");
    return 2;
  }
  match parsed {
    Some(pv) => {
      var iso2 = date.date_iso8601(&pv);
      if iso2 != "2026-08-12" {
        io.println("smoke_convert_time: date round-trip failed");
        return 3;
      }
    },
    None => {
      io.println("smoke_convert_time: date none failed");
      return 3;
    },
  }
  var wd = date.date_weekday(&d);
  if wd < 0 || wd > 6 {
    io.println("smoke_convert_time: date_weekday failed");
    return 4;
  }
  var doy = date.date_day_of_year(&d);
  if doy != 224 {
    io.println("smoke_convert_time: date_day_of_year failed");
    return 5;
  }

  var dt = datetime.datetime_new(2026, 8, 12, 14, 30, 45);
  var dtiso = datetime.datetime_iso8601(&dt);
  if dtiso != "2026-08-12T14:30:45" {
    io.println("smoke_convert_time: datetime_iso8601 failed");
    return 6;
  }
  var dtparsed = datetime.datetime_from_iso8601("2026-08-12T14:30:45");
  if !dtparsed.is_some {
    io.println("smoke_convert_time: datetime_from_iso8601 failed");
    return 7;
  }
  match dtparsed {
    Some(dv) => {
      if dv.hour != 14 || dv.minute != 30 {
        io.println("smoke_convert_time: datetime fields failed");
        return 8;
      }
    },
    None => {
      io.println("smoke_convert_time: datetime none failed");
      return 8;
    },
  }

  var dsec = duration.duration_seconds(5);
  if duration.duration_as_secs(dsec) != 5 {
    io.println("smoke_convert_time: duration_seconds failed");
    return 9;
  }
  var dms = duration.duration_millis(1500);
  if duration.duration_as_ms(dms) != 1500 {
    io.println("smoke_convert_time: duration_millis failed");
    return 10;
  }
  if duration.duration_as_secs(dms) != 1 {
    io.println("smoke_convert_time: duration_as_secs failed");
    return 11;
  }
  var dmicro = duration.duration_micros(1500000);
  if duration.duration_as_secs(dmicro) != 1 {
    io.println("smoke_convert_time: duration_micros failed");
    return 12;
  }
  var dnano = duration.duration_nanos(2000000000);
  if duration.duration_as_secs(dnano) != 2 {
    io.println("smoke_convert_time: duration_nanos failed");
    return 13;
  }

  var tod = time.time_now();
  if tod < 0 || tod > 86399 {
    io.println("smoke_convert_time: time_now failed");
    return 14;
  }
  var ts = time.timestamp_now();
  if ts <= 0 {
    io.println("smoke_convert_time: timestamp_now failed");
    return 15;
  }
  var epoch = time.timestamp_to_date(0);
  if epoch.year != 1970 {
    io.println("smoke_convert_time: timestamp_to_date failed");
    return 16;
  }
  var back_ts = time.date_to_timestamp(&d);
  var back_date = time.timestamp_to_date(back_ts);
  if date.date_iso8601(&back_date) != "2026-08-12" {
    io.println("smoke_convert_time: date_to_timestamp failed");
    return 17;
  }

  var ts_now = timestamp.timestamp_now();
  if ts_now <= 0 {
    io.println("smoke_convert_time: timestamp.timestamp_now failed");
    return 18;
  }
  var tsd = timestamp.timestamp_to_datetime(0);
  if tsd.year != 1970 || tsd.hour != 0 {
    io.println("smoke_convert_time: timestamp_to_datetime failed");
    return 19;
  }
  var t0 = timestamp.timestamp_from_datetime(&tsd);
  if t0 != 0 {
    io.println("smoke_convert_time: timestamp_from_datetime failed");
    return 20;
  }
  var fd = timestamp.timestamp_from_date(&d);
  var fdd = timestamp.timestamp_to_date(fd);
  if date.date_iso8601(&fdd) != "2026-08-12" {
    io.println("smoke_convert_time: timestamp_from_date failed");
    return 21;
  }

  io.println("OK");
  return 0;
}
