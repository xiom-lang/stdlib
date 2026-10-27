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
// NOT implemented here (documented scoping boundary): the connection-level
// multiplexing state machine (concurrency limits, GOAWAY drain handling).
// Stream-ID allocation, per-stream state transitions, SETTINGS/flow-control,
// and the RST_STREAM/GOAWAY/WINDOW_UPDATE payloads are available below.
// 0x40 dynamic-table
// inserts are rejected with a clear Err so a caller cannot silently mis-decode
// them; the dynamic table itself is available as the standalone
// H2HpackDynamicTable primitives below, Huffman (H=1) string bodies are
// handled by h2_hpack_huffman_decode / h2_hpack_string_encode_huffman, and
// HEADERS + CONTINUATION fragments are joined by H2HeaderBlock.
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
// HEADERS + CONTINUATION reassembly (RFC 9113 section 4.3)
// ---------------------------------------------------------------------------

/// A header block being reassembled from one HEADERS frame and zero or more
/// CONTINUATION frames. `bytes` is the concatenated header-block fragment.
pub type H2HeaderBlock = {
  stream_id: Int;
  bytes: Vec[UInt8];
  complete: Bool;
}

/// Start a header block from a HEADERS payload (padding/priority already
/// stripped by the caller). `end_headers` sets the complete flag.
pub fn h2_header_block_new(stream_id: Int, payload: &Vec[UInt8], end_headers: Bool) -> H2HeaderBlock
  requires: stream_id > 0
  ensures: result.stream_id == stream_id
  ensures: result.complete == end_headers
  ensures: result.bytes.len() == payload.len()
{
  var b = Vec[UInt8].new();
  var i = 0;
  while i < payload.len() {
    b.push(payload[i]);
    i = i + 1;
  }
  return H2HeaderBlock{
    stream_id: stream_id;
    bytes: b;
    complete: end_headers;
  };
}

/// Append a CONTINUATION payload. Err when the block is already complete,
/// the frame is not CONTINUATION, or the stream id differs. Returns whether
/// the block is complete after the append.
pub fn h2_header_block_append(block: &mut H2HeaderBlock, frame_type: Int, flags: Int, stream_id: Int, payload: &Vec[UInt8]) -> Result[Bool, Str]
  requires: block.stream_id > 0
{
  if block.complete {
    return Err("h2: header block already complete");
  };
  if frame_type != H2_FRAME_CONTINUATION {
    return Err("h2: expected CONTINUATION");
  };
  if stream_id != block.stream_id {
    return Err("h2: CONTINUATION stream mismatch");
  };
  var i = 0;
  while i < payload.len() {
    block.bytes.push(payload[i]);
    i = i + 1;
  };
  if (flags & H2_FLAG_END_HEADERS) != 0 {
    block.complete = true;
  };
  return Ok(block.complete);
}

/// True once END_HEADERS has been seen.
pub fn h2_header_block_is_complete(block: &H2HeaderBlock) -> Bool
  ensures: result == block.complete
{
  return block.complete;
}

/// Total reassembled header-block length in bytes.
pub fn h2_header_block_len(block: &H2HeaderBlock) -> Int
  ensures: result == block.bytes.len()
{
  return block.bytes.len();
}

/// Copy the reassembled header-block bytes (for h2_hpack_* input).
pub fn h2_header_block_to_bytes(block: &H2HeaderBlock) -> Vec[UInt8]
  ensures: result.len() == block.bytes.len()
{
  var out = Vec[UInt8].new();
  var i = 0;
  while i < block.bytes.len() {
    out.push(block.bytes[i]);
    i = i + 1;
  }
  return out;
}

// ---------------------------------------------------------------------------
// SETTINGS and flow-control windows (RFC 9113 sections 6.5 / 6.9)
// ---------------------------------------------------------------------------

/// SETTINGS_HEADER_TABLE_SIZE identifier.
pub const H2_SETTINGS_HEADER_TABLE_SIZE: Int = 1;
/// SETTINGS_ENABLE_PUSH identifier.
pub const H2_SETTINGS_ENABLE_PUSH: Int = 2;
/// SETTINGS_MAX_CONCURRENT_STREAMS identifier.
pub const H2_SETTINGS_MAX_CONCURRENT_STREAMS: Int = 3;
/// SETTINGS_INITIAL_WINDOW_SIZE identifier.
pub const H2_SETTINGS_INITIAL_WINDOW_SIZE: Int = 4;
/// SETTINGS_MAX_FRAME_SIZE identifier.
pub const H2_SETTINGS_MAX_FRAME_SIZE: Int = 5;
/// SETTINGS_MAX_HEADER_LIST_SIZE identifier.
pub const H2_SETTINGS_MAX_HEADER_LIST_SIZE: Int = 6;

/// Maximum HTTP/2 flow-control window (2^31-1).
pub const H2_MAX_WINDOW: Int = 2147483647;

/// One SETTINGS entry (6 bytes on the wire: 2-byte id, 4-byte value).
pub type H2Setting = {
  id: Int;
  value: Int;
}

fn _h2_push_u16(out: &mut Vec[UInt8], v: Int) {
  out.push(((v >> 8) & 0xFF) as UInt8);
  out.push((v & 0xFF) as UInt8);
}

