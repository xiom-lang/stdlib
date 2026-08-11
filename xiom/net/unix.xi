// XIOM - Network: Unix Domain Sockets
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.net.unix

// ============================================================================
// AF_UNIX domain socket client and server over minimal FFI.
// Connect, listen, accept, send/recv, plus socketpair and credentials.
// ============================================================================

// struct UnixSocket { fd: Int; path: Str; listening: Bool }

// (UnixSocket, UnixSocket) - socketpair result: the connected pair.
// (Int, Int, Int) - peer_credentials result: pid, uid, gid.

// fn unix_connect(path: Str) -> Result[UnixSocket, Str] - connect to a listening unix socket. TODO(compiler): implement.
// fn unix_listen(path: Str) -> Result[UnixSocket, Str] - create a listening socket on a path. TODO(compiler): implement.
// fn unix_accept(sock) -> Result[UnixSocket, Str] - accept an incoming connection. TODO(compiler): implement.
// fn unix_send(sock, data: &Vec[UInt8]) -> Result[Int, Str] - write bytes to a socket. TODO(compiler): implement.
// fn unix_recv(sock, max: Int) -> Result[Vec[UInt8], Str] - read up to max bytes from a socket. TODO(compiler): implement.
// fn unix_close(sock) - close a socket and its fd. TODO(compiler): implement.
// fn unix_bind(path: Str) -> Result[UnixSocket, Str] - bind a socket to a path. TODO(compiler): implement.
// fn unix_connect_timeout(path: Str, timeout_ms: Int) -> Result[UnixSocket, Str] - connect with a timeout. TODO(compiler): implement.
// fn unix_socketpair() -> Result[(UnixSocket, UnixSocket), Str] - create an anonymous connected pair. TODO(compiler): implement.
// fn unix_peer_credentials(sock) -> Result[(Int, Int, Int), Str] - read the peer pid, uid, and gid. TODO(compiler): implement.
