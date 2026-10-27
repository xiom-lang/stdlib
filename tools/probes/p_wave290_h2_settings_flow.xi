// p_wave290_h2_settings_flow.xi -- HTTP/2 SETTINGS + flow-control windows.
// Locks encode/decode/validate and window consume/increment/resize.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_wave290_h2_settings_flow

use xiom.net.h2;
use xiom.collections;

fn main() -> Int {
  // SETTINGS round-trip.
  var s = h2.h2_settings_new();
  h2.h2_settings_add(&mut s, h2.H2_SETTINGS_HEADER_TABLE_SIZE, 4096);
  h2.h2_settings_add(&mut s, h2.H2_SETTINGS_ENABLE_PUSH, 0);
  h2.h2_settings_add(&mut s, h2.H2_SETTINGS_INITIAL_WINDOW_SIZE, 65535);
  h2.h2_settings_add(&mut s, h2.H2_SETTINGS_MAX_FRAME_SIZE, 16384);
  let enc = h2.h2_settings_encode(&s);
  if enc.is_err { return 1; }
  if enc.value.len() != 24 { return 2; }
  var dec = h2.h2_settings_new();
  let dr = h2.h2_settings_decode_into(&enc.value, &mut dec);
  if dr.is_err { return 3; }
  if dec.len() != 4 { return 4; }
  if dec[0].id != h2.H2_SETTINGS_HEADER_TABLE_SIZE { return 5; }
  if dec[0].value != 4096 { return 6; }
  if dec[2].value != 65535 { return 7; }

  // Encode range checks.
  var bad_id = h2.h2_settings_new();
  h2.h2_settings_add(&mut bad_id, 0x10000, 1);
  if h2.h2_settings_encode(&bad_id).is_ok { return 8; }
  var bad_val = h2.h2_settings_new();
  h2.h2_settings_add(&mut bad_val, 1, -1);
  if h2.h2_settings_encode(&bad_val).is_ok { return 9; }
  var huge_val = h2.h2_settings_new();
  h2.h2_settings_add(&mut huge_val, 1, 4294967296);
  if h2.h2_settings_encode(&huge_val).is_ok { return 10; }

  // Decode length check.
  var short = Vec[UInt8].new();
  short.push(0);
  if h2.h2_settings_decode(&short).is_ok { return 11; }

  // Validation.
  if h2.h2_settings_validate(&s).is_err { return 12; }
  var push2 = h2.h2_settings_new();
  h2.h2_settings_add(&mut push2, h2.H2_SETTINGS_ENABLE_PUSH, 2);
  if h2.h2_settings_validate(&push2).is_ok { return 13; }
  var win_big = h2.h2_settings_new();
  h2.h2_settings_add(&mut win_big, h2.H2_SETTINGS_INITIAL_WINDOW_SIZE, 2147483648);
  if h2.h2_settings_validate(&win_big).is_ok { return 14; }
  var frame_small = h2.h2_settings_new();
  h2.h2_settings_add(&mut frame_small, h2.H2_SETTINGS_MAX_FRAME_SIZE, 1000);
  if h2.h2_settings_validate(&frame_small).is_ok { return 15; }
  var dup = h2.h2_settings_new();
  h2.h2_settings_add(&mut dup, h2.H2_SETTINGS_ENABLE_PUSH, 0);
  h2.h2_settings_add(&mut dup, h2.H2_SETTINGS_ENABLE_PUSH, 1);
  if h2.h2_settings_validate(&dup).is_ok { return 16; }

  // Window consume/increment.
  var w = h2.h2_window_new(65535);
  if h2.h2_window_available(&w) != 65535 { return 17; }
  let c1 = h2.h2_window_consume(&mut w, 1000);
  if c1.is_err { return 18; }
  if c1.value != 64535 { return 19; }
  if h2.h2_window_consume(&mut w, 70000).is_ok { return 20; }
  if h2.h2_window_consume(&mut w, -1).is_ok { return 21; }
  let i1 = h2.h2_window_increment(&mut w, 1000);
  if i1.is_err { return 22; }
  if i1.value != 65535 { return 23; }
  if h2.h2_window_increment(&mut w, 0).is_ok { return 24; }
  var mx = h2.h2_window_new(h2.H2_MAX_WINDOW);
  if h2.h2_window_increment(&mut mx, 1).is_ok { return 25; }

  // Window resize (SETTINGS INITIAL_WINDOW_SIZE delta).
  var r = h2.h2_window_new(65535);
  if h2.h2_window_consume(&mut r, 1000).is_err { return 26; }
  let z = h2.h2_window_resize(&mut r, 70000);
  if z.is_err { return 27; }
  if z.value != 69000 { return 28; }
  if h2.h2_window_resize(&mut r, 100).is_ok { return 29; }

  return 0;
}
