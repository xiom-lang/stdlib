// XIOM -- Networking: HTTP/2 Framing + HPACK Foundation
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Phase-2 shelf foundation (REL-20261015-2202-pulse item 9). This module is
// deliberately a PURE primitive layer:
//   * RFC 9113 section 4.1 frame headers (9-byte wire shape) + full frames;
//   * HPACK (RFC 7541) integer and string primitives;
//   * the 61-entry HPACK static table (RFC 7541 Appendix A);
//   * one header field encode/decode: static-indexed, or a literal without
//     indexing (indexed name or new name).
// NOT implemented here (documented scoping boundary): Huffman coding,
// CONTINUATION reassembly, and connection state. Huffman strings and 0x40
// dynamic-table inserts are rejected with a clear Err so a caller cannot
// silently mis-decode them; the dynamic table itself is available as the
// standalone H2HpackDynamicTable primitives below for a stateful caller.
// No module-level tables: the static table lives in one private match chain.

module xiom.net.h2

// Depends on: xiom.string (byte_at/c_str only through the Str face)

use xiom.string;

/// HTTP/2 DATA frame type.
pub const H2_FRAME_DATA: Int = 0;
/// HTTP/2 HEADERS frame type.
pub const H2_FRAME_HEADERS: Int = 1;
/// HTTP/2 PRIORITY frame type.
pub const H2_FRAME_PRIORITY: Int = 2;
/// HTTP/2 RST_STREAM frame type.
pub const H2_FRAME_RST_STREAM: Int = 3;
/// HTTP/2 SETTINGS frame type.
pub const H2_FRAME_SETTINGS: Int = 4;
/// HTTP/2 PUSH_PROMISE frame type.
pub const H2_FRAME_PUSH_PROMISE: Int = 5;
/// HTTP/2 PING frame type.
pub const H2_FRAME_PING: Int = 6;
/// HTTP/2 GOAWAY frame type.
pub const H2_FRAME_GOAWAY: Int = 7;
/// HTTP/2 WINDOW_UPDATE frame type.
pub const H2_FRAME_WINDOW_UPDATE: Int = 8;
/// HTTP/2 CONTINUATION frame type.
pub const H2_FRAME_CONTINUATION: Int = 9;

/// END_STREAM flag (DATA/HEADERS).
pub const H2_FLAG_END_STREAM: Int = 0x1;
/// ACK flag (SETTINGS/PING).
pub const H2_FLAG_ACK: Int = 0x1;
/// END_HEADERS flag (HEADERS/CONTINUATION).
pub const H2_FLAG_END_HEADERS: Int = 0x4;
/// PADDED flag (DATA/HEADERS/PUSH_PROMISE).
pub const H2_FLAG_PADDED: Int = 0x8;
/// PRIORITY flag (HEADERS).
pub const H2_FLAG_PRIORITY: Int = 0x20;

/// HTTP/2 NO_ERROR code.
pub const H2_ERROR_NO_ERROR: Int = 0;
/// HTTP/2 PROTOCOL_ERROR code.
pub const H2_ERROR_PROTOCOL_ERROR: Int = 1;
/// HTTP/2 INTERNAL_ERROR code.
pub const H2_ERROR_INTERNAL_ERROR: Int = 2;
/// HTTP/2 FLOW_CONTROL_ERROR code.
pub const H2_ERROR_FLOW_CONTROL_ERROR: Int = 3;
/// HTTP/2 COMPRESSION_ERROR code.
pub const H2_ERROR_COMPRESSION_ERROR: Int = 9;

/// Decoded HTTP/2 frame header. `length` is the payload length (24-bit),
/// `stream_id` has the reserved bit cleared (31-bit).
pub type H2FrameHeader = {
  length: Int;
  frame_type: Int;
  flags: Int;
  stream_id: Int;
}

// ---------------------------------------------------------------------------
// Frame headers / frames
// ---------------------------------------------------------------------------

