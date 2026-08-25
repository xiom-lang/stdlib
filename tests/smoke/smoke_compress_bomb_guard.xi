// smoke_compress_bomb_guard.xi -- decompression-bomb caps
// Compresses a known payload, then proves gzip_decompress_capped rejects
// the same stream when the cap is below the real output size, accepts it
// above, and that the plain variant still round-trips (default 1 GiB cap).
module smoke_compress_bomb_guard
use xiom.compress.gzip;
use xiom.io;
use xiom.convert;

fn main() -> Int {
  // 200 bytes of patterned data; compressed stream is much smaller.
  var v = Vec[UInt8].new();
  var i = 0;
  while i < 200 {
    v.push((65 + (i % 26)) as UInt8);
    i += 1;
  }
  var g = gzip.gzip_compress(&v);
  match g {
    Err(e) => { io.println("compress err: " + e); return 1; }
    Ok(stream) => {
      // cap far BELOW the true size -> must be rejected
      var low = gzip.gzip_decompress_capped(&stream, 10);
      match low {
        Ok(_) => { io.println("cap10 accepted (BAD)"); return 2; }
        Err(_) => {}
      }
      // cap ABOVE the true size -> must succeed and round-trip
      var high = gzip.gzip_decompress_capped(&stream, 1048576);
      match high {
        Ok(out) => {
          if out.len() != 200 { io.println("cap1M len"); return 3; }
          var k = 0;
          while k < 200 {
            if out[k] != v[k] { io.println("cap1M byte"); return 4; }
            k += 1;
          }
        }
        Err(e) => { io.println("cap1M err: " + e); return 5; }
      }
      // plain variant (default 1 GiB cap) still works
      var plain = gzip.gzip_decompress(&stream);
      match plain {
        Ok(out) => {
          if out.len() != 200 { io.println("plain len"); return 6; }
        }
        Err(e) => { io.println("plain err: " + e); return 7; }
      }
      io.println("OK");
      return 0;
    }
  }
}
