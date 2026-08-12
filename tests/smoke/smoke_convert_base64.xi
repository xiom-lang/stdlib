// XIOM stdlib smoke test - xiom.convert.base64 + xiom.convert.base64url
// Checks: known-answer base64("hello") = "aGVsbG8=", URL-safe unpadded forms,
// round-trips, and invalid-input rejection.

module smoke_convert_base64
use xiom.convert.base64;
use xiom.convert.base64url;
use xiom.io;
use xiom.string;

fn main() -> Int {
  var data = Vec[UInt8].new();
  data.push(104);
  data.push(101);
  data.push(108);
  data.push(108);
  data.push(111);
  var enc = base64.base64_encode(&data);
  if enc != "aGVsbG8=" { io.println(string.str_concat("b64 got ", enc)); return 1; }

  var encs = base64.base64_encode_str("hello");
  if encs != "aGVsbG8=" { io.println(string.str_concat("b64_str got ", encs)); return 2; }

  var dec = base64.base64_decode("aGVsbG8=");
  match dec {
    Ok(out) => {
      if out.len() != 5 { io.println("b64 decode len"); return 3; }
      var i = 0;
      while i < 5 {
        var a = out[i] as Int;
        var b = data[i] as Int;
        if a != b { io.println("b64 decode byte"); return 4; }
        i = i + 1;
      }
    },
    Err(e) => { io.println(string.str_concat("b64 decode err ", e)); return 5; },
  }

  var ds = base64.base64_decode_str("aGVsbG8=");
  match ds {
    Ok(v) => { if v != "hello" { io.println(string.str_concat("b64 decode_str got ", v)); return 6; } },
    Err(e) => { io.println(string.str_concat("b64 decode_str err ", e)); return 7; },
  }

  var e_empty = base64.base64_encode(&(Vec[UInt8].new()));
  if e_empty != "" { io.println("b64 empty"); return 8; }

  var bad = base64.base64_decode("aGVsbG8");
  match bad {
    Ok(_) => { io.println("b64 bad length accepted"); return 9; },
    Err(_) => {},
  }
  var bad2 = base64.base64_decode("!!!!");
  match bad2 {
    Ok(_) => { io.println("b64 bad char accepted"); return 10; },
    Err(_) => {},
  }

  var encu = base64url.base64url_encode(&data);
  if encu != "aGVsbG8" { io.println(string.str_concat("b64u got ", encu)); return 11; }

  var encus = base64url.base64url_encode_str("hello");
  if encus != "aGVsbG8" { io.println(string.str_concat("b64u_str got ", encus)); return 12; }

  var decu = base64url.base64url_decode("aGVsbG8");
  match decu {
    Ok(out) => {
      if out.len() != 5 { io.println("b64u decode len"); return 13; }
      var i = 0;
      while i < 5 {
        var a = out[i] as Int;
        var b = data[i] as Int;
        if a != b { io.println("b64u decode byte"); return 14; }
        i = i + 1;
      }
    },
    Err(e) => { io.println(string.str_concat("b64u decode err ", e)); return 15; },
  }

  var dsu = base64url.base64url_decode_str("aGVsbG8");
  match dsu {
    Ok(v) => { if v != "hello" { io.println(string.str_concat("b64u decode_str got ", v)); return 16; } },
    Err(e) => { io.println(string.str_concat("b64u decode_str err ", e)); return 17; },
  }

  var badu = base64url.base64url_decode("aGVs!G8");
  match badu {
    Ok(_) => { io.println("b64u bad char accepted"); return 18; },
    Err(_) => {},
  }

  io.println("OK");
  return 0;
}
