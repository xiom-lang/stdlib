// kat_crypto_sha2.xi -- NIST CAVP / FIPS 180-4 known-answer tests
// Vectors: SHA-224/256/384/512 over "", "abc", and the 448-bit message.
// Source: NIST CSRC example hashes (FIPS 180-4 appendix B / CAVP SHS).
// Exit 0 = all digests match; nonzero + tag = first mismatch.
module kat_crypto_sha2
use xiom.crypto;
use xiom.io;
use xiom.encoding.hex;

fn bytes_of(s: Str) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 0;
  while i < s.len() {
    v.push(s.byte_at(i));
    i += 1;
  }
  return v;
}

fn main() -> Int {
  // ---- SHA-256 ----
  var empty = Vec[UInt8].new();
  var h = crypto.sha256_hex(&empty);
  if h != "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" {
    io.println("sha256(empty): " + h);
    return 1;
  }

  var abc = bytes_of("abc");
  h = crypto.sha256_hex(&abc);
  if h != "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad" {
    io.println("sha256(abc): " + h);
    return 2;
  }

  var m448 = bytes_of("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq");
  h = crypto.sha256_hex(&m448);
  if h != "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1" {
    io.println("sha256(448bit): " + h);
    return 3;
  }

  // ---- SHA-224 ----
  var h224 = crypto.sha224(&abc);
  if hex.hex_encode(&h224) != "23097d223405d8228642a477bda255b32aadbce4bda0b3f7e36c9da7" {
    io.println("sha224(abc): " + hex.hex_encode(&h224));
    return 4;
  }

  // ---- SHA-512 ----
  var h512 = crypto.sha512(&empty);
  if hex.hex_encode(&h512) != "cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e" {
    io.println("sha512(empty): " + hex.hex_encode(&h512));
    return 5;
  }

  h512 = crypto.sha512(&abc);
  if hex.hex_encode(&h512) != "ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f" {
    io.println("sha512(abc): " + hex.hex_encode(&h512));
    return 6;
  }

  // ---- SHA-384 ----
  var h384 = crypto.sha384(&abc);
  if hex.hex_encode(&h384) != "cb00753f45a35e8bb5a03d699ac65007272c32ab0eded1631a8b605a43ff5bed8086072ba1e7cc2358baeca134c825a7" {
    io.println("sha384(abc): " + hex.hex_encode(&h384));
    return 7;
  }

  // Digest length invariants
  if crypto.sha256(&m448).len() != 32 { io.println("sha256 len"); return 8; }
  if crypto.sha512(&m448).len() != 64 { io.println("sha512 len"); return 9; }

  io.println("kat_crypto_sha2 OK");
  return 0;
}
