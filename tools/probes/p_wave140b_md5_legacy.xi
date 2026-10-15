// p_wave140b_md5_legacy.xi -- wave 140 lock: the deprecated legacy module
// xiom.crypto.md5 (Vec[Int] API, use xiom.crypto.md5;) must also be
// RFC-correct. Pre-wave its round helper rotated RIGHT (MD5 needs LEFT)
// and shifted an unmasked 64-bit accumulation, so legacy digests were
// wrong too. Returns 0 when every digest matches.

module p_wave140b_md5_legacy

use xiom.string;
use xiom.crypto.md5;

fn to_ints(s: Str) -> Vec[Int] {
  var v: Vec[Int] = Vec[Int].new();
  var i: Int = 0;
  while i < string.str_len(s) {
    v.push(string.byte_at(s, i) as Int);
    i = i + 1;
  };
  v
}

fn main() -> Int {
  if md5.md5_hex(&to_ints("a")) != "0cc175b9c0f1b6a831c399e269772661" { return 1; }
  if md5.md5_hex(&to_ints("abc")) != "900150983cd24fb0d6963f7d28e17f72" { return 2; }
  if md5.md5_hex(&to_ints("hello world")) != "5eb63bbbe01eeed093cb22bb8f5acdc3" { return 3; }
  if md5.md5_hex(&to_ints("The quick brown fox jumps over the lazy dog")) != "9e107d9d372bb6826bd81d3542a419d6" { return 4; }
  return 0
}
