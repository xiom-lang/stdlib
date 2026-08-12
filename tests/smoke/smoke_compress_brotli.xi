// XIOM stdlib smoke test - xiom.compress.brotli
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_compress_brotli
use xiom.compress.brotli;
use xiom.io;

fn bytes_equal(a: Vec[UInt8], b: Vec[UInt8]) -> Bool {
  if a.len() != b.len() {
    return false;
  }
  var i = 0;
  while i < a.len() {
    var x = a[i];
    var y = b[i];
    if x != y {
      return false;
    }
    i = i + 1;
  }
  return true;
}

fn main() -> Int {
  var data = Vec[UInt8].new();
  var i = 0;
  while i < 400 {
    data.push((65 + (i % 11)) as UInt8);
    i = i + 1;
  }
  var j = 0;
  while j < 150 {
    data.push(100);
    j = j + 1;
  }

  var comp = brotli.brotli_compress(&data);
  if comp.len() < 10 {
    io.println("brotli: output too short");
    return 1;
  }
  var cb0 = comp[0];
  var cb1 = comp[1];
  var cb2 = comp[2];
  var cb3 = comp[3];
  if cb0 != 0xCE || cb1 != 0xB2 || cb2 != 0xCF || cb3 != 0x81 {
    io.println("brotli: magic bytes missing");
    return 2;
  }
  var dec = brotli.brotli_decompress(&comp);
  if dec.is_err {
    io.println("brotli: decompress failed");
    return 3;
  }
  var ok = false;
  match dec {
    Ok(v) => { ok = bytes_equal(v, data); };
    Err(_) => { ok = false; };
  }
  if !ok {
    io.println("brotli: round-trip mismatch");
    return 4;
  }

  var q = brotli.brotli_compress_quality(&data, 9);
  var qd = brotli.brotli_decompress(&q);
  if qd.is_err {
    io.println("brotli: quality decompress failed");
    return 5;
  }
  var okq = false;
  match qd {
    Ok(v) => { okq = bytes_equal(v, data); };
    Err(_) => { okq = false; };
  }
  if !okq {
    io.println("brotli: quality round-trip mismatch");
    return 6;
  }

  var w = brotli.brotli_compress_window(&data, 1048576);
  var wd = brotli.brotli_decompress(&w);
  if wd.is_err {
    io.println("brotli: window decompress failed");
    return 7;
  }
  var okw = false;
  match wd {
    Ok(v) => { okw = bytes_equal(v, data); };
    Err(_) => { okw = false; };
  }
  if !okw {
    io.println("brotli: window round-trip mismatch");
    return 8;
  }

  io.println("OK");
  return 0;
}
