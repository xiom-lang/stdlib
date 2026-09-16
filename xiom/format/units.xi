// XIOM - Format: Units
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.format.units

// Depends on: xiom.string

use xiom.string;
use xiom.convert;

// ============================================================================
// Human-readable formatting of bytes, bits, percentages, ratios, SI and
// binary prefixes, temperature, currency, duration and frequency.
//
// Byte/binary sizing steps at 1000/1024; SI prefixes k/M/G/T (positive) and
// m/u/n (negative); percentages format a fraction in [0,1]; currency uses the
// ISO code symbol with comma grouping and two decimals (JPY zero decimals).
// All outputs are plain strings; floats are formatted via the exact
// scaled-integer formatter (round-half-away-from-zero).
// ============================================================================

const KIB: Float64 = 1024.0;

/// Format a byte count with a decimal unit suffix (B, KB, MB, GB, TB).
pub fn format_bytes(bytes: Int) -> Str {
  return _size_str(bytes, 1000.0, "B", "K", "M", "G", "T");
}

/// Format a byte count with a binary unit suffix (B, KiB, MiB, GiB, TiB).
pub fn format_bytes_binary(bytes: Int) -> Str {
  return _size_str(bytes, KIB, "B", "Ki", "Mi", "Gi", "Ti");
}

/// Format a bit count with a decimal unit suffix (b, Kb, Mb, Gb, Tb).
pub fn format_bits(bits: Int) -> Str {
  return _size_str(bits, 1000.0, "b", "K", "M", "G", "T");
}

fn _size_str(value: Int, step: Float64, unit: Str, k: Str, m: Str, g: Str, t: Str) -> Str {
  var v = value as Float64;
  if v < 0.0 {
    v = 0.0 - v;
  };
  if v < step {
    return convert.float_to_fixed_str(v, 0) + " " + unit;
  };
  if v < step * step {
    return convert.float_to_fixed_str(v / step, 1) + " " + k + unit;
  };
  if v < step * step * step {
    return convert.float_to_fixed_str(v / (step * step), 1) + " " + m + unit;
  };
  if v < step * step * step * step {
    return convert.float_to_fixed_str(v / (step * step * step), 1) + " " + g + unit;
  };
  return convert.float_to_fixed_str(v / (step * step * step * step), 1) + " " + t + unit;
}

/// Format a fraction in [0,1] as a percentage with `decimals` places.
pub fn format_percent(f: Float64, decimals: Int) -> Str {
  var d = decimals;
  if d < 0 {
    d = 0;
  };
  return convert.float_to_fixed_str(f * 100.0, d) + "%";
}

/// Format a percentage with a percent sign and no decimals.
pub fn format_percent_sign(f: Float64) -> Str {
  return convert.float_to_fixed_str(f * 100.0, 0) + "%";
}

/// Format num/den as a ratio, handling zero denominators ("inf", "NaN", "-inf").
pub fn format_ratio(num: Int, den: Int) -> Str {
  if den == 0 {
    if num == 0 {
      return "NaN";
    };
    if num < 0 {
      return "-inf";
    };
    return "inf";
  };
  return convert.int_to_string(num) + "/" + convert.int_to_string(den);
}

/// Scientific notation with the given precision ("1.23e+04").
pub fn format_scientific(f: Float64, prec: Int) -> Str {
  var p = prec;
  if p < 0 {
    p = 0;
  };
  return convert.float_to_sci_str(f, p);
}

/// Engineering notation: exponent is a multiple of three, mantissa has 2
/// decimals ("1.23e+03").
pub fn format_engineering(f: Float64) -> Str {
  if f == 0.0 {
    return "0.00e+00";
  };
  var neg = f < 0.0;
  var v = f;
  if neg {
    v = 0.0 - v;
  };
  var e = 0;
  while v >= 1000.0 {
    v = v / 1000.0;
    e = e + 3;
  }
  while v < 1.0 {
    v = v * 1000.0;
    e = e - 3;
  }
  var body = convert.float_to_fixed_str(v, 2) + _exp_text(e);
  if neg {
    return "-" + body;
  };
  return body;
}

fn _exp_text(e: Int) -> Str {
  var s = "e";
  if e >= 0 {
    s = s + "+";
  } else {
    s = s + "-";
  };
  var a = e;
  if a < 0 {
    a = 0 - a;
  };
  if a < 10 {
    s = s + "0" + convert.int_to_string(a);
  } else {
    s = s + convert.int_to_string(a);
  };
  return s;
}

/// Value with an SI prefix (k, M, G, T; m, u, n) and unit.
pub fn format_si(f: Float64, unit: Str) -> Str {
  return _prefix_str(f, unit, false);
}

/// Value with a binary prefix (Ki, Mi, Gi, Ti) and unit.
pub fn format_binary_prefix(f: Float64, unit: Str) -> Str {
  return _prefix_str(f, unit, true);
}

