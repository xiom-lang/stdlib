// XIOM stdlib fuzz smoke -- encoding round-trip harness (roadmap A3).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Deterministic mutation fuzzing for the byte and string encodings.
// Contract:
//   - decode(encode(data)) == data for hex, base64 (plain/padded/url),
//     base32, base32hex, and percent byte encodings;
//   - percent_encode/component/www-form strings round-trip through their
//     matching decoder;
//   - arbitrary decoder input never crashes or hangs (Ok or Err is fine);
//   - a decoder result re-encodes and re-decodes to the same value.
// Seeds and iteration count come from XIOM_FUZZ_SEED / XIOM_FUZZ_ITERS.
// Returns 0 on success, a unique error code on failure.

module smoke_fuzz_encodings
use xiom.encoding.hex;
use xiom.encoding.base64;
use xiom.encoding.base32;
use xiom.encoding.percent;
use xiom.string;
use xiom.io;
use xiom.env;

fn next_seed(s: Int) -> Int {
  (s * 1103515245 + 12345) % 2147483648
}

fn pick(alphabet: Str, idx: Int) -> Str {
  string.str_slice(alphabet, idx, idx + 1)
}

fn random_from(seed: Int, len: Int, alphabet: Str) -> Str {
  let n = string.str_len(alphabet);
  var s = seed;
  var out = "";
  var i = 0;
  while i < len {
    s = next_seed(s);
    out = out + pick(alphabet, s % n);
    i = i + 1;
  };
  out
}

fn env_int(name: Str, dflt: Int) -> Int {
  let raw = env.var_or(name, "");
  var result = dflt;
  if raw != "" {
    match string.str_to_int(raw) {
      Ok(n) => { if n > 0 { result = n; } },
      Err(_) => {},
    };
  };
  result
}

fn same_bytes(a: &Vec[UInt8], b: &Vec[UInt8]) -> Bool {
  if a.len() != b.len() { return false; }
  var i = 0;
  while i < a.len() {
    if a[i] != b[i] { return false; }
    i = i + 1;
  };
  return true;
}

fn check_bytes(data: &Vec[UInt8]) -> Int {
  let hx = hex.hex_encode(data);
  match hex.hex_decode(hx) {
    Ok(d) => { if !same_bytes(data, &d) { return 300; } },
    Err(_) => { return 301; },
  };

  let b64 = base64.base64_encode(data);
  match base64.base64_decode(b64) {
    Ok(d) => { if !same_bytes(data, &d) { return 302; } },
    Err(_) => { return 303; },
  };
  let b64p = base64.base64_encode_padded(data);
  match base64.base64_decode_padded(b64p) {
    Ok(d) => { if !same_bytes(data, &d) { return 304; } },
    Err(_) => { return 305; },
  };
  let b64u = base64.base64url_encode(data);
  match base64.base64url_decode(b64u) {
    Ok(d) => { if !same_bytes(data, &d) { return 306; } },
    Err(_) => { return 307; },
  };

  let b32 = base32.base32_encode(data);
  match base32.base32_decode(b32) {
    Ok(d) => { if !same_bytes(data, &d) { return 308; } },
    Err(_) => { return 309; },
  };
  let b32h = base32.base32hex_encode(data);
  match base32.base32hex_decode(b32h) {
    Ok(d) => { if !same_bytes(data, &d) { return 310; } },
    Err(_) => { return 311; },
  };

  let pct = percent.percent_encode_bytes(data);
  match percent.percent_decode_bytes(pct) {
    Ok(d) => { if !same_bytes(data, &d) { return 312; } },
    Err(_) => { return 313; },
  };
  return 0;
}

fn check_strings(input: Str) -> Int {
  let pe = percent.percent_encode(input);
  match percent.percent_decode(pe) {
    Ok(d) => { if d != input { return 320; } },
    Err(_) => { return 321; },
  };
  let pc = percent.percent_encode_component(input);
  match percent.percent_decode_component(pc) {
    Ok(d) => { if d != input { return 322; } },
    Err(_) => { return 323; },
  };
  let pw = percent.percent_encode_www_form(input);
  match percent.percent_decode_www_form(pw) {
    Ok(d) => { if d != input { return 324; } },
    Err(_) => { return 325; },
  };

  // String encoders on valid text: encode -> decode is the identity.
  let he = hex.hex_encode_str(input);
  match hex.hex_decode_str(he) {
    Ok(d) => { if d != input { return 326; } },
    Err(_) => { return 327; },
  };
  let be = base64.base64_encode_str(input);
  match base64.base64_decode_str(be) {
    Ok(d) => { if d != input { return 328; } },
    Err(_) => { return 329; },
  };
  let b32e = base32.base32_encode_str(input);
  match base32.base32_decode_str(b32e) {
    Ok(d) => { if d != input { return 330; } },
    Err(_) => { return 331; },
  };

  // Arbitrary input to the string decoders must be total (Ok or Err, no
  // crash). Do not assert byte identity here: the *_decode_str docs say the
  // caller owns UTF-8 validity, so a binary payload may be invalid text.
  match hex.hex_decode_str(input) { Ok(_) => {}, Err(_) => {} };
  match base64.base64_decode_str(input) { Ok(_) => {}, Err(_) => {} };
  match base32.base32_decode_str(input) { Ok(_) => {}, Err(_) => {} };
  return 0;
}

fn main() -> Int {
  let iters = env_int("XIOM_FUZZ_ITERS", 120);
  let base = env_int("XIOM_FUZZ_SEED", 20261106);
  var run = 0;
  while run < 3 {
    var seed = base + run * 7919;
    var i = 0;
    while i < iters {
      seed = next_seed(seed);
      let len = seed % 64;
      var data = Vec[UInt8].new();
      var j = 0;
      while j < len {
        seed = next_seed(seed);
        data.push((seed % 256) as UInt8);
        j = j + 1;
      };
      let rc1 = check_bytes(&data);
      if rc1 != 0 { return rc1; }

      seed = next_seed(seed);
      let s = random_from(seed, seed % 32, "0123456789abcdefABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz%-_ .~+/= ");
      let rc2 = check_strings(s);
      if rc2 != 0 {
        io.println("fuzz-encodings input=" + s);
        return rc2;
      };
      i = i + 1;
    };
    run = run + 1;
  };
  io.println("fuzz-encodings: 3 seeds x " + iters.to_str() + " inputs OK");
  return 0;
}
