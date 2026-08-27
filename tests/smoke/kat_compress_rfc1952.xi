// kat_compress_rfc1952.xi -- REAL gzip/DEFLATE interop known-answer tests
//
// The stdlib deflate/gzip stack now speaks RFC 1951/1952 (replaced the
// pre-1.0 custom container 2026-08-27). Vectors:
//   reader side: gzip streams produced by python zlib (fixed-Huffman,
//     dynamic-Huffman, and stored blocks) embedded as hex -- decompressed
//     byte-exact.
//   producer side: byte-exact comparison of xiom output against the
//     python-generated reference for the same input (fixed + stored).
// Cross-checked live: python gzip.decompress(xiom_output) == input.
module kat_compress_rfc1952
use xiom.compress.gzip;
use xiom.compress.deflate;
use xiom.io;
use xiom.encoding.hex;

fn hx(s: Str) -> Vec[UInt8] {
  match hex.hex_decode(s) {
    Ok(v) => { return v; }
    Err(e) => { io.println("bad hex literal"); return Vec[UInt8].new(); }
  }
}

fn bytes_of(s: Str) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 0;
  while i < s.len() {
    v.push(s.byte_at(i));
    i = i + 1;
  }
  return v;
}

fn mk_a(n: Int) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 0;
  while i < n {
    v.push(97u8);
    i += 1;
  }
  return v;
}

fn mk_cyc(n: Int) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 0;
  while i < n {
    v.push((65 + (i * 7) % 26) as UInt8);
    i += 1;
  }
  return v;
}

// decompress a stream and byte-compare against `want`
fn check_stream(tag: Str, stream: Vec[UInt8], want: &Vec[UInt8], code: Int) -> Int {
  match gzip.gzip_decompress(&stream) {
    Ok(out) => {
      if out.len() != want.len() {
        io.println(tag + " len");
        return code;
      }
      var i = 0;
      while i < want.len() {
        if out[i] != want[i] {
          io.println(tag + " byte");
          return code;
        }
        i += 1;
      }
      return 0;
    }
    Err(e) => { io.println(tag + " err: " + e); return code; }
  }
}

fn main() -> Int {
  var hello = bytes_of("hello world, hello world!");
  var a500 = mk_a(500);
  var cyc1000 = mk_cyc(1000);

  // ---- reader side: python-produced real streams ----
  var r = check_stream("s1", hx("1f8b080000000000040acb48cdc9c95728cf2fca49d151c8407014018333b48219000000"), &hello, 1);
  if r != 0 { return r; }
  r = check_stream("s2", hx("1f8b080000000000000acb48cdc9c95728cf2fca49d151c8407014018333b48219000000"), &hello, 2);
  if r != 0 { return r; }
  r = check_stream("s3", hx("1f8b080000000000040a4b4c1c05230d000011419205f4010000"), &a500, 3);
  if r != 0 { return r; }
  r = check_stream("s4", hx("1f8b080000000000000a4b4c1c05230d000011419205f4010000"), &a500, 4);
  if r != 0 { return r; }
  r = check_stream("s6", hx("1f8b080000000000040a73f4f00f73f60a8c70f5098e72f70b75f20c0877f10e8a74f30d711c95199519951926320037b7ee1be8030000"), &cyc1000, 6);
  if r != 0 { return r; }
  r = check_stream("s7", hx("1f8b080000000000000a73f4f00f73f60a8c70f5098e72f70b75f20c0877f10e8a74f30d711c95199519951926320037b7ee1be8030000"), &cyc1000, 7);
  if r != 0 { return r; }
  r = check_stream("s5", hx("1f8b080000000000040a011900e6ff68656c6c6f20776f726c642c2068656c6c6f20776f726c64218333b48219000000"), &hello, 8);
  if r != 0 { return r; }

  // ---- producer side: byte-exact against python reference ----
  var g = gzip.gzip_compress(&hello);
  var ghex = hex.hex_encode(&g);
  // xiom header (xfl=00, os=ff) + fixed-huffman payload + crc + isize
  if ghex != "1f8b08000000000000ffcb48cdc9c95728cf2fca49d15140e22802008333b48219000000" {
    io.println("producer fixed mismatch");
    return 20;
  }

  // stored blocks at level 0 (raw deflate container)
  var d0 = deflate.deflate_compress_level(&hello, 0);
  if hex.hex_encode(&d0) != "011900e6ff68656c6c6f20776f726c642c2068656c6c6f20776f726c6421" {
    io.println("producer stored mismatch");
    return 21;
  }

  // ---- self round-trips at scale ----
  var big = gzip.gzip_compress(&cyc1000);
  r = check_stream("rt1000", big, &cyc1000, 22);
  if r != 0 { return r; }
  var big2 = gzip.gzip_compress(&a500);
  r = check_stream("rt500", big2, &a500, 23);
  if r != 0 { return r; }

  io.println("OK");
  return 0;
}
