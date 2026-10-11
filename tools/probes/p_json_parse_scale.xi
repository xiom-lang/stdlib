// p_json_parse_scale.xi -- wave 111 fix lock: the json_parse byte-lexer
// fast path + the \u escape-consumption fix.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// (1) Escape value correctness: a parsed string must preserve every byte
//     around a \u escape (`"a\u0042c"` is "aBc"; the previous parser
//     swallowed the byte after the 4 hex digits because of a double
//     increment in the escape branch).
// (2) Linearity: numeric payloads parse in sub-quadratic time -- the old
//     parser read every char through string.char_at (strnlen per call) and
//     re-sliced via byte_at (strnlen per byte), so 2x input cost ~4x time.
//     Repro source: xvector docs/repro/xv-json-parse-quadratic (relay
//     REL-20261011-1453-xvector).
// Returns 0 when every case holds.

module p_json_parse_scale

use xiom.serialize.json;
use xiom.time;

// append the decimal digits of `v` to a byte buffer
fn push_int(buf: &mut Vec[UInt8], v: Int) {
  if v == 0 {
    buf.push(48 as UInt8);
    return;
  }
  var digits = Vec[UInt8].new();
  var x = v;
  while x > 0 {
    digits.push((48 + x % 10) as UInt8);
    x = x / 10;
  }
  var i = digits.len();
  while i > 0 {
    i = i - 1;
    buf.push(digits[i]);
  }
}

// build {"a":[1,2,...,n]}
fn build_payload(n: Int) -> Str {
  var buf = Vec[UInt8].new();
  buf.push(123 as UInt8); // {
  buf.push(34 as UInt8);  // "
  buf.push(97 as UInt8);  // a
  buf.push(34 as UInt8);  // "
  buf.push(58 as UInt8);  // :
  buf.push(91 as UInt8);  // [
  var i = 0;
  while i < n {
    if i > 0 { buf.push(44 as UInt8); } // ,
    push_int(&mut buf, i + 1);
    i = i + 1;
  }
  buf.push(93 as UInt8);  // ]
  buf.push(125 as UInt8); // }
  return Str::from_utf8(buf);
}

// parse `p` `reps` times; returns the elapsed ms, or -1 on a parse error
fn parse_ms(p: Str, reps: Int) -> Int {
  let t0 = time.monotonic_ms();
  var i = 0;
  while i < reps {
    let r = json.json_parse(p);
    if r.is_err { return -1; }
    i = i + 1;
  }
  return time.monotonic_ms() - t0;
}

fn main() -> Int {
  // ---- escape value correctness (\u must consume exactly 4 hex digits)
  let r1 = json.json_parse("\"a\\u0042c\"");
  match r1 {
    Ok(v1) => {
      let t1 = json.json_stringify(v1);
      if t1 != "\"aBc\"" { return 1; }
    },
    Err(_) => { return 1; }
  }
  let r2 = json.json_parse("\"\\u0041\\n\"");
  match r2 {
    Ok(v2) => {
      let t2 = json.json_stringify(v2);
      if t2 != "\"A\\n\"" { return 2; }
    },
    Err(_) => { return 2; }
  }
  let r3 = json.json_parse("\"\\u0041\\u0042\\u0043\"");
  match r3 {
    Ok(v3) => {
      let t3 = json.json_stringify(v3);
      if t3 != "\"ABC\"" { return 3; }
    },
    Err(_) => { return 3; }
  }
  // multibyte passthrough: caf + U+00E9 -> 7 bytes stringified
  let r4 = json.json_parse("\"caf\\u00e9\"");
  match r4 {
    Ok(v4) => {
      let t4 = json.json_stringify(v4);
      if t4.len() != 7 { return 4; }
    },
    Err(_) => { return 4; }
  }

  // ---- linearity (bounded: one timed parse per size)
  let p1 = build_payload(20000);
  let p2 = build_payload(40000);
  let warm = json.json_parse(p2);
  if warm.is_err { return 5; }
  let t_small = parse_ms(p1, 1);
  if t_small < 0 { return 6; }
  let t_big = parse_ms(p2, 1);
  if t_big < 0 { return 6; }
  // absolute budgets: pre-fix the same sizes take ~18 s / ~72 s (quadratic)
  if t_small > 1500 { return 6; }
  if t_big > 3000 { return 6; }
  // sub-quadratic ratio (only enforced when the small sample is measurable)
  if t_small >= 10 {
    if t_big > t_small * 3 { return 6; }
  }

  // ---- structure spot check on the large payload
  match warm {
    Ok(v) => {
      if json.json_get(v, "a").is_some == false { return 7; }
      if json.json_get(v, "b").is_some { return 7; }
    },
    Err(_) => { return 7; }
  }
  return 0;
}
