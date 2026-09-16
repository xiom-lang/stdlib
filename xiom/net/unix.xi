// XIOM - Network: Unix Domain Sockets
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.net.unix

// Depends on: xiom.net, xiom.ffi

// ============================================================================
// AF_UNIX domain socket client and server over minimal FFI.
// All functions require the OS AF_UNIX socket layer, which the pure stdlib
// does not expose -- every function is a documented stub returning Err (or a
// documented default) with the fd-based helpers left for the FFI layer.
// ============================================================================

// struct UnixSocket { fd: Int; path: Str; listening: Bool }
pub type UnixSocket = {
  fd: Int;
  path: Str;
  listening: Bool;
}

// (UnixSocket, UnixSocket) - socketpair result: the connected pair.
// (Int, Int, Int) - peer_credentials result: pid, uid, gid.

/// Connect to a listening unix socket.
/// NOT IMPLEMENTED: requires the AF_UNIX socket layer (not available in the
/// pure stdlib).
/// Returns: Err("unix_connect: AF_UNIX sockets not available in the pure stdlib").
pub fn unix_connect(path: Str) -> Result[UnixSocket, Str] {
  let _ = path;
  Err("unix_connect: AF_UNIX sockets not available in the pure stdlib")
}

/// Create a listening socket on a path.
/// NOT IMPLEMENTED: requires the AF_UNIX socket layer (see unix_connect).
/// Returns: Err("unix_listen: AF_UNIX sockets not available in the pure stdlib").
pub fn unix_listen(path: Str) -> Result[UnixSocket, Str] {
  let _ = path;
  Err("unix_listen: AF_UNIX sockets not available in the pure stdlib")
}

/// Accept an incoming connection.
/// NOT IMPLEMENTED: requires the AF_UNIX socket layer (see unix_connect).
/// Returns: Err("unix_accept: AF_UNIX sockets not available in the pure stdlib").
pub fn unix_accept(sock: UnixSocket) -> Result[UnixSocket, Str] {
  let _ = sock;
  Err("unix_accept: AF_UNIX sockets not available in the pure stdlib")
}

/// Write bytes to a socket.
/// NOT IMPLEMENTED: requires the AF_UNIX socket layer (see unix_connect).
/// Returns: Err("unix_send: AF_UNIX sockets not available in the pure stdlib").
pub fn unix_send(sock: UnixSocket, data: &Vec[UInt8]) -> Result[Int, Str] {
  let _ = sock;
  let _ = data;
  Err("unix_send: AF_UNIX sockets not available in the pure stdlib")
}

/// Read up to max bytes from a socket.
/// NOT IMPLEMENTED: requires the AF_UNIX socket layer (see unix_connect).
/// Returns: Err("unix_recv: AF_UNIX sockets not available in the pure stdlib").
pub fn unix_recv(sock: UnixSocket, max: Int) -> Result[Vec[UInt8], Str] {
  let _ = sock;
  let _ = max;
  Err("unix_recv: AF_UNIX sockets not available in the pure stdlib")
}

/// Close a socket and its fd.
/// NO-OP: no live sockets exist in the pure stdlib.
pub fn unix_close(sock: UnixSocket) {
  let _ = sock;
}

/// Bind a socket to a path.
/// NOT IMPLEMENTED: requires the AF_UNIX socket layer (see unix_connect).
/// Returns: Err("unix_bind: AF_UNIX sockets not available in the pure stdlib").
pub fn unix_bind(path: Str) -> Result[UnixSocket, Str] {
  let _ = path;
  Err("unix_bind: AF_UNIX sockets not available in the pure stdlib")
}

/// Connect with a timeout.
/// NOT IMPLEMENTED: requires the AF_UNIX socket layer (see unix_connect).
/// Returns: Err("unix_connect_timeout: AF_UNIX sockets not available in the pure stdlib").
pub fn unix_connect_timeout(path: Str, timeout_ms: Int) -> Result[UnixSocket, Str] {
  let _ = path;
  let _ = timeout_ms;
  Err("unix_connect_timeout: AF_UNIX sockets not available in the pure stdlib")
}

/// Create an anonymous connected pair.
/// NOT IMPLEMENTED: requires the AF_UNIX socket layer (see unix_connect).
/// Returns: Err("unix_socketpair: AF_UNIX sockets not available in the pure stdlib").
pub fn unix_socketpair() -> Result[(UnixSocket, UnixSocket), Str] {
  Err("unix_socketpair: AF_UNIX sockets not available in the pure stdlib")
}

/// Read the peer pid, uid, and gid.
/// NOT IMPLEMENTED: requires the AF_UNIX socket layer (see unix_connect).
/// Returns: Err("unix_peer_credentials: AF_UNIX sockets not available in the pure stdlib").
pub fn unix_peer_credentials(sock: UnixSocket) -> Result[(Int, Int, Int), Str] {
  let _ = sock;
  Err("unix_peer_credentials: AF_UNIX sockets not available in the pure stdlib")
}
