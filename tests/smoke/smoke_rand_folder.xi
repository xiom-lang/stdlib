// XIOM — Smoke test for the stdlib/xiom/rand/ folder modules:
// mt19937 (Mersenne Twister), pcg (PCG-XSH-RR), chacha (ChaCha20 RNG).
module smoke_rand_folder
use xiom.rand.mt19937;
use xiom.rand.pcg;
use xiom.rand.chacha;

fn _u32i(x: UInt32) -> Int {
  return (x as Int) & 0xFFFFFFFF;
}

fn main() -> Int {
  // ── mt19937 ──────────────────────────────────────────────────────────────
  // Known vectors: default seed 5489 -> 0xD091BB5C (3499211612);
  // seed 0 -> 0x8C7F0AAC (2357136044).
  var mt1 = mt19937.mt19937_new();
  let v1 = mt19937.mt19937_next_u32(&mut mt1);
  if _u32i(v1) != 3499211612 { return 1; }

  var mt0 = mt19937.mt19937_from_seed(0 as UInt32);
  let v0 = mt19937.mt19937_next_u32(&mut mt0);
  if _u32i(v0) != 2357136044 { return 2; }

  var mt = mt19937.mt19937_new();
  var i: Int = 0;
  while i < 10 {
    let d = mt19937.mt19937_next_u32(&mut mt);
    let di = _u32i(d);
    if di < 0 || di >= 4294967296 { return 3; }
    i = i + 1;
  }
  let mf = mt19937.mt19937_next_float(&mut mt);
  if mf < 0.0 || mf >= 1.0 { return 4; }
  let mb = mt19937.mt19937_next_bounded(&mut mt, 10);
  if mb < 0 || mb >= 10 { return 5; }
  let mi = mt19937.mt19937_next_int(&mut mt);
  if mi < 0 || mi >= 4294967296 { return 6; }

  // reseed must reproduce from_seed
  var mt3 = mt19937.mt19937_from_seed(12345 as UInt32);
  var mt4 = mt19937.mt19937_new();
  mt19937.mt19937_reseed(&mut mt4, 12345 as UInt32);
  var j: Int = 0;
  while j < 5 {
    let a = mt19937.mt19937_next_u32(&mut mt3);
    let b = mt19937.mt19937_next_u32(&mut mt4);
    if _u32i(a) != _u32i(b) { return 7; }
    j = j + 1;
  }

  // ── pcg ──────────────────────────────────────────────────────────────────
  // Same seed must give an identical 5-value sequence.
  var p1 = pcg.pcg_from_seed(0x1234567890 as UInt64);
  var p2 = pcg.pcg_from_seed(0x1234567890 as UInt64);
  var pa = Vec[Int].new();
  j = 0;
  while j < 5 {
    pa.push(_u32i(pcg.pcg_next_u32(&mut p1)));
    j = j + 1;
  }
  j = 0;
  while j < 5 {
    let x = _u32i(pcg.pcg_next_u32(&mut p2));
    if x != pa[j] { return 8; }
    j = j + 1;
  }
  // Different seeds must give a different first value.
  var q1 = pcg.pcg_from_seed(0x1FEDCBA987654321 as UInt64);
  let qv = _u32i(pcg.pcg_next_u32(&mut q1));
  if qv == pa[0] { return 9; }
  let pf = pcg.pcg_next_float(&mut p2);
  if pf < 0.0 || pf >= 1.0 { return 10; }
  let pb = pcg.pcg_next_bounded(&mut p2, 7);
  if pb < 0 || pb >= 7 { return 11; }
  let pi = pcg.pcg_next_int(&mut p2);
  if pi < 0 || pi >= 4294967296 { return 12; }

  // ── chacha ───────────────────────────────────────────────────────────────
  // Known vector: all-zero key/nonce/counter 0 block starts with 0xADE0B876.
  var c1 = chacha.chacha_rng_new();
  let cw = chacha.chacha_rng_next_u32(&mut c1);
  if _u32i(cw) != 2917185654 { return 13; }

  // Same seed must give an identical 5-value sequence.
  var c2 = chacha.chacha_rng_from_seed(0x0D1CE2B3A4B5C6D7 as UInt64);
  var c3 = chacha.chacha_rng_from_seed(0x0D1CE2B3A4B5C6D7 as UInt64);
  var ca = Vec[Int].new();
  j = 0;
  while j < 5 {
    ca.push(_u32i(chacha.chacha_rng_next_u32(&mut c2)));
    j = j + 1;
  }
  j = 0;
  while j < 5 {
    let x = _u32i(chacha.chacha_rng_next_u32(&mut c3));
    if x != ca[j] { return 14; }
    j = j + 1;
  }
  // Different seeds must give a different first value.
  var c4 = chacha.chacha_rng_from_seed(0x0E5C0FFEE5E6F7F8 as UInt64);
  let cv = _u32i(chacha.chacha_rng_next_u32(&mut c4));
  if cv == ca[0] { return 15; }

  // 200 draws: all < 2^32 and not all equal.
  var c5 = chacha.chacha_rng_from_seed(0x0D1CE2B3A4B5C6D7 as UInt64);
  var not_all_equal: Bool = false;
  var prev: Int = -1;
  j = 0;
  while j < 200 {
    let x = _u32i(chacha.chacha_rng_next_u32(&mut c5));
    if x < 0 || x >= 4294967296 { return 16; }
    if prev != -1 && x != prev { not_all_equal = true; }
    prev = x;
    j = j + 1;
  }
  if !not_all_equal { return 17; }
  let cf = chacha.chacha_rng_next_float(&mut c5);
  if cf < 0.0 || cf >= 1.0 { return 18; }
  let cb = chacha.chacha_rng_next_bounded(&mut c5, 11);
  if cb < 0 || cb >= 11 { return 19; }
  let ci = chacha.chacha_rng_next_int(&mut c5);
  if ci < 0 || ci >= 4294967296 { return 20; }

  return 0;
}
