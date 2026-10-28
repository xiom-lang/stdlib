// XIOM - Network: HTTP/2 frame I/O over a byte stream
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Frame transport for the pure h2 primitives in xiom.net.h2: a buffered
// reader that reassembles 9-byte frame headers and payloads from a
// TcpStream, HEADERS + CONTINUATION joining, and writers for frames,
// SETTINGS/PING ACKs and a fragmented header block. No connection state
// machine here (see H2Connection in xiom.net.h2).
//
// Reading is buffered because TcpStream.read appends up to 4096 bytes per
// call: the reader keeps the excess bytes for the next frame instead of
// losing them. Payloads are capped by max_payload (default 16384, the
// RFC 9113 initial SETTINGS_MAX_FRAME_SIZE).

module xiom.net.h2_io

use xiom.net;
use xiom.net.h2;

/// Buffered HTTP/2 frame reader over a TcpStream.
/// `buf`/`start` hold the read buffer and its consumed-prefix cursor;
/// `max_payload` is the accepted frame payload size; `closed` records EOF.
pub type H2Reader = {
  stream: TcpStream;
  buf: Vec[UInt8];
  start: Int;
  max_payload: Int;
  closed: Bool;
}

// _clamp_payload clamps a requested payload cap into 1..0xFFFFFF
// (<=0 selects the RFC 9113 default 16384).
fn _clamp_payload(max_payload: Int) -> Int {
  if max_payload <= 0 {
    return 16384;
  }
  if max_payload > 0xFFFFFF {
    return 0xFFFFFF;
  }
  max_payload
}

// _compact drops fully consumed bytes and re-bases the cursor once the
// consumed prefix is large.
fn _compact(r: &mut H2Reader) {
  if r.start == r.buf.len() {
    r.buf.clear();
    r.start = 0;
  } else if r.start >= 8192 {
    var rest = Vec[UInt8].new();
    rest.reserve(r.buf.len() - r.start);
    var i = r.start;
    while i < r.buf.len() {
      rest.push(r.buf[i]);
      i = i + 1;
    }
    r.buf = rest;
    r.start = 0;
  }
}

// _ensure reads until at least n bytes are buffered. Ok(false) on EOF
// before n bytes; Err on a transport failure. The read targets a local
// vector and the bytes are appended after the call: passing `&mut r.buf`
// directly to a method on a cloned struct field is the known
// aggregate/field-receiver aliasing trap (the second read sees EOF).
fn _ensure(r: &mut H2Reader, n: Int) -> Result[Bool, Str] {
  while r.buf.len() - r.start < n {
    if r.closed {
      return Ok(false);
    }
    var chunk = Vec[UInt8].new();
    match r.stream.clone().read(&mut chunk) {
      Ok(0) => {
        r.closed = true;
        return Ok(false);
      },
      Ok(k) => {
        var i = 0;
        while i < k {
          r.buf.push(chunk[i]);
          i = i + 1;
        }
      },
      Err(e) => { return Err("h2_io: read failed: " + e.message); },
    }
  }
  return Ok(true);
}

/// Create a frame reader. `max_payload <= 0` selects 16384; values above
/// 0xFFFFFF are clamped.
/// Parameters: stream -- the transport; max_payload -- accepted payload cap.
/// Complexity: O(1).
pub fn h2_reader_new(stream: TcpStream, max_payload: Int) -> H2Reader
  ensures: result.max_payload >= 1
  ensures: result.max_payload <= 0xFFFFFF
{
  return H2Reader{
    stream: stream;
    buf: Vec[UInt8].new();
    start: 0;
    max_payload: _clamp_payload(max_payload);
    closed: false;
  };
}

/// Bytes buffered but not yet consumed.
/// Complexity: O(1).
pub fn h2_reader_available(r: &H2Reader) -> Int
  ensures: result >= 0
{
  return r.buf.len() - r.start;
}