fn _h2_push_u32(out: &mut Vec[UInt8], v: Int) {
  out.push(((v >> 24) & 0xFF) as UInt8);
  out.push(((v >> 16) & 0xFF) as UInt8);
  out.push(((v >> 8) & 0xFF) as UInt8);
  out.push((v & 0xFF) as UInt8);
}

/// New empty SETTINGS list. Module-side constructor so callers do not have
/// to spell a qualified generic type (which the compiler erases at call
/// sites).
pub fn h2_settings_new() -> Vec[H2Setting]
  ensures: result.len() == 0
{
  return Vec[H2Setting].new();
}

/// Append one SETTINGS entry to a caller-owned list.
pub fn h2_settings_add(settings: &mut Vec[H2Setting], id: Int, value: Int)
  requires: true
{
  settings.push(H2Setting{ id: id; value: value; });
}

/// Encode a SETTINGS payload (6 bytes per entry). Err when an id is outside
/// 0..=0xFFFF or a value outside 0..=0xFFFFFFFF.
pub fn h2_settings_encode(settings: &Vec[H2Setting]) -> Result[Vec[UInt8], Str]
  requires: true
{
  var out = Vec[UInt8].new();
  var i = 0;
  while i < settings.len() {
    let s = settings[i];
    if s.id < 0 || s.id > 0xFFFF {
      return Err("h2: SETTINGS id out of range");
    }
    if s.value < 0 || s.value > 0xFFFFFFFF {
      return Err("h2: SETTINGS value out of range");
    }
    _h2_push_u16(&mut out, s.id);
    _h2_push_u32(&mut out, s.value);
    i = i + 1;
  }
  return Ok(out);
}

/// Decode a SETTINGS payload. Err when the length is not a multiple of 6.
pub fn h2_settings_decode(payload: &Vec[UInt8]) -> Result[Vec[H2Setting], Str]
  ensures: (payload.len() % 6 != 0) => (result.is_err)
{
  if payload.len() % 6 != 0 {
    return Err("h2: SETTINGS length not a multiple of 6");
  }
  var out = Vec[H2Setting].new();
  var i = 0;
  while i < payload.len() {
    let id = ((payload[i] as Int) << 8) | (payload[i + 1] as Int);
    let value = ((payload[i + 2] as Int) << 24) | ((payload[i + 3] as Int) << 16) | ((payload[i + 4] as Int) << 8) | (payload[i + 5] as Int);
    out.push(H2Setting{ id: id; value: value; });
    i = i + 6;
  }
  return Ok(out);
}

/// Decode a SETTINGS payload into a caller-owned list. Preferred over the
/// returning form when the caller inspects the struct fields: a nested
/// generic return (`Result[Vec[H2Setting], Str]`) is type-erased at some
/// call sites. The list is cleared first.
pub fn h2_settings_decode_into(payload: &Vec[UInt8], out: &mut Vec[H2Setting]) -> Result[Unit, Str]
  ensures: (payload.len() % 6 != 0) => (result.is_err)
{
  if payload.len() % 6 != 0 {
    return Err("h2: SETTINGS length not a multiple of 6");
  }
  out.clear();
  var i = 0;
  while i < payload.len() {
    let id = ((payload[i] as Int) << 8) | (payload[i + 1] as Int);
    let value = ((payload[i + 2] as Int) << 24) | ((payload[i + 3] as Int) << 16) | ((payload[i + 4] as Int) << 8) | (payload[i + 5] as Int);
    out.push(H2Setting{ id: id; value: value; });
    i = i + 6;
  }
  return Ok(());
}

/// Validate the SETTINGS entries: duplicate ids, ENABLE_PUSH 0/1,
/// INITIAL_WINDOW_SIZE <= 2^31-1, and MAX_FRAME_SIZE 16384..=16777215.
/// Unknown ids are accepted (RFC 9113 section 6.5.2).
pub fn h2_settings_validate(settings: &Vec[H2Setting]) -> Result[Unit, Str]
  requires: true
{
  var i = 0;
  while i < settings.len() {
    let s = settings[i];
    if s.id == H2_SETTINGS_ENABLE_PUSH {
      if s.value != 0 && s.value != 1 {
        return Err("h2: ENABLE_PUSH must be 0 or 1");
      }
    }
    if s.id == H2_SETTINGS_INITIAL_WINDOW_SIZE {
      if s.value > H2_MAX_WINDOW {
        return Err("h2: INITIAL_WINDOW_SIZE too large");
      }
    }
    if s.id == H2_SETTINGS_MAX_FRAME_SIZE {
      if s.value < 16384 || s.value > 16777215 {
        return Err("h2: MAX_FRAME_SIZE out of range");
      }
    }
    var j = i + 1;
    while j < settings.len() {
      if settings[j].id == s.id {
        return Err("h2: duplicate SETTINGS id");
      }
      j = j + 1;
    }
    i = i + 1;
  }
  return Ok(());
}

/// A one-direction HTTP/2 flow-control window.
pub type H2Window = {
  available: Int;
  initial: Int;
}

