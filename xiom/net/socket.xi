// XIOM - Networking: Sockets
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.net.socket

// Depends on: xiom.net + xiom.string
//
// Raw TCP/UDP socket lifecycle: create, bind, listen, accept, connect,
// send, receive, address queries and options. The core operations are
// implemented on the same runtime socket primitives used by xiom.net;
// timeout, non-blocking, reuse-addr and shutdown are real since wave 119
// (SO_RCVTIMEO / FIONBIO / O_NONBLOCK / setsockopt + shutdown); the
// bind honored-address path and socket_local_addr are real since wave 155
// (REL-20261016-1404); the peer address and pending bytes still return a
// documented Err. Wave 121 adds
// the full-send loop (socket_send_all) and the chunked-transfer stream
// helpers (socket_chunk_encode / socket_chunked_end / socket_stream_chunk /
// socket_stream_end; Transfer-Encoding: chunked writers for SSE-style
// streaming endpoints, REL-20261012-1946-pulse). Wave 122 adds SO_REUSEPORT
// (POSIX; Windows has the documented no-equivalent Err) and the poll
// wrappers socket_poll_read / socket_poll_write (poll() / WSAPoll; up to
// 1024 fds, bounded timeouts, ready fds in input order). Wave 175 adds
// socket_listen_fds (systemd socket activation: LISTEN_PID/LISTEN_FDS, fds
// 3..3+N-1, POSIX-only) so zero-downtime reloads can adopt inherited
// listeners; LISTEN_FDNAMES is left in place for the caller. Waves 176/177
// add the eventloop_* readiness layer (Linux epoll, Windows WSAPoll; macOS/
// BSD Err until the kqueue wave -- see docs/EVENT_LOOP_PLAN.md).

use xiom.env;
use xiom.os.platform as plat;

// Handle ABI (REL-20261030-1628): xiom_socket_create/accept/close return
// int64_t on every target, so their declarations stay `-> Int` (POSIX fd and
// Win64 SOCKET both widen losslessly). Do not narrow them to Int32.
extern "C" {
  fn xiom_socket_create(family: Int, typ: Int, proto: Int) -> Int;
  fn xiom_socket_connect(sock: Int, host: *UInt8, port: Int) -> Int32;
  fn xiom_socket_bind(sock: Int, port: Int) -> Int32;
  fn xiom_socket_bind_addr(sock: Int, host: *UInt8, port: Int) -> Int32;
  fn xiom_socket_listen(sock: Int, backlog: Int) -> Int32;
  fn xiom_socket_accept(sock: Int, client_ip: *UInt8, client_port: *Int) -> Int;
  // Int32 returns: the runtime returns C `int` and -1 means failure; an i64
  // read would see 4294967295 and mis-classify errors (wave-119 fix for
  // recv/recvfrom; wave 121 extends it to send -- the same reason
  // xiom_socket_connect above is Int32).
  fn xiom_socket_send(sock: Int, buf: *UInt8, len: Int) -> Int32;
  fn xiom_socket_recv(sock: Int, buf: *UInt8, len: Int) -> Int32;
  fn xiom_socket_close(sock: Int) -> Int;
  fn xiom_socket_sendto(sock: Int, buf: *UInt8, len: Int, host: *UInt8, port: Int) -> Int32;
  fn xiom_socket_recvfrom(sock: Int, buf: *UInt8, len: Int, out_ip: *UInt8, out_port: *Int) -> Int32;
  fn xiom_socket_set_timeout(sock: Int, ms: Int) -> Int32;
  fn xiom_socket_set_nonblocking(sock: Int, on: Int) -> Int32;
  fn xiom_socket_reuse_addr(sock: Int, on: Int) -> Int32;
  fn xiom_socket_reuseport(sock: Int, on: Int) -> Int32;
  fn xiom_socket_set_nodelay(sock: Int, on: Int) -> Int32;
  fn xiom_socket_set_keepalive(sock: Int, on: Int) -> Int32;
  fn xiom_poll(fds: *Int, nfds: Int, timeout_ms: Int, for_write: Int) -> Int;
  fn xiom_getpid() -> Int64;
  fn xiom_eventloop_create() -> Int32;
  fn xiom_eventloop_ctl(handle: Int, op: Int, fd: Int, read: Int, write: Int) -> Int32;
  fn xiom_eventloop_wait(handle: Int, timeout_ms: Int, out_fds: *Int, out_flags: *Int, max: Int) -> Int;
  fn xiom_eventloop_close(handle: Int) -> Int32;
  fn xiom_socket_shutdown(sock: Int, how: Int) -> Int32;
  fn xiom_socket_local_addr(sock: Int, ip_buf: *UInt8, buf_size: Int, out_port: *Int) -> Int32;
}

const AF_INET: Int = 2;
const SOCK_STREAM: Int = 1;
const SOCK_DGRAM: Int = 2;

/// socket_tcp creates a TCP socket and returns its fd, or Err.
/// Complexity: O(1) syscall.
pub fn socket_tcp() -> Result[Int, Str]
  ensures: (result.is_ok == false) || (result.is_err == false)
{
  let fd = unsafe { xiom_socket_create(AF_INET, SOCK_STREAM, 0) };
  if fd < 0 {
    return Err("socket_tcp: failed to create socket");
  }
  Ok(fd)
}