/// Read one complete frame. Err on EOF (no partial header), a closed
/// stream mid-frame, a payload above max_payload, or a transport failure.
/// Complexity: O(frame).
pub fn h2_reader_read_frame(r: &mut H2Reader) -> Result[(H2FrameHeader, Vec[UInt8]), Str]
  ensures: true
{
  let has_header = _ensure(r, 9);
  match has_header {
    Err(e) => { return Err(e); },
    Ok(v) => {
      if !v {
        return Err("h2_io: stream closed");
      }
    },
  }
  var hbytes = Vec[UInt8].new();
  var i = 0;
  while i < 9 {
    hbytes.push(r.buf[r.start + i]);
    i = i + 1;
  }
  let decoded = h2.h2_frame_header_decode(&hbytes);
  match decoded {
    Err(e) => { return Err(e); },
    Ok(h) => {
      if h.length > r.max_payload {
        return Err("h2_io: frame payload exceeds max_payload");
      }
      let need = 9 + h.length;
      let has_frame = _ensure(r, need);
      match has_frame {
        Err(e) => { return Err(e); },
        Ok(v) => {
          if !v {
            return Err("h2_io: stream closed mid-frame");
          }
        },
      }
      var payload = Vec[UInt8].new();
      payload.reserve(h.length);
      var j = 0;
      while j < h.length {
        payload.push(r.buf[r.start + 9 + j]);
        j = j + 1;
      }
      r.start = r.start + need;
      _compact(r);
      return Ok((h, payload));
    },
  }
}

/// Join a HEADERS frame payload with its CONTINUATION frames until
/// END_HEADERS. Err when the first frame is not HEADERS, an intermediate
/// frame is not CONTINUATION on the same stream, or the block exceeds
/// `max_block` (<=0 selects 1 MiB).
/// Parameters: r -- the reader; first -- the HEADERS frame just read;
///         max_block -- the assembled block cap.
/// Complexity: O(block).
pub fn h2_join_header_block(r: &mut H2Reader, first: (H2FrameHeader, Vec[UInt8]), max_block: Int) -> Result[Vec[UInt8], Str]
  ensures: true
{
  if first.0.frame_type != h2.H2_FRAME_HEADERS {
    return Err("h2_io: header block must start with HEADERS");
  }
  let cap = if max_block <= 0 { 1048576 } else { max_block };
  var out = Vec[UInt8].new();
  out.reserve(first.1.len());
  var i = 0;
  while i < first.1.len() {
    out.push(first.1[i]);
    i = i + 1;
  }
  if (first.0.flags & h2.H2_FLAG_END_HEADERS) != 0 {
    return Ok(out);
  }
  var done = false;
  while !done {
    let next = h2_reader_read_frame(r);
    match next {
      Err(e) => { return Err(e); },
      Ok(f) => {
        if f.0.frame_type != h2.H2_FRAME_CONTINUATION {
          return Err("h2_io: expected CONTINUATION");
        }
        if f.0.stream_id != first.0.stream_id {
          return Err("h2_io: CONTINUATION stream mismatch");
        }
        if out.len() + f.1.len() > cap {
          return Err("h2_io: header block exceeds max_block");
        }
        var k = 0;
        while k < f.1.len() {
          out.push(f.1[k]);
          k = k + 1;
        }
        if (f.0.flags & h2.H2_FLAG_END_HEADERS) != 0 {
          done = true;
        }
      },
    }
  }
  return Ok(out);
}

/// Close the underlying socket and mark the reader closed.
/// Complexity: O(1).
pub fn h2_reader_close(r: &mut H2Reader)
  ensures: r.closed == true
{
  if !r.closed {
    let _ = r.stream.clone().close();
    r.closed = true;
  }
}