/// Create a window with `initial` available bytes.
pub fn h2_window_new(initial: Int) -> H2Window
  requires: initial >= 0 && initial <= H2_MAX_WINDOW
  ensures: result.available == initial
  ensures: result.initial == initial
{
  return H2Window{ available: initial; initial: initial; };
}

/// Current available window bytes.
pub fn h2_window_available(w: &H2Window) -> Int
  ensures: result == w.available
{
  return w.available;
}

/// Consume up to `n` bytes. Err on a negative value or an underflow.
pub fn h2_window_consume(w: &mut H2Window, n: Int) -> Result[Int, Str]
  requires: w.available >= 0 && w.available <= H2_MAX_WINDOW
{
  if n < 0 {
    return Err("h2: negative window consume");
  }
  if n > w.available {
    return Err("h2: flow-control window underflow");
  }
  w.available = w.available - n;
  return Ok(w.available);
}

/// Add `n` bytes (WINDOW_UPDATE). Err on a non-positive value or overflow.
pub fn h2_window_increment(w: &mut H2Window, n: Int) -> Result[Int, Str]
  requires: w.available >= 0 && w.available <= H2_MAX_WINDOW
{
  if n <= 0 {
    return Err("h2: non-positive window increment");
  }
  if w.available + n > H2_MAX_WINDOW {
    return Err("h2: flow-control window overflow");
  }
  w.available = w.available + n;
  return Ok(w.available);
}

/// Apply a SETTINGS INITIAL_WINDOW_SIZE change: shift `available` by the
/// difference and record the new initial. Err when the shift underflows or
/// overflows.
pub fn h2_window_resize(w: &mut H2Window, new_initial: Int) -> Result[Int, Str]
  requires: new_initial >= 0 && new_initial <= H2_MAX_WINDOW
  requires: w.available >= 0 && w.available <= H2_MAX_WINDOW
{
  let delta = new_initial - w.initial;
  if w.available + delta < 0 {
    return Err("h2: window resize underflow");
  }
  if w.available + delta > H2_MAX_WINDOW {
    return Err("h2: window resize overflow");
  }
  w.available = w.available + delta;
  w.initial = new_initial;
  return Ok(w.available);
}

// ---------------------------------------------------------------------------
// Stream states (RFC 9113 section 5.1)
// ---------------------------------------------------------------------------

/// Per-stream HTTP/2 state.
pub type H2StreamState = enum { Idle, Open, HalfClosedLocal, HalfClosedRemote, Closed }

/// Events that drive the per-stream state machine. HEADERS/DATA with
/// END_STREAM are modelled as the frame event followed by the EndStream event.
pub type H2StreamEvent = enum { SendHeaders, RecvHeaders, SendData, RecvData, SendEndStream, RecvEndStream, SendRst, RecvRst }

/// Stable diagnostic name for a stream state.
pub fn h2_stream_state_name(state: H2StreamState) -> Str
  requires: true
{
  match state {
    H2StreamState.Idle => "idle",
    H2StreamState.Open => "open",
    H2StreamState.HalfClosedLocal => "half-closed-local",
    H2StreamState.HalfClosedRemote => "half-closed-remote",
    H2StreamState.Closed => "closed",
  }
}

/// Apply one event to a stream state. Err on a protocol-invalid transition
/// (for example DATA on an idle stream, a send after local END_STREAM, or any
/// event on a closed stream).
pub fn h2_stream_transition(state: H2StreamState, event: H2StreamEvent) -> Result[H2StreamState, Str]
  requires: true
{
  match state {
    H2StreamState.Idle => {
      match event {
        H2StreamEvent.SendHeaders => { return Ok(H2StreamState.Open); },
        H2StreamEvent.RecvHeaders => { return Ok(H2StreamState.Open); },
        H2StreamEvent.SendRst => { return Err("h2: RST_STREAM on idle stream"); },
        _ => { return Err("h2: invalid event on idle stream"); },
      }
    },
    H2StreamState.Open => {
      match event {
        H2StreamEvent.SendEndStream => { return Ok(H2StreamState.HalfClosedLocal); },
        H2StreamEvent.RecvEndStream => { return Ok(H2StreamState.HalfClosedRemote); },
        H2StreamEvent.SendRst => { return Ok(H2StreamState.Closed); },
        H2StreamEvent.RecvRst => { return Ok(H2StreamState.Closed); },
        _ => { return Ok(H2StreamState.Open); },
      }
    },
    H2StreamState.HalfClosedLocal => {
      match event {
        H2StreamEvent.RecvEndStream => { return Ok(H2StreamState.Closed); },
        H2StreamEvent.SendRst => { return Ok(H2StreamState.Closed); },
        H2StreamEvent.RecvRst => { return Ok(H2StreamState.Closed); },
        H2StreamEvent.SendHeaders => { return Err("h2: send after local END_STREAM"); },
        H2StreamEvent.SendData => { return Err("h2: send after local END_STREAM"); },
        H2StreamEvent.SendEndStream => { return Err("h2: duplicate local END_STREAM"); },
        _ => { return Ok(H2StreamState.HalfClosedLocal); },
      }
    },
    H2StreamState.HalfClosedRemote => {
      match event {
        H2StreamEvent.SendEndStream => { return Ok(H2StreamState.Closed); },
        H2StreamEvent.SendRst => { return Ok(H2StreamState.Closed); },
        H2StreamEvent.RecvRst => { return Ok(H2StreamState.Closed); },
        H2StreamEvent.RecvHeaders => { return Err("h2: recv after remote END_STREAM"); },
        H2StreamEvent.RecvData => { return Err("h2: recv after remote END_STREAM"); },
        H2StreamEvent.RecvEndStream => { return Err("h2: duplicate remote END_STREAM"); },
        _ => { return Ok(H2StreamState.HalfClosedRemote); },
      }
    },
    H2StreamState.Closed => {
      return Err("h2: event on closed stream");
    },
  }
  return Err("h2: unreachable stream transition");
}

