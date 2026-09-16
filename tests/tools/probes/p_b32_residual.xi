// p_b32_residual.xi -- R15 residual after a07507c4: same-name delegation
// of Result/Str-returning catalog fns is frame-dependent.
module p_b32_residual
use xiom.convert.base32;
use xiom.io;

fn dump(tag: Str, r: Result[Vec[UInt8], Str]) -> Int {
  match r {
    Ok(v) => { io.println(tag + " OK len=" + v.len()); },
    Err(e) => { io.println(tag + " ERR msg=[" + e + "]"); },
  }
  return 0;
}

fn main() -> Int {
  var v = Vec[UInt8].new();
  v.push(102); v.push(111); v.push(111);

  // Str-returning same-name legs.
  io.println("enc=[" + base32.base32_encode(&v) + "]");
  io.println("hex=[" + base32.base32hex_encode(&v) + "]");

  // Result-returning same-name leg: inline match vs helper frame.
  let inline = base32.base32_decode("MZXW6===");
  match inline {
    Ok(x) => { io.println("inline OK len=" + x.len()); },
    Err(e) => { io.println("inline ERR msg=[" + e + "]"); },
  }
  let _ = dump("helper", base32.base32_decode("MZXW6==="));

  io.println("RESIDUAL DONE");
  return 0;
}
