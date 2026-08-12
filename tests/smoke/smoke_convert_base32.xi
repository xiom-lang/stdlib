// XIOM stdlib smoke test - xiom.convert.base32
// Checks: RFC 4648 base32 and base32hex known-answer vectors + round-trips.

module smoke_convert_base32
use xiom.convert.base32;
use xiom.io;
use xiom.string;

fn build(s: Str) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  var i = 0;
  while i < s.len() {
    var c = s.char_at(i);
    result.push(c as UInt8);
    i = i + 1;
  };
  result
}

fn check_rt(s: Str, expected: Str) -> Bool {
  var bytes = build(s);
  var enc = base32.base32_encode(&bytes);
  if enc != expected {
    io.println(string.str_concat("base32_encode(", string.str_concat(s, string.str_concat(") = ", enc))));
    return false;
  };
  var dec = base32.base32_decode(expected);
  match dec {
    Ok(out) => {
      if out.len() != bytes.len() {
        io.println(string.str_concat("base32_decode len ", to_string(out.len())));
        return false;
      };
      var i = 0;
      while i < out.len() {
        var a = out[i] as Int;
        var b = bytes[i] as Int;
        if a != b {
          io.println("base32_decode byte mismatch");
          return false;
        };
        i = i + 1;
      };
      return true;
    },
    Err(e) => {
      io.println(string.str_concat("base32_decode err ", e));
      return false;
    },
  }
}

fn main() -> Int {
  if !check_rt("", "") { return 1; }
  if !check_rt("f", "MY======") { return 2; }
  if !check_rt("fo", "MZXQ====") { return 3; }
  if !check_rt("foo", "MZXW6===") { return 4; }
  if !check_rt("foob", "MZXW6YQ=") { return 5; }
  if !check_rt("fooba", "MZXW6YTB") { return 6; }
  if !check_rt("foobar", "MZXW6YTBOI======") { return 7; }

  var foo = build("foo");
  var hex_enc = base32.base32hex_encode(&foo);
  if hex_enc != "CPNMU===" { io.println(string.str_concat("base32hex got ", hex_enc)); return 8; }
  var hex_dec = base32.base32hex_decode("CPNMU===");
  match hex_dec {
    Ok(out) => {
      if out.len() != 3 { io.println("base32hex len"); return 9; }
      var b0 = out[0] as Int;
      var b1 = out[1] as Int;
      var b2 = out[2] as Int;
      if b0 != 102 || b1 != 111 || b2 != 111 { io.println("base32hex bytes"); return 10; }
    },
    Err(e) => { io.println(string.str_concat("base32hex err ", e)); return 11; },
  }

  var bad = base32.base32_decode("MZ!W6===");
  match bad {
    Ok(_) => { io.println("invalid char accepted"); return 12; },
    Err(_) => {},
  }
  var badlen = base32.base32_decode("MZXW6E");
  match badlen {
    Ok(_) => { io.println("invalid length accepted"); return 13; },
    Err(_) => {},
  }

  io.println("OK");
  return 0;
}
