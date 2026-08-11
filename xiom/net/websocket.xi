// XIOM - Network: WebSocket
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.net.websocket

// ============================================================================
// WebSocket framing and client handshake per RFC 6455.
// Frame encode/decode, masking, and the connect/send/recv client API.
// ============================================================================

// struct WsFrame { opcode: Int; fin: Bool; masked: Bool; payload: Vec[UInt8] }
// struct WsConnection { socket: TcpStream; key: Str; open: Bool }

// (Str, Int, Str) - parse_url result: host, port, path.

// fn ws_handshake_request(host: Str, path: Str, key: Str) -> Str - build a client upgrade request. TODO(compiler): implement.
// fn ws_accept_key(key: Str) -> Str - compute the Sec-WebSocket-Accept value for a client key. TODO(compiler): implement.
// fn ws_handshake_verify(response: Str, key: Str) -> Bool - verify a server upgrade response against the client key. TODO(compiler): implement.
// fn ws_frame_encode(opcode: Int, payload: &Vec[UInt8], mask: Bool) -> Vec[UInt8] - serialize one WebSocket frame. TODO(compiler): implement.
// fn ws_frame_decode(frame: &Vec[UInt8]) -> Result[WsFrame, Str] - parse one WebSocket frame from bytes. TODO(compiler): implement.
// fn ws_connect(url: Str) -> Result[WsConnection, Str] - open a WebSocket connection to a ws/wss url. TODO(compiler): implement.
// fn ws_send(conn, text: Str) -> Result[Unit, Str] - send a text message. TODO(compiler): implement.
// fn ws_send_binary(conn, data: &Vec[UInt8]) -> Result[Unit, Str] - send a binary message. TODO(compiler): implement.
// fn ws_recv(conn) -> Result[WsFrame, Str] - receive the next frame from the connection. TODO(compiler): implement.
// fn ws_close(conn, code: Int) - send a close frame and tear down the connection. TODO(compiler): implement.
// fn ws_ping(conn) - send a ping frame. TODO(compiler): implement.
// fn ws_pong(conn) - send a pong frame. TODO(compiler): implement.
// fn ws_parse_url(url: Str) -> Result[(Str, Int, Str), Str] - split a ws url into host, port, and path. TODO(compiler): implement.
// fn ws_random_key() -> Str - generate a random Sec-WebSocket-Key value. TODO(compiler): implement.
