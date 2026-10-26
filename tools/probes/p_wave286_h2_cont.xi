// p_wave286_h2_cont.xi -- HEADERS + CONTINUATION reassembly helpers.
// Covers payload concatenation, END_HEADERS completion, append-after-complete,
// wrong frame type, stream mismatch and the already-complete start. rc 0.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_wave286_h2_cont

use xiom.net.h2;

fn main() -> Int {
  var h1 = Vec[UInt8].new();
  h1.push(1);
  h1.push(2);
  var b = h2.h2_header_block_new(1, &h1, false);
  if h2.h2_header_block_len(&b) != 2 { return 1; }
  if h2.h2_header_block_is_complete(&b) { return 2; }
  let ob = h2.h2_header_block_to_bytes(&b);
  if ob.len() != 2 { return 3; }
  if ob[1] != 2 { return 4; }

  var c1 = Vec[UInt8].new();
  c1.push(3);
  c1.push(4);
  let r1 = h2.h2_header_block_append(&mut b, h2.H2_FRAME_CONTINUATION, 0, 1, &c1);
  if r1.is_err { return 5; }
  if r1.value { return 6; }
  if h2.h2_header_block_len(&b) != 4 { return 7; }

  var c2 = Vec[UInt8].new();
  c2.push(5);
  let r2 = h2.h2_header_block_append(&mut b, h2.H2_FRAME_CONTINUATION, h2.H2_FLAG_END_HEADERS, 1, &c2);
  if r2.is_err { return 8; }
  if !r2.value { return 9; }
  if !h2.h2_header_block_is_complete(&b) { return 10; }
  if h2.h2_header_block_len(&b) != 5 { return 11; }
  let out = h2.h2_header_block_to_bytes(&b);
  if out.len() != 5 { return 12; }
  if out[0] != 1 { return 13; }
  if out[4] != 5 { return 14; }

  // A complete block rejects further CONTINUATION.
  if h2.h2_header_block_append(&mut b, h2.H2_FRAME_CONTINUATION, 0, 1, &c2).is_ok { return 15; }

  // Wrong frame type and wrong stream are rejected.
  var b2 = h2.h2_header_block_new(3, &h1, false);
  if h2.h2_header_block_append(&mut b2, h2.H2_FRAME_HEADERS, 0, 3, &c2).is_ok { return 16; }
  if h2.h2_header_block_append(&mut b2, h2.H2_FRAME_CONTINUATION, 0, 4, &c2).is_ok { return 17; }

  // A block started with END_HEADERS is complete and cannot append.
  var b3 = h2.h2_header_block_new(5, &h1, true);
  if !h2.h2_header_block_is_complete(&b3) { return 18; }
  if h2.h2_header_block_append(&mut b3, h2.H2_FRAME_CONTINUATION, 0, 5, &c2).is_ok { return 19; }

  return 0;
}
