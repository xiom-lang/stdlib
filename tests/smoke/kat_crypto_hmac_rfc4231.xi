// kat_crypto_hmac_rfc4231.xi -- RFC 4231 HMAC-SHA-256/512 known-answer tests
// Test cases 1, 2, 3, 6, 7 (SHA-256) and case 1 (SHA-512), verbatim from the RFC.
module kat_crypto_hmac_rfc4231
use xiom.crypto;
use xiom.crypto.mac;
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

fn repeat_byte(b: Int, n: Int) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 0;
  while i < n {
    v.push(b as UInt8);
    i += 1;
  }
  return v;
}

fn check(tag: Str, got: Vec[UInt8], want: Str, code: Int) -> Int {
  var actual = hex.hex_encode(&got);
  if actual != want {
    io.println("rfc4231 " + tag + ": " + actual);
    return code;
  }
  return 0;
}

fn main() -> Int {
  // ---- TC1: key = 0x0b x20, data = "Hi There" ----
  var k1 = repeat_byte(0x0b, 20);
  var d1 = bytes_of("Hi There");
  var r = check("tc1", crypto.hmac_sha256(&k1, &d1),
    "b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7", 1);
  if r != 0 { return r; }

  // ---- TC2: key = "Jefe", data = "what do ya want for nothing?" ----
  var k2 = bytes_of("Jefe");
  var d2 = bytes_of("what do ya want for nothing?");
  r = check("tc2", crypto.hmac_sha256(&k2, &d2),
    "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843", 2);
  if r != 0 { return r; }

  // ---- TC3: key = 0xaa x20, data = 0xdd x50 ----
  var k3 = repeat_byte(0xaa, 20);
  var d3 = repeat_byte(0xdd, 50);
  r = check("tc3", crypto.hmac_sha256(&k3, &d3),
    "773ea91e36800e46854db8ebd09181a72959098b3ef8c122d9635514ced565fe", 3);
  if r != 0 { return r; }

  // ---- TC6: key = 0xaa x131 (> block size), data = hash-key-first vector ----
  var k6 = repeat_byte(0xaa, 131);
  var d6 = bytes_of("Test Using Larger Than Block-Size Key - Hash Key First");
  r = check("tc6", crypto.hmac_sha256(&k6, &d6),
    "60e431591ee0b67f0d8a26aacbf5b77f8e0bc6213728c5140546040f0ee37f54", 6);
  if r != 0 { return r; }

  // ---- TC7: key = 0xaa x131, data larger than block size ----
  var d7 = bytes_of("This is a test using a larger than block-size key and a larger than block-size data. The key needs to be hashed before being used by the HMAC algorithm.");
  r = check("tc7", crypto.hmac_sha256(&k6, &d7),
    "9b09ffa71b942fcb27635fbcd5b0e944bfdc63644f0713938a7f51535c3a35e2", 7);
  if r != 0 { return r; }

  // ---- SHA-512 TC1 (facade lacks hmac_sha512; use xiom.crypto.mac) ----
  var h512 = mac.hmac_sha512(&k1, &d1);
  r = check("tc1-512", h512,
    "87aa7cdea5ef619d4ff0b4241a1d6cb02379f4e2ce4ec2787ad0b30545e17cdedaa833b7d6b8a702038b274eaea3f4e4be9d914eeb61f1702e696c203a126854", 8);
  if r != 0 { return r; }

  // ---- constant-time compare positive/negative on a real tag ----
  var good = crypto.hmac_sha256(&k2, &d2);
  if !crypto.constant_time_compare(&good, &good) {
    io.println("ct compare self failed");
    return 9;
  }
  var bad = Vec[UInt8].new();
  var bi = 0;
  while bi < good.len() {
    if bi == 0 && good[bi] == 0u8 {
      bad.push(1u8);
    } else {
      if bi == 0 { bad.push(0u8); } else { bad.push(good[bi]); }
    }
    bi += 1;
  }
  if crypto.constant_time_compare(&good, &bad) {
    io.println("ct compare accepted tampered tag");
    return 10;
  }

  io.println("kat_crypto_hmac_rfc4231 OK");
  return 0;
}