/// socket_udp creates a UDP socket and returns its fd, or Err.
/// Complexity: O(1) syscall.
pub fn socket_udp() -> Result[Int, Str]
  ensures: (result.is_ok == false) || (result.is_err == false)
{
  let fd = unsafe { xiom_socket_create(AF_INET, SOCK_DGRAM, 0) };
  if fd < 0 {
    return Err("socket_udp: failed to create socket");
  }
  Ok(fd)
}

/// socket_bind binds a socket to addr:port on the given address (wave
/// 155, REL-20261016-1404: the address is honored -- pass "0.0.0.0" for
/// the wildcard; an unparsable IPv4 literal is a typed Err).
/// Complexity: O(1) syscall.
pub fn socket_bind(fd: Int, addr: Str, port: Int) -> Result[Unit, Str]
  ensures: (result.is_ok == false) || (fd >= 0 && addr.len() > 0 && port >= 1 && port <= 65535)
{
  if fd < 0 {
    return Err("socket_bind: invalid fd");
  }
  if addr.len() == 0 {
    return Err("socket_bind: empty address");
  }
  if port <= 0 || port > 65535 {
    return Err("socket_bind: port out of range");
  }
  var c_host: [256]UInt8;
  var i = 0;
  let hlen = addr.len();
  while i < hlen && i < 255 {
    c_host[i] = addr.byte_at(i);
    i = i + 1;
  }
  c_host[i] = 0 as UInt8;
  let rc: Int32 = unsafe { xiom_socket_bind_addr(fd, &c_host as *UInt8, port) };
  if rc == -2 {
    return Err("socket_bind: invalid address");
  }
  if rc < 0 {
    return Err("socket_bind: bind failed");
  }
  Ok(())
}

/// socket_listen marks a bound TCP socket as listening.
/// Complexity: O(1) syscall.
pub fn socket_listen(fd: Int, backlog: Int) -> Result[Unit, Str]
  ensures: (result.is_ok == false) || (fd >= 0 && backlog >= 0)
{
  if fd < 0 {
    return Err("socket_listen: invalid fd");
  }
  if backlog < 0 {
    return Err("socket_listen: negative backlog");
  }
  let rc: Int32 = unsafe { xiom_socket_listen(fd, backlog) };
  if rc < 0 {
    return Err("socket_listen: listen failed");
  }
  Ok(())
}

/// socket_accept accepts a connection and returns the new socket fd.
/// Complexity: O(1) blocking syscall.
pub fn socket_accept(fd: Int) -> Result[Int, Str]
  ensures: (result.is_ok == false) || (fd >= 0)
{
  if fd < 0 {
    return Err("socket_accept: invalid fd");
  }
  var ip_buf: [64]UInt8;
  var port_val: Int = 0;
  let client = unsafe { xiom_socket_accept(fd, &ip_buf as *UInt8, &port_val) };
  if client < 0 {
    return Err("socket_accept: accept failed");
  }
  Ok(client)
}

/// socket_connect connects a socket to a remote addr:port.
/// Complexity: O(1) syscall.
pub fn socket_connect(fd: Int, addr: Str, port: Int) -> Result[Unit, Str]
  ensures: (result.is_ok == false) || (fd >= 0 && addr.len() > 0 && port >= 1 && port <= 65535)
{
  if fd < 0 {
    return Err("socket_connect: invalid fd");
  }
  if addr.len() == 0 {
    return Err("socket_connect: empty address");
  }
  if port <= 0 || port > 65535 {
    return Err("socket_connect: port out of range");
  }
  var c_host: [256]UInt8;
  var i = 0;
  let hlen = addr.len();
  while i < hlen && i < 255 {
    c_host[i] = addr.byte_at(i);
    i = i + 1;
  }
  c_host[i] = 0 as UInt8;
  let rc: Int32 = unsafe { xiom_socket_connect(fd, &c_host as *UInt8, port) };
  if rc < 0 {
    return Err("socket_connect: connect failed");
  }
  Ok(())
}

/// socket_send sends bytes on a socket; returns the count written.
/// Complexity: O(n) syscall.
pub fn socket_send(fd: Int, data: &Vec[UInt8]) -> Result[Int, Str]
  ensures: (result.is_ok == false) || (fd >= 0 && data.len() <= 65536)
{
  if fd < 0 {
    return Err("socket_send: invalid fd");
  }
  var raw_buf: [65536]UInt8;
  let dlen = data.len();
  if dlen > 65536 {
    return Err("socket_send: data too large for stack buffer");
  }
  var i = 0;
  while i < dlen {
    raw_buf[i] = data[i];
    i = i + 1;
  }
  let n32: Int32;
  unsafe {
    n32 = xiom_socket_send(fd, &raw_buf as *UInt8, dlen);
  }
  let n = n32 as Int;
  if n < 0 {
    return Err("socket_send: send failed");
  }
  Ok(n)
}

