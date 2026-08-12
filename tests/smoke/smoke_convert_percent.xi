// XIOM stdlib smoke test - xiom.convert.percent
// Checks: percent encode/decode (full URL and component).
// NOTE: split from smoke_convert_percent_bytes (combination with xiom.convert.bytes
// miscompiles percent_encode — BUG 24/26 family; isolated module verified).
module smoke_convert_percent
use xiom.convert.percent;
use xiom.io;
use xiom.string;

fn main() -> Int {
  if percent.percent_encode("a b") != "a%20b" { io.println(string.str_concat("pct got ", percent.percent_encode("a b"))); return 1; }
  if percent.percent_encode("hello world") != "hello%20world" { io.println("pct 2"); return 2; }
  if percent.percent_encode("/a?b=1&c=2") != "/a?b=1&c=2" { io.println(string.str_concat("pct reserved ", percent.percent_encode("/a?b=1&c=2"))); return 3; }
  if percent.percent_encode_component("/a?b=1") != "%2Fa%3Fb%3D1" { io.println(string.str_concat("pct comp ", percent.percent_encode_component("/a?b=1"))); return 4; }

  var pd = percent.percent_decode("a%20b");
  match pd {
    Ok(v) => { if v != "a b" { io.println(string.str_concat("pct dec got ", v)); return 5; } },
    Err(e) => { io.println(string.str_concat("pct dec err ", e)); return 6; },
  }
  var pdc = percent.percent_decode_component("a+b");
  match pdc {
    Ok(v) => { if v != "a b" { io.println(string.str_concat("pct dec comp got ", v)); return 7; } },
    Err(e) => { io.println(string.str_concat("pct dec comp err ", e)); return 8; },
  }
  var pdbad = percent.percent_decode("a%zz");
  match pdbad {
    Ok(_) => { io.println("pct bad escape accepted"); return 9; },
    Err(_) => {},
  }
  var pdtrunc = percent.percent_decode("a%2");
  match pdtrunc {
    Ok(_) => { io.println("pct truncated accepted"); return 10; },
    Err(_) => {},
  }
  io.println("smoke_convert_percent: OK");
  return 0;
}
