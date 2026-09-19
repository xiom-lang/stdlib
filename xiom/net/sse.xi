// XIOM - Network: Server-Sent Events Client
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.net.sse

// Depends on: xiom.net, xiom.string

// ============================================================================
// Server-Sent Events client per the WHATWG SSE spec. The wire builders live in
// net.xi; this module owns connection lifecycle and parsing. Parsing and the
// pure event accessors are fully implemented; the connection functions require
// a live TcpStream -- they are documented stubs returning Err.
// ============================================================================

use xiom.string;
use xiom.net;

/// struct SseConnection { socket: TcpStream; url: Str; open: Bool }
pub type SseConnection = {
  socket: net.TcpStream;
  url: Str;
  open: Bool;
}

/// struct SseEvent { id: Str; event: Str; data: Str; retry: Int }
pub type SseEvent = {
  id: Str;
  event: Str;
  data: Str;
  retry: Int;
}

// split splits s on every occurrence of delim.
fn split(s: Str, delim: Str) -> Vec[Str] {
  var result: Vec[Str] = Vec[Str]::new();
  let dlen = delim.len();
  if dlen == 0 {
    var i = 0;
    while i < s.len() {
      result.push(string.str_slice(s, i, i + 1));
      i = i + 1;
    }
    return result;
  }
  var start = 0;
  var pos = 0;
  let slen = s.len();
  while pos < slen {
    if pos + dlen <= slen && string.str_slice(s, pos, pos + dlen) == delim {
      result.push(string.str_slice(s, start, pos));
      pos = pos + dlen;
      start = pos;
    } else {
      pos = pos + 1;
    }
  }
  result.push(string.str_slice(s, start, slen));
  result
}

// fresh re-slices a string read from a vector element.
fn fresh(s: Str) -> Str {
  string.str_slice(s, 0, s.len())
}

// strip_cr removes a trailing carriage return.
fn strip_cr(s: Str) -> Str {
  let len = s.len();
  if len > 0 && s.byte_at(len - 1) == 13 {
    return string.str_slice(s, 0, len - 1);
  }
  s
}

// append_line appends a line's field value to an accumulator per the SSE
// spec: data lines are joined with "\n", event/id take the last value, retry
// takes the last parseable value.
fn apply_line(e: SseEvent, line: Str) -> SseEvent {
  let l = strip_cr(line);
  let len = l.len();
  if len == 0 {
    return e;
  }
  var value: Str = "";
  var field: Str = l;
  if l.byte_at(0) == 58 {
    // Comment line: ignored.
    return e;
  }
  var colon = -1;
  var i = 0;
  while i < len {
    if l.byte_at(i) == 58 {
      colon = i;
      break;
    }
    i = i + 1;
  }
  if colon >= 0 {
    field = string.str_slice(l, 0, colon);
    if colon + 1 < len && l.byte_at(colon + 1) == 32 {
      value = string.str_slice(l, colon + 2, len);
    } else {
      value = string.str_slice(l, colon + 1, len);
    }
  }
  if field == "data" {
    if e.data.len() == 0 {
      return SseEvent{ id: e.id; event: e.event; data: value; retry: e.retry; };
    }
    let joined = e.data + "\n" + value;
    return SseEvent{ id: e.id; event: e.event; data: joined; retry: e.retry; };
  }
  if field == "id" {
    return SseEvent{ id: value; event: e.event; data: e.data; retry: e.retry; };
  }
  if field == "event" {
    return SseEvent{ id: e.id; event: value; data: e.data; retry: e.retry; };
  }
  if field == "retry" {
    var r: Int = 0;
    var k = 0;
    while k < value.len() {
      let b = value.byte_at(k);
      if b < 48 || b > 57 {
        return e;
      }
      r = r * 10 + (b as Int - 48);
      k = k + 1;
    }
    return SseEvent{ id: e.id; event: e.event; data: e.data; retry: r; };
  }
  e
}

/// Parse one raw event chunk.
/// Parameters: chunk -- a raw event block (a sequence of "field: value" lines
///          ending with a blank line).
/// Returns: Ok(SseEvent) for a well-formed chunk, Err for an empty chunk.
/// Complexity: O(n). Pure.
pub fn sse_parse_event(chunk: Str) -> Result[SseEvent, Str] {
  if chunk.len() == 0 {
    return Err("empty event chunk");
  }
  var e = SseEvent{ id: ""; event: "message"; data: ""; retry: 0; };
  let lines = split(chunk, "\n");
  var i = 0;
  while i < lines.len() {
    let line = fresh(lines[i]);
    e = apply_line(e, line);
    i = i + 1;
  }
  Ok(e)
}

/// Return the event id field.
/// Parameters: e -- the event.
/// Returns: Some(id) when the id is non-empty, None otherwise.
/// Complexity: O(1). Pure.
pub fn sse_event_id(e: SseEvent) -> Option[Str] {
  if e.id.len() > 0 {
    return Some(e.id);
  }
  None
}

/// Return the event data field.
/// Parameters: e -- the event.
/// Returns: the data field (possibly "").
/// Complexity: O(1). Pure.
pub fn sse_event_data(e: SseEvent) -> Str {
  e.data
}

/// Open a text/event-stream connection.
/// NOT IMPLEMENTED: requires a live TCP connection that the pure stdlib does
/// not manage.
/// Returns: Err("sse_connect: TCP connections not available in the pure stdlib").
pub fn sse_connect(url: Str) -> Result[SseConnection, Str] {
  let _ = url;
  Err("sse_connect: TCP connections not available in the pure stdlib")
}

/// Connect with custom request headers.
/// NOT IMPLEMENTED: requires a live TCP connection (see sse_connect).
/// Returns: Err("sse_connect_headers: TCP connections not available in the pure stdlib").
pub fn sse_connect_headers(url: Str, headers: &Vec[(Str, Str)]) -> Result[SseConnection, Str] {
  let _ = url;
  let _ = headers;
  Err("sse_connect_headers: TCP connections not available in the pure stdlib")
}

/// Read and parse the next event.
/// NOT IMPLEMENTED: requires a live connection (see sse_connect).
/// Returns: Err("sse_read_event: connection not available in the pure stdlib").
pub fn sse_read_event(conn: SseConnection) -> Result[SseEvent, Str] {
  let _ = conn;
  Err("sse_read_event: connection not available in the pure stdlib")
}

/// Close the event stream connection.
/// NO-OP: no live connection exists in the pure stdlib.
pub fn sse_close(conn: SseConnection) {
  let _ = conn;
}

/// Drain available events into out and return the count.
/// NOT IMPLEMENTED: requires a live connection (see sse_connect). Always
/// returns 0 with the output vector untouched.
pub fn sse_read_events(conn: SseConnection, out: &mut Vec[SseEvent]) -> Int {
  let _ = conn;
  let _ = out;
  0
}