/// socket_send_all writes every byte of data, advancing by the syscall's
/// partial counts so a short send cannot silently truncate a response.
/// Real implementation (wave 121). Returns: Ok(data.len()).
/// Complexity: O(n) syscall loop.
pub fn socket_send_all(fd: Int, data: &Vec[UInt8]) -> Result[Int, Str]
  ensures: data.len() == 0 => result is Ok
  ensures: result is Ok => fd >= 0
{
  if fd < 0 {
    return Err("socket_send_all: invalid fd");
  }
  let n = data.len();
  if n == 0 {
    return Ok(0);
  }
  var sent = 0;
  while sent < n {
    let w32: Int32;
    unsafe {
      w32 = xiom_socket_send(fd, &data[sent] as *UInt8, n - sent);
    }
    let w = w32 as Int;
    if w <= 0 {
      return Err("socket_send_all: send failed");
    }
    sent = sent + w;
  }
  Ok(sent)
}

// hex_bytes renders a non-negative length as lowercase ASCII hex digits.
fn hex_bytes(v: Int) -> Vec[UInt8] {
  var digits = Vec[UInt8].new();
  if v == 0 {
    digits.push(48);
    return digits;
  }
  var t = v;
  while t > 0 {
    let d = t & 0x0F;
    if d < 10 {
      digits.push((48 + d) as UInt8);
    } else {
      digits.push((87 + d) as UInt8);
    }
    t = t >> 4;
  }
  var out = Vec[UInt8].new();
  var i = digits.len() - 1;
  while i >= 0 {
    out.push(digits[i]);
    i = i - 1;
  }
  out
}

/// socket_chunk_encode wraps data in one HTTP/1.1 chunked-transfer frame:
/// "<hex length>\r\n" + data + "\r\n". Empty data yields "" (a zero-length
/// chunk would terminate the stream; use socket_chunked_end for that).
/// Complexity: O(n). Pure.
pub fn socket_chunk_encode(data: &Vec[UInt8]) -> Str
  ensures: data.len() == 0 => result.len() == 0
  ensures: data.len() > 0 => result.len() >= data.len() + 3
{
  var out = Vec[UInt8].new();
  let dlen = data.len();
  if dlen == 0 {
    return Str::from_utf8(out);
  }
  let hx = hex_bytes(dlen);
  var h = 0;
  while h < hx.len() {
    out.push(hx[h]);
    h = h + 1;
  }
  out.push(13);
  out.push(10);
  var i = 0;
  while i < dlen {
    out.push(data[i]);
    i = i + 1;
  }
  out.push(13);
  out.push(10);
  Str::from_utf8(out)
}

/// socket_chunked_end returns the terminating zero-length chunk
/// ("0\r\n\r\n") that finishes a chunked-transfer body. Complexity: O(1).
/// Pure.
pub fn socket_chunked_end() -> Str
  ensures: result.len() == 5
{
  var out = Vec[UInt8].new();
  out.push(48);
  out.push(13);
  out.push(10);
  out.push(13);
  out.push(10);
  Str::from_utf8(out)
}

/// socket_stream_chunk sends one chunk frame (encode + full send). Empty
/// data is a documented no-op (Ok(())). Write the response head with
/// Transfer-Encoding: chunked first (e.g. via
/// server.server_build_response_headers), then chunks, then
/// socket_stream_end.
/// Returns: Ok(()) once the frame is on the wire; Err on failure.
/// Complexity: O(n) network I/O.
pub fn socket_stream_chunk(fd: Int, data: &Vec[UInt8]) -> Result[Unit, Str]
  ensures: data.len() == 0 => result is Ok
  ensures: result is Ok => fd >= 0
{
  if fd < 0 {
    return Err("socket_stream_chunk: invalid fd");
  }
  if data.len() == 0 {
    return Ok(());
  }
  let chunk = socket_chunk_encode(data);
  var bytes: Vec[UInt8] = Vec[UInt8].new();
  var i = 0;
  while i < chunk.len() {
    bytes.push(chunk.byte_at(i));
    i = i + 1;
  }
  let sent = socket_send_all(fd, &bytes);
  match sent {
    Ok(_) => Ok(()),
    Err(e) => Err(e),
  }
}

/// socket_stream_end sends the terminating zero-length chunk.
/// Returns: Ok(()) once the terminator is on the wire; Err on failure.
/// Complexity: O(1) network I/O.
pub fn socket_stream_end(fd: Int) -> Result[Unit, Str]
  ensures: result is Ok => fd >= 0
{
  if fd < 0 {
    return Err("socket_stream_end: invalid fd");
  }
  let tail = socket_chunked_end();
  var bytes: Vec[UInt8] = Vec[UInt8].new();
  var i = 0;
  while i < tail.len() {
    bytes.push(tail.byte_at(i));
    i = i + 1;
  }
  let sent = socket_send_all(fd, &bytes);
  match sent {
    Ok(_) => Ok(()),
    Err(e) => Err(e),
  }
}

