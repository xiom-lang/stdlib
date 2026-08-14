// XIOM stdlib smoke test - xiom.compress.lz4 + xiom.compress.snappy
// Returns 0 on success, nonzero on failure (process exit code).
//
// Full round-trips restored (BUG 26 #1 FIXED 4e95717e — catalog-returned
// Vecs re-enter &Vec params again).

module smoke_compress_lz4_snappy
use xiom.compress.lz4;
use xiom.compress.snappy;
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
  var small = Vec[UInt8].new();
  var i = 0;
  while i < 32 {
    small.push((65 + (i % 7)) as UInt8);
    i = i + 1;
  }
  var j = 0;
  while j < 16 {
    small.push(97);
    j = j + 1;
  }

  // lz4 frame round-trip
  var lz = lz4.lz4_compress(small);
  if lz.len() == 0 {
    io.println("lz4: frame compress empty");
    return 1;
  }
  var dl = lz4.lz4_decompress(lz);
  match dl {
    Ok(v) => { if !bytes_equal(v, small) { io.println("lz4: frame roundtrip"); return 2; } }
    Err(e) => { io.println("lz4: frame decompress err " + e); return 3; }
  }
  var bound = lz4.lz4_bound(48);
  if bound <= 0 {
    io.println("lz4: bound");
    return 4;
  }
  // lz4 block round-trip
  var blk = lz4.lz4_compress_block(small);
  if blk.len() == 0 {
    io.println("lz4: block compress empty");
    return 5;
  }
  var dblk = lz4.lz4_decompress_block(blk);
  match dblk {
    Ok(v) => { if !bytes_equal(v, small) { io.println("lz4: block roundtrip"); return 6; } }
    Err(e) => { io.println("lz4: block decompress err " + e); return 7; }
  }
  // lz4 hc round-trip
  var hc = lz4.lz4_compress_hc(small);
  if hc.len() == 0 {
    io.println("lz4: hc compress empty");
    return 8;
  }
  var dhc = lz4.lz4_decompress(hc);
  match dhc {
    Ok(v) => { if !bytes_equal(v, small) { io.println("lz4: hc roundtrip"); return 9; } }
    Err(e) => { io.println("lz4: hc decompress err " + e); return 10; }
  }

  var big = Vec[UInt8].new();
  var k = 0;
  while k < 300 {
    big.push((65 + (k % 13)) as UInt8);
    k = k + 1;
  }
  var m = 0;
  while m < 200 {
    big.push(97);
    m = m + 1;
  }
  var big_c = lz4.lz4_compress(big);
  if big_c.len() < 10 {
    io.println("lz4: big compress failed");
    return 11;
  }
  var big_d = lz4.lz4_decompress(big_c);
  match big_d {
    Ok(v) => { if !bytes_equal(v, big) { io.println("lz4: big roundtrip"); return 12; } }
    Err(e) => { io.println("lz4: big decompress err " + e); return 13; }
  }

  // snappy round-trip
  var sn = snappy.snappy_compress(big);
  if sn.len() == 0 {
    io.println("snappy: compress empty");
    return 14;
  }
  var sd = snappy.snappy_decompress(sn);
  match sd {
    Ok(v) => { if !bytes_equal(v, big) { io.println("snappy: roundtrip"); return 15; } }
    Err(e) => { io.println("snappy: decompress err " + e); return 16; }
  }
  var sv = snappy.snappy_validate(big);
  if !sv {
    io.println("snappy: validate raw");
    return 17;
  }
  var ul = snappy.snappy_uncompressed_len(sn);
  var ulok = false;
  match ul {
    Ok(v) => { if v == big.len() { ulok = true; } }
    Err(_) => {}
  }
  if !ulok {
    io.println("snappy: uncompressed_len");
    return 18;
  }
  var mcl = snappy.snappy_max_compressed_len(500);
  if mcl <= 0 {
    io.println("snappy: max_compressed_len");
    return 19;
  }
  var sf = snappy.snappy_compress_frame(big);
  if sf.len() == 0 {
    io.println("snappy: frame compress empty");
    return 20;
  }
  var sfd = snappy.snappy_decompress_frame(sf);
  match sfd {
    Ok(v) => { if !bytes_equal(v, big) { io.println("snappy: frame roundtrip"); return 21; } }
    Err(e) => { io.println("snappy: frame decompress err " + e); return 22; }
  }

  io.println("smoke_compress_lz4_snappy: OK");
  return 0;
}