/// Encode the 9-byte HTTP/2 frame header. Err when any field is outside its
/// wire range (length 0..=0xFFFFFF, type/flags 0..=0xFF, stream id
/// 0..=0x7FFFFFFF). The reserved stream-id bit is emitted as 0.
pub fn h2_frame_header_encode(length: Int, frame_type: Int, flags: Int, stream_id: Int) -> Result[Vec[UInt8], Str]
  ensures: (length < 0 || length > 0xFFFFFF || frame_type < 0 || frame_type > 0xFF || flags < 0 || flags > 0xFF || stream_id < 0 || stream_id > 0x7FFFFFFF) => (result.is_err)
  ensures: (length >= 0 && length <= 0xFFFFFF && frame_type >= 0 && frame_type <= 0xFF && flags >= 0 && flags <= 0xFF && stream_id >= 0 && stream_id <= 0x7FFFFFFF) => (result.is_ok)
{
  if length < 0 || length > 0xFFFFFF {
    return Err("h2: frame length out of range");
  };
  if frame_type < 0 || frame_type > 0xFF {
    return Err("h2: frame type out of range");
  };
  if flags < 0 || flags > 0xFF {
    return Err("h2: frame flags out of range");
  };
  if stream_id < 0 || stream_id > 0x7FFFFFFF {
    return Err("h2: stream id out of range");
  };
  var out = Vec[UInt8].new();
  out.push(((length >> 16) & 0xFF) as UInt8);
  out.push(((length >> 8) & 0xFF) as UInt8);
  out.push((length & 0xFF) as UInt8);
  out.push(frame_type as UInt8);
  out.push(flags as UInt8);
  out.push(((stream_id >> 24) & 0x7F) as UInt8);
  out.push(((stream_id >> 16) & 0xFF) as UInt8);
  out.push(((stream_id >> 8) & 0xFF) as UInt8);
  out.push((stream_id & 0xFF) as UInt8);
  return Ok(out);
}

/// Decode the 9-byte HTTP/2 frame header. Err("h2: incomplete frame header")
/// when fewer than 9 bytes are available; the reserved stream-id bit is
/// masked off.
pub fn h2_frame_header_decode(bytes: &Vec[UInt8]) -> Result[H2FrameHeader, Str]
  ensures: (bytes.len() < 9) => (result.is_err)
  ensures: (bytes.len() >= 9) => (result.is_ok)
{
  if bytes.len() < 9 {
    return Err("h2: incomplete frame header");
  };
  let length = ((bytes[0] as Int) << 16) | ((bytes[1] as Int) << 8) | (bytes[2] as Int);
  let frame_type = bytes[3] as Int;
  let flags = bytes[4] as Int;
  let stream_id = (((bytes[5] as Int) & 0x7F) << 24) | ((bytes[6] as Int) << 16) | ((bytes[7] as Int) << 8) | (bytes[8] as Int);
  return Ok(H2FrameHeader{
    length: length;
    frame_type: frame_type;
    flags: flags;
    stream_id: stream_id;
  });
}

/// Encode one complete HTTP/2 frame: the 9-byte header (length derived from
/// `payload`) followed by the payload. Err on an out-of-range type/flags/
/// stream id or a payload longer than the 24-bit frame limit.
pub fn h2_frame_encode(frame_type: Int, flags: Int, stream_id: Int, payload: &Vec[UInt8]) -> Result[Vec[UInt8], Str]
  ensures: (payload.len() > 0xFFFFFF) => (result.is_err)
  ensures: (payload.len() <= 0xFFFFFF && frame_type >= 0 && frame_type <= 0xFF && flags >= 0 && flags <= 0xFF && stream_id >= 0 && stream_id <= 0x7FFFFFFF) => (result.is_ok)
{
  let header = h2_frame_header_encode(payload.len(), frame_type, flags, stream_id);
  match header {
    Err(e) => { return Err(e); },
    Ok(h) => {
      var out = Vec[UInt8].new();
      var i = 0;
      while i < 9 {
        out.push(h[i]);
        i = i + 1;
      };
      i = 0;
      while i < payload.len() {
        out.push(payload[i]);
        i = i + 1;
      };
      return Ok(out);
    },
  }
}

/// Decode one complete frame at the start of `bytes` (header + payload).
/// Err on a short header, a short payload, or an invalid header field.
pub fn h2_frame_decode(bytes: &Vec[UInt8]) -> Result[(H2FrameHeader, Vec[UInt8]), Str]
  ensures: (bytes.len() < 9) => (result.is_err)
{
  if bytes.len() < 9 {
    return Err("h2: incomplete frame header");
  };
  let decoded = h2_frame_header_decode(bytes);
  match decoded {
    Err(e) => { return Err(e); },
    Ok(h) => {
      if bytes.len() < 9 + h.length {
        return Err("h2: incomplete frame payload");
      };
      var payload = Vec[UInt8].new();
      var i = 0;
      while i < h.length {
        payload.push(bytes[9 + i]);
        i = i + 1;
      };
      return Ok((h, payload));
    },
  }
}

