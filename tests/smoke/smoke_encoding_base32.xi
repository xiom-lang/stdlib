// XIOM stdlib smoke test — xiom.encoding.base32
// base32/base32hex known answers and round trips, invalid-input errors.
// Returns 0 on success, nonzero on failure.

module smoke_encoding_base32
use xiom.encoding.base32;
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
  var foobar = _bytes("foobar");

  // known answer: RFC 4648 example base32("foobar") == "MZXW6YTBOI======"
  var enc = base32.base32_encode(&foobar);
  if enc != "MZXW6YTBOI======" { io.println("b32-foobar"); return 1; }
  var dec = base32.base32_decode("MZXW6YTBOI======");
  match dec {
    Ok(bytes) => {
      if !_eq_bytes(bytes, &foobar) { io.println("b32-foobar-back"); return 2; }
    },
    Err(_) => { io.println("b32-foobar-err"); return 3; },
  }

  // empty input
  var empty = Vec[UInt8].new();
  if base32.base32_encode(&empty) != "" { io.println("b32-empty"); return 4; }

  // string wrappers
  if base32.base32_encode_str("foobar") != "MZXW6YTBOI======" { io.println("b32-enc-str"); return 5; }
  var dstr = base32.base32_decode_str("MZXW6YTBOI======");
  match dstr {
    Ok(v) => { if v != "foobar" { io.println("b32-dec-str"); return 6; } },
    Err(_) => { io.println("b32-dec-str-err"); return 7; },
  }

  // base32hex round trip (same bit layout, alphabet 0-9 A-V)
  var hexenc = base32.base32hex_encode(&foobar);
  if hexenc != "CPNMUOJ1E8======" { io.println("b32hex-foobar"); return 8; }
  var hexdec = base32.base32hex_decode(hexenc);
  match hexdec {
    Ok(bytes) => {
      if !_eq_bytes(bytes, &foobar) { io.println("b32hex-back"); return 9; }
    },
    Err(_) => { io.println("b32hex-err"); return 10; },
  }
  if hexenc == enc { io.println("b32hex-eq-b32"); return 11; }

  // invalid input -> Err
  var bad = base32.base32_decode("MZXW6YTBOI======");
  match bad {
    Ok(_) => {},
    Err(_) => { io.println("b32-valid-not-err"); return 12; },
  }
  var bad2 = base32.base32_decode("1");
  match bad2 {
    Ok(_) => { io.println("b32-short-not-err"); return 13; },
    Err(_) => {},
  }
  var bad3 = base32.base32_decode("MZX@6Y");
  match bad3 {
    Ok(_) => { io.println("b32-badchar-not-err"); return 14; },
    Err(_) => {},
  }

  io.println("OK");
  return 0;
}
