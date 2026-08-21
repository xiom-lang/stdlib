// XIOM stdlib smoke test - xiom.convert.bytes
// Checks: integer <-> bytes round-trips, hex rendering, concat, reverse.
module smoke_convert_bytes
use xiom.convert.bytes;
use xiom.io;
use xiom.string;

fn main() -> Int {

  var bv = Vec[UInt8].new();
  bv.push(1);
  bv.push(2);
  bv.push(3);
  bv.push(4);
  bv.push(5);
  bv.push(6);
  bv.push(7);
  bv.push(8);
  var tb = bytes.to_bytes(0x0102030405060708);
  var i = 0;
  while i < 8 {
    var a = tb[i] as Int;
    var b = bv[i] as Int;
    if a != b { io.println("to_bytes mismatch"); return 11; }
    i = i + 1;
  }
  // NOTE: bytes.from_bytes is not exercised -- the name collides with a
  // compiler builtin (any call emits invalid IR; see bytes.xi TODO(compiler)).
  // The bytes->int direction is covered via xiom.convert.endian's
  // from_be_bytes in smoke_convert_endian.xi.

  var hex = Vec[UInt8].new();
  hex.push(255);
  hex.push(16);
  if bytes.bytes_to_hex(&hex) != "ff10" { io.println(string.str_concat("bytes_to_hex ", bytes.bytes_to_hex(&hex))); return 14; }
  var hb = bytes.hex_to_bytes("ff10");
  match hb {
    Ok(out) => {
      if out.len() != 2 { io.println("hex_to_bytes len"); return 15; }
      var b0 = out[0] as Int;
      var b1 = out[1] as Int;
      if b0 != 255 || b1 != 16 { io.println("hex_to_bytes bytes"); return 16; }
    },
    Err(e) => { io.println(string.str_concat("hex_to_bytes err ", e)); return 17; },
  }

  var a = Vec[UInt8].new();
  a.push(1);
  a.push(2);
  var b = Vec[UInt8].new();
  b.push(3);
  b.push(4);
  var cat = bytes.bytes_concat(&a, &b);
  if cat.len() != 4 { io.println("concat len"); return 18; }
  var c0 = cat[0] as Int;
  var c3 = cat[3] as Int;
  if c0 != 1 || c3 != 4 { io.println("concat bytes"); return 19; }

  var rev = bytes.bytes_reverse(&cat);
  var r0 = rev[0] as Int;
  var r3 = rev[3] as Int;
  if r0 != 4 || r3 != 1 { io.println("reverse"); return 20; }

  io.println("OK");
  return 0;
}
