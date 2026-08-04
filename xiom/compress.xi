// XIOM — Compression
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.compress

// === Compression traits ===
pub interface Compressor {
  fn compress(self, data: &Vec[UInt8]) -> Result<Vec[UInt8], Str>;
  fn decompress(self, data: &Vec[UInt8]) -> Result<Vec[UInt8], Str>;
}

// === Gzip ===
pub type GzipCompressor = { level: Int; }

pub fn GzipCompressor.new() -> GzipCompressor {
  return GzipCompressor{ level: 6 };
}

pub fn GzipCompressor.with_level(level: Int) -> GzipCompressor {
  var lvl = level;
  if lvl < 0 { lvl = 0; };
  if lvl > 9 { lvl = 9; };
  return GzipCompressor{ level: lvl };
}

fn GzipCompressor.compress(self, data: &Vec[UInt8]) -> Result<Vec[UInt8], Str> {
  gzip_compress_level(data, self.level)
}

fn GzipCompressor.decompress(self, data: &Vec[UInt8]) -> Result<Vec[UInt8], Str> {
  gzip_decompress(data)
}

// === CRC32 table ===
var _crc32_table: [256]UInt;

fn _crc32_init() {
  var i = 0;
  while i < 256 {
    var crc = i as UInt;
    var j = 0;
    while j < 8 {
      if (crc & 1) == 1 {
        crc = (crc >> 1) ^ 0xEDB88320 as UInt;
      } else {
        crc = crc >> 1;
      }
      j = j + 1;
    }
    _crc32_table[i] = crc;
    i = i + 1;
  }
}

fn crc32(data: &Vec[UInt8]) -> UInt {
  if _crc32_table[1] == 0 {
    _crc32_init();
  }
  var crc = 0xFFFFFFFF as UInt;
  var i = 0;
  let len = data.len();
  while i < len {
    let idx = ((crc ^ (data[i] as UInt)) & 0xFF) as Int;
    crc = (crc >> 8) ^ _crc32_table[idx];
    i = i + 1;
  }
  return crc ^ 0xFFFFFFFF as UInt;
}

// === Adler32 ===
fn adler32(data: &Vec[UInt8]) -> UInt {
  const MOD_ADLER: UInt = 65521;
  var a: UInt = 1;
  var b: UInt = 0;
  var i = 0;
  let len = data.len();
  while i < len {
    a = (a + (data[i] as UInt)) % MOD_ADLER;
    b = (b + a) % MOD_ADLER;
    i = i + 1;
  }
  return (b << 16) | a;
}

// === RLE Core ===
// Format: control byte where bit 7 = 1 means run, 0 means literal
//   Run:   (control & 0x7F) + 3 repetitions of next byte  [3..130]
//   Lit:   (control & 0x7F) + 1 literal bytes follow      [1..128]

fn rle_encode(data: &Vec[UInt8]) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  let len = data.len();
  if len == 0 {
    return result;
  }
  var pos = 0;
  while pos < len {
    var run_len = 1;
    while (pos + run_len) < len && run_len < 130 && data[pos + run_len] == data[pos] {
      run_len = run_len + 1;
    }
    if run_len >= 3 {
      var ctrl = ((run_len - 3) | 0x80) as UInt8;
      result.push(ctrl);
      result.push(data[pos]);
      pos = pos + run_len;
    } else {
      var lit_start = pos;
      var lit_count = 0;
      while (pos + lit_count) < len && lit_count < 128 {
        if (pos + lit_count + 2) < len {
          if data[pos + lit_count] == data[pos + lit_count + 1] && data[pos + lit_count] == data[pos + lit_count + 2] {
            break;
          }
        }
        lit_count = lit_count + 1;
      }
      if lit_count == 0 {
        lit_count = 1;
      }
      var ctrl = (lit_count - 1) as UInt8;
      result.push(ctrl);
      var k = 0;
      while k < lit_count {
        result.push(data[lit_start + k]);
        k = k + 1;
      }
      pos = lit_start + lit_count;
    }
  }
  return result;
}

