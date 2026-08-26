// kat_crypto_sha_multiblock.xi -- SHA-256/512 block-boundary known answers
// Vectors computed with python hashlib (oracle). The 55/56 (SHA-256) and
// 111/112 (SHA-512) boundaries exercise the length-field placement where
// padding spills into a second block -- the classic off-by-one region for
// handwritten SHA implementations.
module kat_crypto_sha_multiblock
use xiom.crypto;
use xiom.io;
use xiom.encoding.hex;

fn mk_a(n: Int) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 0;
  while i < n {
    v.push(97u8);
    i += 1;
  }
  return v;
}

fn expect512(tag: Str, n: Int, want: Str, code: Int) -> Int {
  var v = mk_a(n);
  var h = crypto.sha512(&v);
  var got = hex.hex_encode(&h);
  if got != want {
    io.println("sha512 " + tag + ": " + got);
    return code;
  }
  return 0;
}

fn expect256(tag: Str, n: Int, want: Str, code: Int) -> Int {
  var v = mk_a(n);
  var h = crypto.sha256_hex(&v);
  if h != want {
    io.println("sha256 " + tag + ": " + h);
    return code;
  }
  return 0;
}

fn main() -> Int {
  // SHA-512: one block holds <= 111 bytes of message
  var r = expect512("a111", 111,
    "fa9121c7b32b9e01733d034cfc78cbf67f926c7ed83e82200ef86818196921760b4beff48404df811b953828274461673c68d04e297b0eb7b2b4d60fc6b566a2", 1);
  if r != 0 { return r; }
  r = expect512("a112", 112,
    "c01d080efd492776a1c43bd23dd99d0a2e626d481e16782e75d54c2503b5dc32bd05f0f1ba33e568b88fd2d970929b719ecbb152f58f130a407c8830604b70ca", 2);
  if r != 0 { return r; }
  r = expect512("a113", 113,
    "55ddd8ac210a6e18ba1ee055af84c966e0dbff091c43580ae1be703bdb85da31acf6948cf5bd90c55a20e5450f22fb89bd8d0085e39f85a86cc46abbca75e24d", 3);
  if r != 0 { return r; }
  r = expect512("a1000", 1000,
    "67ba5535a46e3f86dbfbed8cbbaf0125c76ed549ff8b0b9e03e0c88cf90fa634fa7b12b47d77b694de488ace8d9a65967dc96df599727d3292a8d9d447709c97", 4);
  if r != 0 { return r; }

  // SHA-256: one block holds <= 55 bytes
  r = expect256("a55", 55,
    "9f4390f8d30c2dd92ec9f095b65e2b9ae9b0a925a5258e241c9f1e910f734318", 5);
  if r != 0 { return r; }
  r = expect256("a56", 56,
    "b35439a4ac6f0948b6d6f9e3c6af0f5f590ce20f1bde7090ef7970686ec6738a", 6);
  if r != 0 { return r; }
  r = expect256("a1000", 1000,
    "41edece42d63e8d9bf515a9ba6932e1c20cbc9f5a5d134645adb5db1b9737ea3", 7);
  if r != 0 { return r; }

  io.println("OK");
  return 0;
}