// ---------------------------------------------------------------------------
// HPACK integers / strings
// ---------------------------------------------------------------------------

/// Encode an HPACK integer (RFC 7541 section 5.1) with a `prefix_bits`-wide
/// prefix. `first_byte` supplies the high bits (pattern bits); its low
/// `prefix_bits` are replaced. Err on a negative value or a prefix outside
/// 1..=8.
pub fn h2_hpack_int_encode(value: Int, prefix_bits: Int, first_byte: Int) -> Result[Vec[UInt8], Str]
  ensures: (value < 0 || prefix_bits < 1 || prefix_bits > 8 || first_byte < 0 || first_byte > 0xFF) => (result.is_err)
  ensures: (value >= 0 && prefix_bits >= 1 && prefix_bits <= 8 && first_byte >= 0 && first_byte <= 0xFF) => (result.is_ok)
{
  if value < 0 {
    return Err("h2: negative HPACK integer");
  };
  if prefix_bits < 1 || prefix_bits > 8 {
    return Err("h2: HPACK prefix out of range");
  };
  if first_byte < 0 || first_byte > 0xFF {
    return Err("h2: HPACK first byte out of range");
  };
  let max_prefix = (1 << prefix_bits) - 1;
  let high_bits = first_byte & (0xFF - max_prefix);
  var out = Vec[UInt8].new();
  if value < max_prefix {
    out.push((high_bits | value) as UInt8);
    return Ok(out);
  };
  out.push((high_bits | max_prefix) as UInt8);
  var n = value - max_prefix;
  while n >= 128 {
    out.push(((n % 128) + 128) as UInt8);
    n = n / 128;
  };
  out.push(n as UInt8);
  return Ok(out);
}

/// Decode an HPACK integer at `pos`. Returns (value, consumed bytes). Err on
/// an invalid position/prefix, a truncated continuation, or an overflow.
pub fn h2_hpack_int_decode(bytes: &Vec[UInt8], pos: Int, prefix_bits: Int) -> Result[(Int, Int), Str]
  ensures: (pos < 0 || pos >= bytes.len() || prefix_bits < 1 || prefix_bits > 8) => (result.is_err)
{
  if pos < 0 || pos >= bytes.len() {
    return Err("h2: HPACK integer position out of range");
  };
  if prefix_bits < 1 || prefix_bits > 8 {
    return Err("h2: HPACK prefix out of range");
  };
  let max_prefix = (1 << prefix_bits) - 1;
  let first = bytes[pos] as Int;
  var value = first & max_prefix;
  if value < max_prefix {
    return Ok((value, 1));
  };
  var shift = 0;
  var i = pos + 1;
  while i < bytes.len() {
    let b = bytes[i] as Int;
    value = value + ((b & 0x7F) << shift);
    if (b & 0x80) == 0 {
      return Ok((value, i - pos + 1));
    };
    shift = shift + 7;
    if shift > 28 {
      return Err("h2: HPACK integer overflow");
    };
    i = i + 1;
  };
  return Err("h2: truncated HPACK integer");
}

/// Encode an HPACK string without Huffman coding (H=0): the 7-bit length
/// prefix followed by the raw bytes.
pub fn h2_hpack_string_encode(s: Str) -> Vec[UInt8]
  ensures: result.len() >= 1
{
  var out = Vec[UInt8].new();
  let prefix = h2_hpack_int_encode(s.len(), 7, 0);
  match prefix {
    Ok(p) => {
      var i = 0;
      while i < p.len() {
        out.push(p[i]);
        i = i + 1;
      };
    },
    Err(_) => { out.push(0); },
  };
  var j = 0;
  while j < s.len() {
    out.push(s.byte_at(j));
    j = j + 1;
  };
  return out;
}

