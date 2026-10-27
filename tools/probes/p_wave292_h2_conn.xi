// p_wave292_h2_conn.xi -- connection-control payloads + stream ids.
// Covers stream-id allocation, RST_STREAM, GOAWAY and WINDOW_UPDATE.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_wave292_h2_conn

use xiom.net.h2;
use xiom.collections;

fn main() -> Int {
  // Stream ids: client odd, server even, max 2^31-1.
  let a = h2.h2_stream_id_next(0, true);
  if a.is_err || a.value != 1 { return 1; }
  let b = h2.h2_stream_id_next(1, true);
  if b.is_err || b.value != 3 { return 2; }
  let c = h2.h2_stream_id_next(0, false);
  if c.is_err || c.value != 2 { return 3; }
  let d = h2.h2_stream_id_next(2, false);
  if d.is_err || d.value != 4 { return 4; }
  let e = h2.h2_stream_id_next(0x7FFFFFFD, true);
  if e.is_err || e.value != 0x7FFFFFFF { return 5; }
  if h2.h2_stream_id_next(0x7FFFFFFF, true).is_ok { return 6; }
  if !h2.h2_stream_id_is_client(1) { return 7; }
  if h2.h2_stream_id_is_client(2) { return 8; }

  // RST_STREAM.
  let r = h2.h2_rst_stream_encode(3);
  if r.is_err || r.value.len() != 4 { return 9; }
  let rd = h2.h2_rst_stream_decode(&r.value);
  if rd.is_err || rd.value != 3 { return 10; }
  var short = Vec[UInt8].new();
  short.push(0);
  if h2.h2_rst_stream_decode(&short).is_ok { return 11; }

  // GOAWAY.
  var dbg = Vec[UInt8].new();
  dbg.push(65);
  dbg.push(66);
  let g = h2.h2_goaway_encode(5, 0, &dbg);
  if g.is_err || g.value.len() != 10 { return 12; }
  var outdbg = Vec[UInt8].new();
  let gd = h2.h2_goaway_decode_into(&g.value, &mut outdbg);
  if gd.is_err { return 13; }
  if gd.value.0 != 5 { return 14; }
  if gd.value.1 != 0 { return 15; }
  if outdbg.len() != 2 { return 16; }
  if outdbg[0] != 65 || outdbg[1] != 66 { return 16; }
  if h2.h2_goaway_decode_into(&short, &mut outdbg).is_ok { return 17; }

  // WINDOW_UPDATE.
  let w = h2.h2_window_update_encode(1000);
  if w.is_err || w.value.len() != 4 { return 18; }
  let wd = h2.h2_window_update_decode(&w.value);
  if wd.is_err || wd.value != 1000 { return 19; }
  if h2.h2_window_update_encode(0).is_ok { return 20; }
  var zero = Vec[UInt8].new();
  zero.push(0); zero.push(0); zero.push(0); zero.push(0);
  if h2.h2_window_update_decode(&zero).is_ok { return 21; }
  var res = Vec[UInt8].new();
  res.push(0x80); res.push(0); res.push(0); res.push(1);
  let rres = h2.h2_window_update_decode(&res);
  if rres.is_err || rres.value != 1 { return 22; }

  return 0;
}