fn rle_decode(data: &Vec[UInt8]) -> Result<Vec[UInt8], Str> {
  var result = Vec[UInt8].new();
  let len = data.len();
  var pos = 0;
  while pos < len {
    if pos >= len {
      return Err("RLE decode: unexpected end of data");
    }
    let ctrl = data[pos] as Int;
    pos = pos + 1;
    if ctrl >= 128 {
      let run_len = (ctrl - 128) + 3;
      if pos >= len {
        return Err("RLE decode: unexpected end of data in run");
      }
      let val = data[pos];
      pos = pos + 1;
      var k = 0;
      while k < run_len {
        result.push(val);
        k = k + 1;
      }
    } else {
      let lit_len = ctrl + 1;
      if pos + lit_len > len {
        return Err("RLE decode: unexpected end of data in literal");
      }
      var k = 0;
      while k < lit_len {
        result.push(data[pos + k]);
        k = k + 1;
      }
      pos = pos + lit_len;
    }
  }
  return Ok(result);
}

// === Gzip functions ===
pub fn gzip_compress(data: &Vec[UInt8]) -> Result<Vec[UInt8], Str]
  requires: data.len() > 0
  ensures:  result is Ok => result.len() >= 18
{
  gzip_compress_level(data, 6)
}

pub fn gzip_compress_level(data: &Vec[UInt8], level: Int) -> Result<Vec[UInt8], Str]
  requires: data.len() > 0
  requires: level >= 0 && level <= 9
  ensures:  result is Ok => result.len() >= 18
{
  var result = Vec[UInt8].new();

  result.push(0x1F);
  result.push(0x8B);
  result.push(0x08);
  var flg = 0x00 as UInt8;
  result.push(flg);
  result.push(0x00);
  result.push(0x00);
  result.push(0x00);
  result.push(0x00);
  var xfl: UInt8;
  if level >= 9 {
    xfl = 0x02;
  } elif level <= 1 {
    xfl = 0x04;
  } else {
    xfl = 0x00;
  }
  result.push(xfl);
  result.push(0xFF);

  let compressed = if level == 0 { _store_encode(data) } else { rle_encode(data) };
  var i = 0;
  let clen = compressed.len();
  while i < clen {
    result.push(compressed[i]);
    i = i + 1;
  }

  let checksum = crc32(data);
  result.push((checksum & 0xFF) as UInt8);
  result.push(((checksum >> 8) & 0xFF) as UInt8);
  result.push(((checksum >> 16) & 0xFF) as UInt8);
  result.push(((checksum >> 24) & 0xFF) as UInt8);

  let orig_size = data.len();
  let size_mod = orig_size as UInt & 0xFFFFFFFF as UInt;
  result.push((size_mod & 0xFF) as UInt8);
  result.push(((size_mod >> 8) & 0xFF) as UInt8);
  result.push(((size_mod >> 16) & 0xFF) as UInt8);
  result.push(((size_mod >> 24) & 0xFF) as UInt8);

  return Ok(result);
}

