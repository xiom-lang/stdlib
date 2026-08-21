// XIOM -- Hashing: CRC-64 / CRC-32C / CRC-16-CCITT and classic checksums
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.hash.crc

// CRC-64 (ECMA poly 0x42F0E1EBA9EA3693), CRC-32C (Castagnoli) and
// CRC-16/CCITT plus the classic BSD/SysV/Internet checksums.
//
// NOTE: the CRC-64 lookup tables are built at runtime by _crc64_table_refl()
// and _crc64_table_msb() using the standard bitwise construction
// (for each i: crc = i; 8 times: crc = (crc >> 1) ^ poly if crc & 1).
// Module-level const arrays are mis-materialized by the current compiler
// (same limitation noted in xiom.crypto for _SHA512_K), so they cannot be
// precomputed as constants.

const _CRC64_POLY: UInt64 = 0x42F0E1EBA9EA3693;
const _CRC64_POLY_REFL: UInt64 = 0xC96C5795D7870F42;

/// Logical (unsigned) right shift of a UInt64 by k bits.
fn _u64_shr(x: UInt64, k: Int) -> UInt64 {
  if k <= 0 { return x; }
  if k >= 64 { var z: UInt64 = 0; return z; }
  var mask: UInt64 = ((1 as UInt64) << (64 - k)) - 1;
  return (x >> k) & mask;
}

/// Runtime-builds the reflected (LSB-first) CRC-64 table.
fn _crc64_table_refl() -> [256]UInt64 {
  var t: [256]UInt64;
  var i = 0;
  while i < 256 {
    var crc: UInt64 = i as UInt64;
    var j = 0;
    while j < 8 {
      if (crc & 1) == 1 {
        crc = _u64_shr(crc, 1) ^ _CRC64_POLY_REFL;
      } else {
        crc = _u64_shr(crc, 1);
      }
      j = j + 1;
    }
    t[i] = crc;
    i = i + 1;
  }
  return t;
}

/// Runtime-builds the MSB-first CRC-64 table.
fn _crc64_table_msb() -> [256]UInt64 {
  var t: [256]UInt64;
  var i = 0;
  while i < 256 {
    var crc = (i as UInt64) << 56;
    var j = 0;
    while j < 8 {
      if (crc & 0x8000000000000000) == 0x8000000000000000 {
        crc = (crc << 1) ^ _CRC64_POLY;
      } else {
        crc = crc << 1;
      }
      j = j + 1;
    }
    t[i] = crc;
    i = i + 1;
  }
  return t;
}

/// CRC-64/ECMA of a byte string (reflected variant, init/xorout all-ones).
/// Check: crc64_ecma("123456789") == 0x995DC9BBDF1939FA.
pub fn crc64_ecma(data: &Vec[UInt8]) -> UInt64 {
  var t = _crc64_table_refl();
  var crc: UInt64 = 0xFFFFFFFFFFFFFFFF;
  var i = 0;
  while i < data.len() {
    var byte: UInt64 = data[i] as UInt64;
    var idx = (crc ^ byte) & 0xFF;
    crc = _u64_shr(crc, 8) ^ t[idx as Int];
    i = i + 1;
  }
  return crc ^ 0xFFFFFFFFFFFFFFFF;
}

/// CRC-64/WE of a byte string (non-reflected, init/xorout all-ones).
/// Check: crc64_we("123456789") == 0x62EC59E3F1A4F00A.
pub fn crc64_we(data: &Vec[UInt8]) -> UInt64 {
  var t = _crc64_table_msb();
  var crc: UInt64 = 0xFFFFFFFFFFFFFFFF;
  var i = 0;
  while i < data.len() {
    var byte: UInt64 = data[i] as UInt64;
    var top = _u64_shr(crc, 56) & 0xFF;
    var idx = (top ^ byte) & 0xFF;
    crc = (crc << 8) ^ t[idx as Int];
    i = i + 1;
  }
  return crc ^ 0xFFFFFFFFFFFFFFFF;
}

