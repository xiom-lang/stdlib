// smoke_compress_crc32.xi -- CRC-32 (IEEE) known-answer tests
// Values cross-checked against zlib.crc32. Guards the bitwise no-table
// implementation that replaced the mis-materialized module-level table
// (the old version returned all-zero-table garbage at EVERY size and AVed
// past 4096-byte inputs).
module smoke_compress_crc32
use xiom.compress.gzip;
use xiom.io;
use xiom.convert;

fn bytes_of(s: Str) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 0;
  while i < s.len() {
    v.push(s.byte_at(i));
    i = i + 1;
  }
  return v;
}

fn expect(tag: Str, got: UInt32, want_dec: Str, code: Int) -> Int {
  // masked-then-string comparison avoids UInt32->Int casts entirely
  var m = got & 4294967295;
  var got_str = convert.int_to_string(m);
  if got_str != want_dec {
    io.println("crc " + tag + ": " + got_str + " want " + want_dec);
    return code;
  }
  return 0;
}

fn main() -> Int {
  var empty = Vec[UInt8].new();
  var r = expect("empty", gzip_crc32(&empty), "0", 1);
  if r != 0 { return r; }

  r = expect("a", gzip_crc32(&bytes_of("a")), "3904355907", 2);
  if r != 0 { return r; }

  r = expect("abc", gzip_crc32(&bytes_of("abc")), "891568578", 3);
  if r != 0 { return r; }

  // the classic check value for the IEEE polynomial
  r = expect("123456789", gzip_crc32(&bytes_of("123456789")), "3421780262", 4);
  if r != 0 { return r; }

  // longer cyclic pattern (crosses block boundaries in real pipelines)
  var big = Vec[UInt8].new();
  var i = 0;
  while i < 5000 {
    big.push((65 + (i % 26)) as UInt8);
    i += 1;
  }
  r = expect("cyclic5000", gzip_crc32(&big), "2428730309", 5);
  if r != 0 { return r; }

  io.println("OK");
  return 0;
}
