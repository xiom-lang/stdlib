// p_wave174_shapes.xi -- wave 174 lock: HTTP/2 frame header/frame codecs and
// the HPACK static-table/integer/string/header foundation (REL-20261015-2202
// item 9 scoping slice; RFC 9113 section 4.1 + RFC 7541 sections 5.1/6 and
// Appendix A). The probe covers the wire KATs, the 9-byte header layout, the
// RFC 7541 C.1 integer vectors, static-table lookups, indexed + literal
// header fields, and the explicit rejection paths (Huffman strings, dynamic
// inserts/indexes, out-of-range fields).
// Returns 0 when all rows hold; a nonzero return names the first failing row.
//
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_wave174_shapes

use xiom.net.h2;

fn main() -> Int {
  // --- row 1: constants ---
  if h2.H2_FRAME_DATA != 0 || h2.H2_FRAME_HEADERS != 1 { return 1; }
  if h2.H2_FRAME_SETTINGS != 4 || h2.H2_FRAME_CONTINUATION != 9 { return 1; }
  if h2.H2_FLAG_END_STREAM != 1 || h2.H2_FLAG_END_HEADERS != 4 { return 1; }
  if h2.H2_ERROR_COMPRESSION_ERROR != 9 { return 1; }

  // --- row 2: frame header encode/decode KAT ---
  let hdr = h2.h2_frame_header_encode(5, h2.H2_FRAME_DATA, 0, 1);
  match hdr {
    Ok(b) => {
      if b.len() != 9 { return 2; }
      if b[0] != 0 || b[1] != 0 || b[2] != 5 { return 2; }
      if b[3] != 0 || b[4] != 0 { return 2; }
      if b[5] != 0 || b[6] != 0 || b[7] != 0 || b[8] != 1 { return 2; }
    },
    Err(_) => { return 2; },
  };
  var raw_header = Vec[UInt8].new();
  raw_header.push(0); raw_header.push(0); raw_header.push(5);
  raw_header.push(0); raw_header.push(0);
  raw_header.push(0); raw_header.push(0); raw_header.push(0); raw_header.push(1);
  let decoded = h2.h2_frame_header_decode(&raw_header);
  match decoded {
    Ok(h) => {
      if h.length != 5 || h.frame_type != 0 || h.flags != 0 || h.stream_id != 1 { return 2; }
    },
    Err(_) => { return 2; },
  };

  // --- row 3: frame header range errors ---
  let bad_len = h2.h2_frame_header_encode(0x1000000, 0, 0, 1);
  if !bad_len.is_err { return 3; }
  let bad_type = h2.h2_frame_header_encode(0, 0x100, 0, 1);
  if !bad_type.is_err { return 3; }
  let bad_flags = h2.h2_frame_header_encode(0, 0, 0x100, 1);
  if !bad_flags.is_err { return 3; }
  let bad_stream = h2.h2_frame_header_encode(0, 0, 0, 0x80000000);
  if !bad_stream.is_err { return 3; }
  let bad_negative = h2.h2_frame_header_encode(0 - 1, 0, 0, 1);
  if !bad_negative.is_err { return 3; }

  // --- row 4: complete frame encode/decode ---
  var payload = Vec[UInt8].new();
  payload.push(104); payload.push(101); payload.push(108); payload.push(108); payload.push(111);
  let frame = h2.h2_frame_encode(h2.H2_FRAME_DATA, h2.H2_FLAG_END_STREAM, 1, &payload);
  match frame {
    Ok(b) => {
      if b.len() != 14 { return 4; }
      if b[0] != 0 || b[1] != 0 || b[2] != 5 { return 4; }
      if b[3] != 0 || b[4] != 1 { return 4; }
      if b[9] != 104 || b[13] != 111 { return 4; }
      let back = h2.h2_frame_decode(&b);
      match back {
        Ok(pair) => {
          if pair.0.length != 5 || pair.0.flags != 1 { return 4; }
          if pair.1.len() != 5 || pair.1[0] != 104 || pair.1[4] != 111 { return 4; }
        },
        Err(_) => { return 4; },
      };
    },
    Err(_) => { return 4; },
  };
  var short_header = Vec[UInt8].new();
  short_header.push(0); short_header.push(0); short_header.push(5);
  if !h2.h2_frame_decode(&short_header).is_err { return 4; }
  var short_payload = Vec[UInt8].new();
  var k = 0;
  while k < 12 {
    short_payload.push(0);
    k = k + 1;
  };
  short_payload[2] = 5;
  if !h2.h2_frame_decode(&short_payload).is_err { return 4; }

  // --- row 5: HPACK integer KATs (RFC 7541 C.1) ---
  let i10 = h2.h2_hpack_int_encode(10, 5, 0);
  match i10 {
    Ok(b) => { if b.len() != 1 || b[0] != 0x0A { return 5; } },
    Err(_) => { return 5; },
  };
  let i1337 = h2.h2_hpack_int_encode(1337, 5, 0);
  match i1337 {
    Ok(b) => {
      if b.len() != 3 || b[0] != 0x1F || b[1] != 0x9A || b[2] != 0x0A { return 5; }
      let back = h2.h2_hpack_int_decode(&b, 0, 5);
      match back {
        Ok(p) => { if p.0 != 1337 || p.1 != 3 { return 5; } },
        Err(_) => { return 5; },
      };
    },
    Err(_) => { return 5; },
  };
  let i42 = h2.h2_hpack_int_encode(42, 8, 0);
  match i42 {
    Ok(b) => { if b.len() != 1 || b[0] != 0x2A { return 5; } },
    Err(_) => { return 5; },
  };
  if !h2.h2_hpack_int_encode(0 - 1, 5, 0).is_err { return 5; }
  if !h2.h2_hpack_int_encode(0, 0, 0).is_err { return 5; }
  if !h2.h2_hpack_int_encode(0, 9, 0).is_err { return 5; }
  var truncated = Vec[UInt8].new();
  truncated.push(0x1F);
  if !h2.h2_hpack_int_decode(&truncated, 0, 5).is_err { return 5; }
  if !h2.h2_hpack_int_decode(&truncated, 0 - 1, 5).is_err { return 5; }

  // --- row 6: HPACK string KATs + Huffman rejection ---
  let s0 = h2.h2_hpack_string_encode("www.example.com");
  if s0.len() != 16 || s0[0] != 0x0F { return 6; }
  let sd0 = h2.h2_hpack_string_decode(&s0, 0);
  match sd0 {
    Ok(p) => { if p.0 != "www.example.com" || p.1 != 16 { return 6; } },
    Err(_) => { return 6; },
  };
  let empty_s = h2.h2_hpack_string_encode("");
  if empty_s.len() != 1 || empty_s[0] != 0 { return 6; }
  let sd1 = h2.h2_hpack_string_decode(&empty_s, 0);
  match sd1 {
    Ok(p) => { if p.0 != "" || p.1 != 1 { return 6; } },
    Err(_) => { return 6; },
  };
  var huff = Vec[UInt8].new();
  huff.push(0x85);
  if !h2.h2_hpack_string_decode(&huff, 0).is_err { return 6; }

  // --- row 7: static table ---
  if h2.h2_hpack_static_len() != 61 { return 7; }
  match h2.h2_hpack_static_name(2) {
    Some(n) => { if n != ":method" { return 7; } },
    None => { return 7; },
  };
  match h2.h2_hpack_static_value(2) {
    Some(v) => { if v != "GET" { return 7; } },
    None => { return 7; },
  };
  match h2.h2_hpack_static_value(8) {
    Some(v) => { if v != "200" { return 7; } },
    None => { return 7; },
  };
  match h2.h2_hpack_static_name(61) {
    Some(n) => { if n != "www-authenticate" { return 7; } },
    None => { return 7; },
  };
  match h2.h2_hpack_static_value(16) {
    Some(v) => { if v != "gzip, deflate" { return 7; } },
    None => { return 7; },
  };
  if h2.h2_hpack_static_name(0).is_some || h2.h2_hpack_static_name(62).is_some { return 7; }
  if !h2.h2_hpack_static_value(62).is_none { return 7; }
  match h2.h2_hpack_static_find_name(":status") {
    Some(i) => { if i != 8 { return 7; } },
    None => { return 7; },
  };
  match h2.h2_hpack_static_find(":method", "GET") {
    Some(i) => { if i != 2 { return 7; } },
    None => { return 7; },
  };
  if h2.h2_hpack_static_find("x-custom", "").is_some { return 7; }
  if h2.h2_hpack_static_find_name("").is_some { return 7; }

  // --- row 8: indexed header field ---
  let hi = h2.h2_hpack_encode_header(":method", "GET");
  match hi {
    Ok(b) => {
      if b.len() != 1 || b[0] != 0x82 { return 8; }
      let back = h2.h2_hpack_decode_header(&b, 0);
      match back {
        Ok(p) => { if p.0 != ":method" || p.1 != "GET" || p.2 != 1 { return 8; } },
        Err(_) => { return 8; },
      };
    },
    Err(_) => { return 8; },
  };

  // --- row 9: literal header, indexed name ---
  let hl = h2.h2_hpack_encode_header(":method", "PUT");
  match hl {
    Ok(b) => {
      if b.len() != 5 || b[0] != 0x02 || b[1] != 0x03 { return 9; }
      if b[2] != 80 || b[3] != 85 || b[4] != 84 { return 9; }
      let back = h2.h2_hpack_decode_header(&b, 0);
      match back {
        Ok(p) => { if p.0 != ":method" || p.1 != "PUT" || p.2 != 5 { return 9; } },
        Err(_) => { return 9; },
      };
    },
    Err(_) => { return 9; },
  };

  // --- row 10: literal header, new name + rejection paths ---
  let hn = h2.h2_hpack_encode_header("x-test", "v");
  match hn {
    Ok(b) => {
      if b.len() != 10 || b[0] != 0x00 || b[1] != 0x06 { return 10; }
      let back = h2.h2_hpack_decode_header(&b, 0);
      match back {
        Ok(p) => { if p.0 != "x-test" || p.1 != "v" || p.2 != 10 { return 10; } },
        Err(_) => { return 10; },
      };
    },
    Err(_) => { return 10; },
  };
  if !h2.h2_hpack_encode_header("", "v").is_err { return 10; }
  var dynamic_insert = Vec[UInt8].new();
  dynamic_insert.push(0x40);
  dynamic_insert.push(0x01);
  dynamic_insert.push(0x61);
  if !h2.h2_hpack_decode_header(&dynamic_insert, 0).is_err { return 10; }
  var dynamic_index = Vec[UInt8].new();
  dynamic_index.push(0xBE);
  if !h2.h2_hpack_decode_header(&dynamic_index, 0).is_err { return 10; }

  return 0;
}