/// Decode an HPACK string at `pos`. Returns (string, consumed bytes). Only
/// H=0 is supported; an H=1 (Huffman) string is rejected explicitly.
pub fn h2_hpack_string_decode(bytes: &Vec[UInt8], pos: Int) -> Result[(Str, Int), Str]
  ensures: (pos < 0 || pos >= bytes.len()) => (result.is_err)
{
  if pos < 0 || pos >= bytes.len() {
    return Err("h2: HPACK string position out of range");
  };
  if ((bytes[pos] as Int) & 0x80) != 0 {
    return Err("h2: huffman strings not supported");
  };
  let decoded = h2_hpack_int_decode(bytes, pos, 7);
  match decoded {
    Err(e) => { return Err(e); },
    Ok(pair) => {
      let length = pair.0;
      let used = pair.1;
      if length < 0 || pos + used + length > bytes.len() {
        return Err("h2: truncated HPACK string");
      };
      var raw = Vec[UInt8].new();
      var i = 0;
      while i < length {
        raw.push(bytes[pos + used + i]);
        i = i + 1;
      };
      return Ok((Str.from_utf8(raw), used + length));
    },
  }
}

// ---------------------------------------------------------------------------
// HPACK dynamic table (RFC 7541 section 2.3)
// ---------------------------------------------------------------------------

/// HPACK dynamic table. Entries are stored oldest-first; dynamic index 1 is
/// the most recently added entry. An entry costs name.len + value.len + 32
/// bytes (RFC 7541 section 4.1).
pub type H2HpackDynamicTable = {
  names: Vec[Str];
  values: Vec[Str];
  size: Int;
  max_size: Int;
}

fn _h2_dyn_evict_oldest(t: &mut H2HpackDynamicTable) {
  if t.names.len() == 0 { return; }
  t.size = t.size - (t.names[0].len() + t.values[0].len() + 32);
  var nn = Vec[Str].new();
  var nv = Vec[Str].new();
  var i = 1;
  while i < t.names.len() {
    nn.push(t.names[i]);
    nv.push(t.values[i]);
    i = i + 1;
  }
  t.names = nn;
  t.values = nv;
}

/// Create an empty dynamic table with the given maximum size in bytes.
pub fn h2_hpack_dynamic_new(max_size: Int) -> H2HpackDynamicTable
  requires: max_size >= 0
  ensures: result.size == 0
  ensures: result.max_size == max_size
{
  return H2HpackDynamicTable{
    names: Vec[Str].new();
    values: Vec[Str].new();
    size: 0;
    max_size: max_size;
  };
}

/// Number of entries currently in the dynamic table.
pub fn h2_hpack_dynamic_len(t: &H2HpackDynamicTable) -> Int
  ensures: result == t.names.len()
{
  return t.names.len();
}

/// Current byte size of the dynamic table.
pub fn h2_hpack_dynamic_size(t: &H2HpackDynamicTable) -> Int
  ensures: result == t.size
{
  return t.size;
}

/// Insert (name, value) as the newest entry, evicting oldest entries until it
/// fits. An entry larger than max_size clears the table and is not inserted.
pub fn h2_hpack_dynamic_add(t: &mut H2HpackDynamicTable, name: Str, value: Str)
  requires: t.max_size >= 0
{
  let entry = name.len() + value.len() + 32;
  if entry > t.max_size {
    h2_hpack_dynamic_clear(t);
    return;
  }
  while t.size + entry > t.max_size && t.names.len() > 0 {
    _h2_dyn_evict_oldest(t);
  }
  t.names.push(name);
  t.values.push(value);
  t.size = t.size + entry;
}

/// Look up dynamic index (1 = newest). None when the index is outside
/// 1..=len. Complexity: O(1).
pub fn h2_hpack_dynamic_get(t: &H2HpackDynamicTable, index: Int) -> Option[(Str, Str)]
  requires: true
{
  if index < 1 || index > t.names.len() {
    return None;
  }
  let pos = t.names.len() - index;
  return Some((t.names[pos], t.values[pos]));
}

/// Set the maximum table size and evict until the size fits.
pub fn h2_hpack_dynamic_set_max(t: &mut H2HpackDynamicTable, max_size: Int)
  requires: max_size >= 0
{
  t.max_size = max_size;
  while t.size > t.max_size && t.names.len() > 0 {
    _h2_dyn_evict_oldest(t);
  }
}

/// Remove every entry (size becomes 0; max_size is preserved).
pub fn h2_hpack_dynamic_clear(t: &mut H2HpackDynamicTable)
  requires: true
{
  t.names = Vec[Str].new();
  t.values = Vec[Str].new();
  t.size = 0;
}

// ---------------------------------------------------------------------------
// HPACK static table (RFC 7541 Appendix A)
// ---------------------------------------------------------------------------

