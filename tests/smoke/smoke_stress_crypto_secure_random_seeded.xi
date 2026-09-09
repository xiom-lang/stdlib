// smoke_stress_crypto_secure_random_seeded.xi -- lock for the interim
// OS-entropy process seeding of the legacy RNG (2026-09-09).
// 1. Two secure_random_bytes draws in the same process must DIFFER
//    (regression: fixed seed 12345 made every run byte-identical).
// 2. Consumers (rng_crypto, keyx, aead nonce paths) must run without AV.
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