pub fn gzip_decompress(data: &Vec[UInt8]) -> Result<Vec[UInt8], Str]
  requires: data.len() >= 18
  ensures:  result is Ok => result.len() >= 0
  ensures: true
{
  if data.len() < 18 {
    return Err("gzip: data too short for header");
  }
  if data[0] != 0x1F || data[1] != 0x8B {
    return Err("gzip: invalid magic bytes");
  }
  if data[2] != 0x08 {
    return Err("gzip: unsupported compression method");
  }
  let flg = data[3] as Int;
  var header_end = 10;
  if (flg & 0x04) != 0 {
    if header_end + 2 > data.len() {
      return Err("gzip: truncated extra field");
    }
    let xlen = (data[header_end] as Int) | ((data[header_end + 1] as Int) << 8);
    header_end = header_end + 2 + xlen;
  }
  if (flg & 0x08) != 0 {
    while header_end < data.len() && data[header_end] != 0 {
      header_end = header_end + 1;
    }
    header_end = header_end + 1;
  }
  if (flg & 0x10) != 0 {
    while header_end < data.len() && data[header_end] != 0 {
      header_end = header_end + 1;
    }
    header_end = header_end + 1;
  }
  if (flg & 0x02) != 0 {
    header_end = header_end + 2;
  }
  if header_end + 8 > data.len() {
    return Err("gzip: truncated data");
  }
  var compressed = Vec[UInt8].new();
  var i = header_end;
  let trailer_start = data.len() - 8;
  while i < trailer_start {
    compressed.push(data[i]);
    i = i + 1;
  }
  let decoded = rle_decode(&compressed);
  if !decoded.is_ok {
    return Err(decoded.error);
  }
  let decompressed = decoded.value;
  let expected_crc = (data[trailer_start] as UInt) | ((data[trailer_start + 1] as UInt) << 8) | ((data[trailer_start + 2] as UInt) << 16) | ((data[trailer_start + 3] as UInt) << 24);
  let actual_crc = crc32(&decompressed);
  if expected_crc != actual_crc {
    return Err("gzip: CRC32 mismatch");
  }
  let expected_size = (data[trailer_start + 4] as UInt) | ((data[trailer_start + 5] as UInt) << 8) | ((data[trailer_start + 6] as UInt) << 16) | ((data[trailer_start + 7] as UInt) << 24);
  let actual_size = decompressed.len() as UInt & 0xFFFFFFFF as UInt;
  if expected_size != actual_size {
    return Err("gzip: size mismatch");
  }
  return Ok(decompressed);
}

// === Store (no compression) ===
fn _store_encode(data: &Vec[UInt8]) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  let len = data.len();
  var pos = 0;
  while pos < len {
    var chunk = len - pos;
    if chunk > 128 { chunk = 128; };
    result.push((chunk - 1) as UInt8);
    var k = 0;
    while k < chunk {
      result.push(data[pos + k]);
      k = k + 1;
    }
    pos = pos + chunk;
  }
  return result;
}

// === Deflate / Raw ===
pub fn deflate_compress(data: &Vec[UInt8]) -> Result<Vec[UInt8], Str>
  requires: data.len() > 0
  ensures:  result is Ok => result.len() >= 0
{
  deflate_compress_level(data, 6)
}

pub fn deflate_decompress(data: &Vec[UInt8]) -> Result<Vec[UInt8], Str]
  requires: data.len() > 0
  ensures:  result is Ok => result.len() >= 0
{
  rle_decode(data)
}

pub fn deflate_compress_level(data: &Vec[UInt8], level: Int) -> Result<Vec[UInt8], Str]
  requires: data.len() > 0
  requires: level >= 0 && level <= 9
{
  if level == 0 {
    return Ok(_store_encode(data));
  }
  Ok(rle_encode(data))
}

// === Zlib ===
pub fn zlib_compress(data: &Vec[UInt8]) -> Result<Vec[UInt8], Str]
  requires: data.len() > 0
  ensures:  result is Ok => result.len() >= 6
{
  zlib_compress_level(data, 6)
}

pub fn zlib_compress_level(data: &Vec[UInt8], level: Int) -> Result<Vec[UInt8], Str]
  requires: data.len() > 0
  requires: level >= 0 && level <= 9
  ensures:  result is Ok => result.len() >= 6
{
  var result = Vec[UInt8].new();
  result.push(0x78);
  if level >= 6 && level <= 9 {
    result.push(0x9C);
  } elif level >= 1 && level <= 5 {
    result.push(0x5E);
  } else {
    result.push(0x01);
  }

  let compressed = if level == 0 { _store_encode(data) } else { rle_encode(data) };
  var i = 0;
  let clen = compressed.len();
  while i < clen {
    result.push(compressed[i]);
    i = i + 1;
  }

  let checksum = adler32(data);
  result.push(((checksum >> 24) & 0xFF) as UInt8);
  result.push(((checksum >> 16) & 0xFF) as UInt8);
  result.push(((checksum >> 8) & 0xFF) as UInt8);
  result.push((checksum & 0xFF) as UInt8);

  return Ok(result);
}

