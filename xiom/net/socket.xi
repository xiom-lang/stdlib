// XIOM - Networking: Sockets
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.net.socket

// Depends on: xiom.net + xiom.string

// ============================================================================
// Raw TCP/UDP socket lifecycle: create, bind, listen, accept, connect, send,
// receive, address queries and options. NOTE: current implementation lives in
// net.xi - move the functions here during the implementation phase.
// TODO(compiler): implement.
// ============================================================================

// fn socket_tcp() -> Result[Int, Str] - create a TCP socket and return its fd. TODO(compiler): implement.
// fn socket_udp() -> Result[Int, Str] - create a UDP socket and return its fd. TODO(compiler): implement.
// fn socket_bind(fd: Int, addr: Str, port: Int) -> Result[Unit, Str] - bind a socket to addr:port. TODO(compiler): implement.
// fn socket_listen(fd: Int, backlog: Int) -> Result[Unit, Str] - mark a bound TCP socket as listening. TODO(compiler): implement.
// fn socket_accept(fd: Int) -> Result[Int, Str] - accept a connection and return the new socket fd. TODO(compiler): implement.
// fn socket_connect(fd: Int, addr: Str, port: Int) -> Result[Unit, Str] - connect a socket to a remote addr:port. TODO(compiler): implement.
// fn socket_send(fd: Int, data: &Vec[UInt8]) -> Result[Int, Str] - send bytes; returns the count written. TODO(compiler): implement.
// fn socket_recv(fd: Int, max: Int) -> Result[Vec[UInt8], Str] - receive up to max bytes. TODO(compiler): implement.
// fn socket_send_to(fd: Int, data, addr, port) -> Result[Int, Str] - send a datagram to addr:port; returns the count written. TODO(compiler): implement.
// fn socket_recv_from(fd: Int, max) -> Result[(Vec[UInt8], Str, Int), Str] - receive a datagram; the tuple is (data, peer_addr, peer_port). TODO(compiler): implement.
// fn socket_close(fd: Int) - close a socket, releasing the fd. TODO(compiler): implement.
// fn socket_set_timeout(fd: Int, ms: Int) -> Result[Unit, Str] - set the receive timeout in milliseconds. TODO(compiler): implement.
// fn socket_set_nonblocking(fd: Int, on: Bool) -> Result[Unit, Str] - enable or disable non-blocking mode. TODO(compiler): implement.
// fn socket_shutdown(fd: Int, how: Int) -> Result[Unit, Str] - shut down reading, writing, or both per how. TODO(compiler): implement.
// fn socket_peer_addr(fd: Int) -> Result[(Str, Int), Str] - the connected peer address; the tuple is (addr, port). TODO(compiler): implement.
// fn socket_local_addr(fd: Int) -> Result[(Str, Int), Str] - the bound local address; the tuple is (addr, port). TODO(compiler): implement.
// fn socket_available(fd: Int) -> Int - bytes currently readable without blocking. TODO(compiler): implement.
// fn socket_reuse_addr(fd: Int, on: Bool) -> Result[Unit, Str] - enable or disable SO_REUSEADDR. TODO(compiler): implement.
