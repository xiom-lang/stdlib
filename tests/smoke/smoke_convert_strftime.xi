// XIOM stdlib smoke — xiom.convert.{strftime,strptime}
// Returns 0 on success, nonzero on failure (process exit code).
module smoke_convert_strftime
use xiom.io;
use xiom.convert.date;
use xiom.convert.strftime;
use xiom.convert.strptime;

fn main() -> Int {
  var d = date.date_new(2026, 8, 12);

  var ymd = strftime.strftime("%Y-%m-%d", &d);
  if ymd != "2026-08-12" {
    io.println("smoke_convert_strftime: strftime %Y-%m-%d failed");
    return 1;
  }
  var dmy = strftime.strftime("%d/%m/%Y", &d);
  if dmy != "12/08/2026" {
    io.println("smoke_convert_strftime: strftime %d/%m/%Y failed");
    return 2;
  }
  var yy = strftime.strftime("%y-%m-%d", &d);
  if yy != "26-08-12" {
    io.println("smoke_convert_strftime: strftime %y failed");
    return 3;
  }
  var j = strftime.strftime("%j", &d);
  if j != "224" {
    io.println("smoke_convert_strftime: strftime %j failed");
    return 4;
  }
  var pct = strftime.strftime("100%%", &d);
  if pct != "100%" {
    io.println("smoke_convert_strftime: strftime %% failed");
    return 5;
  }
  var now = strftime.strftime_now("%Y");
  var y_only = strftime.strftime("%Y", &d);
  if y_only == "" {
    io.println("smoke_convert_strftime: strftime_now failed");
    return 6;
  }
  if y_only.len() != 4 {
    io.println("smoke_convert_strftime: strftime year len failed");
    return 7;
  }

  var p = strptime.strptime("2026-08-12", "%Y-%m-%d");
  if !p.is_ok {
    io.println("smoke_convert_strftime: strptime ok failed");
    return 8;
  }
  if p.date.day != 12 {
    io.println("smoke_convert_strftime: strptime day failed");
    return 9;
  }
  var iso = strptime.strptime_iso8601("2026-08-12");
  if !iso.is_ok {
    io.println("smoke_convert_strftime: strptime_iso8601 failed");
    return 10;
  }
  var round_str = strftime.strftime("%Y-%m-%d", &d);
  var round = strptime.strptime(round_str, "%Y-%m-%d");
  if !round.is_ok {
    io.println("smoke_convert_strftime: round-trip failed");
    return 11;
  }
  var bad_month = strptime.strptime("2026-13-01", "%Y-%m-%d");
  if bad_month.is_ok {
    io.println("smoke_convert_strftime: invalid month accepted");
    return 12;
  }
  var short = strptime.strptime("2026-08", "%Y-%m-%d");
  if short.is_ok {
    io.println("smoke_convert_strftime: short input accepted");
    return 13;
  }
  var mismatch = strptime.strptime("2026/08/12", "%Y-%m-%d");
  if mismatch.is_ok {
    io.println("smoke_convert_strftime: mismatch accepted");
    return 14;
  }

  io.println("OK");
  return 0;
}