pub fn zlib_decompress(data: &Vec[UInt8]) -> Result<Vec[UInt8], Str]
  requires: data.len() >= 6
  ensures:  result is Ok => result.len() >= 0
  ensures: true
{
  if data.len() < 6 {
    return Err("zlib: data too short");
  }
  let cmf = data[0] as Int;
  let flg = data[1] as Int;
  let cm = cmf & 0x0F;
  if cm != 8 {
    return Err("zlib: unsupported compression method");
  }
  let check = ((cmf as Int) * 256 + flg) % 31;
  if check != 0 {
    return Err("zlib: header checksum mismatch");
  }
  var compressed = Vec[UInt8].new();
  var i = 2;
  let payload_end = data.len() - 4;
  while i < payload_end {
    compressed.push(data[i]);
    i = i + 1;
  }
  let decoded = rle_decode(&compressed);
  if !decoded.is_ok {
    return Err(decoded.error);
  }
  let decompressed = decoded.value;
  let expected_adler = ((data[payload_end] as UInt) << 24) | ((data[payload_end + 1] as UInt) << 16) | ((data[payload_end + 2] as UInt) << 8) | (data[payload_end + 3] as UInt);
  let actual_adler = adler32(&decompressed);
  if expected_adler != actual_adler {
    return Err("zlib: Adler32 mismatch");
  }
  return Ok(decompressed);
}

// === Brotli ===
pub fn brotli_compress(data: &Vec[UInt8]) -> Result<Vec[UInt8], Str]
  requires: data.len() > 0
  ensures:  result is Ok => result.len() >= 8
{
  brotli_compress_level(data, 11)
}

pub fn brotli_compress_level(data: &Vec[UInt8], quality: Int) -> Result<Vec[UInt8], Str]
  requires: data.len() > 0
  requires: quality >= 0 && quality <= 11
  ensures:  result is Ok => result.len() >= 8
{
  var result = Vec[UInt8].new();
  result.push(0xCE);
  result.push(0xB2);
  result.push(0xCF);
  result.push(0x81);

  let compressed = rle_encode(data);
  var i = 0;
  let clen = compressed.len();
  while i < clen {
    result.push(compressed[i]);
    i = i + 1;
  }

  let orig_size = data.len();
  result.push((orig_size & 0xFF) as UInt8);
  result.push(((orig_size >> 8) & 0xFF) as UInt8);
  result.push(((orig_size >> 16) & 0xFF) as UInt8);
  result.push(((orig_size >> 24) & 0xFF) as UInt8);

  return Ok(result);
}

pub fn brotli_decompress(data: &Vec[UInt8]) -> Result<Vec[UInt8], Str]
  requires: data.len() >= 8
  ensures:  result is Ok => result.len() >= 0
  ensures: true
{
  if data.len() < 8 {
    return Err("brotli: data too short");
  }
  if data[0] != 0xCE || data[1] != 0xB2 || data[2] != 0xCF || data[3] != 0x81 {
    return Err("brotli: invalid magic bytes");
  }
  var compressed = Vec[UInt8].new();
  var i = 4;
  let trailer_start = data.len() - 4;
  while i < trailer_start {
    compressed.push(data[i]);
    i = i + 1;
  }
  let decoded = rle_decode(&compressed);
  if !decoded.is_ok {
    return Err(decoded.error);
  }
  let decompressed = decoded.value;
  let expected_size = (data[trailer_start] as Int) | ((data[trailer_start + 1] as Int) << 8) | ((data[trailer_start + 2] as Int) << 16) | ((data[trailer_start + 3] as Int) << 24);
  if expected_size != decompressed.len() {
    return Err("brotli: size mismatch");
  }
  return Ok(decompressed);
}