/// socket_recv receives up to max bytes; returns the bytes received.
/// Complexity: O(n) blocking syscall.
pub fn socket_recv(fd: Int, max: Int) -> Result[Vec[UInt8], Str]
  ensures: (result.is_ok == false) || (fd >= 0 && max > 0)
{
  if fd < 0 {
    return Err("socket_recv: invalid fd");
  }
  if max <= 0 {
    return Err("socket_recv: non-positive max");
  }
  var cap = max;
  if cap > 65536 {
    cap = 65536;
  }
  var raw_buf: [65536]UInt8;
  let n32: Int32 = unsafe { xiom_socket_recv(fd, &raw_buf as *UInt8, cap) };
  let n = n32 as Int;
  if n < 0 {
    return Err("socket_recv: recv failed");
  }
  var result: Vec[UInt8] = Vec[UInt8]::with_capacity(n as UInt);
  var i = 0;
  while i < n {
    result.push(raw_buf[i]);
    i = i + 1;
  }
  Ok(result)
}

/// socket_recv_into receives up to max bytes into a caller-owned buffer:
/// it clears buf, fills it with the bytes received, and returns the count
/// (0 = clean EOF). Err on a socket failure; buf is left empty. The
/// buffer's capacity is reused, so a per-connection buffer allocates at
/// most once instead of once per call (REL-20261022-2049-pulse).
/// Complexity: O(n) blocking syscall.
pub fn socket_recv_into(fd: Int, buf: &mut Vec[UInt8], max: Int) -> Result[Int, Str]
  ensures: (result.is_ok == false) || (fd >= 0 && max > 0)
{
  if fd < 0 {
    return Err("socket_recv_into: invalid fd");
  }
  if max <= 0 {
    return Err("socket_recv_into: non-positive max");
  }
  var cap = max;
  if cap > 65536 {
    cap = 65536;
  }
  var raw_buf: [65536]UInt8;
  let n32: Int32 = unsafe { xiom_socket_recv(fd, &raw_buf as *UInt8, cap) };
  let n = n32 as Int;
  buf.clear();
  if n < 0 {
    return Err("socket_recv_into: recv failed");
  }
  if buf.cap < n {
    buf.reserve(n);
  }
  var i = 0;
  while i < n {
    buf.push(raw_buf[i]);
    i = i + 1;
  }
  Ok(n)
}

/// socket_send_to sends a datagram to addr:port; returns the count
/// written. Complexity: O(n) syscall.
pub fn socket_send_to(fd: Int, data: &Vec[UInt8], addr: Str, port: Int) -> Result[Int, Str]
  ensures: (result.is_ok == false) || (fd >= 0 && port >= 1 && port <= 65535 && data.len() <= 65536)
{
  if fd < 0 {
    return Err("socket_send_to: invalid fd");
  }
  if port <= 0 || port > 65535 {
    return Err("socket_send_to: port out of range");
  }
  var raw_buf: [65536]UInt8;
  let dlen = data.len();
  if dlen > 65536 {
    return Err("socket_send_to: data too large for stack buffer");
  }
  var i = 0;
  while i < dlen {
    raw_buf[i] = data[i];
    i = i + 1;
  }
  var c_host: [256]UInt8;
  var h = 0;
  let alen = addr.len();
  while h < alen && h < 255 {
    c_host[h] = addr.byte_at(h);
    h = h + 1;
  }
  c_host[h] = 0 as UInt8;
  let n: Int32 = unsafe { xiom_socket_sendto(fd, &raw_buf as *UInt8, dlen, &c_host as *UInt8, port) };
  if n < 0 {
    return Err("socket_send_to: sendto failed");
  }
  Ok(n as Int)
}

/// socket_recv_from receives a datagram; the tuple is
/// (data, peer_addr, peer_port). Complexity: O(n) blocking syscall.
pub fn socket_recv_from(fd: Int, max: Int) -> Result[(Vec[UInt8], Str, Int), Str]
  ensures: (result.is_ok == false) || (fd >= 0 && max > 0)
{
  if fd < 0 {
    return Err("socket_recv_from: invalid fd");
  }
  if max <= 0 {
    return Err("socket_recv_from: non-positive max");
  }
  var cap = max;
  if cap > 65536 {
    cap = 65536;
  }
  var raw_buf: [65536]UInt8;
  var ip_buf: [64]UInt8;
  var port_val: Int = 0;
  let n32: Int32 = unsafe { xiom_socket_recvfrom(fd, &raw_buf as *UInt8, cap, &ip_buf as *UInt8, &port_val) };
  let n = n32 as Int;
  if n < 0 {
    return Err("socket_recv_from: recvfrom failed");
  }
  var data: Vec[UInt8] = Vec[UInt8]::with_capacity(n as UInt);
  var i = 0;
  while i < n {
    data.push(raw_buf[i]);
    i = i + 1;
  }
  var ip_len: Int = 0;
  while ip_len < 64 && ip_buf[ip_len] != 0 as UInt8 {
    ip_len = ip_len + 1;
  }
  var ip_chars: Vec[UInt8] = Vec[UInt8]::with_capacity(ip_len as UInt);
  var j = 0;
  while j < ip_len {
    ip_chars.push(ip_buf[j]);
    j = j + 1;
  }
  let peer = Str::from_utf8(ip_chars);
  Ok((data, peer, port_val))
}

