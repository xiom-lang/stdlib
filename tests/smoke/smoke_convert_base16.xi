// XIOM stdlib smoke test - xiom.convert.base16
// Checks: hex_encode/decode round-trips, known-answer hex strings, string wrappers.

module smoke_convert_base16
use xiom.convert.base16;
use xiom.io;
use xiom.string;

fn main() -> Int {
  var data = Vec[UInt8].new();
  data.push(255);
  data.push(16);
  data.push(0);
  var enc = base16.hex_encode(&data);
  if enc != "ff1000" { io.println(string.str_concat("hex_encode got ", enc)); return 1; }

  var dec = base16.hex_decode("ff1000");
  match dec {
    Ok(bytes) => {
      if bytes.len() != 3 { io.println("decode len"); return 2; }
      var b0 = bytes[0] as Int;
      var b1 = bytes[1] as Int;
      var b2 = bytes[2] as Int;
      if b0 != 255 || b1 != 16 || b2 != 0 { io.println("decode bytes"); return 3; }
    },
    Err(e) => { io.println(string.str_concat("decode err ", e)); return 4; },
  }

  var bad = base16.hex_decode("ff1");
  match bad {
    Ok(_) => { io.println("odd length accepted"); return 5; },
    Err(_) => {},
  }
  var bad2 = base16.hex_decode("zz");
  match bad2 {
    Ok(_) => { io.println("bad char accepted"); return 6; },
    Err(_) => {},
  }

  var s = base16.hex_encode_str("hi");
  if s != "6869" { io.println(string.str_concat("encode_str got ", s)); return 7; }

  var ds = base16.hex_decode_str("6869");
  match ds {
    Ok(v) => {
      if v != "hi" { io.println(string.str_concat("decode_str got ", v)); return 8; }
    },
    Err(e) => { io.println(string.str_concat("decode_str err ", e)); return 9; },
  }

  var empty = base16.hex_decode("");
  match empty {
    Ok(v) => {
      if v.len() != 0 { io.println("empty decode len"); return 10; }
    },
    Err(e) => { io.println(string.str_concat("empty decode err ", e)); return 11; },
  }

  io.println("OK");
  return 0;
}