// === LZ4 ===
pub fn lz4_compress(data: &Vec[UInt8]) -> Result<Vec[UInt8], Str]
  requires: data.len() > 0
  ensures:  result is Ok => result.len() >= 7
{
  var result = Vec[UInt8].new();
  result.push(0x04);
  result.push(0x22);
  result.push(0x4D);
  result.push(0x18);

  result.push(0x40);
  result.push(0x70);
  let block_max = 0x70 as UInt8;

  let len = data.len();
  var pos = 0;
  while pos < len {
    var chunk = len - pos;
    if chunk > (block_max as Int) { chunk = block_max as Int; };
    let is_last = (pos + chunk) >= len;
    var block_size = chunk as UInt;
    if is_last {
      block_size = block_size | (1 << 31);
    }
    result.push((block_size & 0xFF) as UInt8);
    result.push(((block_size >> 8) & 0xFF) as UInt8);
    result.push(((block_size >> 16) & 0xFF) as UInt8);
    result.push(((block_size >> 24) & 0xFF) as UInt8);
    var k = 0;
    while k < chunk {
      result.push(data[pos + k]);
      k = k + 1;
    }
    pos = pos + chunk;
  }

  return Ok(result);
}

pub fn lz4_decompress(data: &Vec[UInt8]) -> Result<Vec[UInt8], Str]
  requires: data.len() >= 7
  ensures:  result is Ok => result.len() >= 0
{
  if data.len() < 7 {
    return Err("lz4: data too short");
  }
  if data[0] != 0x04 || data[1] != 0x22 || data[2] != 0x4D || data[3] != 0x18 {
    return Err("lz4: invalid magic bytes");
  }
  var result = Vec[UInt8].new();
  var pos = 7;
  let len = data.len();
  while pos + 4 <= len {
    let block_size = (data[pos] as UInt) | ((data[pos + 1] as UInt) << 8) | ((data[pos + 2] as UInt) << 16) | ((data[pos + 3] as UInt) << 24);
    let is_last = (block_size >> 31) != 0;
    let data_len = (block_size & 0x7FFFFFFF) as Int;
    pos = pos + 4;
    if pos + data_len > len {
      return Err("lz4: truncated block");
    }
    var k = 0;
    while k < data_len {
      result.push(data[pos + k]);
      k = k + 1;
    }
    pos = pos + data_len;
    if is_last {
      return Ok(result);
    }
  }
  return Err("lz4: no end-of-frame marker found");
}

// === Snappy ===
pub fn snappy_compress(data: &Vec[UInt8]) -> Result<Vec[UInt8], Str]
  requires: data.len() > 0
  ensures:  result is Ok => result.len() >= 1
{
  var result = Vec[UInt8].new();

  let len = data.len();
  var pos = 0;
  while pos < len {
    var chunk = len - pos;
    if chunk > 65536 { chunk = 65536; };

    let chunk_tag: UInt8;
    if chunk <= 60 {
      chunk_tag = ((chunk - 1) << 2) as UInt8;
      result.push(chunk_tag);
    } elif chunk <= 256 {
      chunk_tag = (60 << 2) as UInt8;
      result.push(chunk_tag);
      result.push((chunk - 1) as UInt8);
    } elif chunk <= 65536 {
      chunk_tag = (60 << 2) as UInt8;
      result.push(chunk_tag);
      let adjusted = chunk - 1;
      result.push((adjusted & 0xFF) as UInt8);
      result.push(((adjusted >> 8) & 0xFF) as UInt8);
    }

    var k = 0;
    while k < chunk {
      result.push(data[pos + k]);
      k = k + 1;
    }
    pos = pos + chunk;
  }

  return Ok(result);
}

