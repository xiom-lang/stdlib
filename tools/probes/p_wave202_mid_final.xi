// p_wave202_mid_final.xi -- wave 202: mid-module real-clause runtime locks.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Every call below re-evaluates a wave-202 requires/ensures at runtime, so a
// violated clause aborts the probe. Cases:
// 1. ptr: null/dangling classification and address equality (is_null/eq).
// 2. async: AsyncExecutor pending/timer inspection laws and the non-negative
//    sleep domain on sleep_ms/async_sleep_ms (no global driver call).
// 3. error.backtrace: enable flag round-trip (getter/setter postconditions).
// 4. ffi.errno: errno_last reports the value installed by errno_set.
// 5. log.json: log_json_parse Ok payloads carry a level in [0, 5].
// 6. crypto.curves: curve_point_on_curve accepts the secp256k1 generator
//    (named-curve domain) and rejects (0, 0).
// 7. crypto.keyx: x25519_keypair returns 32-byte sk and pk.
// Returns 0 when every case holds.

module p_wave202_mid_final

use xiom.ptr;
use xiom.async;
use xiom.async.AsyncExecutor;
use xiom.error.backtrace;
use xiom.ffi.errno;
use xiom.log.json;
use xiom.crypto.curves as curves;
use xiom.crypto.keyx;
use xiom.io;

fn noop() {}

fn main() -> Int {
  // 1: pointer predicates.
  let n = ptr.null[Int]();
  if !ptr.is_null(n) { return 1; }
  let d = ptr.dangling[Int]();
  if ptr.is_null(d) { return 2; }
  if !ptr.eq(n, n) { return 3; }
  if ptr.eq(n, d) { return 4; }

  // 2: executor inspection + sleep domain.
  var ex = AsyncExecutor.new();
  if async.async_has_pending(&ex) { return 5; }
  if async.async_timer_count(&ex) != 0 { return 6; }
  AsyncExecutor.at(&mut ex, async.async_now_ms() + 60000, noop);
  if !async.async_has_pending(&ex) { return 7; }
  if async.async_timer_count(&ex) != 1 { return 8; }
  async.async_sleep_ms(0);

  // 3: backtrace enable flag round-trip.
  if !backtrace.error_backtrace_enabled() { return 9; }
  backtrace.error_set_backtrace_enabled(false);
  if backtrace.error_backtrace_enabled() { return 10; }
  backtrace.error_set_backtrace_enabled(true);
  if !backtrace.error_backtrace_enabled() { return 11; }

  // 4: errno snapshot reports the installed code.
  errno.errno_set(2);
  if errno.errno_last() != 2 { return 12; }

  // 5: parsed log level stays in the documented 0..5 band.
  let line = json.log_json_entry(2, "wave202");
  let parsed = json.log_json_parse(line);
  if !parsed.is_ok { return 13; }
  match parsed {
    Ok(entry) => {
      if entry.level < 0 || entry.level > 5 { return 14; }
      if entry.message != "wave202" { return 15; }
    },
    Err(_) => { return 16; },
  };
  let bad = json.log_json_parse("not json");
  if bad.is_ok { return 17; }

  // 6: named-curve domain and secp256k1 generator equation.
  let gen = curves.secp256k1_generator();
  if !curves.curve_point_on_curve(1, &gen.0, &gen.1) { return 18; }
  var zx = Vec[UInt8].new();
  var zy = Vec[UInt8].new();
  var bi = 0;
  while bi < 32 {
    zx.push(0 as UInt8);
    zy.push(0 as UInt8);
    bi = bi + 1;
  }
  if curves.curve_point_on_curve(1, &zx, &zy) { return 19; }

  // 7: X25519 keypair wire sizes.
  let kp = keyx.x25519_keypair();
  if kp.0.len() != 32 { return 20; }
  if kp.1.len() != 32 { return 21; }

  io.println("p_wave202_mid_final: OK");
  return 0;
}