// The static table as one private chain (no module-level tables).
fn _h2_static_pair(index: Int) -> (Str, Str) {
  if index == 1 { return (":authority", ""); };
  if index == 2 { return (":method", "GET"); };
  if index == 3 { return (":method", "POST"); };
  if index == 4 { return (":path", "/"); };
  if index == 5 { return (":path", "/index.html"); };
  if index == 6 { return (":scheme", "http"); };
  if index == 7 { return (":scheme", "https"); };
  if index == 8 { return (":status", "200"); };
  if index == 9 { return (":status", "204"); };
  if index == 10 { return (":status", "206"); };
  if index == 11 { return (":status", "304"); };
  if index == 12 { return (":status", "400"); };
  if index == 13 { return (":status", "404"); };
  if index == 14 { return (":status", "500"); };
  if index == 15 { return ("accept-charset", ""); };
  if index == 16 { return ("accept-encoding", "gzip, deflate"); };
  if index == 17 { return ("accept-language", ""); };
  if index == 18 { return ("accept-ranges", ""); };
  if index == 19 { return ("accept", ""); };
  if index == 20 { return ("access-control-allow-origin", ""); };
  if index == 21 { return ("age", ""); };
  if index == 22 { return ("allow", ""); };
  if index == 23 { return ("authorization", ""); };
  if index == 24 { return ("cache-control", ""); };
  if index == 25 { return ("content-disposition", ""); };
  if index == 26 { return ("content-encoding", ""); };
  if index == 27 { return ("content-language", ""); };
  if index == 28 { return ("content-length", ""); };
  if index == 29 { return ("content-location", ""); };
  if index == 30 { return ("content-range", ""); };
  if index == 31 { return ("content-type", ""); };
  if index == 32 { return ("cookie", ""); };
  if index == 33 { return ("date", ""); };
  if index == 34 { return ("etag", ""); };
  if index == 35 { return ("expect", ""); };
  if index == 36 { return ("expires", ""); };
  if index == 37 { return ("from", ""); };
  if index == 38 { return ("host", ""); };
  if index == 39 { return ("if-match", ""); };
  if index == 40 { return ("if-modified-since", ""); };
  if index == 41 { return ("if-none-match", ""); };
  if index == 42 { return ("if-range", ""); };
  if index == 43 { return ("if-unmodified-since", ""); };
  if index == 44 { return ("last-modified", ""); };
  if index == 45 { return ("link", ""); };
  if index == 46 { return ("location", ""); };
  if index == 47 { return ("max-forwards", ""); };
  if index == 48 { return ("proxy-authenticate", ""); };
  if index == 49 { return ("proxy-authorization", ""); };
  if index == 50 { return ("range", ""); };
  if index == 51 { return ("referer", ""); };
  if index == 52 { return ("refresh", ""); };
  if index == 53 { return ("retry-after", ""); };
  if index == 54 { return ("server", ""); };
  if index == 55 { return ("set-cookie", ""); };
  if index == 56 { return ("strict-transport-security", ""); };
  if index == 57 { return ("transfer-encoding", ""); };
  if index == 58 { return ("user-agent", ""); };
  if index == 59 { return ("vary", ""); };
  if index == 60 { return ("via", ""); };
  if index == 61 { return ("www-authenticate", ""); };
  return ("", "");
}

/// Number of HPACK static-table entries (61).
pub fn h2_hpack_static_len() -> Int
  ensures: result == 61
{
  return 61;
}

/// Name of static-table entry `index`, or None when out of range (1..=61).
pub fn h2_hpack_static_name(index: Int) -> Option[Str]
  ensures: (index < 1 || index > 61) => (result.is_none)
{
  if index < 1 || index > 61 {
    return None;
  };
  let pair = _h2_static_pair(index);
  return Some(pair.0);
}

/// Value of static-table entry `index`, or None when out of range (1..=61).
pub fn h2_hpack_static_value(index: Int) -> Option[Str]
  ensures: (index < 1 || index > 61) => (result.is_none)
{
  if index < 1 || index > 61 {
    return None;
  };
  let pair = _h2_static_pair(index);
  return Some(pair.1);
}

/// First static-table index whose name equals `name`, or None. The first
/// match is the canonical name index (e.g. ":method" -> 2).
pub fn h2_hpack_static_find_name(name: Str) -> Option[Int]
  ensures: (name.len() == 0) => (result.is_none)
{
  var i = 1;
  while i <= 61 {
    let pair = _h2_static_pair(i);
    if pair.0 == name {
      return Some(i);
    };
    i = i + 1;
  };
  return None;
}

