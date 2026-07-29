module smoke_time_date_time_fields
use xiom.time;

fn main() -> Int {
  var dt = time.DateTime.now();

  if dt.year() <= 0 { return 1; }
  if dt.month() < 1 || dt.month() > 12 { return 2; }
  if dt.day() < 1 || dt.day() > 31 { return 3; }
  if dt.hour() < 0 || dt.hour() > 23 { return 4; }
  if dt.minute() < 0 || dt.minute() > 59 { return 5; }
  if dt.second() < 0 || dt.second() > 59 { return 6; }
  if dt.weekday() < 0 || dt.weekday() > 6 { return 7; }

  return 0;
}
