// XIOM stdlib smoke test - xiom.compress.deflate + gzip + zlib
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_compress_deflate
use xiom.compress.deflate;
use xiom.compress.gzip;
use xiom.compress.zlib;
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
  while i < 500 {
    data.push((65 + (i % 19)) as UInt8);
    i = i + 1;
  }
  var j = 0;
  while j < 100 {
    data.push(90);
    j = j + 1;
  }

  var df = deflate.deflate_compress(&data);
  var dfd = deflate.deflate_decompress(&df);
  if dfd.is_err {
    io.println("deflate: decompress failed");
    return 1;
  }
  var okd = false;
  match dfd {
    Ok(v) => { okd = bytes_equal(v, data); };
    Err(_) => { okd = false; };
  }
  if !okd {
    io.println("deflate: round-trip mismatch");
    return 2;
  }

  var df0 = deflate.deflate_compress_level(&data, 0);
  var df0d = deflate.deflate_decompress(&df0);
  if df0d.is_err {
    io.println("deflate: level0 decompress failed");
    return 3;
  }
  var ok0 = false;
  match df0d {
    Ok(v) => { ok0 = bytes_equal(v, data); };
    Err(_) => { ok0 = false; };
  }
  if !ok0 {
    io.println("deflate: level0 round-trip mismatch");
    return 4;
  }

  if deflate.deflate_bound(100) < 100 {
    io.println("deflate: bound too small");
    return 5;
  }

  var gz = gzip.gzip_compress(&data);
  if gz.len() < 18 {
    io.println("gzip: output too short");
    return 6;
  }
  var gzb0 = gz[0];
  var gzb1 = gz[1];
  if gzb0 != 0x1F || gzb1 != 0x8B {
    io.println("gzip: magic bytes missing");
    return 7;
  }
  var gzd = gzip.gzip_decompress(&gz);
  if gzd.is_err {
    io.println("gzip: decompress failed");
    return 8;
  }
  var okg = false;
  match gzd {
    Ok(v) => { okg = bytes_equal(v, data); };
    Err(_) => { okg = false; };
  }
  if !okg {
    io.println("gzip: round-trip mismatch");
    return 9;
  }
  if !gzip.gzip_validate(&gz) {
    io.println("gzip: validate failed");
    return 10;
  }
  var gz_crc = gzip.gzip_crc32(&data);
  var gz_zero = gzip.gzip_crc32(&data);
  if gz_crc != gz_zero {
    io.println("gzip: crc32 unstable");
    return 11;
  }
  var hdr = gzip.gzip_header_new(0, 3);
  if hdr.len() != 10 {
    io.println("gzip: header wrong length");
    return 12;
  }

  var zl = zlib.zlib_compress(&data);
  if zl.len() < 6 {
    io.println("zlib: output too short");
    return 13;
  }
  var zlb0 = zl[0];
  if zlb0 != 0x78 {
    io.println("zlib: CMF byte missing");
    return 14;
  }
  var zld = zlib.zlib_decompress(&zl);
  if zld.is_err {
    io.println("zlib: decompress failed");
    return 15;
  }
  var okz = false;
  match zld {
    Ok(v) => { okz = bytes_equal(v, data); };
    Err(_) => { okz = false; };
  }
  if !okz {
    io.println("zlib: round-trip mismatch");
    return 16;
  }
  if !zlib.zlib_validate(&zl) {
    io.println("zlib: validate failed");
    return 17;
  }
  var zl5 = zlib.zlib_compress_level(&data, 5);
  var zl5d = zlib.zlib_decompress(&zl5);
  if zl5d.is_err {
    io.println("zlib: level5 decompress failed");
    return 18;
  }
  var ok5 = false;
  match zl5d {
    Ok(v) => { ok5 = bytes_equal(v, data); };
    Err(_) => { ok5 = false; };
  }
  if !ok5 {
    io.println("zlib: level5 round-trip mismatch");
    return 19;
  }
  var zl_ad = zlib.zlib_adler32(&data);
  if zl_ad == 0 {
    io.println("zlib: adler32 zero");
    return 20;
  }

  io.println("OK");
  return 0;
}
