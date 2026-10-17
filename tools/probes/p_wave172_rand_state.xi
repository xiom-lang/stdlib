// p_wave172_rand_state.xi -- wave 172 lock: explicit global RNG state
// save/restore on xiom.rand (wishlist row 31). Locks:
//   state() returns the opaque non-zero global snapshot; set_state()
//   restores it exactly, so replaying a saved stream is deterministic.
// Rows: 1 initial non-zero, 2 float replay, 3 mixed stream replay (int,
// bool, bytes, uuid, float, normal), 4 zero-seed normalization, 5 negative
// seed snapshot, 6 nested snapshots, 7 StdRng independence, 8 Xorshift64
// independence, 9 a draw advances the state, 10 bulk shuffle replay,
// 11 CSPRNG draws leave the global stream untouched.
// Every returned value is bound before comparing. Returns 0 when all rows
// hold; a nonzero return names the first failing row.
//
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_wave172_rand_state

use xiom.rand;

fn main() -> Int {
  // --- row 1: initial global state is non-zero ---
  let s0 = rand.state();
  if s0 == 0 { return 1; }

  // --- row 2: the float stream replays from a snapshot ---
  rand.seed_from_value(1234);
  let a0 = rand.state();
  if a0 != 1234 { return 2; }
  let f0 = rand.random();
  let f1 = rand.random();
  let f2 = rand.random();
  rand.set_state(a0);
  let g0 = rand.random();
  let g1 = rand.random();
  let g2 = rand.random();
  if f0 != g0 { return 2; }
  if f1 != g1 { return 2; }
  if f2 != g2 { return 2; }

  // --- row 3: mixed stream (int, bool, bytes, uuid, float, normal) ---
  rand.seed_from_value(777);
  let b0 = rand.state();
  let i0 = rand.random_int(0, 1000);
  let i1 = rand.random_int(0 - 50, 50);
  let flag0 = rand.random_bool();
  let bytes0 = rand.random_bytes(13);
  let uuid0 = rand.uuid_v4();
  let rf0 = rand.random_float(0.0 - 2.0, 3.0);
  let norm0 = rand.sample_normal(0.0, 1.0);
  rand.set_state(b0);
  let i0b = rand.random_int(0, 1000);
  let i1b = rand.random_int(0 - 50, 50);
  let flag1 = rand.random_bool();
  let bytes1 = rand.random_bytes(13);
  let uuid1 = rand.uuid_v4();
  let rf1 = rand.random_float(0.0 - 2.0, 3.0);
  let norm1 = rand.sample_normal(0.0, 1.0);
  if i0 != i0b { return 3; }
  if i1 != i1b { return 3; }
  if flag0 != flag1 { return 3; }
  if uuid0 != uuid1 { return 3; }
  if bytes0.len() != bytes1.len() { return 3; }
  var k = 0;
  while k < bytes0.len() {
    if bytes0[k] != bytes1[k] { return 3; }
    k = k + 1;
  };
  if rf0 != rf1 { return 3; }
  if norm0 != norm1 { return 3; }

  // --- row 4: seed_from_value(0) normalizes to 1 ---
  rand.seed_from_value(0);
  let z0 = rand.state();
  if z0 != 1 { return 4; }

  // --- row 5: a negative seed snapshot is exact ---
  rand.seed_from_value(0 - 7);
  let neg0 = rand.state();
  if neg0 != 0 - 7 { return 5; }
  let nf0 = rand.random();
  rand.set_state(neg0);
  let nf1 = rand.random();
  if nf0 != nf1 { return 5; }
  let neg1 = rand.state();
  if neg1 == neg0 { return 5; }

  // --- row 6: nested snapshots replay to the same positions ---
  rand.seed_from_value(99);
  let q0 = rand.state();
  let v1 = rand.random();
  let v2 = rand.random();
  let q1 = rand.state();
  let v3 = rand.random();
  let q2 = rand.state();
  rand.set_state(q1);
  let q1b = rand.state();
  if q1b != q1 { return 6; }
  let v3b = rand.random();
  if v3b != v3 { return 6; }
  let q2b = rand.state();
  if q2b != q2 { return 6; }
  rand.set_state(q0);
  let w1 = rand.random();
  let w2 = rand.random();
  let w3 = rand.random();
  if w1 != v1 { return 6; }
  if w2 != v2 { return 6; }
  if w3 != v3 { return 6; }

  // --- row 7: StdRng is independent of the global stream ---
  rand.seed_from_value(555);
  let p0 = rand.state();
  var srng = rand.StdRng.from_seed(9);
  let sr0 = srng.next_int();
  let sr1 = srng.next_int();
  let p_after = rand.state();
  if p_after != p0 { return 7; }
  var srng2 = rand.StdRng.from_seed(9);
  let sr0b = srng2.next_int();
  if sr0 != sr0b { return 7; }
  if sr0 == sr1 { return 7; }
  let p1 = rand.random();
  rand.set_state(p0);
  let p2 = rand.random();
  if p1 != p2 { return 7; }

  // --- row 8: Xorshift64 is independent too ---
  rand.seed_from_value(8080);
  let x0 = rand.state();
  var xs = rand.Xorshift64.new(123);
  let xv = xs.next_int();
  let x_after = rand.state();
  if x_after != x0 { return 8; }
  var xs2 = rand.Xorshift64.new(123);
  let xvb = xs2.next_int();
  if xv != xvb { return 8; }

  // --- row 9: every draw advances the stored state ---
  rand.seed_from_value(2026);
  let d0 = rand.state();
  let dv = rand.random();
  let d1 = rand.state();
  if dv < 0.0 || dv >= 1.0 { return 9; }
  if d0 == d1 { return 9; }

  // --- row 10: bulk shuffle replay (element-wise + final position) ---
  rand.seed_from_value(31337);
  let e0 = rand.state();
  var group = Vec[Int].new();
  var g = 0;
  while g < 8 {
    group.push(g + 1);
    g = g + 1;
  };
  rand.shuffle(&mut group);
  let e1 = rand.state();
  rand.set_state(e0);
  var group2 = Vec[Int].new();
  var g2 = 0;
  while g2 < 8 {
    group2.push(g2 + 1);
    g2 = g2 + 1;
  };
  rand.shuffle(&mut group2);
  if group.len() != group2.len() { return 10; }
  var m = 0;
  while m < group.len() {
    if group[m] != group2[m] { return 10; }
    m = m + 1;
  };
  let e2 = rand.state();
  if e2 != e1 { return 10; }

  // --- row 11: CSPRNG draws leave the global stream untouched ---
  rand.seed_from_value(4242);
  let h0 = rand.state();
  let cb = rand.random_bytes_crypto(8);
  if cb.len() != 8 { return 11; }
  let h1 = rand.state();
  if h1 != h0 { return 11; }
  let hf0 = rand.random();
  rand.set_state(h0);
  let hf1 = rand.random();
  if hf0 != hf1 { return 11; }

  return 0;
}
