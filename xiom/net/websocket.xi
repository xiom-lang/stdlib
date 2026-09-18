// XIOM - Network: WebSocket
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.net.websocket

// Depends on: xiom.string, xiom.net
//
// WebSocket framing and client handshake per RFC 6455.
// Frame encode/decode, masking, and the connect/send/recv client API.

use xiom.string;
use xiom.encoding;
use xiom.math;

// struct WsFrame { opcode: Int; fin: Bool; masked: Bool; payload: Vec[UInt8] }
/// struct WsFrame { opcode: Int; fin: Bool; masked: Bool; payload: Vec[UInt8] }
pub type WsFrame = {
  opcode: Int;
  fin: Bool;
  masked: Bool;
  payload: Vec[UInt8];
} derive[Clone]

// struct WsConnection { socket: TcpStream; key: Str; open: Bool }
/// struct WsConnection { socket: TcpStream; key: Str; open: Bool }
pub type WsConnection = {
  fd: Int;
  key: Str;
  open: Bool;
}

// --- String helpers -----------------------------------------------------------

// idx_of returns the byte index of needle in hay, or -1 if not found.
fn idx_of(hay: Str, needle: Str) -> Int {
  let hlen = hay.len();
  let nlen = needle.len();
  if nlen == 0 { return 0; }
  if nlen > hlen { return -1; }
  var i = 0;
  while i <= hlen - nlen {
    if string.str_slice(hay, i, i + nlen) == needle {
      return i;
    }
    i = i + 1;
  }
  -1
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

// str_to_int parses leading decimal digits into an integer.
fn str_to_int(s: Str) -> Int {
  var result = 0;
  var i = 0;
  let len = s.len();
  while i < len {
    let b = s.byte_at(i);
    if b < 48 || b > 57 { break; }
    result = result * 10 + (b as Int - 48);
    i = i + 1;
  }
  result
}

// --- Handshake builders -------------------------------------------------------

// ws_handshake_request builds a client upgrade request for the given
// host, path, and Sec-WebSocket-Key value. Complexity: O(1). Pure.
/// ws_handshake_request builds a client upgrade request for the given
/// host, path, and Sec-WebSocket-Key value. Complexity: O(1). Pure.
pub fn ws_handshake_request(host: Str, path: Str, key: Str) -> Str {
  var request = "GET ";
  var p = path;
  if p.len() == 0 {
    p = "/";
  }
  request = request + p;
  request = request + " HTTP/1.1\r\n";
  request = request + "Host: " + host + "\r\n";
  request = request + "Upgrade: websocket\r\n";
  request = request + "Connection: Upgrade\r\n";
  request = request + "Sec-WebSocket-Key: " + key + "\r\n";
  request = request + "Sec-WebSocket-Version: 13\r\n";
  request = request + "\r\n";
  request
}

// --- SHA-1 (self-contained, RFC 3174) -----------------------------------------

fn mask32(v: Int) -> Int {
  math.bit_and(v, 0xFFFFFFFF)
}

fn rotl(v: Int, n: Int) -> Int {
  let a = math.shl(mask32(v), n);
  let b = math.shr(v, 32 - n);
  math.bit_or(mask32(a), b)
}

fn f_ch(x: Int, y: Int, z: Int) -> Int {
  math.bit_or(math.bit_and(x, y), math.bit_and(math.bit_not(x), z))
}

fn f_par(x: Int, y: Int, z: Int) -> Int {
  math.bit_xor(math.bit_xor(x, y), z)
}

fn f_maj(x: Int, y: Int, z: Int) -> Int {
  math.bit_xor(math.bit_xor(math.bit_and(x, y), math.bit_and(x, z)), math.bit_and(y, z))
}

fn k_const(t: Int) -> Int {
  if t < 20 { return 0x5A827999; }
  if t < 40 { return 0x6ED9EBA1; }
  if t < 60 { return 0x8F1BBCDC; }
  0xCA62C1D6
}

fn f_round(t: Int, x: Int, y: Int, z: Int) -> Int {
  if t < 20 { return f_ch(x, y, z); }
  if t < 40 { return f_par(x, y, z); }
  if t < 60 { return f_maj(x, y, z); }
  f_par(x, y, z)
}

fn add32(a: Int, b: Int) -> Int {
  math.bit_and(a + b, 0xFFFFFFFF)
}

// sha1 computes the 20-byte SHA-1 digest of data.
fn sha1(data: &Vec[UInt8]) -> Vec[UInt8] {
  var msg_len = data.len();
  var total = msg_len + 9;
  var rem = total % 64;
  if rem != 0 {
    total = total + (64 - rem);
  }
  var padded: Vec[UInt8] = Vec[UInt8]::new();
  var i = 0;
  while i < msg_len {
    padded.push(data[i]);
    i = i + 1;
  }
  padded.push(128 as UInt8);
  var j = msg_len + 1;
  while j < total - 8 {
    padded.push(0 as UInt8);
    j = j + 1;
  }
  let bit_len = msg_len * 8;
  var k = 0;
  while k < 8 {
    let shift = (7 - k) * 8;
    let byte = math.shr(bit_len, shift) as Int;
    padded.push((math.bit_and(byte, 0xFF)) as UInt8);
    k = k + 1;
  }

  var h0 = 0x67452301;
  var h1 = 0xEFCDAB89;
  var h2 = 0x98BADCFE;
  var h3 = 0x10325476;
  var h4 = 0xC3D2E1F0;

  var block = 0;
  while block < total / 64 {
    var w: Vec[Int] = Vec[Int]::new();
    var t = 0;
    while t < 80 {
      w.push(0);
      t = t + 1;
    }
    var idx = 0;
    while idx < 16 {
      let base = block * 64 + idx * 4;
      let b0 = padded[base] as Int;
      let b1 = padded[base + 1] as Int;
      let b2 = padded[base + 2] as Int;
      let b3 = padded[base + 3] as Int;
      let wv = math.bit_or(math.bit_or(math.shl(b0, 24), math.shl(b1, 16)), math.bit_or(math.shl(b2, 8), b3));
      w[idx] = wv;
      idx = idx + 1;
    }
    var i2 = 16;
    while i2 < 80 {
      let v = math.bit_xor(math.bit_xor(math.bit_xor(w[i2 - 3], w[i2 - 8]), w[i2 - 14]), w[i2 - 16]);
      w[i2] = rotl(v, 1);
      i2 = i2 + 1;
    }
    var a = h0;
    var b = h1;
    var c = h2;
    var d = h3;
    var e = h4;
    var tt = 0;
    while tt < 80 {
      let temp = add32(add32(add32(add32(rotl(a, 5), f_round(tt, b, c, d)), e), w[tt]), k_const(tt));
      e = d;
      d = c;
      c = rotl(b, 30);
      b = a;
      a = temp;
      tt = tt + 1;
    }
    h0 = add32(h0, a);
    h1 = add32(h1, b);
    h2 = add32(h2, c);
    h3 = add32(h3, d);
    h4 = add32(h4, e);
    block = block + 1;
  }
  var out: Vec[UInt8] = Vec[UInt8]::new();
  var vals: Vec[Int] = Vec[Int]::new();
  vals.push(h0);
  vals.push(h1);
  vals.push(h2);
  vals.push(h3);
  vals.push(h4);
  var vi = 0;
  while vi < 5 {
    let hv = vals[vi];
    var sh = 24;
    while sh >= 0 {
      let byte = math.shr(hv, sh) as Int;
      out.push((math.bit_and(byte, 0xFF)) as UInt8);
      sh = sh - 8;
    }
    vi = vi + 1;
  }
  out
}

// ws_accept_key computes the Sec-WebSocket-Accept value for a client
// key per RFC 6455: base64(SHA-1(key + GUID)). Complexity: O(n).
/// ws_accept_key computes the Sec-WebSocket-Accept value for a client
/// key per RFC 6455: base64(SHA-1(key + GUID)). Complexity: O(n).
pub fn ws_accept_key(key: Str) -> Str {
  var input: Vec[UInt8] = Vec[UInt8]::new();
  var i = 0;
  while i < key.len() {
    input.push(key.byte_at(i));
    i = i + 1;
  }
  let guid = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
  var g = 0;
  while g < guid.len() {
    input.push(guid.byte_at(g));
    g = g + 1;
  }
  let digest = sha1(&input);
  encoding.base64_encode(&digest)
}

// ws_handshake_verify checks a server upgrade response against the
// client key: the status line must be 101 and the Sec-WebSocket-Accept
// header must match the computed accept value. Complexity: O(n). Pure.
/// ws_handshake_verify checks a server upgrade response against the
/// client key: the status line must be 101 and the Sec-WebSocket-Accept
/// header must match the computed accept value. Complexity: O(n). Pure.
pub fn ws_handshake_verify(response: Str, key: Str) -> Bool {
  let nl = idx_of(response, "\r\n");
  var status_line = response;
  if nl >= 0 {
    status_line = string.str_slice(response, 0, nl);
  } else {
    let nl2 = idx_of(response, "\n");
    if nl2 >= 0 {
      status_line = string.str_slice(response, 0, nl2);
    }
  }
  if !string.str_contains(status_line, " 101 ") {
    return false;
  }
  if !string.str_contains(response, "Upgrade: websocket") && !string.str_contains(response, "upgrade: websocket") {
    return false;
  }
  let expected = ws_accept_key(key);
  let lowered = string.str_lower(response);
  let accept = string.str_lower("sec-websocket-accept: ");
  let ap = idx_of(lowered, accept);
  if ap < 0 {
    return false;
  }
  var line_end = idx_of(lowered, "\r\n");
  let from = ap + accept.len();
  if line_end < 0 || line_end < from {
    line_end = lowered.len();
  }
  let got = string.str_slice(lowered, from, line_end);
  got == string.str_lower(expected)
}

// --- Frame encode / decode ----------------------------------------------------

// ws_frame_encode serializes one WebSocket frame. When mask is true a
// random-looking client mask (derived from payload length) is applied.
// Complexity: O(n). Pure.
/// ws_frame_encode serializes one WebSocket frame. When mask is true a
/// random-looking client mask (derived from payload length) is applied.
/// Complexity: O(n). Pure.
pub fn ws_frame_encode(opcode: Int, payload: &Vec[UInt8], mask: Bool) -> Vec[UInt8] {
  var out: Vec[UInt8] = Vec[UInt8]::new();
  let plen = payload.len();
  var first = 0x80 as UInt8;
  if opcode >= 0 {
    first = (0x80 | (opcode & 0x0F)) as UInt8;
  }
  out.push(first);
  var second = 0 as UInt8;
  if mask {
    second = (0x80 as UInt8);
  }
  if plen < 126 {
    out.push((second | plen as UInt8));
  } elif plen < 65536 {
    out.push((second | 126 as UInt8));
    out.push((plen >> 8) as UInt8);
    out.push((plen & 0xFF) as UInt8);
  } else {
    out.push((second | 127 as UInt8));
    var shift = 56;
    while shift >= 0 {
      out.push((plen >> shift) as UInt8);
      shift = shift - 8;
    }
  }
  var mask_key: [4]UInt8;
  if mask {
    var seed = plen + 0x5A;
    var mk = 0;
    while mk < 4 {
      seed = seed * 1103515245 + 12345;
      mask_key[mk] = ((seed >> 16) & 0xFF) as UInt8;
      mk = mk + 1;
    }
    var m = 0;
    while m < 4 {
      out.push(mask_key[m]);
      m = m + 1;
    }
    var i = 0;
    while i < plen {
      out.push((payload[i] ^ mask_key[i % 4]) as UInt8);
      i = i + 1;
    }
  } else {
    var i = 0;
    while i < plen {
      out.push(payload[i]);
      i = i + 1;
    }
  }
  out
}

// ws_frame_decode parses one WebSocket frame from bytes. Returns Err on
// truncated or invalid input. Complexity: O(n). Pure.
/// ws_frame_decode parses one WebSocket frame from bytes. Returns Err on
/// truncated or invalid input. Complexity: O(n). Pure.
pub fn ws_frame_decode(frame: &Vec[UInt8]) -> Result[WsFrame, Str] {
  if frame.len() < 2 {
    return Err("frame too short");
  }
  let b0 = frame[0] as Int;
  let b1 = frame[1] as Int;
  let fin = (b0 & 0x80) != 0;
  let opcode = b0 & 0x0F;
  let masked = (b1 & 0x80) != 0;
  var payload_len = b1 & 0x7F;
  var offset = 2;
  if payload_len == 126 {
    if frame.len() < 4 {
      return Err("frame too short for extended length");
    }
    payload_len = ((frame[2] as Int) << 8) | (frame[3] as Int);
    offset = 4;
  } elif payload_len == 127 {
    if frame.len() < 10 {
      return Err("frame too short for 64-bit length");
    }
    payload_len = 0;
    var shift = 56;
    var k = 2;
    while shift >= 0 {
      payload_len = payload_len + ((frame[k] as Int) << shift);
      shift = shift - 8;
      k = k + 1;
    }
    offset = 10;
  }
  var mask_key: [4]UInt8;
  if masked {
    if frame.len() < offset + 4 {
      return Err("frame too short for mask key");
    }
    var m = 0;
    while m < 4 {
      mask_key[m] = frame[offset + m];
      m = m + 1;
    }
    offset = offset + 4;
  }
  if frame.len() < offset + payload_len {
    return Err("frame truncated");
  }
  var payload: Vec[UInt8] = Vec[UInt8]::new();
  var i = 0;
  while i < payload_len {
    if masked {
      payload.push((frame[offset + i] ^ mask_key[i % 4]) as UInt8);
    } else {
      payload.push(frame[offset + i]);
    }
    i = i + 1;
  }
  Ok(WsFrame{ opcode: opcode; fin: fin; masked: masked; payload: payload; })
}

// ws_random_key generates a Sec-WebSocket-Key value (base64 of 16
// bytes) for use in client handshakes. Deterministic derivation from
// the current time keeps the module free of external RNG state.
/// ws_random_key generates a Sec-WebSocket-Key value (base64 of 16
/// bytes) for use in client handshakes. Deterministic derivation from
/// the current time keeps the module free of external RNG state.
pub fn ws_random_key() -> Str {
  let t = time_seed();
  var bytes: Vec[UInt8] = Vec[UInt8]::new();
  var i = 0;
  while i < 16 {
    let v = (t >> ((i % 8) * 8)) as Int;
    bytes.push((v & 0xFF) as UInt8);
    i = i + 1;
  }
  encoding.base64_encode(&bytes)
}

// time_seed returns a coarse second-scale seed mixed to avoid trivially
// sequential keys. Uses the same C time() primitive as xiom.io.
fn time_seed() -> Int {
  let base = io_now();
  base * 2654435761 + 0x9E3779B9
}

extern "C" {
  fn time(t: *Int) -> Int;
}

fn io_now() -> Int {
  var t: Int = 0;
  unsafe {
    let _ = time(&t);
  }
  t
}

// ws_parse_url splits a ws:// or wss:// URL into host, port, and path.
// The port is the explicit port when present, otherwise the scheme
// default. Returns Err for malformed input. Complexity: O(n). Pure.
/// ws_parse_url splits a ws:// or wss:// URL into host, port, and path.
/// The port is the explicit port when present, otherwise the scheme
/// default. Returns Err for malformed input. Complexity: O(n). Pure.
pub fn ws_parse_url(url: Str) -> Result[(Str, Int, Str), Str] {
  let len = url.len();
  if len == 0 {
    return Err("empty websocket url");
  }
  let scheme_pos = idx_of(url, "://");
  if scheme_pos < 0 {
    return Err("missing scheme separator");
  }
  let scheme = string.str_slice(url, 0, scheme_pos);
  var default_port = 80;
  if scheme == "wss" {
    default_port = 443;
  }
  var rest = string.str_slice(url, scheme_pos + 3, len);
  if rest.len() == 0 {
    return Err("missing host");
  }
  var host = "";
  var port = default_port;
  var path = "/";
  var authority_end = rest.len();
  let path_start = idx_of(rest, "/");
  let query_start = idx_of(rest, "?");
  let frag_start = idx_of(rest, "#");
  if path_start >= 0 && path_start < authority_end { authority_end = path_start; }
  if query_start >= 0 && query_start < authority_end { authority_end = query_start; }
  if frag_start >= 0 && frag_start < authority_end { authority_end = frag_start; }
  var authority = string.str_slice(rest, 0, authority_end);
  if authority.len() == 0 {
    return Err("missing host");
  }
  let colon_pos = idx_of(authority, ":");
  if colon_pos >= 0 {
    host = string.str_slice(authority, 0, colon_pos);
    let port_str = string.str_slice(authority, colon_pos + 1, authority.len());
    if port_str.len() > 0 {
      port = str_to_int(port_str);
    }
  } else {
    host = authority;
  }
  if host.len() == 0 {
    return Err("missing host");
  }
  let after = string.str_slice(rest, authority_end, rest.len());
  if after.len() > 0 {
    var path_end = after.len();
    let q_pos = idx_of(after, "?");
    let f_pos = idx_of(after, "#");
    if q_pos >= 0 && q_pos < path_end { path_end = q_pos; }
    if f_pos >= 0 && f_pos < path_end { path_end = f_pos; }
    let p = string.str_slice(after, 0, path_end);
    if p.len() > 0 {
      path = p;
    }
  }
  Ok((host, port, path))
}

// --- Client API (transport-aware) ---------------------------------------------

extern "C" {
  fn xiom_socket_create(family: Int, typ: Int, proto: Int) -> Int;
  fn xiom_socket_connect(sock: Int, host: *UInt8, port: Int) -> Int;
  fn xiom_socket_send(sock: Int, buf: *UInt8, len: Int) -> Int;
  fn xiom_socket_recv(sock: Int, buf: *UInt8, len: Int) -> Int;
  fn xiom_socket_close(sock: Int) -> Int;
}

// ws_connect opens a WebSocket connection to a ws:// or wss:// URL,
// performing the client handshake. TLS (wss) is not supported by the
// runtime socket layer; use ws://. Complexity: network I/O.
/// ws_connect opens a WebSocket connection to a ws:// or wss:// URL,
/// performing the client handshake. TLS (wss) is not supported by the
/// runtime socket layer; use ws://. Complexity: network I/O.
pub fn ws_connect(url: Str) -> Result[WsConnection, Str] {
  let parsed = ws_parse_url(url);
  var host = "";
  var port = 80;
  var path = "/";
  match parsed {
    Ok(t) => {
      host = t.0;
      port = t.1;
      path = t.2;
    }
    Err(e) => { return Err(e); }
  }
  let key = ws_random_key();
  let request = ws_handshake_request(host, path, key);
  let fd = unsafe { xiom_socket_create(2, 1, 0) };
  if fd < 0 {
    return Err("failed to create socket");
  }
  var c_host: [256]UInt8;
  var hi = 0;
  let hlen = host.len();
  while hi < hlen && hi < 255 {
    c_host[hi] = host.byte_at(hi);
    hi = hi + 1;
  }
  c_host[hi] = 0 as UInt8;
  let conn = unsafe { xiom_socket_connect(fd, &c_host as *UInt8, port) };
  if conn < 0 {
    unsafe { xiom_socket_close(fd); }
    return Err("connection failed");
  }
  var send_buf: [1024]UInt8;
  var si = 0;
  let rlen = request.len();
  if rlen > 1024 {
    unsafe { xiom_socket_close(fd); }
    return Err("handshake too large");
  }
  while si < rlen {
    send_buf[si] = request.byte_at(si);
    si = si + 1;
  }
  let sent = unsafe { xiom_socket_send(fd, &send_buf as *UInt8, rlen) };
  if sent < 0 {
    unsafe { xiom_socket_close(fd); }
    return Err("send failed");
  }
  var recv_buf: [2048]UInt8;
  var raw: Vec[UInt8] = Vec[UInt8]::with_capacity(2048);
  var done = false;
  while !done {
    let n = unsafe { xiom_socket_recv(fd, &recv_buf as *UInt8, 2048) };
    if n <= 0 {
      done = true;
    } else {
      var ri = 0;
      while ri < n {
        raw.push(recv_buf[ri]);
        ri = ri + 1;
      }
    }
  }
  unsafe { xiom_socket_close(fd); }
  let resp = Str::from_utf8(raw);
  if !ws_handshake_verify(resp, key) {
    return Err("handshake verification failed");
  }
  Ok(WsConnection{ fd: fd; key: key; open: true; })
}

// ws_send sends a text message over an open connection.
// Complexity: network I/O.
/// ws_send sends a text message over an open connection.
/// Complexity: network I/O.
pub fn ws_send(conn: &WsConnection, text: Str) -> Result[Unit, Str] {
  if !conn.open {
    return Err("connection closed");
  }
  var payload: Vec[UInt8] = Vec[UInt8]::new();
  var i = 0;
  while i < text.len() {
    payload.push(text.byte_at(i));
    i = i + 1;
  }
  let frame = ws_frame_encode(1, &payload, true);
  ws_send_frame(conn, frame)
}

// ws_send_binary sends a binary message over an open connection.
// Complexity: network I/O.
/// ws_send_binary sends a binary message over an open connection.
/// Complexity: network I/O.
pub fn ws_send_binary(conn: &WsConnection, data: &Vec[UInt8]) -> Result[Unit, Str] {
  if !conn.open {
    return Err("connection closed");
  }
  let frame = ws_frame_encode(2, data, true);
  ws_send_frame(conn, frame)
}

// ws_send_frame writes raw frame bytes to the socket.
fn ws_send_frame(conn: &WsConnection, frame: Vec[UInt8]) -> Result[Unit, Str] {
  var send_buf: [8192]UInt8;
  var i = 0;
  let flen = frame.len();
  if flen > 8192 {
    return Err("frame too large");
  }
  while i < flen {
    send_buf[i] = frame[i];
    i = i + 1;
  }
  let sent = unsafe { xiom_socket_send(conn.fd, &send_buf as *UInt8, flen) };
  if sent < 0 {
    return Err("send failed");
  }
  Ok(())
}

// ws_recv receives the next frame from the connection.
// Complexity: network I/O.
/// ws_recv receives the next frame from the connection.
/// Complexity: network I/O.
pub fn ws_recv(conn: &WsConnection) -> Result[WsFrame, Str] {
  if !conn.open {
    return Err("connection closed");
  }
  var recv_buf: [8192]UInt8;
  var raw: Vec[UInt8] = Vec[UInt8]::with_capacity(8192);
  var done = false;
  while !done {
    let n = unsafe { xiom_socket_recv(conn.fd, &recv_buf as *UInt8, 8192) };
    if n <= 0 {
      done = true;
    } else {
      var ri = 0;
      while ri < n {
        raw.push(recv_buf[ri]);
        ri = ri + 1;
      }
    }
  }
  if raw.len() < 2 {
    return Err("connection closed by peer");
  }
  ws_frame_decode(&raw)
}

// ws_close sends a close frame and tears down the connection.
// Complexity: network I/O.
/// ws_close sends a close frame and tears down the connection.
/// Complexity: network I/O.
pub fn ws_close(conn: &WsConnection, code: Int) {
  var payload: Vec[UInt8] = Vec[UInt8]::new();
  payload.push(((code >> 8) & 0xFF) as UInt8);
  payload.push((code & 0xFF) as UInt8);
  let frame = ws_frame_encode(8, &payload, true);
  let _ = ws_send_frame(conn, frame);
  unsafe { xiom_socket_close(conn.fd); }
}

// ws_ping sends a ping frame.
// Complexity: network I/O.
/// ws_ping sends a ping frame.
/// Complexity: network I/O.
pub fn ws_ping(conn: &WsConnection) {
  let empty: Vec[UInt8] = Vec[UInt8]::new();
  let frame = ws_frame_encode(9, &empty, true);
  let _ = ws_send_frame(conn, frame);
}

// ws_pong sends a pong frame.
// Complexity: network I/O.
/// ws_pong sends a pong frame.
/// Complexity: network I/O.
pub fn ws_pong(conn: &WsConnection) {
  let empty: Vec[UInt8] = Vec[UInt8]::new();
  let frame = ws_frame_encode(10, &empty, true);
  let _ = ws_send_frame(conn, frame);
}
