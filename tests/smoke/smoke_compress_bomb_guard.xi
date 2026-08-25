// smoke_compress_bomb_guard.xi -- decompression-bomb caps
// Compresses a known payload, then proves gzip_decompress_capped rejects
// the same stream when the cap is below the real output size, accepts it
// above, and that the plain variant still round-trips (default 1 GiB cap).
module smoke_compress_bomb_guard
use xiom.compress.gzip;
use xiom.compress.lz4;
use xiom.compress.snappy;
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

  // ---- lz4 / snappy capped variants ----
  var lv = Vec[UInt8].new();
  var li = 0;
  while li < 100 {
    lv.push((97 + (li % 20)) as UInt8);
    li += 1;
  }
  var lzc = lz4.lz4_compress(&lv);
  var lzlow = lz4.lz4_decompress_capped(&lzc, 10);
  match lzlow {
    Ok(_) => { io.println("lz4 cap10 accepted (BAD)"); return 20; }
    Err(_) => {}
  }
  var lzhigh = lz4.lz4_decompress_capped(&lzc, 65536);
  match lzhigh {
    Ok(out) => { if out.len() != 100 { io.println("lz4 cap1M len"); return 21; } }
    Err(e) => { io.println("lz4 cap1M err: " + e); return 22; }
  }

  var sv = Vec[UInt8].new();
  var si = 0;
  while si < 100 {
    sv.push((97 + (si % 20)) as UInt8);
    si += 1;
  }
  var sc = snappy.snappy_compress(&sv);
  var slow = snappy.snappy_decompress_capped(&sc, 10);
  match slow {
    Ok(_) => { io.println("snappy cap10 accepted (BAD)"); return 23; }
    Err(_) => {}
  }
  var shigh = snappy.snappy_decompress_capped(&sc, 65536);
  match shigh {
    Ok(out) => {
      if out.len() != 100 { io.println("snappy cap1M len"); return 24; }
      var sj = 0;
      while sj < 100 {
        if out[sj] != sv[sj] { io.println("snappy cap1M byte"); return 25; }
        sj += 1;
      }
    }
    Err(e) => { io.println("snappy cap1M err: " + e); return 26; }
  }
      io.println("OK");
      return 0;
    }
  }
}
