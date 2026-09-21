// XIOM - Conversion: Roundtrip
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.convert.roundtrip

// Depends on: none

// ============================================================================
// Verify helpers that check format/parse round-trips. Formatting delegates to
// the canonical xiom.convert float formatters and xiom.num.base radix codec
// (all different function names, so delegation is safe from the same-name
// miscompile).
// ============================================================================

use xiom.string;
use xiom.convert;
use xiom.num.base;

/// True iff s is a canonical decimal integer: parsing it succeeds and
/// formatting the result reproduces s exactly. Complexity: O(n).
pub fn roundtrip_int(s: Str) -> Bool {
  var r = string.str_to_int(s);
  if !r.is_ok {
    return false;
  };
  var formatted = to_string(r.value);
  if formatted != s {
    return false;
  };
  true
}

/// True iff parsing s, formatting canonically, and re-parsing yields the same
/// value (the value is stable under the canonical float formatter).
/// Complexity: O(n).
pub fn roundtrip_float(s: Str) -> Bool {
  var f1 = _parse_float(s);
  match f1 {
    Some(v1) => {
      var formatted = convert.float_to_string(v1);
      var f2 = _parse_float(formatted);
      match f2 {
        Some(v2) => {
          return v2 == v1;
        },
        None => {
          return false;
        },
      }
    },
    None => {
      return false;
    },
  }
}

/// True iff formatting f with exactly `decimals` fraction digits and parsing
/// the result back reproduces f. Complexity: O(decimals).
pub fn roundtrip_fixed(f: Float64, decimals: Int) -> Bool {
  var formatted = convert.float_to_fixed_str(f, decimals);
  var r = _parse_float(formatted);
  match r {
    Some(v) => {
      return v == f;
    },
    None => {
      return false;
    },
  }
}

/// True iff formatting n in the given base and parsing it back reproduces n.
/// Returns false for an invalid base (2-36 required). Complexity: O(log n).
pub fn roundtrip_base(n: Int, base: Int) -> Bool {
  var formatted = xiom.num.base.to_base(n, base);
  var r = xiom.num.base.from_base(formatted, base);
  if !r.is_ok {
    return false;
  };
  r.value == n
}

/// Private decimal float parser (sign, '.', optional 'e'/'E' exponent).
fn _parse_float(s: Str) -> Option[Float64] {
  let len = s.len();
  if len == 0 {
    return None;
  };
  var i: Int = 0;
  var negative = false;
  var first = string.byte_at(s, 0);
  if first == 45 {
    negative = true;
    i = 1;
  } elif first == 43 {
    i = 1;
  };
  if i >= len {
    return None;
  };
  var int_part: Float64 = 0.0;
  var frac_part: Float64 = 0.0;
  var frac_div: Float64 = 10.0;
  var has_frac = false;
  var has_digit = false;
  while i < len {
    var b = string.byte_at(s, i) as Int;
    b = b & 0xFF;
    if b == 46 {
      if has_frac {
        return None;
      };
      has_frac = true;
      i = i + 1;
      continue;
    };
    if b == 101 || b == 69 {
      i = i + 1;
      var exp_negative = false;
      if i < len {
        var ec = string.byte_at(s, i);
        if ec == 45 {
          exp_negative = true;
          i = i + 1;
        } elif ec == 43 {
          i = i + 1;
        };
      };
      var exp_val: Int = 0;
      var exp_ok = false;
      while i < len {
        var eb = string.byte_at(s, i) as Int;
        eb = eb & 0xFF;
        if eb < 48 || eb > 57 {
          return None;
        };
        exp_val = exp_val * 10 + (eb - 48);
        exp_ok = true;
        i = i + 1;
      };
      if !exp_ok {
        return None;
      };
      var value = int_part + frac_part;
      var mult: Float64 = 1.0;
      if exp_negative {
        var j: Int = 0;
        while j < exp_val {
          mult = mult * 0.1;
          j = j + 1;
        };
      } else {
        var j: Int = 0;
        while j < exp_val {
          mult = mult * 10.0;
          j = j + 1;
        };
      };
      value = value * mult;
      if negative {
        value = -value;
      };
      return Some(value);
    };
    if b < 48 || b > 57 {
      return None;
    };
    var digit = (b - 48) as Float64;
    if has_frac {
      frac_part = frac_part + digit / frac_div;
      frac_div = frac_div * 10.0;
    } else {
      int_part = int_part * 10.0 + digit;
    };
    has_digit = true;
    i = i + 1;
  };
  if !has_digit {
    return None;
  };
  var value = int_part + frac_part;
  if negative {
    value = -value;
  };
  Some(value)
}
