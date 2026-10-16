// p_wave168_shapes.xi -- wave 168 locks: Keccak-256 (wishlist row 25) and
// FNV-1a over Str + masked combine (row 34); ZIP container read/write
// (row 22, xiom.compress.zip).
//
// Keccak-256 provenance: all digests cross-checked 2026-10-16 against
// pycryptodome 3.24.1 Crypto.Hash.keccak digest_bits=256 (the 0x01-padding
// original-Keccak/Ethereum variant, NOT FIPS 202 SHA3-256). The empty and
// "abc" answers are the well-known Ethereum keccak256 values. The 136/137/
// 1000-byte messages carry bytes (i*7 + 3) mod 256 (rate-boundary, one-past-
// boundary and multi-block paths).
//
// FNV provenance: fnv1a32/fnv1a64 values computed with the reference FNV
// algorithm (offset 0x811C9DC5 / 0xCBF29CE484222325, prime 0x01000193 /
// 0x100000001B3) and cross-checked in Python; the Str variants must be
// byte-exact with the Vec[UInt8] variants of the same input.
//
// ZIP fixture provenance: the 441-byte archive embedded in row 10 was
// produced 2026-10-16 by Python 3.7.9 zipfile (ZipInfo, fixed 1980-01-01
// timestamps) with entries hello.txt (stored, "hello zip world\n"),
// data.bin (deflated, "compressible line\n" x8), empty.txt (stored, ""),
// empty_d.txt (deflated, ""). The reverse direction was checked the same
// day: archives produced by the xiom.compress.zip writer were read back
// by python zipfile (testzip() clean, contents byte-equal).
//
// Rows (0 = all hold):
//  1 -- keccak256("") KAT: c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470
//  2 -- keccak256("abc") KAT: 4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45
//  3 -- keccak256 136B pattern (exactly one rate block)
//  4 -- keccak256 137B pattern (block + 1-byte tail; tail-pad boundary)
//  5 -- keccak256 1000B pattern (multi-block) + digest length 32, hex 64
//  6 -- fnv1a_str("") offset basis; "hello"/"abc"/fox vectors
//  7 -- fnv1a_str byte-parity with fnv1a32 over the same bytes
//  8 -- fnv1a64_str vectors + byte-parity with fnv1a64
//  9 -- fnv1a_combine_masked: bits<=0 -> 0; bits 16/1 truncate; bits 64 == combine_hashes; order-dependent
// 10 -- zip: python fixture extracts (names, contents; stored + deflate + empty entries)
// 11 -- zip: fixture entry metadata (methods/sizes/CRCs) + zip_read hit/miss
// 12 -- zip: corrupted stored payload -> Err (CRC32 mismatch path)
// 13 -- zip: writer round-trip (stored + nested deflate + repeat-rich deflate + empty deflate)
// 14 -- zip: empty archive is 22 bytes; reader lists/extracts zero entries
// 15 -- zip: zip_list order on the fixture; zip_read on the written archive
// 16 -- zip: rejection rows (not-a-zip, truncated, multi-disk, unknown method, zip64 marker)
// 17 -- zip: writer output structural lock (sigs/fields/offsets) + writer rejects (empty name, method 3)
// Setup failures use 20+.

module p_wave168_shapes

use xiom.crypto.keccak;
use xiom.hash;
use xiom.compress.zip;
use xiom.compress.crc32;
use xiom.encoding.hex;

fn bytes_pattern(n: Int) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 0;
  while i < n {
    var b = (i * 7 + 3) % 256;
    v.push(b as UInt8);
    i = i + 1;
  }
  return v;
}

fn _raw_u8(base: *UInt8, i: Int) -> UInt8
  requires: true  // raw byte read; callers bound i against len (T007)
{
  unsafe { return *(base + i); }
}

fn ascii_bytes(s: Str) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 0;
  let len = s.len();
  let base = s.c_str();
  while i < len {
    v.push(_raw_u8(base, i));
    i = i + 1;
  }
  return v;
}

fn hex_of(data: &Vec[UInt8]) -> Str {
  return hex.hex_encode(data);
}

fn copy_vec(v: &Vec[UInt8]) -> Vec[UInt8] {
  var out = Vec[UInt8].new();
  var i = 0;
  while i < v.len() {
    out.push(v[i]);
    i = i + 1;
  }
  return out;
}

