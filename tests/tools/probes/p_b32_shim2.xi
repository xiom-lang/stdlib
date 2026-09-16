module p_b32_shim2
use xiom.convert.base32;
use xiom.io;

fn dump(tag: Str, r: Result[Vec[UInt8], Str]) -> Int {
  match r {
    Ok(v) => {
      var s = tag;
      var i = 0;
      while i < v.len() { s = s + " " + (v[i] as Int); i = i + 1; }
      io.println(s);
    },
    Err(e) => { io.println(tag + " ERR " + e); },
  }
  io.flush_stdout();
  return 0;
}

fn main() -> Int {
  var v = Vec[UInt8].new();
  v.push(102); v.push(111); v.push(111);
  var v2 = Vec[UInt8].new();
  v2.push(102); v2.push(111); v2.push(111); v2.push(98); v2.push(97); v2.push(114);

  io.println("1"); io.flush_stdout();
  io.println("enc=" + base32.base32_encode(&v) + " hex=" + base32.base32hex_encode(&v));
  io.flush_stdout();

  io.println("2"); io.flush_stdout();
  var d1 = dump("d1", base32.base32_decode("MZXW6==="));
  io.flush_stdout();

  io.println("3"); io.flush_stdout();
  var d2 = dump("d2", base32.base32hex_decode("CPNMU==="));
  io.flush_stdout();

  io.println("4"); io.flush_stdout();
  var d3 = dump("d3", base32.base32_decode("MZXW6YTB"));
  io.flush_stdout();

  io.println("5"); io.flush_stdout();
  var d4 = dump("d4", base32.base32_decode("MZXW6YTBOI=="));
  io.flush_stdout();

  io.println("6 unpadded"); io.flush_stdout();
  var d5 = dump("d5", base32.base32_decode("MZXW6YTBOI"));
  io.flush_stdout();

  io.println("7 lower-hex"); io.flush_stdout();
  var d6 = dump("d6", base32.base32hex_decode("cpnmu"));
  io.flush_stdout();

  io.println("8 invalid"); io.flush_stdout();
  var d7 = dump("d7", base32.base32_decode("MZXW6YTD"));
  io.flush_stdout();

  io.println("SHIM2 OK");
  return 0;
}
