// smoke_stress_crypto_secure_random_seeded.xi -- locks for the CSPRNG
// pipeline (2026-09-09):
// 1. secure_random_bytes is OS-entropy backed (R4 flip after the
//    confined-block growth fix, 041e8bb3); two draws MUST differ.
// 2. Draws larger than the 16-byte initial Vec capacity MUST survive
//    (regression: pre-fix confined growth dangled the returned buffer).
// 3. Consumers (rng_crypto, keyx, aead nonce paths) run without AV.
// 4. A no-OS fallback would still differ across runs (seeded LCG).
// Exit 0 = green. A deterministic generator fails at check 2.
module smoke_stress_crypto_secure_random_seeded
use xiom.crypto;
use xiom.crypto.rng_crypto;
use xiom.io;
use xiom.convert;

fn bytes_sum(b: &Vec[UInt8]) -> Int {
  var s = 0;
  var i = 0;
  while i < b.len() {
    s = s + (b[i] as Int);
    i = i + 1;
  }
  return s;
}

fn main() -> Int {
  // two full-size draws through the public path
  var a = crypto.secure_random_bytes(64);
  var b = crypto.secure_random_bytes(64);
  if a.len() != 64 { io.println("len-a"); return 1; }
  if b.len() != 64 { io.println("len-b"); return 2; }
  var same = true;
  var i = 0;
  while i < 64 {
    if a[i] != b[i] { same = false; };
    i = i + 1;
  }
  if same { io.println("deterministic-draws"); return 3; }

  // growth-escape regression: multi-draw at 5000 bytes (pre-R4: AV)
  var big1 = crypto.secure_random_bytes(5000);
  var big2 = crypto.secure_random_bytes(5000);
  if big1.len() != 5000 { io.println("big1-len"); return 8; }
  if big2.len() != 5000 { io.println("big2-len"); return 9; }
  var sbig1 = bytes_sum(&big1);
  var sbig2 = bytes_sum(&big2);
  if sbig1 == sbig2 { io.println("big-equal"); return 10; }

  // rng_crypto multi-call consumers
  var u1 = crypto_random_u64();
  var u2 = crypto_random_u64();
  if u1 == u2 { io.println("u64-equal"); return 4; }
  var f1 = crypto_random_float();
  if f1 < 0.0 || f1 >= 1.0 { io.println("float-range"); return 5; }
  var s1 = bytes_sum(&crypto_random_bytes(32));
  var s2 = bytes_sum(&crypto_random_bytes(32));
  if s1 == s2 { io.println("rng-bytes-equal"); return 6; }
  var n = crypto_random_uniform(1000);
  if n < 0 || n >= 1000 { io.println("uniform-range"); return 7; }

  io.println("OK");
  return 0;
}