/// CRC-32C (Castagnoli) of a byte string.
/// Check: crc32c("123456789") == 0xE3069283.
pub fn crc32c(data: &Vec[UInt8]) -> UInt32 {
  var crc: UInt64 = 0xFFFFFFFF;
  var i = 0;
  while i < data.len() {
    var byte: UInt64 = data[i] as UInt64;
    crc = crc ^ byte;
    var j = 0;
    while j < 8 {
      if (crc & 1) == 1 {
        crc = (crc >> 1) ^ 0x82F63B78;
      } else {
        crc = crc >> 1;
      }
      crc = crc & 0xFFFFFFFF;
      j = j + 1;
    }
    i = i + 1;
  }
  return ((crc ^ 0xFFFFFFFF) & 0xFFFFFFFF) as UInt32;
}

/// CRC-16/CCITT (FALSE) of a byte string.
/// Check: crc16_ccitt("123456789") == 0x29B1.
pub fn crc16_ccitt(data: &Vec[UInt8]) -> UInt32 {
  var crc: UInt64 = 0xFFFF;
  var i = 0;
  while i < data.len() {
    var byte: UInt64 = data[i] as UInt64;
    crc = (crc ^ (byte << 8)) & 0xFFFF;
    var j = 0;
    while j < 8 {
      if (crc & 0x8000) == 0x8000 {
        crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
      } else {
        crc = (crc << 1) & 0xFFFF;
      }
      j = j + 1;
    }
    i = i + 1;
  }
  return (crc & 0xFFFF) as UInt32;
}

/// BSD sum: 16-bit checksum = rotate-right-1 + byte per byte.
pub fn checksum_bsd(data: &Vec[UInt8]) -> UInt32 {
  var sum: UInt64 = 0;
  var i = 0;
  while i < data.len() {
    var byte: UInt64 = data[i] as UInt64;
    sum = ((sum >> 1) | ((sum & 1) << 15)) & 0xFFFF;
    sum = (sum + byte) & 0xFFFF;
    i = i + 1;
  }
  return sum as UInt32;
}

/// SysV sum: 16-bit accumulator with a rotate-right-1 after each byte.
pub fn checksum_sysv(data: &Vec[UInt8]) -> UInt32 {
  var sum: UInt64 = 0;
  var i = 0;
  while i < data.len() {
    var byte: UInt64 = data[i] as UInt64;
    sum = (sum + byte) & 0xFFFF;
    sum = ((sum >> 1) | ((sum & 1) << 15)) & 0xFFFF;
    i = i + 1;
  }
  return sum as UInt32;
}

/// RFC 1071 Internet checksum: 16-bit one's complement of the sum of 16-bit
/// big-endian words.
pub fn checksum_internet(data: &Vec[UInt8]) -> UInt32 {
  var total: UInt64 = 0;
  var i = 0;
  let len = data.len();
  while i + 1 < len {
    var hi: UInt64 = data[i] as UInt64;
    var lo: UInt64 = data[i + 1] as UInt64;
    total = total + (hi << 8) + lo;
    i = i + 2;
  }
  if i < len {
    var hi: UInt64 = data[i] as UInt64;
    total = total + (hi << 8);
  }
  total = (total & 0xFFFF) + _u64_shr(total, 16);
  total = (total & 0xFFFF) + _u64_shr(total, 16);
  return ((0xFFFF - (total & 0xFFFF)) & 0xFFFF) as UInt32;
}

/// Adler-32 (RFC 1950). Verified against a clang-built reference
/// (2026-08-11): "" -> 0x00000001, "a" -> 0x00620062, "abc" -> 0x024d0127,
/// "Wikipedia" -> 0x11e60398 (matches the Wikipedia article).
pub fn adler32(data: &Vec[UInt8]) -> UInt32 {
  var a: Int = 1;
  var b: Int = 0;
  var i: Int = 0;
  let len = data.len();
  while i < len {
    a = (a + (data[i] as Int)) % 65521;
    b = (b + a) % 65521;
    i = i + 1;
  }
  return ((b << 16) | a) as UInt32;
}
