// XIOM stdlib smoke test - xiom.format.units
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_format_units
use xiom.format.units;
use xiom.io;
use xiom.string;

fn main() -> Int {
  var bytes = format_bytes(1536);
  if !string.str_contains(bytes, "KB") {
    io.println("units: bytes missing KB: " + bytes);
    return 1;
  }
  var bbin = format_bytes_binary(1536);
  if !string.str_contains(bbin, "KiB") {
    io.println("units: binary bytes missing KiB");
    return 2;
  }
  var bits = format_bits(2500);
  if !string.str_contains(bits, "Kb") {
    io.println("units: bits missing Kb");
    return 3;
  }
  var pct = format_percent(0.5, 1);
  if pct != "50.0%" {
    io.println("units: percent wrong: " + pct);
    return 4;
  }
  var ratio = format_ratio(3, 4);
  if ratio != "3/4" {
    io.println("units: ratio wrong");
    return 5;
  }
  if format_ratio(3, 0) != "inf" {
    io.println("units: ratio zero denominator wrong");
    return 6;
  }
  var sci = format_scientific(12345.0, 2);
  if !string.str_contains(sci, "e+04") {
    io.println("units: scientific wrong: " + sci);
    return 7;
  }
  var eng = format_engineering(12345.0);
  if !string.str_contains(eng, "e+03") {
    io.println("units: engineering wrong: " + eng);
    return 8;
  }
  var km = format_si(2500.0, "m");
  if km != "2.5 km" {
    io.println("units: km conversion wrong: " + km);
    return 9;
  }
  var binp = format_binary_prefix(4096.0, "B");
  if !string.str_contains(binp, "KiB") {
    io.println("units: binary prefix wrong: " + binp);
    return 10;
  }
  var cel = format_temperature_celsius(21.5);
  if !string.str_contains(cel, "C") {
    io.println("units: celsius wrong");
    return 11;
  }
  var cur = format_currency(123456, "USD");
  if cur != "$1,234.56" {
    io.println("units: currency wrong: " + cur);
    return 12;
  }
  var secs = format_seconds(3661);
  if secs != "1h 1m 1s" {
    io.println("units: seconds wrong: " + secs);
    return 13;
  }
  var hz = format_hertz(2500000.0);
  if !string.str_contains(hz, "MHz") {
    io.println("units: hertz wrong");
    return 14;
  }
  var ps = format_percent_sign(0.75);
  if ps != "75%" {
    io.println("units: percent sign wrong: " + ps);
    return 15;
  }

  io.println("OK");
  return 0;
}
