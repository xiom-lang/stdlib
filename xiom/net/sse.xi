// XIOM - Network: Server-Sent Events Client
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.net.sse

// ============================================================================
// Server-Sent Events client per the WHATWG SSE spec. The wire builders
// live in net.xi; this module owns connection lifecycle and parsing.
// ============================================================================

// struct SseConnection { socket: TcpStream; url: Str; open: Bool }
// struct SseEvent { id: Str; event: Str; data: Str; retry: Int }

// fn sse_connect(url: Str) -> Result[SseConnection, Str] - open a text/event-stream connection. TODO(compiler): implement.
// fn sse_read_event(conn) -> Result[SseEvent, Str] - read and parse the next event. TODO(compiler): implement.
// fn sse_parse_event(chunk: Str) -> Result[SseEvent, Str] - parse one raw event chunk. TODO(compiler): implement.
// fn sse_close(conn) - close the event stream connection. TODO(compiler): implement.
// fn sse_read_events(conn, out: &mut Vec[SseEvent]) -> Int - drain available events into out and return the count. TODO(compiler): implement.
// fn sse_event_id(e: SseEvent) -> Option[Str] - return the event id field. TODO(compiler): implement.
// fn sse_event_data(e: SseEvent) -> Str - return the event data field. TODO(compiler): implement.
// fn sse_connect_headers(url: Str, headers: &Vec[(Str, Str)]) -> Result[SseConnection, Str] - connect with custom request headers. TODO(compiler): implement.
