// p_wave298_h2_conn_mux.xi -- HTTP/2 connection-level multiplexing
// (REL-20261015-2202-pulse item 9, connection state machine).
//
// Locks the connection state: concurrency cap, local stream-id allocation,
// stream close tracking, received-GOAWAY drain (including dropping streams
// above the peer's last id and rejecting an increased last id), and a local
// graceful drain.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_wave298_h2_conn_mux

use xiom.net.h2;

fn main() -> Int {
  // ---- client connection, concurrency cap 2
  var c = h2.h2_conn_new(2, true);
  if h2.h2_conn_active(&c) != 0 { return 1; }
  if h2.h2_conn_can_open(&c) != true { return 2; }
  match h2.h2_conn_open_stream(&mut c) {
    Some(id) => { if id != 1 { return 3; } },
    None => { return 4; },
  }
  match h2.h2_conn_open_stream(&mut c) {
    Some(id) => { if id != 3 { return 5; } },
    None => { return 6; },
  }
  if h2.h2_conn_open_stream(&mut c).is_some { return 7; }
  if h2.h2_conn_active(&c) != 2 { return 8; }
  if h2.h2_conn_close_stream(&mut c, 1) != true { return 9; }
  if h2.h2_conn_close_stream(&mut c, 99) != false { return 10; }
  if h2.h2_conn_active(&c) != 1 { return 11; }
  match h2.h2_conn_open_stream(&mut c) {
    Some(id) => { if id != 5 { return 12; } },
    None => { return 13; },
  }

  // ---- received GOAWAY(last=3): drop 5, keep 3
  if h2.h2_conn_recv_goaway(&mut c, 3, h2.H2_ERROR_NO_ERROR) != true { return 14; }
  if h2.h2_conn_is_draining(&c) != true { return 15; }
  if h2.h2_conn_active(&c) != 1 { return 16; }
  if h2.h2_conn_can_open(&c) != false { return 17; }
  if h2.h2_conn_open_stream(&mut c).is_some { return 18; }
  if h2.h2_conn_goaway_last_id(&c) != 3 { return 19; }
  if h2.h2_conn_goaway_error(&c) != 0 { return 20; }
  if h2.h2_conn_is_closed(&c) != false { return 21; }
  if h2.h2_conn_recv_goaway(&mut c, 5, 0) != false { return 22; }
  if h2.h2_conn_recv_goaway(&mut c, 1, 0) != true { return 23; }
  if h2.h2_conn_active(&c) != 0 { return 24; }
  if h2.h2_conn_is_closed(&c) != true { return 25; }

  // ---- clamping + range validation
  var c2 = h2.h2_conn_new(0, false);
  if h2.h2_conn_can_open(&c2) != true { return 26; }
  match h2.h2_conn_open_stream(&mut c2) {
    Some(id) => { if id != 2 { return 27; } },
    None => { return 28; },
  }
  if h2.h2_conn_open_stream(&mut c2).is_some { return 29; }
  if h2.h2_conn_recv_goaway(&mut c2, -1, 0) != false { return 30; }
  if h2.h2_conn_recv_goaway(&mut c2, 0x80000000, 0) != false { return 31; }
  if h2.h2_conn_recv_goaway(&mut c2, 0, 0x100000000) != false { return 32; }

  // ---- local graceful drain (server role, even ids)
  var c3 = h2.h2_conn_new(4, false);
  match h2.h2_conn_open_stream(&mut c3) {
    Some(id) => { if id != 2 { return 33; } },
    None => { return 34; },
  }
  match h2.h2_conn_open_stream(&mut c3) {
    Some(id) => { if id != 4 { return 35; } },
    None => { return 36; },
  }
  if h2.h2_conn_begin_drain(&mut c3, 0, h2.H2_ERROR_NO_ERROR) != true { return 37; }
  if h2.h2_conn_can_open(&c3) != false { return 38; }
  if h2.h2_conn_is_closed(&c3) != false { return 39; }
  if h2.h2_conn_begin_drain(&mut c3, 2, 0) != false { return 40; }
  if h2.h2_conn_close_stream(&mut c3, 2) != true { return 41; }
  if h2.h2_conn_is_closed(&c3) != false { return 42; }
  if h2.h2_conn_close_stream(&mut c3, 4) != true { return 43; }
  if h2.h2_conn_is_closed(&c3) != true { return 44; }
  return 0;
}
