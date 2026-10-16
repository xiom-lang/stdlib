// XIOM - Compression: neutral CRC-32
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.compress.crc32

// ============================================================================
// Neutral CRC-32 (IEEE 802.3, reflected polynomial 0xEDB88320) with no
// container coupling. The zip-class consumers (docx/pptx/xlsx; packages
// wishlist row 24 / the 2026-10-02 relay) need the checksum as a plain
// `Int`, little-endian-push friendly, without importing the gzip module.
// `xiom.compress.gzip.gzip_crc32` keeps its UInt32-returning surface.
//
// Table-free bitwise form: module-level tables are mis-materialized by this
// toolchain (see gzip.xi), so all state stays in locals. Complexity O(n*8).
// ============================================================================

/// Compute the CRC-32 checksum (reflected 0xEDB88320) of `data` as an Int.
/// Known answer: crc32("123456789") == 0xCBF43926 (3421780262). O(n*8).
pub fn crc32(data: &Vec[UInt8]) -> Int
  ensures: (data.len() == 0) => (result == 0)
{
  var crc = 0xFFFFFFFF as UInt;
  var len = data.len();
  var i = 0;
  while i < len {
    crc = crc ^ (data[i] as UInt);
    var j = 0;
    while j < 8 {
      if (crc & 1) == 1 {
        crc = (crc >> 1) ^ (0xEDB88320 as UInt);
      } else {
        crc = crc >> 1;
      };
      j = j + 1;
    };
    i = i + 1;
  };
  var v = crc ^ (0xFFFFFFFF as UInt);
  return v as Int;
}
