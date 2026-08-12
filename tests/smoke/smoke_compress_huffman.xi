// XIOM stdlib smoke test - xiom.compress.huffman
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_compress_huffman
use xiom.compress.huffman;
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
  data.push(97);
  data.push(97);
  data.push(97);
  data.push(97);
  data.push(98);
  data.push(98);
  data.push(98);
  data.push(98);
  data.push(99);
  data.push(99);
  data.push(99);
  data.push(99);

  var compressed = huffman_compress(&data);
  var decompressed = huffman_decompress(&compressed);
  if decompressed.is_err {
    io.println("huffman: decompress failed");
    return 1;
  }
  var ok = false;
  match decompressed {
    Ok(v) => { ok = bytes_equal(v, data); };
    Err(_) => { ok = false; };
  }
  if !ok {
    io.println("huffman: round-trip mismatch");
    return 2;
  }

  var freq = Vec[Int].new();
  var i = 0;
  while i < 256 {
    freq.push(0);
    i = i + 1;
  }
  var j = 0;
  while j < data.len() {
    var b = data[j] as Int;
    freq[b] = freq[b] + 1;
    j = j + 1;
  }
  var tree = huffman_build(&freq);
  var packed = huffman_encode(tree, &data);
  if packed.len() >= data.len() {
    io.println("huffman: no compression");
    return 3;
  }

  var big = Vec[UInt8].new();
  var k = 0;
  while k < 900 {
    big.push(97);
    k = k + 1;
  }
  var m = 0;
  while m < 100 {
    big.push(98);
    m = m + 1;
  }
  var big_c = huffman_compress(&big);
  if big_c.len() >= big.len() {
    io.println("huffman: big input did not compress");
    return 4;
  }
  var big_d = huffman_decompress(&big_c);
  if big_d.is_err {
    io.println("huffman: big decompress failed");
    return 5;
  }
  var okbig = false;
  match big_d {
    Ok(v) => { okbig = bytes_equal(v, big); };
    Err(_) => { okbig = false; };
  }
  if !okbig {
    io.println("huffman: big round-trip mismatch");
    return 6;
  }

  var rl = rle_compress(&data);
  var rld = rle_decompress(&rl);
  if rld.is_err {
    io.println("huffman: rle decompress failed");
    return 7;
  }
  var okr = false;
  match rld {
    Ok(v) => { okr = bytes_equal(v, data); };
    Err(_) => { okr = false; };
  }
  if !okr {
    io.println("huffman: rle round-trip mismatch");
    return 8;
  }

  var bad = huffman_decompress(&data);
  if !bad.is_err {
    io.println("huffman: short container accepted");
    return 9;
  }

  io.println("OK");
  return 0;
}
