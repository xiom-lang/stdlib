// XIOM stdlib smoke test - xiom.compress.lz77
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_compress_lz77
use xiom.compress.lz77;
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
  data.push(104);
  data.push(101);
  data.push(108);
  data.push(108);
  data.push(111);
  data.push(32);
  data.push(104);
  data.push(101);
  data.push(108);
  data.push(108);
  data.push(111);
  data.push(32);
  data.push(104);
  data.push(101);
  data.push(108);
  data.push(108);
  data.push(111);
  data.push(32);
  data.push(119);
  data.push(111);
  data.push(114);
  data.push(108);
  data.push(100);

  var tokens = lz77.lz77_compress(&data);
  var decompressed = lz77.lz77_decompress(&tokens);
  if decompressed.is_err {
    io.println("lz77: decompress failed");
    return 1;
  }
  var ok = false;
  match decompressed {
    Ok(v) => { ok = bytes_equal(v, data); };
    Err(_) => { ok = false; };
  }
  if !ok {
    io.println("lz77: round-trip mismatch");
    return 2;
  }

  var m = lz77.lz77_find_longest_match(&data, 6, 6);
  if m.0 < 3 {
    io.println("lz77: find_longest_match found no match");
    return 3;
  }

  var token = lz77.lz77_token_encode(10, 42);
  var parts = lz77.lz77_token_decode(token);
  if parts.0 != 10 || parts.1 != 42 {
    io.println("lz77: token encode/decode mismatch");
    return 4;
  }

  var repeated = Vec[UInt8].new();
  var r = 0;
  while r < 200 {
    repeated.push(65);
    r = r + 1;
  }
  var t2 = lz77.lz77_compress(&repeated);
  if t2.len() >= repeated.len() {
    io.println("lz77: repeated data did not compress");
    return 5;
  }
  var d2 = lz77.lz77_decompress(&t2);
  if d2.is_err {
    io.println("lz77: repeated decompress failed");
    return 6;
  }
  var ok2 = false;
  match d2 {
    Ok(v) => { ok2 = bytes_equal(v, repeated); };
    Err(_) => { ok2 = false; };
  }
  if !ok2 {
    io.println("lz77: repeated round-trip mismatch");
    return 7;
  }

  io.println("OK");
  return 0;
}