// ---------------------------------------------------------------------------
// Connection-control frames + stream ids (RFC 9113 sections 5.1.1 / 6.4 / 6.8)
// ---------------------------------------------------------------------------

/// Next locally initiated stream id. Client ids are odd, server ids even;
/// `last_id` is the last locally used id (0 = none). Err above 2^31-1.
pub fn h2_stream_id_next(last_id: Int, local_is_client: Bool) -> Result[Int, Str]
  requires: last_id >= 0 && last_id <= 0x7FFFFFFF
{
  if last_id == 0 {
    if local_is_client { return Ok(1); }
    return Ok(2);
  }
  if last_id + 2 > 0x7FFFFFFF {
    return Err("h2: stream id exhausted");
  }
  return Ok(last_id + 2);
}

/// True for client-initiated (odd) stream ids.
pub fn h2_stream_id_is_client(id: Int) -> Bool
  requires: id > 0
{
  return id % 2 == 1;
}

/// RST_STREAM payload (4-byte error code).
pub fn h2_rst_stream_encode(error_code: Int) -> Result[Vec[UInt8], Str]
  ensures: (error_code < 0 || error_code > 0xFFFFFFFF) => (result.is_err)
{
  if error_code < 0 || error_code > 0xFFFFFFFF {
    return Err("h2: RST_STREAM error code out of range");
  }
  var out = Vec[UInt8].new();
  _h2_push_u32(&mut out, error_code);
  return Ok(out);
}

/// Decode a RST_STREAM payload. Err when the length is not 4.
pub fn h2_rst_stream_decode(payload: &Vec[UInt8]) -> Result[Int, Str]
  ensures: (payload.len() != 4) => (result.is_err)
{
  if payload.len() != 4 {
    return Err("h2: RST_STREAM length must be 4");
  }
  let code = ((payload[0] as Int) << 24) | ((payload[1] as Int) << 16) | ((payload[2] as Int) << 8) | (payload[3] as Int);
  return Ok(code);
}

/// GOAWAY payload: last stream id (31 bits), error code, debug data.
pub fn h2_goaway_encode(last_stream_id: Int, error_code: Int, debug: &Vec[UInt8]) -> Result[Vec[UInt8], Str]
  ensures: (last_stream_id < 0 || last_stream_id > 0x7FFFFFFF || error_code < 0 || error_code > 0xFFFFFFFF) => (result.is_err)
{
  if last_stream_id < 0 || last_stream_id > 0x7FFFFFFF {
    return Err("h2: GOAWAY last stream id out of range");
  }
  if error_code < 0 || error_code > 0xFFFFFFFF {
    return Err("h2: GOAWAY error code out of range");
  }
  var out = Vec[UInt8].new();
  _h2_push_u32(&mut out, last_stream_id);
  _h2_push_u32(&mut out, error_code);
  var i = 0;
  while i < debug.len() {
    out.push(debug[i]);
    i = i + 1;
  }
  return Ok(out);
}

/// Decode GOAWAY into (last_stream_id, error_code) and copy the debug data
/// into the caller-owned vector. The last-id reserved bit is masked.
pub fn h2_goaway_decode_into(payload: &Vec[UInt8], debug: &mut Vec[UInt8]) -> Result[(Int, Int), Str]
  ensures: (payload.len() < 8) => (result.is_err)
{
  if payload.len() < 8 {
    return Err("h2: GOAWAY payload too short");
  }
  let last = ((payload[0] as Int) << 24) | ((payload[1] as Int) << 16) | ((payload[2] as Int) << 8) | (payload[3] as Int);
  let code = ((payload[4] as Int) << 24) | ((payload[5] as Int) << 16) | ((payload[6] as Int) << 8) | (payload[7] as Int);
  debug.clear();
  var i = 8;
  while i < payload.len() {
    debug.push(payload[i]);
    i = i + 1;
  }
  return Ok((last & 0x7FFFFFFF, code));
}

/// WINDOW_UPDATE payload (4-byte increment, reserved bit 0, 1..=2^31-1).
pub fn h2_window_update_encode(increment: Int) -> Result[Vec[UInt8], Str]
  ensures: (increment < 1 || increment > 0x7FFFFFFF) => (result.is_err)
{
  if increment < 1 || increment > 0x7FFFFFFF {
    return Err("h2: WINDOW_UPDATE increment out of range");
  }
  var out = Vec[UInt8].new();
  _h2_push_u32(&mut out, increment);
  return Ok(out);
}

