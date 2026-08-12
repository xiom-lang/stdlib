// XIOM stdlib smoke test - xiom.format.relative
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_format_relative
use xiom.format.relative;
use xiom.io;
use xiom.string;

fn main() -> Int {
  var past = format_relative_time(-65);
  if !string.str_contains(past, "minute") {
    io.println("relative: past phrase wrong");
    return 1;
  }
  if !string.str_contains(past, "ago") {
    io.println("relative: past missing ago");
    return 2;
  }
  var future = format_relative_time(7200);
  if !string.str_contains(future, "in 2 hours") {
    io.println("relative: future phrase wrong: " + future);
    return 3;
  }
  var short = format_relative_time_short(65);
  if short != "1m" {
    io.println("relative: short form wrong: " + short);
    return 4;
  }
  if format_relative_time_short(5) != "now" {
    io.println("relative: now wrong");
    return 5;
  }
  var elapsed = format_elapsed(0, 65);
  if !string.str_contains(elapsed, "minute") {
    io.println("relative: elapsed wrong");
    return 6;
  }
  var ms = format_elapsed_ms(1500);
  if !string.str_contains(ms, "s") {
    io.println("relative: elapsed_ms wrong");
    return 7;
  }
  var ago = format_ago(100, 200);
  if !string.str_contains(ago, "ago") {
    io.println("relative: ago wrong");
    return 8;
  }
  var until = format_until(300, 200);
  if !string.str_contains(until, "in") {
    io.println("relative: until wrong");
    return 9;
  }
  var age = format_age(5);
  if !string.str_contains(age, "day") {
    io.println("relative: age wrong");
    return 10;
  }
  var parts = relative_parts(3661);
  if parts.len() != 3 {
    io.println("relative: parts count wrong");
    return 11;
  }
  var secs = format_seconds(3661);
  if !string.str_contains(secs, "1h") {
    io.println("relative: seconds format wrong: " + secs);
    return 12;
  }

  io.println("OK");
  return 0;
}