/// socket_recv_timeout receives up to max bytes with a per-call deadline:
/// it sets the receive timeout to ms, receives, then restores no-timeout
/// (0). A deadline expiry (or any recv failure) surfaces as Err -- the
/// slowloris guard from REL-20261011-0317-pulse-2. Real since wave 119.
pub fn socket_recv_timeout(fd: Int, max: Int, ms: Int) -> Result[Vec[UInt8], Str]
  ensures: (fd < 0) => (result is Err)
  ensures: (ms < 0) => (result is Err)
{
  if fd < 0 {
    return Err("socket_recv_timeout: invalid fd");
  }
  if ms < 0 {
    return Err("socket_recv_timeout: negative timeout");
  }
  let st = socket_set_timeout(fd, ms);
  match st {
    Ok(_) => {},
    Err(_) => {
      return Err("socket_recv_timeout: set timeout failed");
    },
  };
  let r = socket_recv(fd, max);
  let sr = socket_set_timeout(fd, 0);
  let _ = sr;
  return r;
}

/// socket_recv_timeout_into is socket_recv_into with a per-call receive
/// deadline: it sets the receive timeout to ms, receives into buf, then
/// restores no-timeout (0). Ok(0) is a clean EOF; Err is a timeout or
/// socket failure (the 408 path) and leaves buf empty. Buffer capacity is
/// reused across calls (REL-20261022-2049-pulse).
/// Complexity: O(n) syscall.
pub fn socket_recv_timeout_into(fd: Int, buf: &mut Vec[UInt8], max: Int, ms: Int) -> Result[Int, Str]
  ensures: (fd < 0) => (result is Err)
  ensures: (ms < 0) => (result is Err)
{
  if fd < 0 {
    return Err("socket_recv_timeout_into: invalid fd");
  }
  if ms < 0 {
    return Err("socket_recv_timeout_into: negative timeout");
  }
  let st = socket_set_timeout(fd, ms);
  match st {
    Ok(_) => {},
    Err(_) => {
      return Err("socket_recv_timeout_into: set timeout failed");
    },
  };
  let r = socket_recv_into(fd, buf, max);
  let sr = socket_set_timeout(fd, 0);
  let _ = sr;
  return r;
}

/// socket_close closes a socket, releasing the fd.
/// Complexity: O(1) syscall.
pub fn socket_close(fd: Int)
  ensures: true
{
  if fd >= 0 {
    unsafe { xiom_socket_close(fd); }
  }
}

/// socket_set_timeout sets the receive timeout in milliseconds
/// (SO_RCVTIMEO; 0 = no timeout). Real since wave 119. Invalid inputs keep
/// the documented early-error path (no contract abort).
/// Returns: Ok(()) once the option is set; Err on failure.
pub fn socket_set_timeout(fd: Int, ms: Int) -> Result[Unit, Str]
  ensures: (fd < 0) => (result is Err)
  ensures: (ms < 0) => (result is Err)
{
  if fd < 0 {
    return Err("socket_set_timeout: invalid fd");
  }
  if ms < 0 {
    return Err("socket_set_timeout: negative timeout");
  }
  let rc: Int32;
  unsafe {
    rc = xiom_socket_set_timeout(fd, ms);
  }
  if rc != 0 {
    return Err("socket_set_timeout: setsockopt failed");
  }
  Ok(())
}

/// socket_set_nonblocking enables or disables non-blocking mode
/// (fcntl O_NONBLOCK on POSIX, ioctlsocket FIONBIO on Windows). Real
/// since wave 119; invalid fd keeps the documented early-error path.
pub fn socket_set_nonblocking(fd: Int, on: Bool) -> Result[Unit, Str]
  ensures: (fd < 0) => (result is Err)
{
  if fd < 0 {
    return Err("socket_set_nonblocking: invalid fd");
  }
  var v = 0;
  if on {
    v = 1;
  }
  let rc: Int32;
  unsafe {
    rc = xiom_socket_set_nonblocking(fd, v);
  }
  if rc != 0 {
    return Err("socket_set_nonblocking: mode change failed");
  }
  Ok(())
}

/// socket_set_nodelay disables or enables Nagle (TCP_NODELAY). Real since
/// wave 143; invalid fds keep the documented early-error path.
pub fn socket_set_nodelay(fd: Int, on: Bool) -> Result[Unit, Str]
  ensures: (fd < 0) => (result is Err)
{
  if fd < 0 {
    return Err("socket_set_nodelay: invalid fd");
  }
  var v = 0;
  if on {
    v = 1;
  }
  let rc: Int32;
  unsafe {
    rc = xiom_socket_set_nodelay(fd, v);
  }
  if rc != 0 {
    return Err("socket_set_nodelay: setsockopt failed");
  }
  Ok(())
}

/// socket_set_keepalive enables or disables SO_KEEPALIVE on a socket. Real
/// since wave 143; invalid fds keep the documented early-error path.
pub fn socket_set_keepalive(fd: Int, on: Bool) -> Result[Unit, Str]
  ensures: (fd < 0) => (result is Err)
{
  if fd < 0 {
    return Err("socket_set_keepalive: invalid fd");
  }
  var v = 0;
  if on {
    v = 1;
  }
  let rc: Int32;
  unsafe {
    rc = xiom_socket_set_keepalive(fd, v);
  }
  if rc != 0 {
    return Err("socket_set_keepalive: setsockopt failed");
  }
  Ok(())
}

