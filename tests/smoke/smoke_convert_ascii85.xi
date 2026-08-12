// XIOM stdlib smoke test - xiom.convert.ascii85
// Checks: known-answer vector, zero-run 'z' compression, tail handling,
// round-trips, and invalid-input rejection.

module smoke_convert_ascii85
use xiom.convert.ascii85;
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

fn main() -> Int {
  var data = build("Hello world!");
  var enc = ascii85.to_ascii85(&data);
  if enc != "87cURD]j7BEbo80" { io.println(string.str_concat("a85 got ", enc)); return 1; }

  var zeros = Vec[UInt8].new();
  zeros.push(0);
  zeros.push(0);
  zeros.push(0);
  zeros.push(0);
  var zenc = ascii85.to_ascii85(&zeros);
  if zenc != "z" { io.println(string.str_concat("a85 z got ", zenc)); return 2; }

  var empty = ascii85.to_ascii85(&(Vec[UInt8].new()));
  if empty != "" { io.println("a85 empty"); return 3; }

  var dec = ascii85.from_ascii85(enc);
  match dec {
    Ok(out) => {
      if out.len() != 12 { io.println("a85 decode len"); return 4; }
      var i = 0;
      while i < 12 {
        var a = out[i] as Int;
        var b = data[i] as Int;
        if a != b { io.println("a85 decode byte"); return 5; }
        i = i + 1;
      }
    },
    Err(e) => { io.println(string.str_concat("a85 decode err ", e)); return 6; },
  }

  var dsz = ascii85.from_ascii85("z");
  match dsz {
    Ok(out) => {
      if out.len() != 4 { io.println("a85 z decode len"); return 7; }
      var b0 = out[0] as Int;
      if b0 != 0 { io.println("a85 z bytes"); return 8; }
    },
    Err(e) => { io.println(string.str_concat("a85 z decode err ", e)); return 9; },
  }

  var ds = ascii85.ascii85_encode_str("Hello world!");
  if ds != "87cURD]j7BEbo80" { io.println(string.str_concat("a85 str got ", ds)); return 10; }
  var back = ascii85.ascii85_decode_str("87cURD]j7BEbo80");
  match back {
    Ok(v) => { if v != "Hello world!" { io.println(string.str_concat("a85 decode_str got ", v)); return 11; } },
    Err(e) => { io.println(string.str_concat("a85 decode_str err ", e)); return 12; },
  }

  var bad = ascii85.from_ascii85("uuuuu");
  match bad {
    Ok(_) => { io.println("a85 overflow accepted"); return 13; },
    Err(_) => {},
  }

  io.println("OK");
  return 0;
}