/// Exact static-table (name, value) index, or None.
pub fn h2_hpack_static_find(name: Str, value: Str) -> Option[Int]
  ensures: (name.len() == 0) => (result.is_none)
{
  var i = 1;
  while i <= 61 {
    let pair = _h2_static_pair(i);
    if pair.0 == name && pair.1 == value {
      return Some(i);
    };
    i = i + 1;
  };
  return None;
}

// ---------------------------------------------------------------------------
// One header field
// ---------------------------------------------------------------------------

/// Encode one header field. An exact static (name, value) pair becomes an
/// indexed field; otherwise a literal without indexing is emitted, using a
/// static name index when the name is known or a new-name string otherwise.
/// Huffman coding is not used. Err on an empty name.
pub fn h2_hpack_encode_header(name: Str, value: Str) -> Result[Vec[UInt8], Str]
  ensures: (name.len() == 0) => (result.is_err)
{
  if name.len() == 0 {
    return Err("h2: empty header name");
  };
  var out = Vec[UInt8].new();
  let exact = h2_hpack_static_find(name, value);
  match exact {
    Some(idx) => {
      let encoded = h2_hpack_int_encode(idx, 7, 0x80);
      match encoded {
        Err(e) => { return Err(e); },
        Ok(b) => {
          var i = 0;
          while i < b.len() {
            out.push(b[i]);
            i = i + 1;
          };
          return Ok(out);
        },
      };
    },
    None => {},
  };
  var name_index = 0;
  let found = h2_hpack_static_find_name(name);
  match found {
    Some(idx) => { name_index = idx; },
    None => {},
  };
  let name_enc = h2_hpack_int_encode(name_index, 4, 0x00);
  match name_enc {
    Err(e) => { return Err(e); },
    Ok(b) => {
      var i = 0;
      while i < b.len() {
        out.push(b[i]);
        i = i + 1;
      };
    },
  };
  if name_index == 0 {
    let name_bytes = h2_hpack_string_encode(name);
    var i = 0;
    while i < name_bytes.len() {
      out.push(name_bytes[i]);
      i = i + 1;
    };
  };
  let value_bytes = h2_hpack_string_encode(value);
  var j = 0;
  while j < value_bytes.len() {
    out.push(value_bytes[j]);
    j = j + 1;
  };
  return Ok(out);
}

/// Decode one header field at `pos`. Returns (name, value, consumed bytes).
/// Supported: indexed static fields and literal fields without indexing
/// (indexed or new name). Dynamic-table inserts (0x40), dynamic indexes
/// (>61) and Huffman strings are rejected explicitly.
pub fn h2_hpack_decode_header(bytes: &Vec[UInt8], pos: Int) -> Result[(Str, Str, Int), Str]
  ensures: (pos < 0 || pos >= bytes.len()) => (result.is_err)
{
  if pos < 0 || pos >= bytes.len() {
    return Err("h2: HPACK header position out of range");
  };
  let first = bytes[pos] as Int;
  if (first & 0x80) != 0 {
    let decoded = h2_hpack_int_decode(bytes, pos, 7);
    match decoded {
      Err(e) => { return Err(e); },
      Ok(pair) => {
        let idx = pair.0;
        let used = pair.1;
        if idx < 1 || idx > 61 {
          return Err("h2: dynamic-table index not supported");
        };
        let entry = _h2_static_pair(idx);
        return Ok((entry.0, entry.1, used));
      },
    };
  };
  if (first & 0x40) != 0 {
    return Err("h2: dynamic table insert not supported");
  };
  let name_dec = h2_hpack_int_decode(bytes, pos, 4);
  match name_dec {
    Err(e) => { return Err(e); },
    Ok(pair) => {
      let name_index = pair.0;
      var used = pair.1;
      var name = "";
      if name_index == 0 {
        let name_str = h2_hpack_string_decode(bytes, pos + used);
        match name_str {
          Err(e) => { return Err(e); },
          Ok(sp) => {
            name = sp.0;
            used = used + sp.1;
          },
        };
      } else {
        if name_index > 61 {
          return Err("h2: dynamic-table name index not supported");
        };
        let entry = _h2_static_pair(name_index);
        name = entry.0;
      };
      let value_dec = h2_hpack_string_decode(bytes, pos + used);
      match value_dec {
        Err(e) => { return Err(e); },
        Ok(sp) => {
          let value = sp.0;
          let total = used + sp.1;
          return Ok((name, value, total));
        },
      };
    },
  }
}
