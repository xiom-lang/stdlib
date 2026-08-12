// XIOM stdlib smoke test — xiom.encoding.base64
// base64/base64url known answers, padded variants, invalid-input errors.
// Returns 0 on success, nonzero on failure.

module smoke_encoding_base64
use xiom.encoding.base64;
use xiom.io;
use xiom.string;

fn _bytes(s: Str) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 0;
  while i < s.len() {
    v.push(string.byte_at(s, i));
    i = i + 1;
  };
  v
}

fn _eq_bytes(a: Vec[UInt8], b: &Vec[UInt8]) -> Bool {
  if a.len() != b.len() { return false; }
  var i = 0;
  while i < a.len() {
    if a[i] != b[i] { return false; }
    i = i + 1;
  }
  true
}

fn main() -> Int {
  var hello = _bytes("hello");

  // known answer and back
  var enc = base64.base64_encode(&hello);
  if enc != "aGVsbG8=" { io.println("b64-hello"); return 1; }
  var dec = base64.base64_decode("aGVsbG8=");
  match dec {
    Ok(bytes) => {
      if !_eq_bytes(bytes, &hello) { io.println("b64-hello-back"); return 2; }
    },
    Err(_) => { io.println("b64-hello-err"); return 3; },
  }

  // empty input
  var empty = Vec[UInt8].new();
  if base64.base64_encode(&empty) != "" { io.println("b64-empty"); return 4; }
  var de = base64.base64_decode("");
  match de {
    Ok(bytes) => { if bytes.len() != 0 { io.println("b64-empty-back"); return 5; } },
    Err(_) => { io.println("b64-empty-err"); return 6; },
  }

  // string wrappers
  if base64.base64_encode_str("hello") != "aGVsbG8=" { io.println("b64-enc-str"); return 7; }
  var dstr = base64.base64_decode_str("aGVsbG8=");
  match dstr {
    Ok(v) => { if v != "hello" { io.println("b64-dec-str"); return 8; } },
    Err(_) => { io.println("b64-dec-str-err"); return 9; },
  }

  // padded variants
  if base64.base64_encode_padded(&hello) != "aGVsbG8=" { io.println("b64-pad-enc"); return 10; }
  var dp = base64.base64_decode_padded("aGVsbG8=");
  match dp {
    Ok(bytes) => { if !_eq_bytes(bytes, &hello) { io.println("b64-pad-dec"); return 11; } },
    Err(_) => { io.println("b64-pad-dec-err"); return 12; },
  }
  var dp2 = base64.base64_decode_padded("aGVsbG8");
  match dp2 {
    Ok(_) => { io.println("b64-pad-missing-not-err"); return 13; },
    Err(_) => {},
  }

  // url-safe variants (unpadded)
  var uenc = base64.base64url_encode(&hello);
  if uenc != "aGVsbG8" { io.println("b64url-hello"); return 14; }
  var udec = base64.base64url_decode("aGVsbG8");
  match udec {
    Ok(bytes) => {
      if !_eq_bytes(bytes, &hello) { io.println("b64url-hello-back"); return 15; }
    },
    Err(_) => { io.println("b64url-hello-err"); return 16; },
  }

  // invalid input -> Err
  var bad = base64.base64_decode("aGVsbG8=");
  match bad {
    Ok(_) => {},
    Err(_) => { io.println("b64-valid-not-err"); return 17; },
  }
  var bad2 = base64.base64_decode("abc!");
  match bad2 {
    Ok(_) => { io.println("b64-bang-not-err"); return 18; },
    Err(_) => {},
  }
  var bad3 = base64.base64_decode("abc");
  match bad3 {
    Ok(_) => { io.println("b64-len-not-err"); return 19; },
    Err(_) => {},
  }

  io.println("OK");
  return 0;
}
