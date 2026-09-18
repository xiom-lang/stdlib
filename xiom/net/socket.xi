// XIOM - Networking: Sockets
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.net.socket

// Depends on: xiom.net + xiom.string
//
// Raw TCP/UDP socket lifecycle: create, bind, listen, accept, connect,
// send, receive, address queries and options. The core operations are
// implemented on the same runtime socket primitives used by xiom.net;
// options that the runtime does not expose (timeout, non-blocking,
// reuse-addr, shutdown, peer/local address, pending bytes) return a
// documented Err instead of crashing.

extern "C" {
  fn xiom_socket_create(family: Int, typ: Int, proto: Int) -> Int;
  fn xiom_socket_connect(sock: Int, host: *UInt8, port: Int) -> Int;
  fn xiom_socket_bind(sock: Int, port: Int) -> Int;
  fn xiom_socket_listen(sock: Int, backlog: Int) -> Int;
  fn xiom_socket_accept(sock: Int, client_ip: *UInt8, client_port: *Int) -> Int;
  fn xiom_socket_send(sock: Int, buf: *UInt8, len: Int) -> Int;
  fn xiom_socket_recv(sock: Int, buf: *UInt8, len: Int) -> Int;
  fn xiom_socket_close(sock: Int) -> Int;
  fn xiom_socket_sendto(sock: Int, buf: *UInt8, len: Int, host: *UInt8, port: Int) -> Int;
  fn xiom_socket_recvfrom(sock: Int, buf: *UInt8, len: Int, out_ip: *UInt8, out_port: *Int) -> Int;
}

const AF_INET: Int = 2;
const SOCK_STREAM: Int = 1;
const SOCK_DGRAM: Int = 2;

// socket_tcp creates a TCP socket and returns its fd, or Err.
// Complexity: O(1) syscall.
/// socket_tcp creates a TCP socket and returns its fd, or Err.
/// Complexity: O(1) syscall.
pub fn socket_tcp() -> Result[Int, Str] {
  let fd = unsafe { xiom_socket_create(AF_INET, SOCK_STREAM, 0) };
  if fd < 0 {
    return Err("socket_tcp: failed to create socket");
  }
  Ok(fd)
}

// socket_udp creates a UDP socket and returns its fd, or Err.
// Complexity: O(1) syscall.
/// socket_udp creates a UDP socket and returns its fd, or Err.
/// Complexity: O(1) syscall.
pub fn socket_udp() -> Result[Int, Str] {
  let fd = unsafe { xiom_socket_create(AF_INET, SOCK_DGRAM, 0) };
  if fd < 0 {
    return Err("socket_udp: failed to create socket");
  }
  Ok(fd)
}

// socket_bind binds a socket to addr:port. The runtime binds to the
// given port on the wildcard address; the addr string is validated for
// non-emptiness. Complexity: O(1) syscall.
/// socket_bind binds a socket to addr:port. The runtime binds to the
/// given port on the wildcard address; the addr string is validated for
/// non-emptiness. Complexity: O(1) syscall.
pub fn socket_bind(fd: Int, addr: Str, port: Int) -> Result[Unit, Str] {
  if fd < 0 {
    return Err("socket_bind: invalid fd");
  }
  if addr.len() == 0 {
    return Err("socket_bind: empty address");
  }
  if port <= 0 || port > 65535 {
    return Err("socket_bind: port out of range");
  }
  let rc = unsafe { xiom_socket_bind(fd, port) };
  if rc < 0 {
    return Err("socket_bind: bind failed");
  }
  Ok(())
}

// socket_listen marks a bound TCP socket as listening.
// Complexity: O(1) syscall.
/// socket_listen marks a bound TCP socket as listening.
/// Complexity: O(1) syscall.
pub fn socket_listen(fd: Int, backlog: Int) -> Result[Unit, Str] {
  if fd < 0 {
    return Err("socket_listen: invalid fd");
  }
  if backlog < 0 {
    return Err("socket_listen: negative backlog");
  }
  let rc = unsafe { xiom_socket_listen(fd, backlog) };
  if rc < 0 {
    return Err("socket_listen: listen failed");
  }
  Ok(())
}

