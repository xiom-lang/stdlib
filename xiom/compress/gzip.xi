// XIOM - Compression: Gzip
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.compress.gzip

// Depends on: xiom.string

use xiom.compress.deflate;
use xiom.io;

// ============================================================================
// Gzip container format (RFC 1952 shape): 10-byte header, DEFLATE payload
// (from xiom.compress.deflate), CRC32 trailer (4 bytes LE), ISIZE trailer
// (4 bytes LE). Header flags FEXTRA (0x04), FNAME (0x08), FCOMMENT (0x10)
// and FHCRC (0x02) are parsed on decompress; gzip_header_new emits a bare
// header with all flags clear.
//
// Round-trip correctness within XIOM is the goal; the payload is the
// DEFLATE-shaped stream above, so gzip_decompress calls deflate_decompress.
// Complexity: O(n) checksums, O(n * window) payload.
// ============================================================================

// CRC-32 (IEEE, reflected 0xEDB88320) computed BITWISE with no lookup table.
//
// BUG FIX (2026-08-25): this used a lazily-initialized module-level
// [256]UInt table. Module-level arrays are mis-materialized by the current
// compiler (undersized backing store): the init loop silently overflowed the
// heap on every call -- surviving for inputs <= ~4095 bytes and hitting
// unmapped memory (AV) beyond that (probes crc_*.xi / p_crc_local.xi; also
// reads through the table returned all zeros, so tags were wrong anyway).
// The bitwise form keeps all state in locals and is exact. If throughput
// ever matters, bind a C crc32 in runtime/ instead of restoring the table.
fn _gzip_crc32_impl(data: &Vec[UInt8]) -> UInt {
  var crc = 0xFFFFFFFF as UInt;
  var len = data.len();
  var i = 0;
  while i < len {
    crc = crc ^ (data[i] as UInt);
    var j = 0;
    while j < 8 {
      if (crc & 1) == 1 {
        crc = (crc >> 1) ^ 0xEDB88320 as UInt;
      } else {
        crc = crc >> 1;
      };
      j = j + 1;
    }
    i = i + 1;
  }
  return crc ^ 0xFFFFFFFF as UInt;
}

/// Compute the CRC-32 checksum (IEEE 802.3 polynomial) of `data`. O(n).
pub fn gzip_crc32(data: &Vec[UInt8]) -> UInt32 {
  var c = _gzip_crc32_impl(data);
  return c as UInt32;
}

/// Build a bare gzip header: magic (1F 8B), method (08), flags (00), MTIME
/// (`mtime`, LE, may be 0), XFL (00) and OS (`os`, masked to 8 bits; use 255
/// for unknown, 3 for Unix). Returns 10 bytes.
pub fn gzip_header_new(mtime: Int, os: Int) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  result.push(0x1F);
  result.push(0x8B);
  result.push(0x08);
  result.push(0x00);
  result.push((mtime & 0xFF) as UInt8);
  result.push(((mtime >> 8) & 0xFF) as UInt8);
  result.push(((mtime >> 16) & 0xFF) as UInt8);
  result.push(((mtime >> 24) & 0xFF) as UInt8);
  result.push(0x00);
  result.push((os & 0xFF) as UInt8);
  return result;
}

/// Wrap `data` in a gzip stream: header (mtime 0, OS 255) + DEFLATE payload
/// + CRC32 trailer + ISIZE trailer.
pub fn gzip_compress(data: &Vec[UInt8]) -> Vec[UInt8] {
  var result = gzip_header_new(0, 255);
  var payload = deflate.deflate_compress(data);
  var i = 0;
  var plen = payload.len();
  while i < plen {
    result.push(payload[i]);
    i = i + 1;
  }
  var crc = _gzip_crc32_impl(data);
  result.push((crc & 0xFF) as UInt8);
  result.push(((crc >> 8) & 0xFF) as UInt8);
  result.push(((crc >> 16) & 0xFF) as UInt8);
  result.push(((crc >> 24) & 0xFF) as UInt8);
  var size = data.len() as UInt;
  result.push((size & 0xFF) as UInt8);
  result.push(((size >> 8) & 0xFF) as UInt8);
  result.push(((size >> 16) & 0xFF) as UInt8);
  result.push(((size >> 24) & 0xFF) as UInt8);
  return result;
}

// Default output ceiling for uncapped decompression (1 GiB); enforced in
// the deflate expander stages before allocation grows. Capped variant
// accepts an explicit limit -- see lz77.xi for the convention.
const _GZIP_DEFAULT_CAP: Int = 1073741824;

/// Unwrap and validate a gzip stream. Parses the optional header fields,
/// decompresses the payload, and verifies the CRC32 and ISIZE trailer values.
/// Returns Err on any mismatch or malformed input.
pub fn gzip_decompress(data: &Vec[UInt8]) -> Result[Vec[UInt8], Str] {
  return gzip_decompress_capped(data, _GZIP_DEFAULT_CAP);
}