/// socket_shutdown shuts down reading, writing, or both per how
/// (0 = receive, 1 = send, 2 = both). Real since wave 119; invalid fd/how
/// keep the documented early-error path (no contract abort).
pub fn socket_shutdown(fd: Int, how: Int) -> Result[Unit, Str]
  ensures: (fd < 0) => (result is Err)
  ensures: (how < 0) => (result is Err)
  ensures: (how > 2) => (result is Err)
{
  if fd < 0 {
    return Err("socket_shutdown: invalid fd");
  }
  if how < 0 || how > 2 {
    return Err("socket_shutdown: invalid how");
  }
  let rc: Int32;
  unsafe {
    rc = xiom_socket_shutdown(fd, how);
  }
  if rc != 0 {
    return Err("socket_shutdown: shutdown failed");
  }
  Ok(())
}

/// socket_peer_addr returns the connected peer address. The runtime does
/// not expose getpeername(); always returns a documented Err.
pub fn socket_peer_addr(fd: Int) -> Result[(Str, Int), Str]
  ensures: result.is_err == true
{
  if fd < 0 {
    return Err("socket_peer_addr: invalid fd");
  }
  Err("socket_peer_addr: getpeername() not exposed by runtime")
}

/// socket_local_addr returns the bound local (addr, port) via
/// getsockname (real since wave 155, REL-20261016-1404); an unbound or
/// closed fd returns Err.
pub fn socket_local_addr(fd: Int) -> Result[(Str, Int), Str]
  ensures: (fd < 0) => (result is Err)
{
  if fd < 0 {
    return Err("socket_local_addr: invalid fd");
  }
  var ip_buf: [64]UInt8;
  var port_val: Int = 0;
  let rc: Int32 = unsafe { xiom_socket_local_addr(fd, &ip_buf as *UInt8, 64, &port_val) };
  if rc != 0 {
    return Err("socket_local_addr: getsockname failed");
  }
  var ip_len: Int = 0;
  while ip_len < 64 && ip_buf[ip_len] != 0 as UInt8 {
    ip_len = ip_len + 1;
  }
  var ip_chars: Vec[UInt8] = Vec[UInt8]::with_capacity(ip_len as UInt);
  var j = 0;
  while j < ip_len {
    ip_chars.push(ip_buf[j]);
    j = j + 1;
  }
  Ok((Str::from_utf8(ip_chars), port_val))
}

/// socket_available returns the number of bytes currently readable
/// without blocking. The runtime does not expose FIONREAD; returns 0.
pub fn socket_available(fd: Int) -> Int
  ensures: result == 0
{
  let _ = fd;
  0
}

/// socket_reuse_addr enables or disables SO_REUSEADDR. Real since wave
/// 119 (setsockopt on both platforms; the Windows bind also sets it);
/// invalid fd keeps the documented early-error path.
/// Returns: Ok(()) once the option is set; Err on failure.
pub fn socket_reuse_addr(fd: Int, on: Bool) -> Result[Unit, Str]
  ensures: (fd < 0) => (result is Err)
{
  if fd < 0 {
    return Err("socket_reuse_addr: invalid fd");
  }
  var v = 0;
  if on {
    v = 1;
  }
  let rc: Int32;
  unsafe {
    rc = xiom_socket_reuse_addr(fd, v);
  }
  if rc != 0 {
    return Err("socket_reuse_addr: setsockopt failed");
  }
  Ok(())
}

/// socket_set_reuseport enables or disables SO_REUSEPORT (real since wave
/// 122; POSIX only). Windows has no equivalent: the documented Err says to
/// run N processes on distinct ports behind a reverse proxy. The double
/// bind of one port by two SO_REUSEPORT listeners is the POSIX semantic.
/// Returns: Ok(()) once the option is set; Err on failure or on Windows.
pub fn socket_set_reuseport(fd: Int, on: Bool) -> Result[Unit, Str]
  ensures: (fd < 0) => (result is Err)
{
  if fd < 0 {
    return Err("socket_set_reuseport: invalid fd");
  }
  var v = 0;
  if on {
    v = 1;
  }
  let rc: Int32;
  unsafe {
    rc = xiom_socket_reuseport(fd, v);
  }
  if rc != 0 {
    if env.FAMILY == "windows" {
      return Err("socket_set_reuseport: SO_REUSEPORT has no Windows equivalent (run N processes on distinct ports behind a reverse proxy)");
    }
    return Err("socket_set_reuseport: setsockopt SO_REUSEPORT failed");
  }
  Ok(())
}

