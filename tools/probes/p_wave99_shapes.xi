// p_wave99_shapes.xi -- wave 99 shape validation: crypto hash + xxhash/city + constants
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-99 clause guards:
//   (a) xiom.crypto.hash: the exact digest/hex sizes (sha256/sha512/md5,
//       hmac variants), pbkdf2/hkdf degenerate -> empty and derived ->
//       requested-length claims;
//   (b) xiom.crypto flat wrappers: sha256/sha256_hex/blake3 sizes;
//   (c) xiom.hash.xxhash: the empty-input pins for xxh64/xxh32/xxh3_64/
//       xxh3_128 (seed 0) against the standard constants;
//   (d) xiom.hash.city: city64 empty pin and city128 pair length;
//   (e) xiom.math.constants: infinity/neg_infinity range pins and the
//       NaN self-inequality pin.
// Values returned from the module surface are bound before comparing.
// Returns 0 when every case holds.

module p_wave99_shapes

use xiom.crypto as crypto;
use xiom.crypto.hash as chash;
use xiom.hash.xxhash as xxh;
use xiom.hash.city as city;
use xiom.math.constants as mc;

fn main() -> Int {
  // ---- crypto.hash: digest sizes
  var eb = Vec[UInt8].new();
  let s256 = chash.crypto_hash_sha256(&eb);
  if s256.len() != 32 { return 1; }
  let s512 = chash.crypto_hash_sha512(&eb);
  if s512.len() != 64 { return 2; }
  let md5d = chash.crypto_hash_md5(&eb);
  if md5d.len() != 16 { return 3; }
  let h256 = chash.crypto_hash_sha256_hex(&eb);
  if h256.len() != 64 { return 4; }
  let h512 = chash.crypto_hash_sha512_hex(&eb);
  if h512.len() != 128 { return 5; }

  // ---- crypto.hash: hmac sizes
  let hm1 = chash.crypto_hash_hmac_sha256(&eb, &eb);
  if hm1.len() != 32 { return 6; }
  let hm2 = chash.crypto_hash_hmac_sha512(&eb, &eb);
  if hm2.len() != 64 { return 7; }
  let hm3 = chash.crypto_hash_hmac_md5(&eb, &eb);
  if hm3.len() != 16 { return 8; }

  // ---- crypto.hash: pbkdf2 / hkdf
  let pb0 = chash.crypto_hash_pbkdf2_sha256(&eb, &eb, 0, 8);
  if pb0.len() != 0 { return 9; }
  let pb1 = chash.crypto_hash_pbkdf2_sha256(&eb, &eb, 1, 8);
  if pb1.len() != 8 { return 10; }
  let hk0 = chash.crypto_hash_hkdf(&eb, &eb, &eb, 0);
  if hk0.len() != 0 { return 11; }
  let hk1 = chash.crypto_hash_hkdf(&eb, &eb, &eb, 16);
  if hk1.len() != 16 { return 12; }

  // ---- crypto flat wrappers
  let fs256 = crypto.sha256(&eb);
  if fs256.len() != 32 { return 13; }
  let fshex = crypto.sha256_hex(&eb);
  if fshex.len() != 64 { return 14; }
  let b3 = crypto.blake3(&eb);
  if b3.len() != 32 { return 15; }

  // ---- xxhash: empty-input standard pins
  let x64 = xxh.xxh64(&eb, 0);
  if x64 != 0xEF46DB3751D8E999 { return 16; }
  let x32 = xxh.xxh32(&eb, 0);
  if x32 != 0x02CC5D05 { return 17; }
  let x3a = xxh.xxh3_64(&eb);
  if x3a != 0x2D06800538D394C2 { return 18; }
  let x3b = xxh.xxh3_64_with_seed(&eb, 0);
  if x3b != 0x2D06800538D394C2 { return 19; }
  let x128a = xxh.xxh3_128(&eb);
  if x128a.low64 != 0x6001C324468D497F { return 20; }
  if x128a.high64 != 0x99AA06D3014798D8 { return 21; }
  let x128b = xxh.xxh3_128_with_seed(&eb, 0);
  if x128b.low64 != 0x6001C324468D497F { return 22; }
  if x128b.high64 != 0x99AA06D3014798D8 { return 23; }

  // ---- city: empty pins / pair length
  let c64 = city.city64(&eb);
  if c64 != 0x9AE16A3B2F90404F { return 24; }
  let c128 = city.city128(&eb);
  if c128.len() != 2 { return 25; }

  // ---- math constants
  let inf = mc.infinity();
  if inf <= 1.0 { return 26; }
  let ninf = mc.neg_infinity();
  if ninf >= -1.0 { return 27; }
  let nn = mc.nan();
  if nn == nn { return 28; }

  return 0;
}