/// Decompress with a hard ceiling on output size (decompression-bomb
/// guard). The header's declared ISIZE is rejected up-front when it
/// exceeds the cap; the payload cap is enforced inside the deflate stages.
pub fn gzip_decompress_capped(data: &Vec[UInt8], max_out: Int) -> Result[Vec[UInt8], Str] {
  var len = data.len();
  if len < 18 {
    return Err("gzip: data too short for header");
  };
  if data[0] != 0x1F || data[1] != 0x8B {
    return Err("gzip: invalid magic bytes");
  };
  if data[2] != 0x08 {
    return Err("gzip: unsupported compression method");
  };
  // Early rejection on the DECLARED size; the deflate stages still enforce
  // the real bound (a lying ISIZE must not allocate past the cap either).
  var isize_pos = len - 4;
  var ds0 = data[isize_pos] as Int;
  var ds1 = data[isize_pos + 1] as Int;
  var ds2 = data[isize_pos + 2] as Int;
  var ds3 = data[isize_pos + 3] as Int;
  var declared = ds0 | (ds1 << 8) | (ds2 << 16) | (ds3 << 24);
  if declared > max_out {
    return Err("gzip: declared output exceeds cap");
  };
  var flg = data[3] as Int;
  var header_end = 10;
  if (flg & 0x04) != 0 {
    if header_end + 2 > len {
      return Err("gzip: truncated extra field");
    };
    var x0 = data[header_end] as Int;
    var x1 = data[header_end + 1] as Int;
    var xlen = x0 | (x1 << 8);
    header_end = header_end + 2 + xlen;
  };
  if (flg & 0x08) != 0 {
    while header_end < len {
      var fname_b = data[header_end];
      if fname_b == 0 {
        break;
      };
      header_end = header_end + 1;
    }
    header_end = header_end + 1;
  };
  if (flg & 0x10) != 0 {
    while header_end < len {
      var fcomm_b = data[header_end];
      if fcomm_b == 0 {
        break;
      };
      header_end = header_end + 1;
    }
    header_end = header_end + 1;
  };
  if (flg & 0x02) != 0 {
    header_end = header_end + 2;
  };
  if header_end + 8 > len {
    return Err("gzip: truncated data");
  };
  var trailer_start = len - 8;
  var payload = Vec[UInt8].new();
  var i = header_end;
  while i < trailer_start {
    payload.push(data[i]);
    i = i + 1;
  }
  var decoded = deflate.deflate_decompress_capped(&payload, max_out);
  var decompressed = Vec[UInt8].new();
  match decoded {
    Ok(v) => { decompressed = v; };
    Err(e) => { return Err(e); };
  }
  var c0 = data[trailer_start] as UInt;
  var c1 = data[trailer_start + 1] as UInt;
  var c2 = data[trailer_start + 2] as UInt;
  var c3 = data[trailer_start + 3] as UInt;
  var expected_crc = c0 | (c1 << 8) | (c2 << 16) | (c3 << 24);
  var actual_crc = _gzip_crc32_impl(&decompressed);
  if expected_crc != actual_crc {
    return Err("gzip: CRC32 mismatch");
  };
  var s0 = data[trailer_start + 4] as UInt;
  var s1 = data[trailer_start + 5] as UInt;
  var s2 = data[trailer_start + 6] as UInt;
  var s3 = data[trailer_start + 7] as UInt;
  var expected_size = s0 | (s1 << 8) | (s2 << 16) | (s3 << 24);
  var actual_size = decompressed.len() as UInt;
  if expected_size != actual_size {
    return Err("gzip: size mismatch");
  };
  return Ok(decompressed);
}

/// Gzip a file to `<path>.gz`. Returns Err when the source cannot be read or
/// the target cannot be written.
pub fn gzip_compress_file(path: Str) -> Result[Unit, Str] {
  var bytes = io.read_file_bytes(path);
  match bytes {
    Ok(b) => {
      var compressed = gzip_compress(&b);
      var target = path + ".gz";
      var written = io.write_file_bytes(target, &compressed);
      match written {
        Ok(_) => { return Ok(()); };
        Err(e) => { return Err(e.message); };
      }
    };
    Err(e) => { return Err(e.message); };
  }
}

/// Gunzip a file into raw bytes. Returns Err on read failures or invalid
/// gzip data.
pub fn gzip_decompress_file(path: Str) -> Result[Vec[UInt8], Str] {
  var bytes = io.read_file_bytes(path);
  match bytes {
    Ok(b) => { return gzip_decompress(&b); };
    Err(e) => { return Err(e.message); };
  }
}

/// Sanity-check magic, method, and the minimum trailer footprint. O(1).
pub fn gzip_validate(data: &Vec[UInt8]) -> Bool {
  var len = data.len();
  if len < 18 {
    return false;
  };
  if data[0] != 0x1F || data[1] != 0x8B {
    return false;
  };
  if data[2] != 0x08 {
    return false;
  };
  return true;
}
