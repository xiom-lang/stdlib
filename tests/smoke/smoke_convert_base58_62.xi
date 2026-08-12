// XIOM stdlib smoke test - xiom.convert.base58 + xiom.convert.base62
// Checks: integer <-> base58/base62, byte round-trips, base58check round-trip
// and corruption detection.

module smoke_convert_base58_62
use xiom.convert.base58;
use xiom.convert.base62;
use xiom.io;
use xiom.convert;
use xiom.string;

fn main() -> Int {
  if base58.to_base58(0) != "1" { io.println("b58 zero"); return 1; }
  if base58.to_base58(58) != "21" { io.println(string.str_concat("b58 58 ", base58.to_base58(58))); return 2; }
  if base58.to_base58(10) != "B" { io.println(string.str_concat("b58 10 ", base58.to_base58(10))); return 3; }
  if base58.to_base58(-10) != "-B" { io.println(string.str_concat("b58 -10 ", base58.to_base58(-10))); return 4; }

  var f10 = base58.from_base58("B");
  match f10 {
    Ok(v) => { if v != 10 { io.println("b58 parse 10"); return 5; } },
    Err(e) => { io.println(string.str_concat("b58 parse err ", e)); return 6; },
  }
  var f58 = base58.from_base58("21");
  match f58 {
    Ok(v) => { if v != 58 { io.println("b58 parse 58"); return 7; } },
    Err(e) => { io.println(string.str_concat("b58 parse err ", e)); return 8; },
  }
  var fe = base58.from_base58("");
  match fe {
    Ok(_) => { io.println("b58 empty accepted"); return 9; },
    Err(_) => {},
  }
  var fz = base58.from_base58("0");
  match fz {
    Ok(_) => { io.println("b58 invalid char accepted"); return 10; },
    Err(_) => {},
  }

  var n = -9223372036854775808;
  var rt = base58.from_base58(base58.to_base58(n));
  match rt {
    Ok(v) => { if v != n { io.println("b58 INT_MIN roundtrip"); return 11; } },
    Err(e) => { io.println(string.str_concat("b58 rt err ", e)); return 12; },
  }

  var bytes = Vec[UInt8].new();
  bytes.push(0);
  bytes.push(1);
  bytes.push(2);
  var b58s = base58.base58_encode(&bytes);
  var b58d = base58.base58_decode(b58s);
  match b58d {
    Ok(out) => {
      if out.len() != 3 { io.println(string.str_concat("b58 decode len ", convert.int_to_string(out.len()))); return 13; }
      var b0 = out[0] as Int;
      var b1 = out[1] as Int;
      var b2 = out[2] as Int;
      if b0 != 0 || b1 != 1 || b2 != 2 { io.println("b58 decode bytes"); return 14; }
    },
    Err(e) => { io.println(string.str_concat("b58 decode err ", e)); return 15; },
  }

  var enc = base58.base58check_encode(&bytes);
  var dec = base58.base58check_decode(enc);
  match dec {
    Ok(out) => {
      if out.len() != 3 { io.println("b58check decode len"); return 16; }
      var b0 = out[0] as Int;
      var b1 = out[1] as Int;
      if b0 != 0 || b1 != 1 { io.println("b58check decode bytes"); return 17; }
    },
    Err(e) => { io.println(string.str_concat("b58check decode err ", e)); return 18; },
  }
  var corrupted = string.str_concat(string.str_slice(enc, 0, string.str_len(enc) - 1), "9");
  var badc = base58.base58check_decode(corrupted);
  match badc {
    Ok(_) => { io.println("b58check corrupt accepted"); return 19; },
    Err(_) => {},
  }

  if base62.to_base62(0) != "0" { io.println("b62 zero"); return 20; }
  if base62.to_base62(62) != "10" { io.println(string.str_concat("b62 62 ", base62.to_base62(62))); return 21; }
  if base62.to_base62(10) != "A" { io.println(string.str_concat("b62 10 ", base62.to_base62(10))); return 22; }
  var fb = base62.from_base62("1Z");
  match fb {
    Ok(v) => { if v != 97 { io.println("b62 parse 1Z"); return 23; } },
    Err(e) => { io.println(string.str_concat("b62 parse err ", e)); return 24; },
  }
  var b62s = base62.base62_encode(&bytes);
  var b62d = base62.base62_decode(b62s);
  match b62d {
    Ok(out) => {
      if out.len() != 3 { io.println("b62 decode len"); return 25; }
      var b0 = out[0] as Int;
      var b2 = out[2] as Int;
      if b0 != 0 || b2 != 2 { io.println("b62 decode bytes"); return 26; }
    },
    Err(e) => { io.println(string.str_concat("b62 decode err ", e)); return 27; },
  }

  io.println("OK");
  return 0;
}
