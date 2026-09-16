// XIOM -- Number Formatting (xiom.format.number)
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Pure human-readable number formatting: thousands separators, fixed-point
// floats, percentages, human bytes, durations, and ordinals. All functions
// are pure and side-effect free.

module xiom.format.number

use xiom.string;
use xiom.convert;

/// Formats an integer with `sep` inserted every three digits from the
/// right. The sign is preserved: fmt_int_with_separators(-987654, ",")
/// -> "-987,654". n == 0 -> "0".
/// Complexity: O(digits).
pub fn fmt_int_with_separators(n: Int, sep: Str) -> Str {
  var s = convert.int_to_string(n);
  var neg = false;
  var body = s;
  if s.len() > 0 && string.byte_at(s, 0) == 45 {
    neg = true;
    body = string.str_slice(s, 1, s.len());
  }
  var result = "";
  var count = 0;
  var i = body.len() - 1;
  while i >= 0 {
    result = string.str_slice(body, i, i + 1) + result;
    count = count + 1;
    if count % 3 == 0 && i > 0 {
      result = sep + result;
    }
    i = i - 1;
  }
  if neg {
    result = "-" + result;
  }
  result
}

/// Formats a float with a fixed number of decimals using integer math.
/// Rounds half away from zero: fmt_float_fixed(3.14159, 2) -> "3.14".
/// Because 2.675 is not exactly representable in binary, its scaled value
/// (267.4999...) rounds to "2.67", not "2.68" -- a documented float-math
/// artifact. Negative values keep their sign.
/// Complexity: O(decimals).
pub fn fmt_float_fixed(x: Float64, decimals: Int) -> Str {
  var dec = decimals;
  if dec < 0 {
    dec = 0;
  }
  if dec > 15 {
    dec = 15;
  }
  var scale = 1;
  var i = 0;
  while i < dec {
    scale = scale * 10;
    i = i + 1;
  }
  var scaled = x * (scale as Float64);
  var rounded: Int;
  if scaled >= 0.0 {
    rounded = to_int(scaled + 0.5);
  } else {
    rounded = to_int(scaled - 0.5);
  }
  var neg = rounded < 0;
  var abs_r = rounded;
  if abs_r < 0 {
    abs_r = -abs_r;
  }
  var int_part = abs_r / scale;
  var frac_part = abs_r % scale;
  var result = "";
  if neg {
    result = "-";
  }
  result = result + convert.int_to_string(int_part);
  if dec > 0 {
    result = result + ".";
    var frac_str = convert.int_to_string(frac_part);
    var pad = dec - string.str_len(frac_str);
    while pad > 0 {
      result = result + "0";
      pad = pad - 1;
    }
    result = result + frac_str;
  }
  result
}

/// Formats a fraction (0..1) as a percentage with `decimals` decimals.
/// fmt_percent(0.125, 1) -> "12.5%". Uses fmt_float_fixed for rounding.
/// Complexity: O(decimals).
pub fn fmt_percent(x: Float64, decimals: Int) -> Str {
  fmt_float_fixed(x * 100.0, decimals) + "%"
}

/// Formats a byte count as human-readable text using binary units.
/// Values below 1024 use plain bytes ("512 B"); larger values use one
/// decimal with KiB/MiB/GiB/TiB ("1.5 KiB"). n == 0 -> "0 B".
/// Complexity: O(units).
pub fn fmt_bytes(n: Int) -> Str {
  if n == 0 {
    return "0 B";
  }
  var value = n;
  if value < 0 {
    value = -value;
  }
  if value < 1024 {
    return convert.int_to_string(value) + " B";
  }
  var units = Vec[Str].new();
  units.push("KiB");
  units.push("MiB");
  units.push("GiB");
  units.push("TiB");
  var t = value * 10;
  var u = -1;
  while t >= 10240 && u < 3 {
    t = (t + 512) / 1024;
    u = u + 1;
  }
  var whole = t / 10;
  var tenth = t % 10;
  var unit_name = "KiB";
  if u >= 0 && u < units.len() {
    unit_name = units[u];
  }
  convert.int_to_string(whole) + "." + convert.int_to_string(tenth) + " " + unit_name
}

/// Formats a millisecond duration as compact time units, omitting zero
/// units while keeping the largest nonzero component. 0 -> "0ms";
/// 65000 -> "1m 5s"; 90061000 -> "1d 1h 1m 1s".
/// Complexity: O(1).
pub fn fmt_duration_ms(ms: Int) -> Str {
  if ms == 0 {
    return "0ms";
  }
  var neg = ms < 0;
  var total = ms;
  if neg {
    total = -total;
  }
  var days = total / 86400000;
  total = total % 86400000;
  var hours = total / 3600000;
  total = total % 3600000;
  var mins = total / 60000;
  total = total % 60000;
  var secs = total / 1000;
  var millis = total % 1000;
  var parts = Vec[Str].new();
  if days > 0 {
    parts.push(convert.int_to_string(days) + "d");
  }
  if hours > 0 {
    parts.push(convert.int_to_string(hours) + "h");
  }
  if mins > 0 {
    parts.push(convert.int_to_string(mins) + "m");
  }
  if secs > 0 {
    parts.push(convert.int_to_string(secs) + "s");
  }
  if millis > 0 {
    parts.push(convert.int_to_string(millis) + "ms");
  }
  if parts.len() == 0 {
    return "0ms";
  }
  var result = "";
  var i = 0;
  while i < parts.len() {
    if i > 0 {
      result = result + " ";
    }
    result = result + parts[i];
    i = i + 1;
  }
  if neg {
    result = "-" + result;
  }
  result
}

/// Formats an integer with its English ordinal suffix:
/// 1st, 2nd, 3rd, 4th, ..., 11th, 12th, 13th, 21st, 22nd, 23rd, 111th.
/// Complexity: O(1).
pub fn fmt_ordinal(n: Int) -> Str {
  var num = n;
  var neg = false;
  if num < 0 {
    neg = true;
    num = -num;
  }
  var last_two = num % 100;
  var last_one = num % 10;
  var suffix = "th";
  if last_two < 11 || last_two > 13 {
    if last_one == 1 {
      suffix = "st";
    } elif last_one == 2 {
      suffix = "nd";
    } elif last_one == 3 {
      suffix = "rd";
    }
  }
  var body = convert.int_to_string(num);
  if neg {
    body = "-" + body;
  }
  body + suffix
}
