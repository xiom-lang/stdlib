// XIOM stdlib smoke test -- xiom.encoding.percent and xiom.encoding.ascii85
// Percent (URL/form/component/bytes) known answers and Ascii85 known answers.
// Returns 0 on success, nonzero on failure.

module smoke_encoding_percent_ascii85
use xiom.encoding.percent;
use xiom.encoding.ascii85;
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
  // ---- percent ----
  if percent.percent_encode("a b") != "a%20b" { io.println("pct-a-b"); return 1; }
  var pd = percent.percent_decode("a%20b");
  match pd {
    Ok(v) => { if v != "a b" { io.println("pct-dec-a-b"); return 2; } },
    Err(_) => { io.println("pct-dec-err"); return 3; },
  }

  // component: '/' must be escaped
  if percent.percent_encode_component("a/b") != "a%2Fb" { io.println("pct-comp"); return 4; }
  var pdc = percent.percent_decode_component("a%2Fb");
  match pdc {
    Ok(v) => { if v != "a/b" { io.println("pct-dec-comp"); return 5; } },
    Err(_) => { io.println("pct-dec-comp-err"); return 6; },
  }

  // form: space -> '+', literal '+' -> %2B
  if percent.percent_encode_www_form("a b+c") != "a+b%2Bc" { io.println("pct-form"); return 7; }
  var pdf = percent.percent_decode_www_form("a+b%2Bc");
  match pdf {
    Ok(v) => { if v != "a b+c" { io.println("pct-dec-form"); return 8; } },
    Err(_) => { io.println("pct-dec-form-err"); return 9; },
  }

  // bytes round trip
  var raw = Vec[UInt8].new();
  raw.push(0);
  raw.push(255);
  raw.push(65);
  var pbe = percent.percent_encode_bytes(&raw);
  if pbe != "%00%FFA" { io.println("pct-bytes-enc"); return 10; }
  var pbd = percent.percent_decode_bytes(pbe);
  match pbd {
    Ok(bytes) => {
      if !_eq_bytes(bytes, &raw) { io.println("pct-bytes-back"); return 11; }
    },
    Err(_) => { io.println("pct-bytes-err"); return 12; },
  }

  // malformed escape -> Err
  var bad = percent.percent_decode("%zz");
  match bad {
    Ok(_) => { io.println("pct-zz-not-err"); return 13; },
    Err(_) => {},
  }
  var bad2 = percent.percent_decode("a%2");
  match bad2 {
    Ok(_) => { io.println("pct-trunc-not-err"); return 14; },
    Err(_) => {},
  }

  // ---- ascii85 ----
  var man = _bytes("Man");
  var a85 = ascii85.ascii85_encode(&man);
  if a85 != "9jqo" { io.println("a85-man"); return 15; }
  var a85d = ascii85.ascii85_decode("9jqo");
  match a85d {
    Ok(bytes) => {
      if !_eq_bytes(bytes, &man) { io.println("a85-man-back"); return 16; }
    },
    Err(_) => { io.println("a85-man-err"); return 17; },
  }

  // long input round trip (12 bytes -> 15 characters)
  var hw = _bytes("Hello world!");
  var a85l = ascii85.ascii85_encode(&hw);
  if string.str_len(a85l) != 15 { io.println("a85-hello-world-len"); return 18; }
  var a85ld = ascii85.ascii85_decode(a85l);
  match a85ld {
    Ok(bytes) => {
      if !_eq_bytes(bytes, &hw) { io.println("a85-hello-world-back"); return 19; }
    },
    Err(_) => { io.println("a85-hello-world-err"); return 20; },
  }
  var a85l2 = ascii85.ascii85_encode(&hw);
  if a85l2 != a85l { io.println("a85-hello-world-det"); return 21; }

  // string wrappers
  if ascii85.ascii85_encode_str("Man") != "9jqo" { io.println("a85-enc-str"); return 21; }
  var a85s = ascii85.ascii85_decode_str("9jqo");
  match a85s {
    Ok(v) => { if v != "Man" { io.println("a85-dec-str"); return 22; } },
    Err(_) => { io.println("a85-dec-str-err"); return 23; },
  }

  // delimiters
  var abc = _bytes("abc");
  var a85d1 = ascii85.ascii85_encode_with_delim(&abc);
  if a85d1 != "<~@:E^~>" { io.println("a85-delim"); return 24; }
  var a85d2 = ascii85.ascii85_decode_with_delim("<~@:E^~>");
  match a85d2 {
    Ok(bytes) => {
      if !_eq_bytes(bytes, &abc) { io.println("a85-delim-back"); return 25; }
    },
    Err(_) => { io.println("a85-delim-err"); return 26; },
  }
  var a85nod = ascii85.ascii85_decode_with_delim("9jqo");
  match a85nod {
    Ok(_) => { io.println("a85-nodelim-not-err"); return 27; },
    Err(_) => {},
  }

  io.println("OK");
  return 0;
}
