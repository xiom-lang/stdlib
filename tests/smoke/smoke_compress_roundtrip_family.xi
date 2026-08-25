// smoke_compress_roundtrip_family.xi -- direct codec round-trips
// Exercises every raw codec at two sizes with byte-exact verification.
// Uses module-qualified calls throughout (bare names have bound wrong
// overloads across modules -- see REPORT_TO_COMPILER_SESSION.md 3b-2 #12).
module smoke_compress_roundtrip_family
use xiom.compress.deflate;
use xiom.compress.lz77;
use xiom.compress.huffman;
use xiom.compress.zlib;
use xiom.compress.snappy;
use xiom.compress.lz4;
use xiom.io;

fn mk(n: Int, seed: Int) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 0;
  while i < n {
    v.push((65 + ((i * 7 + seed) % 26)) as UInt8);
    i += 1;
  }
  return v;
}

fn check(tag: Str, out: &Vec[UInt8], want: &Vec[UInt8]) -> Int {
  if out.len() != want.len() {
    io.println(tag + ": len " + tag);
    return 1;
  }
  var i = 0;
  while i < want.len() {
    if out[i] != want[i] {
      io.println(tag + ": byte");
      return 2;
    }
    i += 1;
  }
  return 0;
}

fn main() -> Int {
  var a = mk(300, 0);
  var b = mk(5000, 3);

  // ---- lz77 ----
  var lz = lz77.lz77_compress(&a);
  var lzb = lz77.lz77_decompress(&lz);
  match lzb {
    Ok(out) => {
      var r = check("lz77-300", &out, &a);
      if r != 0 { return r; }
    }
    Err(e) => { io.println("lz77-300 err " + e); return 3; }
  }

  // ---- huffman ----
  var h = huffman.huffman_compress(&b);
  var hb = huffman.huffman_decompress(&h);
  match hb {
    Ok(out) => {
      var r = check("huff-5000", &out, &b);
      if r != 0 { return r; }
    }
    Err(e) => { io.println("huff-5000 err " + e); return 4; }
  }

  // ---- deflate ----
  var d = deflate.deflate_compress(&b);
  var db = deflate.deflate_decompress(&d);
  match db {
    Ok(out) => {
      var r = check("deflate-5000", &out, &b);
      if r != 0 { return r; }
    }
    Err(e) => { io.println("deflate-5000 err " + e); return 5; }
  }

  // ---- zlib ----
  var z = zlib.zlib_compress(&b);
  var zb = zlib.zlib_decompress(&z);
  match zb {
    Ok(out) => {
      var r = check("zlib-5000", &out, &b);
      if r != 0 { return r; }
    }
    Err(e) => { io.println("zlib-5000 err " + e); return 6; }
  }

  // ---- snappy ----
  var s = snappy.snappy_compress(&b);
  var sb = snappy.snappy_decompress(&s);
  match sb {
    Ok(out) => {
      var r = check("snappy-5000", &out, &b);
      if r != 0 { return r; }
    }
    Err(e) => { io.println("snappy-5000 err " + e); return 7; }
  }

  // ---- lz4 ----
  var l4 = lz4.lz4_compress(&b);
  var l4b = lz4.lz4_decompress(&l4);
  match l4b {
    Ok(out) => {
      var r = check("lz4-5000", &out, &b);
      if r != 0 { return r; }
    }
    Err(e) => { io.println("lz4-5000 err " + e); return 8; }
  }

  io.println("OK");
  return 0;
}
