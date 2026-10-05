// p_pin0640_shapes.xi -- v0.64.0 pin locks: all_types (m195) + exact bits (m194)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the compiler fixes consumed by the v0.64.0 pin wave:
//   - m195: angle-bracket generic receivers keep their type args, so
//     reflect.all_types() is callable and its length mirrors type_count().
//   - m194: num.float.float_bits / bits_to_float lower to an exact LLVM
//     bitcast (1.0 pattern, zero patterns, negative-zero and NaN-safe
//     roundtrips).
// m196 (TcpStream.read) is locked by tests/smoke/smoke_net_tcp_stream.xi and
// m193 (direct runtime externs) by tests/smoke/smoke_guard_alloc_wrap.xi.
// Returns 0 when every case holds.

module p_pin0640_shapes

use xiom.reflect;
use xiom.num.float;

fn main() -> Int {
  // ---- m195: all_types
  let ts = reflect.all_types();
  if ts.len() != reflect.type_count() { return 1; }
  if ts.len() < 0 { return 2; }

  // ---- m194: exact float bit patterns
  if float.float_bits(1.0) != 4607182418800017408 { return 3; }
  if float.float_bits(0.0) != 0 { return 4; }
  if float.bits_to_float(4607182418800017408) != 1.0 { return 5; }
  if float.bits_to_float(0) != 0.0 { return 6; }
  let negzero_bits = 0 - 9223372036854775807 - 1;
  let negzero = float.bits_to_float(negzero_bits);
  if float.float_bits(negzero) != negzero_bits { return 7; }
  if float.float_bits(float.bits_to_float(float.float_bits(2.5))) != float.float_bits(2.5) { return 8; }

  // ---- m194: NaN payload survives the bit roundtrip (bit-level compare)
  let nan_bits = 9221120237041090560;
  if float.float_bits(float.bits_to_float(nan_bits)) != nan_bits { return 9; }

  return 0;
}