/// Decode a WINDOW_UPDATE payload; the reserved bit is masked and an
/// increment of 0 is a protocol error.
pub fn h2_window_update_decode(payload: &Vec[UInt8]) -> Result[Int, Str]
  ensures: (payload.len() != 4) => (result.is_err)
{
  if payload.len() != 4 {
    return Err("h2: WINDOW_UPDATE length must be 4");
  }
  let inc = (((payload[0] as Int) << 24) | ((payload[1] as Int) << 16) | ((payload[2] as Int) << 8) | (payload[3] as Int)) & 0x7FFFFFFF;
  if inc == 0 {
    return Err("h2: WINDOW_UPDATE increment 0");
  }
  return Ok(inc);
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

/// Decode an HPACK string at `pos`. Returns (string, consumed bytes). Both
/// H=0 and H=1 (Huffman) string bodies are supported.
pub fn h2_hpack_string_decode(bytes: &Vec[UInt8], pos: Int) -> Result[(Str, Int), Str]
  ensures: (pos < 0 || pos >= bytes.len()) => (result.is_err)
{
  if pos < 0 || pos >= bytes.len() {
    return Err("h2: HPACK string position out of range");
  };
  let is_huffman = ((bytes[pos] as Int) & 0x80) != 0;
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
      if is_huffman {
        let hs = h2_hpack_huffman_decode(&raw);
        match hs {
          Err(e) => { return Err(e); },
          Ok(s) => { return Ok((s, used + length)); },
        }
      }
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
// HPACK Huffman code (RFC 7541 Appendix B)
// ---------------------------------------------------------------------------

// The 257-entry code table as one private chain (no module-level tables).
// Each entry is (code right-aligned to the LSB, bit length).
fn _h2_huffman_code(sym: Int) -> (Int, Int) {
  if sym == 0 { return (0x1ff8, 13); }
  if sym == 1 { return (0x7fffd8, 23); }
  if sym == 2 { return (0xfffffe2, 28); }
  if sym == 3 { return (0xfffffe3, 28); }
  if sym == 4 { return (0xfffffe4, 28); }
  if sym == 5 { return (0xfffffe5, 28); }
  if sym == 6 { return (0xfffffe6, 28); }
  if sym == 7 { return (0xfffffe7, 28); }
  if sym == 8 { return (0xfffffe8, 28); }
  if sym == 9 { return (0xffffea, 24); }
  if sym == 10 { return (0x3ffffffc, 30); }
  if sym == 11 { return (0xfffffe9, 28); }
  if sym == 12 { return (0xfffffea, 28); }
  if sym == 13 { return (0x3ffffffd, 30); }
  if sym == 14 { return (0xfffffeb, 28); }
  if sym == 15 { return (0xfffffec, 28); }
  if sym == 16 { return (0xfffffed, 28); }
  if sym == 17 { return (0xfffffee, 28); }
  if sym == 18 { return (0xfffffef, 28); }
  if sym == 19 { return (0xffffff0, 28); }
  if sym == 20 { return (0xffffff1, 28); }
  if sym == 21 { return (0xffffff2, 28); }
  if sym == 22 { return (0x3ffffffe, 30); }
  if sym == 23 { return (0xffffff3, 28); }
  if sym == 24 { return (0xffffff4, 28); }
  if sym == 25 { return (0xffffff5, 28); }
  if sym == 26 { return (0xffffff6, 28); }
  if sym == 27 { return (0xffffff7, 28); }
  if sym == 28 { return (0xffffff8, 28); }
  if sym == 29 { return (0xffffff9, 28); }
  if sym == 30 { return (0xffffffa, 28); }
  if sym == 31 { return (0xffffffb, 28); }
  if sym == 32 { return (0x14, 6); }
  if sym == 33 { return (0x3f8, 10); }
  if sym == 34 { return (0x3f9, 10); }
  if sym == 35 { return (0xffa, 12); }
  if sym == 36 { return (0x1ff9, 13); }
  if sym == 37 { return (0x15, 6); }
  if sym == 38 { return (0xf8, 8); }
  if sym == 39 { return (0x7fa, 11); }
  if sym == 40 { return (0x3fa, 10); }
  if sym == 41 { return (0x3fb, 10); }
  if sym == 42 { return (0xf9, 8); }
  if sym == 43 { return (0x7fb, 11); }
  if sym == 44 { return (0xfa, 8); }
  if sym == 45 { return (0x16, 6); }
  if sym == 46 { return (0x17, 6); }
  if sym == 47 { return (0x18, 6); }
  if sym == 48 { return (0x0, 5); }
  if sym == 49 { return (0x1, 5); }
  if sym == 50 { return (0x2, 5); }
  if sym == 51 { return (0x19, 6); }
  if sym == 52 { return (0x1a, 6); }
  if sym == 53 { return (0x1b, 6); }
  if sym == 54 { return (0x1c, 6); }
  if sym == 55 { return (0x1d, 6); }
  if sym == 56 { return (0x1e, 6); }
  if sym == 57 { return (0x1f, 6); }
  if sym == 58 { return (0x5c, 7); }
  if sym == 59 { return (0xfb, 8); }
  if sym == 60 { return (0x7ffc, 15); }
  if sym == 61 { return (0x20, 6); }
  if sym == 62 { return (0xffb, 12); }
  if sym == 63 { return (0x3fc, 10); }
  if sym == 64 { return (0x1ffa, 13); }
  if sym == 65 { return (0x21, 6); }
  if sym == 66 { return (0x5d, 7); }
  if sym == 67 { return (0x5e, 7); }
  if sym == 68 { return (0x5f, 7); }
  if sym == 69 { return (0x60, 7); }
  if sym == 70 { return (0x61, 7); }
  if sym == 71 { return (0x62, 7); }
  if sym == 72 { return (0x63, 7); }
  if sym == 73 { return (0x64, 7); }
  if sym == 74 { return (0x65, 7); }
  if sym == 75 { return (0x66, 7); }
  if sym == 76 { return (0x67, 7); }
  if sym == 77 { return (0x68, 7); }
  if sym == 78 { return (0x69, 7); }
  if sym == 79 { return (0x6a, 7); }
  if sym == 80 { return (0x6b, 7); }
  if sym == 81 { return (0x6c, 7); }
  if sym == 82 { return (0x6d, 7); }
  if sym == 83 { return (0x6e, 7); }
  if sym == 84 { return (0x6f, 7); }
  if sym == 85 { return (0x70, 7); }
  if sym == 86 { return (0x71, 7); }
  if sym == 87 { return (0x72, 7); }
  if sym == 88 { return (0xfc, 8); }
  if sym == 89 { return (0x73, 7); }
  if sym == 90 { return (0xfd, 8); }
  if sym == 91 { return (0x1ffb, 13); }
  if sym == 92 { return (0x7fff0, 19); }
  if sym == 93 { return (0x1ffc, 13); }
  if sym == 94 { return (0x3ffc, 14); }
  if sym == 95 { return (0x22, 6); }
  if sym == 96 { return (0x7ffd, 15); }
  if sym == 97 { return (0x3, 5); }
  if sym == 98 { return (0x23, 6); }
  if sym == 99 { return (0x4, 5); }
  if sym == 100 { return (0x24, 6); }
  if sym == 101 { return (0x5, 5); }
  if sym == 102 { return (0x25, 6); }
  if sym == 103 { return (0x26, 6); }
  if sym == 104 { return (0x27, 6); }
  if sym == 105 { return (0x6, 5); }
  if sym == 106 { return (0x74, 7); }
  if sym == 107 { return (0x75, 7); }
  if sym == 108 { return (0x28, 6); }
  if sym == 109 { return (0x29, 6); }
  if sym == 110 { return (0x2a, 6); }
  if sym == 111 { return (0x7, 5); }
  if sym == 112 { return (0x2b, 6); }
  if sym == 113 { return (0x76, 7); }
  if sym == 114 { return (0x2c, 6); }
  if sym == 115 { return (0x8, 5); }
  if sym == 116 { return (0x9, 5); }
  if sym == 117 { return (0x2d, 6); }
  if sym == 118 { return (0x77, 7); }
  if sym == 119 { return (0x78, 7); }
  if sym == 120 { return (0x79, 7); }
  if sym == 121 { return (0x7a, 7); }
  if sym == 122 { return (0x7b, 7); }
  if sym == 123 { return (0x7ffe, 15); }
  if sym == 124 { return (0x7fc, 11); }
  if sym == 125 { return (0x3ffd, 14); }
  if sym == 126 { return (0x1ffd, 13); }
  if sym == 127 { return (0xffffffc, 28); }
  if sym == 128 { return (0xfffe6, 20); }
  if sym == 129 { return (0x3fffd2, 22); }
  if sym == 130 { return (0xfffe7, 20); }
  if sym == 131 { return (0xfffe8, 20); }
  if sym == 132 { return (0x3fffd3, 22); }
  if sym == 133 { return (0x3fffd4, 22); }
  if sym == 134 { return (0x3fffd5, 22); }
  if sym == 135 { return (0x7fffd9, 23); }
  if sym == 136 { return (0x3fffd6, 22); }
  if sym == 137 { return (0x7fffda, 23); }
  if sym == 138 { return (0x7fffdb, 23); }
  if sym == 139 { return (0x7fffdc, 23); }
  if sym == 140 { return (0x7fffdd, 23); }
  if sym == 141 { return (0x7fffde, 23); }
  if sym == 142 { return (0xffffeb, 24); }
  if sym == 143 { return (0x7fffdf, 23); }
  if sym == 144 { return (0xffffec, 24); }
  if sym == 145 { return (0xffffed, 24); }
  if sym == 146 { return (0x3fffd7, 22); }
  if sym == 147 { return (0x7fffe0, 23); }
  if sym == 148 { return (0xffffee, 24); }
  if sym == 149 { return (0x7fffe1, 23); }
  if sym == 150 { return (0x7fffe2, 23); }
  if sym == 151 { return (0x7fffe3, 23); }
  if sym == 152 { return (0x7fffe4, 23); }
  if sym == 153 { return (0x1fffdc, 21); }
  if sym == 154 { return (0x3fffd8, 22); }
  if sym == 155 { return (0x7fffe5, 23); }
  if sym == 156 { return (0x3fffd9, 22); }
  if sym == 157 { return (0x7fffe6, 23); }
  if sym == 158 { return (0x7fffe7, 23); }
  if sym == 159 { return (0xffffef, 24); }
  if sym == 160 { return (0x3fffda, 22); }
  if sym == 161 { return (0x1fffdd, 21); }
  if sym == 162 { return (0xfffe9, 20); }
  if sym == 163 { return (0x3fffdb, 22); }
  if sym == 164 { return (0x3fffdc, 22); }
  if sym == 165 { return (0x7fffe8, 23); }
  if sym == 166 { return (0x7fffe9, 23); }
  if sym == 167 { return (0x1fffde, 21); }
  if sym == 168 { return (0x7fffea, 23); }
  if sym == 169 { return (0x3fffdd, 22); }
  if sym == 170 { return (0x3fffde, 22); }
  if sym == 171 { return (0xfffff0, 24); }
  if sym == 172 { return (0x1fffdf, 21); }
  if sym == 173 { return (0x3fffdf, 22); }
  if sym == 174 { return (0x7fffeb, 23); }
  if sym == 175 { return (0x7fffec, 23); }
  if sym == 176 { return (0x1fffe0, 21); }
  if sym == 177 { return (0x1fffe1, 21); }
  if sym == 178 { return (0x3fffe0, 22); }
  if sym == 179 { return (0x1fffe2, 21); }
  if sym == 180 { return (0x7fffed, 23); }
  if sym == 181 { return (0x3fffe1, 22); }
  if sym == 182 { return (0x7fffee, 23); }
  if sym == 183 { return (0x7fffef, 23); }
  if sym == 184 { return (0xfffea, 20); }
  if sym == 185 { return (0x3fffe2, 22); }
  if sym == 186 { return (0x3fffe3, 22); }
  if sym == 187 { return (0x3fffe4, 22); }
  if sym == 188 { return (0x7ffff0, 23); }
  if sym == 189 { return (0x3fffe5, 22); }
  if sym == 190 { return (0x3fffe6, 22); }
  if sym == 191 { return (0x7ffff1, 23); }
  if sym == 192 { return (0x3ffffe0, 26); }
  if sym == 193 { return (0x3ffffe1, 26); }
  if sym == 194 { return (0xfffeb, 20); }
  if sym == 195 { return (0x7fff1, 19); }
  if sym == 196 { return (0x3fffe7, 22); }
  if sym == 197 { return (0x7ffff2, 23); }
  if sym == 198 { return (0x3fffe8, 22); }
  if sym == 199 { return (0x1ffffec, 25); }
  if sym == 200 { return (0x3ffffe2, 26); }
  if sym == 201 { return (0x3ffffe3, 26); }
  if sym == 202 { return (0x3ffffe4, 26); }
  if sym == 203 { return (0x7ffffde, 27); }
  if sym == 204 { return (0x7ffffdf, 27); }
  if sym == 205 { return (0x3ffffe5, 26); }
  if sym == 206 { return (0xfffff1, 24); }
  if sym == 207 { return (0x1ffffed, 25); }
  if sym == 208 { return (0x7fff2, 19); }
  if sym == 209 { return (0x1fffe3, 21); }
  if sym == 210 { return (0x3ffffe6, 26); }
  if sym == 211 { return (0x7ffffe0, 27); }
  if sym == 212 { return (0x7ffffe1, 27); }
  if sym == 213 { return (0x3ffffe7, 26); }
  if sym == 214 { return (0x7ffffe2, 27); }
  if sym == 215 { return (0xfffff2, 24); }
  if sym == 216 { return (0x1fffe4, 21); }
  if sym == 217 { return (0x1fffe5, 21); }
  if sym == 218 { return (0x3ffffe8, 26); }
  if sym == 219 { return (0x3ffffe9, 26); }
  if sym == 220 { return (0xffffffd, 28); }
  if sym == 221 { return (0x7ffffe3, 27); }
  if sym == 222 { return (0x7ffffe4, 27); }
  if sym == 223 { return (0x7ffffe5, 27); }
  if sym == 224 { return (0xfffec, 20); }
  if sym == 225 { return (0xfffff3, 24); }
  if sym == 226 { return (0xfffed, 20); }
  if sym == 227 { return (0x1fffe6, 21); }
  if sym == 228 { return (0x3fffe9, 22); }
  if sym == 229 { return (0x1fffe7, 21); }
  if sym == 230 { return (0x1fffe8, 21); }
  if sym == 231 { return (0x7ffff3, 23); }
  if sym == 232 { return (0x3fffea, 22); }
  if sym == 233 { return (0x3fffeb, 22); }
  if sym == 234 { return (0x1ffffee, 25); }
  if sym == 235 { return (0x1ffffef, 25); }
  if sym == 236 { return (0xfffff4, 24); }
  if sym == 237 { return (0xfffff5, 24); }
  if sym == 238 { return (0x3ffffea, 26); }
  if sym == 239 { return (0x7ffff4, 23); }
  if sym == 240 { return (0x3ffffeb, 26); }
  if sym == 241 { return (0x7ffffe6, 27); }
  if sym == 242 { return (0x3ffffec, 26); }
  if sym == 243 { return (0x3ffffed, 26); }
  if sym == 244 { return (0x7ffffe7, 27); }
  if sym == 245 { return (0x7ffffe8, 27); }
  if sym == 246 { return (0x7ffffe9, 27); }
  if sym == 247 { return (0x7ffffea, 27); }
  if sym == 248 { return (0x7ffffeb, 27); }
  if sym == 249 { return (0xffffffe, 28); }
  if sym == 250 { return (0x7ffffec, 27); }
  if sym == 251 { return (0x7ffffed, 27); }
  if sym == 252 { return (0x7ffffee, 27); }
  if sym == 253 { return (0x7ffffef, 27); }
  if sym == 254 { return (0x7fffff0, 27); }
  if sym == 255 { return (0x3ffffee, 26); }
  if sym == 256 { return (0x3fffffff, 30); }
  return (0, 0);
}

// Decode a Huffman-encoded byte string. Builds the code tree once per call
// from the 257-entry table, then walks it bit by bit. Returns Err on an
// invalid code, the EOS symbol, or padding that is not <=7 one-bits.
fn _h2_huffman_decode_raw(bytes: &Vec[UInt8]) -> Result[Vec[UInt8], Str] {
  var left = Vec[Int].new();
  var right = Vec[Int].new();
  var syms = Vec[Int].new();
  left.push(-1);
  right.push(-1);
  syms.push(-1);
  var s = 0;
  while s < 257 {
    let pair = _h2_huffman_code(s);
    let code = pair.0;
    let bits = pair.1;
    var node = 0;
    var b = bits - 1;
    while b >= 0 {
      let bit = (code >> b) & 1;
      var next = -1;
      if bit == 0 { next = left[node]; } else { next = right[node]; };
      if next < 0 {
        next = left.len();
        left.push(-1);
        right.push(-1);
        syms.push(-1);
        if bit == 0 { left[node] = next; } else { right[node] = next; };
      }
      node = next;
      b = b - 1;
    }
    syms[node] = s;
    s = s + 1;
  }

  var out = Vec[UInt8].new();
  var node = 0;
  var pad_bits = 0;
  var pad_ones = true;
  var i = 0;
  while i < bytes.len() {
    let byte = bytes[i] as Int;
    var b = 7;
    while b >= 0 {
      let bit = (byte >> b) & 1;
      if bit == 0 { node = left[node]; } else { node = right[node]; };
      if node < 0 { return Err("h2: invalid huffman code"); }
      pad_bits = pad_bits + 1;
      if bit == 0 { pad_ones = false; }
      if syms[node] >= 0 {
        if syms[node] == 256 { return Err("h2: huffman EOS symbol"); }
        out.push(syms[node] as UInt8);
        node = 0;
        pad_bits = 0;
        pad_ones = true;
      }
      b = b - 1;
    }
    i = i + 1;
  }
  if node != 0 {
    if pad_bits > 7 || pad_ones == false {
      return Err("h2: invalid huffman padding");
    }
  }
  return Ok(out);
}

/// Decode an RFC 7541 Huffman-coded string body (without the H bit/length
/// prefix). Err on an invalid code, EOS, or bad padding.
pub fn h2_hpack_huffman_decode(bytes: &Vec[UInt8]) -> Result[Str, Str]
  requires: true
{
  let raw = _h2_huffman_decode_raw(bytes);
  match raw {
    Err(e) => { return Err(e); },
    Ok(out) => { return Ok(Str.from_utf8(out)); },
  }
}

/// Encode a string body with the RFC 7541 Huffman code, padding the final
/// byte with one-bits. The returned bytes do NOT include the H bit/length
/// prefix; use h2_hpack_string_encode_huffman for a complete HPACK string.
pub fn h2_hpack_huffman_encode(s: Str) -> Vec[UInt8]
  requires: true
{
  var out = Vec[UInt8].new();
  var acc = 0;
  var nbits = 0;
  var i = 0;
  while i < s.len() {
    let pair = _h2_huffman_code(s.byte_at(i) as Int);
    let code = pair.0;
    let bits = pair.1;
    var b = bits - 1;
    while b >= 0 {
      let bit = (code >> b) & 1;
      acc = (acc << 1) | bit;
      nbits = nbits + 1;
      if nbits == 8 {
        out.push(acc as UInt8);
        acc = 0;
        nbits = 0;
      }
      b = b - 1;
    }
    i = i + 1;
  }
  if nbits > 0 {
    let pad = 8 - nbits;
    acc = (acc << pad) | ((1 << pad) - 1);
    out.push(acc as UInt8);
  }
  return out;
}

/// Encode a complete HPACK string with H=1: the 7-bit length prefix (with
/// the high bit set) followed by the Huffman-coded bytes.
pub fn h2_hpack_string_encode_huffman(s: Str) -> Vec[UInt8]
  ensures: result.len() >= 1
{
  let raw = h2_hpack_huffman_encode(s);
  var out = Vec[UInt8].new();
  let prefix = h2_hpack_int_encode(raw.len(), 7, 0x80);
  match prefix {
    Ok(p) => {
      var i = 0;
      while i < p.len() {
        out.push(p[i]);
        i = i + 1;
      };
    },
    Err(_) => { out.push(0x80); },
  };
  var j = 0;
  while j < raw.len() {
    out.push(raw[j]);
    j = j + 1;
  };
  return out;
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
