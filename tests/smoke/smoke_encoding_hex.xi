// XIOM stdlib smoke test -- xiom.encoding.hex
// hex_encode/decode known answers, string/int wrappers, nibble helpers.
// Returns 0 on success, nonzero on failure.

module smoke_encoding_hex
use xiom.encoding.hex;
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
  var abc = _bytes("abc");
  var hi = _bytes("hi");

  // known answers and round trip
  var enc = hex.hex_encode(&abc);
  if enc != "616263" { io.println("hex-abc"); return 1; }
  var dec = hex.hex_decode("616263");
  var dec_ok = false;
  match dec {
    Ok(bytes) => {
      if !_eq_bytes(bytes, &abc) { io.println("hex-abc-back"); return 2; }
      dec_ok = true;
    },
    Err(_) => {},
  }
  if !dec_ok { io.println("hex-abc-err"); return 3; }
  var enc2 = hex.hex_encode(&hi);
  if enc2 != "6869" { io.println("hex-hi"); return 4; }
  var up = hex.hex_encode_upper(&abc);
  if up != "616263" { io.println("hex-upper"); return 5; }

  // upper case for a byte with letters
  var ab = Vec[UInt8].new();
  ab.push(0xAB);
  var up2 = hex.hex_encode_upper(&ab);
  if up2 != "AB" { io.println("hex-upper-ab"); return 6; }
  var lo2 = hex.hex_encode(&ab);
  if lo2 != "ab" { io.println("hex-lower-ab"); return 7; }

  // invalid input -> Err
  var odd = hex.hex_decode("6");
  match odd {
    Ok(_) => { io.println("hex-odd-not-err"); return 8; },
    Err(_) => {},
  }
  var bad = hex.hex_decode("zz");
  match bad {
    Ok(_) => { io.println("hex-zz-not-err"); return 9; },
    Err(_) => {},
  }

  // string wrappers
  if hex.hex_encode_str("abc") != "616263" { io.println("hex-enc-str"); return 10; }
  var ds = hex.hex_decode_str("6869");
  match ds {
    Ok(v) => { if v != "hi" { io.println("hex-dec-str"); return 11; } },
    Err(_) => { io.println("hex-dec-str-err"); return 12; },
  }

  // integer conversions
  if hex.hex_encode_int(255) != "ff" { io.println("hex-int-255"); return 13; }
  if hex.hex_encode_int(0) != "0" { io.println("hex-int-0"); return 14; }
  var di = hex.hex_decode_int("ff");
  match di {
    Ok(v) => { if v != 255 { io.println("hex-dec-int"); return 15; } },
    Err(_) => { io.println("hex-dec-int-err"); return 16; },
  }
  var di2 = hex.hex_decode_int("zz");
  match di2 {
    Ok(_) => { io.println("hex-dec-int-zz"); return 17; },
    Err(_) => {},
  }

  // nibble helpers
  var ni = hex.hex_nibble_to_int('f');
  match ni {
    Some(v) => { if v != 15 { io.println("nibble-f"); return 18; } },
    None => { io.println("nibble-f-none"); return 19; },
  }
  var nz = hex.hex_nibble_to_int('z');
  match nz {
    Some(_) => { io.println("nibble-z-some"); return 20; },
    None => {},
  }
  if hex.hex_int_to_nibble(15) != 'f' { io.println("int-nibble-f"); return 21; }
  if hex.hex_int_to_nibble(10) != 'a' { io.println("int-nibble-a"); return 22; }

  io.println("OK");
  return 0;
}