// poll_impl is the shared body of the poll wrappers: it copies the fd
// list into a bounded stack array, calls the runtime poll and compacts
// the result to the ready fds (in input order).
fn poll_impl(fds: &Vec[Int], timeout_ms: Int, for_write: Bool) -> Result[Vec[Int], Str] {
  let n = fds.len();
  if n > 1024 {
    return Err("socket_poll: too many fds (max 1024)");
  }
  if timeout_ms < 0 {
    return Err("socket_poll: negative timeout");
  }
  var out: Vec[Int] = Vec[Int].new();
  if n == 0 {
    return Ok(out);
  }
  var arr: [1024]Int;
  var i = 0;
  while i < n {
    arr[i] = fds[i];
    i = i + 1;
  }
  var mode = 0;
  if for_write {
    mode = 1;
  }
  let rc: Int;
  unsafe {
    rc = xiom_poll(&arr[0] as *Int, n, timeout_ms, mode);
  }
  if rc < 0 {
    return Err("socket_poll: poll failed");
  }
  var k = 0;
  while k < rc {
    out.push(arr[k]);
    k = k + 1;
  }
  Ok(out)
}

/// socket_poll_read waits for read readiness over a list of sockets and
/// returns the ready ones (in input order; up to 1024 fds per call).
/// Real since wave 122: poll() on POSIX, WSAPoll on Windows. Errors and
/// invalid entries count as ready so the caller can inspect them.
/// timeout_ms: 0 = immediate, > 0 = wait that many ms (negative is Err;
/// no unbounded wait). An empty list is an Ok empty result.
/// Returns: Ok(ready fds); Err on bad arguments or poll failure.
/// Complexity: network wait.
pub fn socket_poll_read(fds: &Vec[Int], timeout_ms: Int) -> Result[Vec[Int], Str]
  ensures: result is Ok => fds.len() <= 1024
  ensures: result is Ok => timeout_ms >= 0
{
  return poll_impl(fds, timeout_ms, false);
}

/// socket_poll_write waits for write readiness over a list of sockets and
/// returns the ready ones (in input order; up to 1024 fds per call).
/// Real since wave 122: poll()/WSAPoll. Same bounds and conventions as
/// socket_poll_read.
/// Returns: Ok(ready fds); Err on bad arguments or poll failure.
/// Complexity: network wait.
pub fn socket_poll_write(fds: &Vec[Int], timeout_ms: Int) -> Result[Vec[Int], Str]
  ensures: result is Ok => fds.len() <= 1024
  ensures: result is Ok => timeout_ms >= 0
{
  return poll_impl(fds, timeout_ms, true);
}

// Strict non-negative decimal parse for the activation counters (no sign,
// no junk, no overflow).
fn _listen_fds_count(s: Str) -> Result[Int, Str] {
  if s.len() == 0 {
    return Err("socket_listen_fds: empty count");
  };
  var v = 0;
  var i = 0;
  while i < s.len() {
    let c = s.byte_at(i) as Int;
    if c < 48 || c > 57 {
      return Err("socket_listen_fds: invalid count");
    };
    if v > 214748364 {
      return Err("socket_listen_fds: count overflow");
    };
    v = v * 10 + (c - 48);
    i = i + 1;
  };
  return Ok(v);
}

/// socket_listen_fds adopts systemd socket activation: LISTEN_PID must equal
/// this process, LISTEN_FDS is the inherited descriptor count, and the fds
/// are 3..3+N-1 (the classic systemd convention). POSIX-only. On success the
/// LISTEN_PID/LISTEN_FDS variables are consumed so a second call cannot
/// double-adopt; LISTEN_FDNAMES stays in place for the caller. Err on
/// Windows, a missing/mismatched PID, an invalid or negative count, or a
/// count above the 1024-fd poll cap.
/// Complexity: O(number of inherited fds).
pub fn socket_listen_fds() -> Result[Vec[Int], Str]
  ensures: (env.host_is_windows()) => (result.is_err)
{
  if env.host_is_windows() {
    return Err("socket_listen_fds: systemd socket activation is POSIX-only");
  };
  let pid_raw = env.get_var("LISTEN_PID");
  let pid_text: Str;
  match pid_raw {
    Ok(v) => { pid_text = v; },
    Err(_) => { return Err("socket_listen_fds: LISTEN_PID is not set"); },
  };
  let pid_parsed = _listen_fds_count(pid_text);
  let listen_pid: Int;
  match pid_parsed {
    Ok(v) => { listen_pid = v; },
    Err(e) => { return Err(e); },
  };
  var current_pid: Int = 0;
  unsafe {
    current_pid = xiom_getpid() as Int;
  };
  if listen_pid != current_pid {
    return Err("socket_listen_fds: LISTEN_PID does not match this process");
  };
  let fds_raw = env.get_var("LISTEN_FDS");
  let fds_text: Str;
  match fds_raw {
    Ok(v) => { fds_text = v; },
    Err(_) => { return Err("socket_listen_fds: LISTEN_FDS is not set"); },
  };
  let count_parsed = _listen_fds_count(fds_text);
  var count: Int = 0;
  match count_parsed {
    Ok(v) => { count = v; },
    Err(e) => { return Err(e); },
  };
  if count > 1024 {
    return Err("socket_listen_fds: too many inherited fds (max 1024)");
  };
  var out = Vec[Int].new();
  var i = 0;
  while i < count {
    out.push(3 + i);
    i = i + 1;
  };
  env.remove_var("LISTEN_PID");
  env.remove_var("LISTEN_FDS");
  return Ok(out);
}

// ---------------------------------------------------------------------------
// Event loop (wave 176; Linux epoll backend, other platforms Err)
// ---------------------------------------------------------------------------