// socket_accept accepts a connection and returns the new socket fd.
// Complexity: O(1) blocking syscall.
/// socket_accept accepts a connection and returns the new socket fd.
/// Complexity: O(1) blocking syscall.
pub fn socket_accept(fd: Int) -> Result[Int, Str] {
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

// socket_connect connects a socket to a remote addr:port.
// Complexity: O(1) syscall.
/// socket_connect connects a socket to a remote addr:port.
/// Complexity: O(1) syscall.
pub fn socket_connect(fd: Int, addr: Str, port: Int) -> Result[Unit, Str] {
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
  let rc = unsafe { xiom_socket_connect(fd, &c_host as *UInt8, port) };
  if rc < 0 {
    return Err("socket_connect: connect failed");
  }
  Ok(())
}

// socket_send sends bytes on a socket; returns the count written.
// Complexity: O(n) syscall.
/// socket_send sends bytes on a socket; returns the count written.
/// Complexity: O(n) syscall.
pub fn socket_send(fd: Int, data: &Vec[UInt8]) -> Result[Int, Str] {
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
  let n = unsafe { xiom_socket_send(fd, &raw_buf as *UInt8, dlen) };
  if n < 0 {
    return Err("socket_send: send failed");
  }
  Ok(n)
}

// socket_recv receives up to max bytes; returns the bytes received.
// Complexity: O(n) blocking syscall.
/// socket_recv receives up to max bytes; returns the bytes received.
/// Complexity: O(n) blocking syscall.
pub fn socket_recv(fd: Int, max: Int) -> Result[Vec[UInt8], Str] {
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
  let n = unsafe { xiom_socket_recv(fd, &raw_buf as *UInt8, cap) };
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

// socket_send_to sends a datagram to addr:port; returns the count
// written. Complexity: O(n) syscall.
/// socket_send_to sends a datagram to addr:port; returns the count
/// written. Complexity: O(n) syscall.
pub fn socket_send_to(fd: Int, data: &Vec[UInt8], addr: Str, port: Int) -> Result[Int, Str] {
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
  let n = unsafe { xiom_socket_sendto(fd, &raw_buf as *UInt8, dlen, &c_host as *UInt8, port) };
  if n < 0 {
    return Err("socket_send_to: sendto failed");
  }
  Ok(n)
}

// socket_recv_from receives a datagram; the tuple is
// (data, peer_addr, peer_port). Complexity: O(n) blocking syscall.
/// socket_recv_from receives a datagram; the tuple is
/// (data, peer_addr, peer_port). Complexity: O(n) blocking syscall.
pub fn socket_recv_from(fd: Int, max: Int) -> Result[(Vec[UInt8], Str, Int), Str] {
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
  let n = unsafe { xiom_socket_recvfrom(fd, &raw_buf as *UInt8, cap, &ip_buf as *UInt8, &port_val) };
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

// socket_close closes a socket, releasing the fd.
// Complexity: O(1) syscall.
/// socket_close closes a socket, releasing the fd.
/// Complexity: O(1) syscall.
pub fn socket_close(fd: Int) {
  if fd >= 0 {
    unsafe { xiom_socket_close(fd); }
  }
}

// socket_set_timeout sets the receive timeout in milliseconds. The
// runtime does not expose SO_RCVTIMEO; always returns a documented Err.
/// socket_set_timeout sets the receive timeout in milliseconds. The
/// runtime does not expose SO_RCVTIMEO; always returns a documented Err.
pub fn socket_set_timeout(fd: Int, ms: Int) -> Result[Unit, Str] {
  if fd < 0 {
    return Err("socket_set_timeout: invalid fd");
  }
  if ms < 0 {
    return Err("socket_set_timeout: negative timeout");
  }
  Err("socket_set_timeout: SO_RCVTIMEO not exposed by runtime")
}

// socket_set_nonblocking enables or disables non-blocking mode. The
// runtime does not expose FIONBIO/O_NONBLOCK; always returns a
// documented Err.
/// socket_set_nonblocking enables or disables non-blocking mode. The
/// runtime does not expose FIONBIO/O_NONBLOCK; always returns a
/// documented Err.
pub fn socket_set_nonblocking(fd: Int, on: Bool) -> Result[Unit, Str] {
  if fd < 0 {
    return Err("socket_set_nonblocking: invalid fd");
  }
  let _ = on;
  Err("socket_set_nonblocking: non-blocking mode not exposed by runtime")
}

// socket_shutdown shuts down reading, writing, or both per how
// (0 = receive, 1 = send, 2 = both). The runtime does not expose
// shutdown(); always returns a documented Err.
/// socket_shutdown shuts down reading, writing, or both per how
/// (0 = receive, 1 = send, 2 = both). The runtime does not expose
/// shutdown(); always returns a documented Err.
pub fn socket_shutdown(fd: Int, how: Int) -> Result[Unit, Str] {
  if fd < 0 {
    return Err("socket_shutdown: invalid fd");
  }
  if how < 0 || how > 2 {
    return Err("socket_shutdown: invalid how");
  }
  Err("socket_shutdown: shutdown() not exposed by runtime")
}

// socket_peer_addr returns the connected peer address. The runtime does
// not expose getpeername(); always returns a documented Err.
/// socket_peer_addr returns the connected peer address. The runtime does
/// not expose getpeername(); always returns a documented Err.
pub fn socket_peer_addr(fd: Int) -> Result[(Str, Int), Str] {
  if fd < 0 {
    return Err("socket_peer_addr: invalid fd");
  }
  Err("socket_peer_addr: getpeername() not exposed by runtime")
}

// socket_local_addr returns the bound local address. The runtime does
// not expose getsockname(); always returns a documented Err.
/// socket_local_addr returns the bound local address. The runtime does
/// not expose getsockname(); always returns a documented Err.
pub fn socket_local_addr(fd: Int) -> Result[(Str, Int), Str] {
  if fd < 0 {
    return Err("socket_local_addr: invalid fd");
  }
  Err("socket_local_addr: getsockname() not exposed by runtime")
}

// socket_available returns the number of bytes currently readable
// without blocking. The runtime does not expose FIONREAD; returns 0.
/// socket_available returns the number of bytes currently readable
/// without blocking. The runtime does not expose FIONREAD; returns 0.
pub fn socket_available(fd: Int) -> Int {
  let _ = fd;
  0
}

// socket_reuse_addr enables or disables SO_REUSEADDR. The runtime does
// not expose setsockopt(); always returns a documented Err.
/// socket_reuse_addr enables or disables SO_REUSEADDR. The runtime does
/// not expose setsockopt(); always returns a documented Err.
pub fn socket_reuse_addr(fd: Int, on: Bool) -> Result[Unit, Str] {
  if fd < 0 {
    return Err("socket_reuse_addr: invalid fd");
  }
  let _ = on;
  Err("socket_reuse_addr: setsockopt() not exposed by runtime")
}
