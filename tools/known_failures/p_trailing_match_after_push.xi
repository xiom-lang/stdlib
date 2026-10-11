// p_trailing_match_after_push.xi -- the checker reports T001
// "return type mismatch: expected Result[Float64, Str], found ()" for a
// function whose body ends in a bare `match` expression once a local
// Vec.push statement precedes it. Found while landing the wave-111 json
// parser rewrite (xiom/serialize/json.xi _json_parse_number): the same
// function shape WITHOUT the push compiles, and the fix is an explicit
// `return match ...;` (or binding the result first).
// Expected post-fix: this compiles and returns 0.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_trailing_match_after_push

fn classify() -> Result[Float64, Str] {
  var scratch = Vec[UInt8].new();
  let b: UInt8 = 53;
  scratch.push(b);
  let parsed: Result[Float64, Str] = Ok(5.0);
  match parsed {
    Ok(v) => { Ok(v) }
    Err(_) => { Err("bad") }
  }
}

fn main() -> Int {
  match classify() {
    Ok(v) => { if v != 5.0 { return 1; } }
    Err(_) => { return 2; }
  }
  return 0;
}
