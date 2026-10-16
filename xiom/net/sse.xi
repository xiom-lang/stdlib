// XIOM - Network: Server-Sent Events Client
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.net.sse

// Depends on: xiom.net, xiom.string

// ============================================================================
// Server-Sent Events client per the WHATWG SSE spec. The wire builders live in
// net.xi; this module owns connection lifecycle and parsing. Parsing and the
// pure event accessors are fully implemented; the connection functions are
// REAL since wave 162 (REL-20261015-2202-pulse item 7): plaintext http://
// connects and streams; https:// is refused with a typed error until the TLS
// seam lands (see xiom.net.tls / the xiom.ssl package).
//
// Reading model: the connection owns a byte buffer with a consumed-prefix
// cursor; sse_read_event blocks until a whole blank-line-terminated block is
// buffered (set a socket timeout for a hard bound) and returns the RAW
// parsed chunk -- comment-only or control-only chunks come back with empty
// data; the dispatch filter (skip empty-data events, update last-event-id)
// is the consumer's step, sse_read_events drains only what is already
// readable when polled.
// ============================================================================

use xiom.string;
use xiom.net;
use xiom.net.socket;

/// struct SseConnection { socket: TcpStream; url: Str; open: Bool;
///                        buf: Vec[UInt8]; start: Int }
/// buf/start hold the read buffer and its consumed-prefix cursor.
/// NOTE: the field type is the BARE leaf `TcpStream` (alias-qualified type
/// paths are the known resolution trap -- see the catalog notes).
pub type SseConnection = {
  socket: TcpStream;
  url: Str;
  open: Bool;
  buf: Vec[UInt8];
  start: Int;
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
pub fn sse_parse_event(chunk: Str) -> Result[SseEvent, Str]
  ensures: ((chunk.len() == 0) => (result.is_err == true)) && ((result.is_err == true) => (chunk.len() == 0)) && ((result.is_ok == true) => (chunk.len() > 0))
{
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
pub fn sse_event_id(e: SseEvent) -> Option[Str]
  ensures: ((e.id.len() == 0) => (result.is_none == true)) && ((result.is_some == true) => (e.id.len() > 0))
{
  if e.id.len() > 0 {
    return Some(e.id);
  }
  None
}

/// Return the event data field.
/// Parameters: e -- the event.
/// Returns: the data field (possibly "").
/// Complexity: O(1). Pure.
pub fn sse_event_data(e: SseEvent) -> Str
  ensures: result == e.data
{
  e.data
}

// ============================================================================
// Connection layer (wave 162). Transport-honest: no TLS in tree yet, so
// https:// URLs are refused with a typed error; a server answering with a
// non-200 status or a non-SSE content type is refused too.
// ============================================================================

// _find_block_end returns the index of the earliest block terminator at or
// after `from`: "\r\n\r\n" (index at the first CR) or "\n\n". -1 when no
// complete terminator is buffered yet. Pure.
fn _find_block_end(buf: &Vec[UInt8], from: Int) -> Int {
  var i = from;
  let n = buf.len();
  while i < n {
    if buf[i] == 13 {
      if i + 3 < n && buf[i + 1] == 10 && buf[i + 2] == 13 && buf[i + 3] == 10 {
        return i;
      };
    } elif buf[i] == 10 {
      if i + 1 < n && buf[i + 1] == 10 {
        return i;
      };
    };
    i = i + 1;
  };
  -1
}

// _block_end_len: terminator length at a _find_block_end hit (CRLFCRLF -> 4,
// LFLF -> 2). Callers pass a hit index.
fn _block_end_len(buf: &Vec[UInt8], at: Int) -> Int {
  if buf[at] == 13 {
    return 4;
  };
  2
}

// _slice_bytes copies buf[from, to) into a fresh vector. Pure.
fn _slice_bytes(buf: &Vec[UInt8], from: Int, to: Int) -> Vec[UInt8] {
  var out = Vec[UInt8].new();
  var i = from;
  while i < to {
    out.push(buf[i]);
    i = i + 1;
  };
  out
}

// _fill appends the socket's next chunk to conn.buf. Ok(n) with n == 0 at
// EOF (conn.open cleared); Err on a transport failure (conn.open cleared).
fn _fill(conn: &mut SseConnection) -> Result[Int, Str] {
  var tmp: Vec[UInt8] = Vec[UInt8].new();
  match conn.socket.read(&mut tmp) {
    Ok(n) => {
      if n == 0 {
        conn.open = false;
        return Ok(0);
      };
      var i = 0;
      while i < tmp.len() {
        conn.buf.push(tmp[i]);
        i = i + 1;
      };
      Ok(n)
    },
    Err(e) => {
      conn.open = false;
      Err("read failed: " + e.message)
    },
  }
}

// _compact drops fully consumed buffer space.
fn _compact(conn: &mut SseConnection) {
  if conn.start >= conn.buf.len() {
    conn.buf = Vec[UInt8].new();
    conn.start = 0;
  };
}

// _read_head buffers until the response-head terminator, consumes it, and
// returns the head text. Err on transport failure, EOF before a full head,
// or a head larger than 64 KiB.
fn _read_head(conn: &mut SseConnection) -> Result[Str, Str] {
  var guard = 0;
  while guard < 256 {
    let at = _find_block_end(&conn.buf, conn.start);
    if at >= 0 {
      let head = Str::from_utf8(_slice_bytes(&conn.buf, conn.start, at));
      conn.start = at + _block_end_len(&conn.buf, at);
      _compact(conn);
      return Ok(head);
    };
    if conn.buf.len() - conn.start > 65536 {
      return Err("response head too large");
    };
    match _fill(conn) {
      Ok(0) => { return Err("connection closed before the response head"); },
      Ok(_) => {},
      Err(e) => { return Err(e); },
    };
    guard = guard + 1;
  };
  Err("response head not terminated")
}

// _status_of extracts the status code from an HTTP response head; -1 when
// the shape does not parse.
fn _status_of(head: Str) -> Int {
  let sp = string.index_of(head, " ");
  if sp.is_none {
    return -1;
  };
  let at = sp.value;
  if at + 4 > head.len() {
    return -1;
  };
  let code = string.str_slice(head, at + 1, at + 4);
  match string.str_to_int(code) {
    Ok(v) => v,
    Err(_) => -1,
  }
}

// _connect_core: shared connect path (empty extra list for sse_connect).
fn _connect_core(url: Str, extra: &Vec[(Str, Str)]) -> Result[SseConnection, Str] {
  if url.len() == 0 {
    return Err("sse_connect: empty url");
  };
  let pr = net.parse_url(url);
  if pr.is_err {
    let perr = pr.value;
    return Err("sse_connect: " + perr.message);
  };
  let parsed = pr.value;
  let pscheme = parsed.scheme;
  let phost = parsed.host;
  let ppath = parsed.path;
  let pquery = parsed.query;
  let pport = parsed.port;
  if pscheme != "http" {
    return Err("sse_connect: unsupported scheme (https needs TLS; see the TLS seam / xiom.ssl package)");
  };
  var port = pport;
  if port <= 0 {
    port = 80;
  };
  var target = ppath;
  if target.len() == 0 {
    target = "/";
  };
  if pquery.len() > 0 {
    target = target + "?" + pquery;
  };
  var request = "GET " + target + " HTTP/1.1\r\n";
  request = request + "Host: " + phost + "\r\n";
  request = request + "Accept: text/event-stream\r\n";
  request = request + "Cache-Control: no-cache\r\n";
  request = request + "Connection: keep-alive\r\n";
  request = request + "User-Agent: XIOM/0.1\r\n";
  var h = 0;
  while h < extra.len() {
    let pair = extra[h];
    let hname = pair.0;
    let hvalue = pair.1;
    if hname.len() == 0 {
      return Err("sse_connect: empty header name");
    };
    if string.str_contains(hname, "\r") || string.str_contains(hname, "\n") {
      return Err("sse_connect: header name contains CR/LF");
    };
    if string.str_contains(hvalue, "\r") || string.str_contains(hvalue, "\n") {
      return Err("sse_connect: header value contains CR/LF");
    };
    request = request + hname + ": " + hvalue + "\r\n";
    h = h + 1;
  };
  request = request + "\r\n";
  var stream = TcpStream{ fd: 0 };
  match net.tcp_connect(phost, port) {
    Ok(s) => { stream = s; },
    Err(e) => { return Err("sse_connect: " + e.message); },
  };
  var req_bytes: Vec[UInt8] = Vec[UInt8].new();
  var j = 0;
  while j < request.len() {
    req_bytes.push(request.byte_at(j));
    j = j + 1;
  };
  match stream.write_all(&req_bytes) {
    Ok(_) => {},
    Err(e) => {
      let _ = stream.close();
      return Err("sse_connect: write failed: " + e.message);
    },
  };
  var conn = SseConnection{ socket: stream; url: url; open: true; buf: Vec[UInt8].new(); start: 0; };
  var head = "";
  match _read_head(&mut conn) {
    Ok(hd) => { head = hd; },
    Err(e) => {
      let _ = conn.socket.close();
      conn.open = false;
      return Err("sse_connect: " + e);
    },
  };
  let status = _status_of(head);
  if status != 200 {
    let _ = conn.socket.close();
    conn.open = false;
    return Err("sse_connect: unexpected status " + status.to_str());
  };
  if !string.str_contains(string.str_lower(head), "content-type: text/event-stream") {
    let _ = conn.socket.close();
    conn.open = false;
    return Err("sse_connect: response content-type is not text/event-stream");
  };
  Ok(conn)
}

/// Open a text/event-stream connection (plaintext http:// only; https:// is
/// refused with a typed error until the TLS seam lands).
/// Parameters: url -- http://host[:port]/path (a missing path becomes "/").
/// Returns: Ok(SseConnection) after a 200 + text/event-stream response head;
///          Err on a bad/empty url, an unsupported scheme, a transport
///          failure, a non-200 status, or a non-SSE content type.
/// Complexity: O(response head).
pub fn sse_connect(url: Str) -> Result[SseConnection, Str]
  ensures: (url.len() == 0) => (result.is_err == true)
{
  var extra: Vec[(Str, Str)] = Vec[(Str, Str)].new();
  _connect_core(url, &extra)
}

/// Connect with custom request headers appended to the standard GET.
/// Header names/values containing CR or LF are refused (request injection).
/// Returns: as sse_connect.
/// Complexity: O(response head + headers).
pub fn sse_connect_headers(url: Str, headers: &Vec[(Str, Str)]) -> Result[SseConnection, Str]
  ensures: (url.len() == 0) => (result.is_err == true)
{
  _connect_core(url, headers)
}

/// Read and parse the next event block.
/// Blocks on the socket until a blank-line-terminated block is buffered (set
/// a socket timeout for a hard bound). Returns the RAW parsed chunk --
/// comment-only chunks come back with empty data (dispatch filtering is the
/// consumer's step). Err after EOF, on a transport failure, or when a block
/// exceeds 1 MiB without a terminator.
/// Complexity: O(block).
pub fn sse_read_event(conn: &mut SseConnection) -> Result[SseEvent, Str]
  ensures: true
{
  var guard = 0;
  while guard < 512 {
    let at = _find_block_end(&conn.buf, conn.start);
    if at >= 0 {
      let chunk = Str::from_utf8(_slice_bytes(&conn.buf, conn.start, at));
      conn.start = at + _block_end_len(&conn.buf, at);
      _compact(conn);
      return sse_parse_event(chunk);
    };
    if !conn.open {
      return Err("sse_read_event: stream closed");
    };
    if conn.buf.len() - conn.start > 1048576 {
      return Err("sse_read_event: event larger than 1 MiB");
    };
    match _fill(conn) {
      Ok(0) => {},
      Ok(_) => {},
      Err(e) => { return Err("sse_read_event: " + e); },
    };
    guard = guard + 1;
  };
  Err("sse_read_event: no complete event")
}

/// Close the stream (idempotent); the connection's open flag is cleared.
/// Complexity: O(1).
pub fn sse_close(conn: &mut SseConnection)
  ensures: true
{
  if conn.open {
    let _ = conn.socket.close();
    conn.open = false;
  };
}

/// Drain events that are already readable (zero-timeout poll; the first pull
/// may block inside a partially buffered block until the socket timeout).
/// Appends to out and returns the number added (capped at 1024 per call).
/// Complexity: O(drained bytes).
pub fn sse_read_events(conn: &mut SseConnection, out: &mut Vec[SseEvent]) -> Int
  ensures: result >= 0
{
  var count = 0;
  var fds: Vec[Int] = Vec[Int].new();
  fds.push(conn.socket.fd);
  while count < 1024 {
    if !conn.open {
      break;
    };
    var ready = false;
    match socket.socket_poll_read(&fds, 0) {
      Ok(v) => { if v.len() > 0 { ready = true; }; },
      Err(_) => { break; },
    };
    if !ready {
      break;
    };
    match sse_read_event(conn) {
      Ok(e) => {
        out.push(e);
        count = count + 1;
      },
      Err(_) => { break; },
    };
  };
  count
}