/// Encode and write one frame. Returns the bytes written.
/// Parameters: stream -- the transport; frame_type/flags/stream_id --
///         the frame header; payload -- the frame payload.
/// Complexity: O(payload).
pub fn h2_write_frame(stream: &TcpStream, frame_type: Int, flags: Int, stream_id: Int, payload: &Vec[UInt8]) -> Result[Int, Str]
  ensures: (result.is_ok == true) => (result.value >= 9)
{
  let encoded = h2.h2_frame_encode(frame_type, flags, stream_id, payload);
  match encoded {
    Err(e) => { return Err(e); },
    Ok(bytes) => {
      match stream.clone().write_all(&bytes) {
        Ok(n) => { return Ok(n); },
        Err(e) => { return Err("h2_io: write failed: " + e.message); },
      }
    },
  }
}

/// Write an empty SETTINGS frame with the ACK flag on stream 0.
/// Complexity: O(1).
pub fn h2_write_settings_ack(stream: &TcpStream) -> Result[Int, Str]
  ensures: (result.is_ok == true) => (result.value == 9)
{
  var empty = Vec[UInt8].new();
  return h2_write_frame(stream, h2.H2_FRAME_SETTINGS, h2.H2_FLAG_ACK, 0, &empty);
}

/// Write a PING ACK carrying the 8-byte opaque payload.
/// Complexity: O(1).
pub fn h2_write_ping_ack(stream: &TcpStream, payload: &Vec[UInt8]) -> Result[Int, Str]
  ensures: (payload.len() != 8) => (result.is_err == true)
  ensures: (result.is_ok == true) => (result.value == 9 + payload.len())
{
  if payload.len() != 8 {
    return Err("h2_io: PING payload must be 8 bytes");
  }
  return h2_write_frame(stream, h2.H2_FRAME_PING, h2.H2_FLAG_ACK, 0, payload);
}

/// Write a header block as HEADERS + CONTINUATION frames. The first frame
/// carries END_STREAM when `end_stream`; the last carries END_HEADERS.
/// `max_frame <= 0` selects 16384. Returns the total bytes written.
/// Parameters: stream -- the transport; stream_id -- the stream;
///         block -- the encoded header block; end_stream -- END_STREAM on
///         the HEADERS frame; max_frame -- fragment size.
/// Complexity: O(block).
pub fn h2_write_header_block(stream: &TcpStream, stream_id: Int, block: &Vec[UInt8], end_stream: Bool, max_frame: Int) -> Result[Int, Str]
  ensures: (stream_id < 0 || stream_id > 0x7FFFFFFF) => (result.is_err == true)
{
  if stream_id < 0 || stream_id > 0x7FFFFFFF {
    return Err("h2_io: stream id out of range");
  }
  var cap = max_frame;
  if cap <= 0 { cap = 16384; }
  if cap > 0xFFFFFF { cap = 0xFFFFFF; }
  var total = 0;
  if block.len() == 0 {
    var empty = Vec[UInt8].new();
    return h2_write_frame(stream, h2.H2_FRAME_HEADERS, h2.H2_FLAG_END_HEADERS, stream_id, &empty);
  }
  var off = 0;
  var first = true;
  while off < block.len() {
    let remaining = block.len() - off;
    let take = if remaining < cap { remaining } else { cap };
    var chunk = Vec[UInt8].new();
    chunk.reserve(take);
    var i = 0;
    while i < take {
      chunk.push(block[off + i]);
      i = i + 1;
    }
    let is_last = off + take >= block.len();
    var flags = 0;
    if is_last { flags = flags | h2.H2_FLAG_END_HEADERS; }
    if first && end_stream { flags = flags | h2.H2_FLAG_END_STREAM; }
    let ftype = if first { h2.H2_FRAME_HEADERS } else { h2.H2_FRAME_CONTINUATION };
    match h2_write_frame(stream, ftype, flags, stream_id, &chunk) {
      Err(e) => { return Err(e); },
      Ok(n) => { total = total + n; },
    }
    first = false;
    off = off + take;
  }
  return Ok(total);
}