fn copy_prefix(v: &Vec[UInt8], n: Int) -> Vec[UInt8] {
  var out = Vec[UInt8].new();
  var i = 0;
  while i < n && i < v.len() {
    out.push(v[i]);
    i = i + 1;
  }
  return out;
}

fn _rd_u16_at(data: &Vec[UInt8], pos: Int) -> Int {
  return (data[pos] as Int) | ((data[pos + 1] as Int) << 8);
}

fn _rd_u32_at(data: &Vec[UInt8], pos: Int) -> Int {
  var v: Int = data[pos] as Int;
  v = v | ((data[pos + 1] as Int) << 8);
  v = v | ((data[pos + 2] as Int) << 16);
  v = v | ((data[pos + 3] as Int) << 24);
  return v;
}

fn main() -> Int {
  // Row 1: keccak256("") KAT.
  var empty = Vec[UInt8].new();
  var h_empty = keccak.keccak256_hex(&empty);
  if h_empty != "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470" { return 1; }

  // Row 2: keccak256("abc") KAT.
  var abc = ascii_bytes("abc");
  var h_abc = keccak.keccak256_hex(&abc);
  if h_abc != "4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45" { return 2; }

  // Row 3: exactly one rate block (136 bytes).
  var m136 = bytes_pattern(136);
  let h136 = keccak.keccak256_hex(&m136);
  if h136 != "742061bcad767ed4c4f5883b1dcb1aad11afdcc140dc469d953759b127b9f9ed" { return 3; }

  // Row 4: one block plus a one-byte tail.
  var m137 = bytes_pattern(137);
  let h137 = keccak.keccak256_hex(&m137);
  if h137 != "e3371f61e770abf254c34239c3b0099ad90594507415bc81dd0a10b9692bbf2a" { return 4; }

  // Row 5: multi-block + shape.
  var m1000 = bytes_pattern(1000);
  let h1000 = keccak.keccak256_hex(&m1000);
  if h1000 != "80cdc8dd52cbb3dbaea8f383209893fa2bb52efbd5aedbb4b26dcfe307fcdc9b" { return 5; }
  let d1000 = keccak.keccak256(&m1000);
  if d1000.len() != 32 { return 5; }
  if h1000.len() != 64 { return 5; }

  // Row 6: FNV-1a 32 over Str.
  if hash.fnv1a_str("") != 0x811C9DC5 { return 6; }
  if hash.fnv1a_str("hello") != 0x4F9F2CAB { return 6; }
  if hash.fnv1a_str("abc") != 0x1A47E90B { return 6; }
  if hash.fnv1a_str("the quick brown fox jumps over the lazy dog") != 0xEF693FF0 { return 6; }

  // Row 7: Str variant is byte-exact with the Vec variant.
  var hello_b = ascii_bytes("hello");
  let v32 = hash.fnv1a32(&hello_b);
  let s32 = hash.fnv1a_str("hello");
  if v32 != s32 { return 7; }
  var abc_b = ascii_bytes("abc");
  let v32b = hash.fnv1a32(&abc_b);
  let s32b = hash.fnv1a_str("abc");
  if v32b != s32b { return 7; }
  let v32c = hash.fnv1a32(&empty);
  let s32c = hash.fnv1a_str("");
  if v32c != s32c { return 7; }

  // Row 8: FNV-1a 64 over Str.
  if hash.fnv1a64_str("") != 0xCBF29CE484222325 { return 8; }
  if hash.fnv1a64_str("hello") != 0xA430D84680AABD0B { return 8; }
  if hash.fnv1a64_str("abc") != 0xE71FA2190541574B { return 8; }
  var fox_b = ascii_bytes("the quick brown fox jumps over the lazy dog");
  let v64 = hash.fnv1a64(&fox_b);
  let s64 = hash.fnv1a64_str("the quick brown fox jumps over the lazy dog");
  if v64 != s64 { return 8; }

  // Row 9: masked combine.
  let a = 0x12345678;
  let b = 0x0BADF00D;
  let full = hash.fnv1a_combine_masked(a, b, 64);
  let reference = hash.combine_hashes(a, b);
  if full != reference { return 9; }
  let m16 = hash.fnv1a_combine_masked(a, b, 16);
  if m16 < 0 || m16 >= 65536 { return 9; }
  let m16_ref = reference & 0xFFFF;
  if m16 != m16_ref { return 9; }
  let m1 = hash.fnv1a_combine_masked(a, b, 1);
  let m1_ref = reference & 1;
  if m1 != m1_ref { return 9; }
  if hash.fnv1a_combine_masked(a, b, 0) != 0 { return 9; }
  if hash.fnv1a_combine_masked(a, b, 0 - 3) != 0 { return 9; }
  let swapped = hash.fnv1a_combine_masked(b, a, 64);
  if swapped == full { return 9; }

  // ===================== zip (row 22) =====================

  // Python zipfile fixture (441 bytes; provenance in the header).
  let fixture_hex = "504b03041400000000000000210053e9d72710000000100000000900000068656c6c6f2e74787468656c6c6f207a697020776f726c640a504b030414000000080000002100d334813c170000009000000008000000646174612e62696e4bcecf2d284a2d2ece4cca4955c8c9cc4be54a1e501100504b03041400000000000000210000000000000000000000000009000000656d7074792e747874504b0304140000000800000021000000000002000000000000000b000000656d7074795f642e7478740300504b010214001400000000000000210053e9d727100000001000000009000000000000000000000080010000000068656c6c6f2e747874504b0102140014000000080000002100d334813c1700000090000000080000000000000000000000800137000000646174612e62696e504b0102140014000000000000002100000000000000000000000000090000000000000000000000800174000000656d7074792e747874504b01021400140000000800000021000000000002000000000000000b000000000000000000000080019b000000656d7074795f642e747874504b05060000000004000400dd000000c60000000000";
  var fixture_r = hex.hex_decode(fixture_hex);
  var fixture = Vec[UInt8].new();
  match fixture_r {
    Ok(v) => { fixture = v; },
    Err(_) => { return 20; },
  }
  if fixture.len() != 441 { return 20; }

  // Row 10: fixture extracts; names and contents in archive order.
  var all = zip.zip_extract(&fixture);
  var line_hex = "636f6d707265737369626c65206c696e650a";
  var expect_lines = "";
  var rep_l = 0;
  while rep_l < 8 {
    expect_lines = expect_lines + line_hex;
    rep_l = rep_l + 1;
  };
  match all {
    Ok(entries) => {
      if entries.len() != 4 { return 10; }
      if entries[0].name != "hello.txt" { return 10; }
      if entries[1].name != "data.bin" { return 10; }
      if entries[2].name != "empty.txt" { return 10; }
      if entries[3].name != "empty_d.txt" { return 10; }
      let hello_hex = hex_of(&entries[0].data);
      if hello_hex != "68656c6c6f207a697020776f726c640a" { return 10; }
      let data_hex = hex_of(&entries[1].data);
      if data_hex != expect_lines { return 10; }
      if entries[2].data.len() != 0 { return 10; }
      if entries[3].data.len() != 0 { return 10; }
    },
    Err(_) => { return 10; },
  }

  // Row 11: metadata + zip_read hit/miss.
  match all {
    Ok(entries) => {
      if entries[0].method != 0 { return 11; }
      if entries[1].method != 8 { return 11; }
      if entries[2].method != 0 { return 11; }
      if entries[3].method != 8 { return 11; }
      if entries[0].uncompressed_size != 16 { return 11; }
      if entries[1].uncompressed_size != 144 { return 11; }
      if entries[1].compressed_size != 23 { return 11; }
      if entries[0].crc != 0x27D7E953 { return 11; }
      if entries[1].crc != 0x3C8134D3 { return 11; }
      if entries[2].crc != 0 { return 11; }
    },
    Err(_) => { return 11; },
  }
  var rd1 = zip.zip_read(&fixture, "data.bin");
  match rd1 {
    Ok(v) => {
      let rd1_hex = hex_of(&v);
      if rd1_hex != expect_lines { return 11; }
    },
    Err(_) => { return 11; },
  }
  var rd2 = zip.zip_read(&fixture, "empty_d.txt");
  match rd2 {
    Ok(v) => { if v.len() != 0 { return 11; } },
    Err(_) => { return 11; },
  }
  var rd3 = zip.zip_read(&fixture, "missing.txt");
  match rd3 {
    Ok(_) => { return 11; },
    Err(_) => {},
  }

  // Row 12: corrupt one stored payload byte (hello.txt data at 30 + 9 = 39).
  var corrupted = copy_vec(&fixture);
  corrupted[39] = ((corrupted[39] as Int) ^ 0x01) as UInt8;
  var cr = zip.zip_extract(&corrupted);
  match cr {
    Ok(_) => { return 12; },
    Err(_) => {},
  }

  // Row 13: writer round-trip through our own reader.
  var zw = zip.zip_writer_new();
  var stored_data = ascii_bytes("stored payload");
  var ra = zip.zip_writer_add(&mut zw, "stored.txt", &stored_data, zip.ZIP_METHOD_STORED);
  match ra {
    Ok(_) => {},
    Err(_) => { return 13; },
  }
  var nested = ascii_bytes("nested content here\n");
  var rb = zip.zip_writer_add(&mut zw, "dir/nested.txt", &nested, zip.ZIP_METHOD_DEFLATE);
  match rb {
    Ok(_) => {},
    Err(_) => { return 13; },
  }
  var line = ascii_bytes("compressible line\n");
  var big = Vec[UInt8].new();
  var rep_b = 0;
  while rep_b < 64 {
    var k = 0;
    while k < line.len() {
      big.push(line[k]);
      k = k + 1;
    }
    rep_b = rep_b + 1;
  };
  var rc = zip.zip_writer_add(&mut zw, "big.txt", &big, zip.ZIP_METHOD_DEFLATE);
  match rc {
    Ok(_) => {},
    Err(_) => { return 13; },
  }
  var emp = Vec[UInt8].new();
  var rdw = zip.zip_writer_add(&mut zw, "empty.txt", &emp, zip.ZIP_METHOD_DEFLATE);
  match rdw {
    Ok(_) => {},
    Err(_) => { return 13; },
  }
  var fin = zip.zip_writer_finish(&mut zw);
  var archive = Vec[UInt8].new();
  match fin {
    Ok(v) => { archive = v; },
    Err(_) => { return 13; },
  }
  var expect_big = "";
  var rep_x = 0;
  while rep_x < 64 {
    expect_big = expect_big + line_hex;
    rep_x = rep_x + 1;
  };
  var back = zip.zip_extract(&archive);
  match back {
    Ok(entries) => {
      if entries.len() != 4 { return 13; }
      if entries[0].name != "stored.txt" { return 13; }
      if entries[1].name != "dir/nested.txt" { return 13; }
      if entries[2].name != "big.txt" { return 13; }
      if entries[3].name != "empty.txt" { return 13; }
      if entries[0].method != 0 { return 13; }
      if entries[1].method != 8 { return 13; }
      if entries[2].method != 8 { return 13; }
      if entries[3].method != 8 { return 13; }
      let s_hex = hex_of(&entries[1].data);
      if s_hex != "6e657374656420636f6e74656e7420686572650a" { return 13; }
      let b_hex = hex_of(&entries[2].data);
      if b_hex != expect_big { return 13; }
      if entries[3].data.len() != 0 { return 13; }
      if entries[0].crc != crc32.crc32(&stored_data) { return 13; }
      if entries[2].crc != crc32.crc32(&big) { return 13; }
    },
    Err(_) => { return 13; },
  }

  // Row 14: empty archive.
  var zw2 = zip.zip_writer_new();
  var fin2 = zip.zip_writer_finish(&mut zw2);
  match fin2 {
    Ok(v) => {
      if v.len() != 22 { return 14; }
      var e2 = zip.zip_extract(&v);
      match e2 {
        Ok(entries) => { if entries.len() != 0 { return 14; } },
        Err(_) => { return 14; },
      }
      var l2 = zip.zip_list(&v);
      match l2 {
        Ok(names) => { if names.len() != 0 { return 14; } },
        Err(_) => { return 14; },
      }
    },
    Err(_) => { return 14; },
  }

  // Row 15: zip_list order on the fixture + zip_read on the written archive.
  var fl = zip.zip_list(&fixture);
  match fl {
    Ok(names) => {
      if names.len() != 4 { return 15; }
      if names[0] != "hello.txt" { return 15; }
      if names[1] != "data.bin" { return 15; }
      if names[2] != "empty.txt" { return 15; }
      if names[3] != "empty_d.txt" { return 15; }
    },
    Err(_) => { return 15; },
  }
  var run = zip.zip_read(&archive, "big.txt");
  match run {
    Ok(v) => {
      let got_hex = hex_of(&v);
      if got_hex != expect_big { return 15; }
    },
    Err(_) => { return 15; },
  }

  // Row 16: rejection rows.
  var junk = ascii_bytes("this is not a zip archive, not at all");
  var jr = zip.zip_extract(&junk);
  match jr {
    Ok(_) => { return 16; },
    Err(_) => {},
  }
  var trunc = copy_prefix(&fixture, 100);
  var tr = zip.zip_extract(&trunc);
  match tr {
    Ok(_) => { return 16; },
    Err(_) => {},
  }
  // EOCD disk field at (441-22)+4 = 423 -> multi-disk.
  var md = copy_vec(&fixture);
  md[423] = 1 as UInt8;
  var mdr = zip.zip_extract(&md);
  match mdr {
    Ok(_) => { return 16; },
    Err(_) => {},
  }
  // First central record method field: central at 198, +10 = 208 -> method 3.
  var um = copy_vec(&fixture);
  um[208] = 3 as UInt8;
  var umr = zip.zip_extract(&um);
  match umr {
    Ok(_) => { return 16; },
    Err(_) => {},
  }
  // Second central record (198 + 46 + 9 = 253) comp size at +20 = 273 -> zip64 marker.
  var z64 = copy_vec(&fixture);
  z64[273] = 0xFF;
  z64[274] = 0xFF;
  z64[275] = 0xFF;
  z64[276] = 0xFF;
  var zr = zip.zip_extract(&z64);
  match zr {
    Ok(_) => { return 16; },
    Err(_) => {},
  }

  // Row 17: structural lock on a fresh stored archive.
  // Layout: local 30 + name 10 + data 14 = 54; central 46 + 10 = 56;
  // EOCD 22; total 132.
  var payload = ascii_bytes("stored payload");
  var sw = zip.zip_writer_new();
  var ar = zip.zip_writer_add(&mut sw, "stored.txt", &payload, zip.ZIP_METHOD_STORED);
  match ar {
    Ok(_) => {},
    Err(_) => { return 17; },
  }
  var sf = zip.zip_writer_finish(&mut sw);
  var sa = Vec[UInt8].new();
  match sf {
    Ok(v) => { sa = v; },
    Err(_) => { return 17; },
  }
  if sa.len() != 132 { return 17; }
  if _rd_u32_at(&sa, 0) != 0x04034B50 { return 17; }
  if _rd_u16_at(&sa, 8) != 0 { return 17; }
  if _rd_u32_at(&sa, 14) != crc32.crc32(&payload) { return 17; }
  if _rd_u32_at(&sa, 18) != 14 { return 17; }
  if _rd_u32_at(&sa, 22) != 14 { return 17; }
  if _rd_u16_at(&sa, 26) != 10 { return 17; }
  if (sa[30] as Int) != 0x73 { return 17; }
  if (sa[39] as Int) != 0x74 { return 17; }
  if (sa[40] as Int) != 0x73 { return 17; }
  if (sa[53] as Int) != 0x64 { return 17; }
  if _rd_u32_at(&sa, 54) != 0x02014B50 { return 17; }
  if _rd_u16_at(&sa, 54 + 10) != 0 { return 17; }
  if _rd_u32_at(&sa, 54 + 16) != crc32.crc32(&payload) { return 17; }
  if _rd_u32_at(&sa, 54 + 20) != 14 { return 17; }
  if _rd_u32_at(&sa, 54 + 24) != 14 { return 17; }
  if _rd_u16_at(&sa, 54 + 28) != 10 { return 17; }
  if _rd_u32_at(&sa, 54 + 42) != 0 { return 17; }
  if _rd_u32_at(&sa, 110) != 0x06054B50 { return 17; }
  if _rd_u16_at(&sa, 110 + 8) != 1 { return 17; }
  if _rd_u16_at(&sa, 110 + 10) != 1 { return 17; }
  if _rd_u32_at(&sa, 110 + 12) != 56 { return 17; }
  if _rd_u32_at(&sa, 110 + 16) != 54 { return 17; }
  // Writer rejection rows.
  var rw = zip.zip_writer_new();
  var bad1 = zip.zip_writer_add(&mut rw, "", &payload, zip.ZIP_METHOD_STORED);
  match bad1 {
    Ok(_) => { return 17; },
    Err(_) => {},
  }
  var bad2 = zip.zip_writer_add(&mut rw, "x", &payload, 3);
  match bad2 {
    Ok(_) => { return 17; },
    Err(_) => {},
  }

  return 0;
}