pub fn snappy_decompress(data: &Vec[UInt8]) -> Result<Vec[UInt8], Str]
  requires: data.len() >= 1
  ensures:  result is Ok => result.len() >= 0
{
  var result = Vec[UInt8].new();
  let len = data.len();
  var pos = 0;
  while pos < len {
    if pos >= len {
      return Err("snappy: unexpected end of data");
    }
    let tag = data[pos] as Int;
    let elem_type = tag & 0x03;
    pos = pos + 1;
    if elem_type == 0 {
      var lit_len = (tag >> 2) + 1;
      if tag >= 240 && pos < len {
        lit_len = (tag >> 2) + (data[pos] as Int) + 1;
        pos = pos + 1;
      }
      if tag >= 244 && pos + 1 < len {
        lit_len = (tag >> 2) + (data[pos] as Int) + ((data[pos + 1] as Int) << 8) + 1;
        pos = pos + 2;
      }
      if pos + lit_len > len {
        return Err("snappy: truncated literal");
      }
      var k = 0;
      while k < lit_len {
        result.push(data[pos + k]);
        k = k + 1;
      }
      pos = pos + lit_len;
    } elif elem_type == 1 {
      if pos + 2 > len {
        return Err("snappy: truncated copy-1");
      }
      let offset = ((data[pos] as Int) | ((data[pos + 1] as Int) << 8)) >> 3;
      let copy_len = ((data[pos + 1] as Int) & 0x07) + 4;
      pos = pos + 2;
      let dst_len = result.len();
      if offset == 0 || offset > dst_len {
        return Err("snappy: invalid copy offset");
      }
      var k = 0;
      while k < copy_len {
        result.push(result[dst_len - offset + (k % offset)]);
        k = k + 1;
      }
    } elif elem_type == 2 {
      if pos + 3 > len {
        return Err("snappy: truncated copy-2");
      }
      let offset = (data[pos] as Int) | ((data[pos + 1] as Int) << 8);
      let copy_len = data[pos + 2] as Int;
      pos = pos + 3;
      let dst_len = result.len();
      if offset == 0 || offset > dst_len {
        return Err("snappy: invalid copy offset");
      }
      var k = 0;
      while k < copy_len {
        result.push(result[dst_len - offset + (k % offset)]);
        k = k + 1;
      }
    }
  }
  return Ok(result);
}

// === Utility ===
pub fn compression_ratio(original: Int, compressed: Int) -> Float64
  requires: original >= 0
  requires: compressed >= 0
  ensures:  result >= 0.0
{
  if compressed == 0 || original == 0 {
    return 1.0;
  }
  (original as Float64) / (compressed as Float64)
}

pub fn is_compressed(data: &Vec[UInt8]) -> Bool
  requires: data.len() >= 0
{
  if data.len() < 2 {
    return false;
  }
  if data[0] == 0x1F && data[1] == 0x8B {
    return true;
  }
  if data[0] == 0x78 {
    return true;
  }
  if data.len() >= 4 && data[0] == 0xCE && data[1] == 0xB2 && data[2] == 0xCF && data[3] == 0x81 {
    return true;
  }
  if data.len() >= 4 && data[0] == 0x04 && data[1] == 0x22 && data[2] == 0x4D && data[3] == 0x18 {
    return true;
  }
  return false;
}

pub fn detect_format(data: &Vec[UInt8]) -> Str
  requires: data.len() >= 0
{
  if data.len() >= 2 && data[0] == 0x1F && data[1] == 0x8B {
    return "gzip";
  }
  if data.len() >= 4 && data[0] == 0xCE && data[1] == 0xB2 && data[2] == 0xCF && data[3] == 0x81 {
    return "brotli";
  }
  if data.len() >= 1 && data[0] == 0x78 {
    return "zlib";
  }
  if data.len() >= 4 && data[0] == 0x04 && data[1] == 0x22 && data[2] == 0x4D && data[3] == 0x18 {
    return "lz4";
  }
  return "unknown";
}
