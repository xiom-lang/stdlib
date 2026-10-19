// p_wave197_math_os.xi -- wave 197: math/os real-path contract invariants.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Every call below re-evaluates a wave-197 requires/ensures at runtime, so a
// violated clause aborts the probe. Cases:
// 1. calculus: the definite-integral delegate returns 0.0 for a == b, and the
//    Gauss-Legendre delegate's zero-width product is 0.0 for a finite integrand.
// 2. game_theory: alpha-beta accepts a non-negative depth and a depth-0 search
//    returns the terminal value game(empty sequence).
// 3. tower: empty sum/product are the Num identities, average's non-zero
//    denominator holds, and clamp/min2/max2 keep their bound laws.
// 4. mathematical_biology: the Euler/compartment steps are fixed points at
//    dt == 0 (Lotka-Volterra, SIR, SEIR, immunology).
// 5. fs_ffi: munmap's non-negative address/length domain accepts a real
//    file mapping and tears it down cleanly.
// Returns 0 when every case holds.

module p_wave197_math_os

use xiom.math;
use xiom.os.fs_ffi;
use xiom.io;

fn sq(x: Float64) -> Float64 {
  return x * x;
}

fn fixed_game(seq: &Vec[Int]) -> Float64 {
  if seq.len() == 0 { return 7.0; }
  return -1.0;
}

fn main() -> Int {
  // 1: zero-width quadrature delegates.
  if math.calculus.integrate(sq, 2.0, 2.0) != 0.0 { return 1; }
  if math.calculus.integrate_gauss(sq, 2.0, 2.0, 4) != 0.0 { return 2; }

  // 2: alpha-beta depth precondition + terminal value.
  if math.game_theory.alpha_beta(fixed_game, 0, -1000.0, 1000.0) != 7.0 { return 3; }

  // 3: tower identities and bound laws.
  var empty_int = Vec[Int].new();
  if math.tower.sum[Int](empty_int) != 0 { return 4; }
  var empty_int2 = Vec[Int].new();
  if math.tower.product[Int](empty_int2) != 1 { return 5; }
  if math.tower.average[Int](10, 20) != 15 { return 6; }
  if math.tower.clamp[Int](150, 0, 100) != 100 { return 7; }
  if math.tower.clamp[Int](-5, 0, 100) != 0 { return 8; }
  if math.tower.min2[Int](3, 7) != 3 { return 9; }
  if math.tower.max2[Int](3, 7) != 7 { return 10; }
  var empty_f = Vec[Float64].new();
  if math.tower.sum[Float64](empty_f) != 0.0 { return 11; }
  var empty_f2 = Vec[Float64].new();
  if math.tower.product[Float64](empty_f2) != 1.0 { return 12; }
  if math.tower.clamp[Float64](0.5, 0.0, 0.25) != 0.25 { return 13; }

  // 4: biological dt == 0 fixed-point laws.
  var lv = math.mathematical_biology.lotka_volterra(1.0, 0.1, 1.0, 0.1, 10.0, 5.0, 0.0);
  if lv.0 != 10.0 || lv.1 != 5.0 { return 14; }
  var sir = math.mathematical_biology.epidemiological_sir(0.3, 0.1, 900.0, 100.0, 0.0, 0.0);
  if sir.0 != 900.0 || sir.1 != 100.0 || sir.2 != 0.0 { return 15; }
  var seir = math.mathematical_biology.epidemiological_seir(0.3, 0.2, 0.1, 900.0, 50.0, 50.0, 0.0, 0.0);
  if seir.0 != 900.0 || seir.1 != 50.0 || seir.2 != 50.0 || seir.3 != 0.0 { return 16; }
  var imm = math.mathematical_biology.immunology(5.0, 3.0, 0.2, 0.1, 0.0);
  if imm.0 != 5.0 || imm.1 != 3.0 { return 17; }

  // 5: munmap domain on a real file mapping.
  let path = "p_wave197_math_os_tmp.bin";
  let _ = io.remove_file(path);
  let w = io.write_file(path, "wave197");
  if w.is_err { return 18; }
  match fs_ffi.mmap(path, 0, 7) {
    Ok(m) => {
      fs_ffi.munmap(m);
    },
    Err(_) => return 19,
  };
  let _ = io.remove_file(path);

  io.println("p_wave197_math_os: OK");
  return 0;
}