fn _prefix_str(f: Float64, unit: Str, binary: Bool) -> Str {
  var step: Float64 = 1000.0;
  if binary {
    step = KIB;
  };
  var v = f;
  var neg = v < 0.0;
  if neg {
    v = 0.0 - v;
  };
  var step2 = step * step;
  var step3 = step2 * step;
  var prefix = "";
  var div = 1.0;
  if v >= step3 {
    if binary {
      prefix = "Gi";
    } else {
      prefix = "G";
    };
    div = step3;
  } elif v >= step2 {
    if binary {
      prefix = "Mi";
    } else {
      prefix = "M";
    };
    div = step2;
  } elif v >= step {
    if binary {
      prefix = "Ki";
    } else {
      prefix = "k";
    };
    div = step;
  } elif v >= 1.0 {
    prefix = "";
    div = 1.0;
  } elif v >= 0.001 {
    prefix = "m";
    div = 0.001;
  } elif v >= 0.000001 {
    prefix = "u";
    div = 0.000001;
  } else {
    prefix = "n";
    div = 0.000000001;
  };
  var body = convert.float_to_fixed_str(v / div, 1) + " " + prefix + unit;
  if neg {
    return "-" + body;
  };
  return body;
}

/// Degrees Celsius with the degree sign and C suffix ("21.5degC").
pub fn format_temperature_celsius(c: Float64) -> Str {
  return convert.float_to_fixed_str(c, 1) + "\u{00b0}C";
}

/// Degrees Fahrenheit with the degree sign and F suffix ("72.0degF").
pub fn format_temperature_fahrenheit(f: Float64) -> Str {
  return convert.float_to_fixed_str(f, 1) + "\u{00b0}F";
}

/// Group a non-negative integer with thousands separators.
fn _group_int(n: Int) -> Str {
  var s = convert.int_to_string(n);
  var result = "";
  var len = s.len();
  var i = 0;
  while i < len {
    if i > 0 && (len - i) % 3 == 0 {
      result = result + ",";
    };
    result = result + string.str_slice(s, i, i + 1);
    i = i + 1;
  }
  return result;
}

/// Currency symbol for an ISO code.
fn _currency_symbol(currency: Str) -> Str {
  if currency == "USD" {
    return "$";
  };
  if currency == "EUR" {
    return "\u{20ac}";
  };
  if currency == "GBP" {
    return "\u{00a3}";
  };
  if currency == "JPY" {
    return "\u{00a5}";
  };
  if currency == "INR" {
    return "\u{20b9}";
  };
  if currency == "AUD" || currency == "CAD" {
    return "$";
  };
  return "";
}

/// Integer cents as a localized currency string ("$1,234.56"). JPY drops the
/// decimals. Negative amounts get a leading minus sign.
pub fn format_currency(amount_cents: Int, currency: Str) -> Str {
  var neg = amount_cents < 0;
  var cents = amount_cents;
  if neg {
    cents = 0 - cents;
  };
  var symbol = _currency_symbol(currency);
  var units = cents / 100;
  var rem = cents % 100;
  var body = symbol;
  if currency == "JPY" {
    var rounded = units;
    if rem >= 50 {
      rounded = rounded + 1;
    };
    body = body + _group_int(rounded);
  } else {
    body = body + _group_int(units) + ".";
    var ds = convert.int_to_string(rem);
    if rem < 10 {
      ds = "0" + ds;
    };
    body = body + ds;
  };
  if neg {
    return "-" + body;
  };
  return body;
}

/// Seconds as a compact human duration ("1h 2m 3s", "2m 5s", "45s").
pub fn format_seconds(secs: Int) -> Str {
  var s = secs;
  if s < 0 {
    s = 0 - s;
  };
  var result = "";
  var days = s / 86400;
  s = s % 86400;
  var hours = s / 3600;
  s = s % 3600;
  var minutes = s / 60;
  s = s % 60;
  if days > 0 {
    result = convert.int_to_string(days) + "d";
  };
  if hours > 0 {
    if result.len() > 0 {
      result = result + " ";
    };
    result = result + convert.int_to_string(hours) + "h";
  };
  if minutes > 0 {
    if result.len() > 0 {
      result = result + " ";
    };
    result = result + convert.int_to_string(minutes) + "m";
  };
  if s > 0 || result.len() == 0 {
    if result.len() > 0 {
      result = result + " ";
    };
    result = result + convert.int_to_string(s) + "s";
  };
  return result;
}

/// Milliseconds as a compact human duration ("1h 2m 3s 500ms", "500ms").
pub fn format_ms(ms: Int) -> Str {
  var m = ms;
  if m < 0 {
    m = 0 - m;
  };
  if m < 1000 {
    return convert.int_to_string(m) + "ms";
  };
  var secs = m / 1000;
  var rem = m % 1000;
  var body = format_seconds(secs);
  if rem > 0 {
    body = body + " " + convert.int_to_string(rem) + "ms";
  };
  return body;
}

/// Frequency with a unit suffix (Hz, kHz, MHz, GHz).
pub fn format_hertz(hz: Float64) -> Str {
  var v = hz;
  var neg = v < 0.0;
  if neg {
    v = 0.0 - v;
  };
  var body = "";
  if v < 1000.0 {
    body = convert.float_to_fixed_str(v, 1) + " Hz";
  } elif v < 1000000.0 {
    body = convert.float_to_fixed_str(v / 1000.0, 1) + " kHz";
  } elif v < 1000000000.0 {
    body = convert.float_to_fixed_str(v / 1000000.0, 1) + " MHz";
  } else {
    body = convert.float_to_fixed_str(v / 1000000000.0, 1) + " GHz";
  };
  if neg {
    return "-" + body;
  };
  return body;
}