/// Opaque readiness-loop handle (an epoll fd on Linux).
pub type EventLoop = { handle: Int; }

/// Readiness batch: parallel fds/flags vectors (no Vec[struct]). Flags:
/// bit 1 = readable, bit 2 = writable, bit 4 = error/hangup.
pub type EventBatch = { fds: Vec[Int]; flags: Vec[Int]; }

/// New empty readiness batch.
pub fn eventbatch_new() -> EventBatch
  ensures: result.fds.len() == 0
  ensures: result.flags.len() == 0
{
  return EventBatch{ fds: Vec[Int].new(); flags: Vec[Int].new(); };
}

/// Create a readiness loop. Linux uses epoll, Windows uses a WSAPoll
/// readiness shim; macOS/BSD return the documented Err until the kqueue
/// wave.
pub fn eventloop_new() -> Result[EventLoop, Str]
  ensures: (plat.platform_is_macos()) => (result.is_err)
{
  var handle: Int = -1;
  unsafe {
    handle = xiom_eventloop_create() as Int;
  };
  if handle < 0 {
    return Err("eventloop_new: backend create failed (unsupported platform or resource limit)");
  };
  return Ok(EventLoop{ handle: handle; });
}

/// Register `fd` for read and/or write readiness. Err on a closed loop,
/// a negative fd, or a backend failure.
pub fn eventloop_add(loop: &EventLoop, fd: Int, read: Bool, write: Bool) -> Result[Unit, Str]
  ensures: (loop.handle < 0 || fd < 0) => (result.is_err)
{
  if loop.handle < 0 || fd < 0 {
    return Err("eventloop_add: invalid loop handle or fd");
  };
  var r = 0;
  var w = 0;
  if read { r = 1; };
  if write { w = 1; };
  var rc: Int = -1;
  unsafe {
    rc = xiom_eventloop_ctl(loop.handle, 0, fd, r, w) as Int;
  };
  if rc != 0 {
    return Err("eventloop_add: backend registration failed");
  };
  return Ok(());
}

/// Change the read/write interest for a registered `fd`.
pub fn eventloop_modify(loop: &EventLoop, fd: Int, read: Bool, write: Bool) -> Result[Unit, Str]
  ensures: (loop.handle < 0 || fd < 0) => (result.is_err)
{
  if loop.handle < 0 || fd < 0 {
    return Err("eventloop_modify: invalid loop handle or fd");
  };
  var r = 0;
  var w = 0;
  if read { r = 1; };
  if write { w = 1; };
  var rc: Int = -1;
  unsafe {
    rc = xiom_eventloop_ctl(loop.handle, 1, fd, r, w) as Int;
  };
  if rc != 0 {
    return Err("eventloop_modify: backend modify failed");
  };
  return Ok(());
}

/// Remove `fd` from the loop.
pub fn eventloop_remove(loop: &EventLoop, fd: Int) -> Result[Unit, Str]
  ensures: (loop.handle < 0 || fd < 0) => (result.is_err)
{
  if loop.handle < 0 || fd < 0 {
    return Err("eventloop_remove: invalid loop handle or fd");
  };
  var rc: Int = -1;
  unsafe {
    rc = xiom_eventloop_ctl(loop.handle, 2, fd, 0, 0) as Int;
  };
  if rc != 0 {
    return Err("eventloop_remove: backend remove failed");
  };
  return Ok(());
}

/// Wait for readiness and APPEND the ready entries to `out`. `timeout_ms`:
/// 0 = immediate, > 0 = wait that many ms, -1 = block until an event.
/// Returns the number of events appended. Err on a closed loop or a timeout
/// below -1.
pub fn eventloop_wait(loop: &EventLoop, timeout_ms: Int, out: &mut EventBatch) -> Result[Int, Str]
  ensures: (loop.handle < 0 || timeout_ms < 0 - 1) => (result.is_err)
{
  if loop.handle < 0 {
    return Err("eventloop_wait: closed loop");
  };
  if timeout_ms < 0 - 1 {
    return Err("eventloop_wait: timeout below -1");
  };
  var fds: [256]Int;
  var flags: [256]Int;
  var rc: Int = -1;
  unsafe {
    rc = xiom_eventloop_wait(loop.handle, timeout_ms, &fds[0] as *Int, &flags[0] as *Int, 256);
  };
  if rc < 0 {
    return Err("eventloop_wait: backend wait failed");
  };
  var i = 0;
  while i < rc {
    out.fds.push(fds[i]);
    out.flags.push(flags[i]);
    i = i + 1;
  };
  return Ok(rc);
}

/// Close the loop and invalidate the handle. Idempotent: returns false when
/// the loop was already closed, true when this call closed it. Registered
/// fds are never closed by the loop.
pub fn eventloop_close(loop: &mut EventLoop) -> Bool
  ensures: result == (loop.handle@pre >= 0)
{
  if loop.handle < 0 {
    return false;
  };
  let handle = loop.handle;
  loop.handle = 0 - 1;
  var rc: Int = 0;
  unsafe {
    rc = xiom_eventloop_close(handle) as Int;
  };
  return true;
}
