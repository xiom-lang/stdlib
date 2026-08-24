// kat_encoding_base32_rfc4648.xi -- RFC 4648 section 10 base32 vectors
// Standard alphabet (A-Z, 2-7, '=' pad) plus base32hex variants.
module kat_encoding_base32_rfc4648
use xiom.encoding.base32;
use xiom.io;

fn bytes_of(s: Str) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 0;
  while i < s.len() {
    v.push(s.byte_at(i));
    i += 1;
  }
  return v;
}

fn expect_str(tag: Str, got: Str, want: Str, code: Int) -> Int {
  if got != want {
    io.println("rfc4648-b32 " + tag + ": got " + got);
    return code;
  }
  return 0;
}

fn main() -> Int {
  var empty = Vec[UInt8].new();
  // ---- encode table: input -> BASE32 / BASE32HEX ----
  // ""        -> ""               / ""
  // f         -> MY======         / CO======
  // fo        -> MZXQ====         / CPNG====
  // foo       -> MZXW6===         / CPNMU===
  // foob      -> MZXW6YQ=         / CPNMUOG=
  // fooba     -> MZXW6YTB         / CPNMUOJ1
  // foobar    -> MZXW6YTBOI====== / CPNMUOJ1E8======
  var r = expect_str("empty", base32.base32_encode(&empty), "", 1);
  if r != 0 { return r; }

  r = expect_str("f", base32.base32_encode(&bytes_of("f")), "MY======", 2);
  if r != 0 { return r; }
  r = expect_str("fo", base32.base32_encode(&bytes_of("fo")), "MZXQ====", 3);
  if r != 0 { return r; }
  r = expect_str("foo", base32.base32_encode(&bytes_of("foo")), "MZXW6===", 4);
  if r != 0 { return r; }
  r = expect_str("foob", base32.base32_encode(&bytes_of("foob")), "MZXW6YQ=", 5);
  if r != 0 { return r; }
  r = expect_str("fooba", base32.base32_encode(&bytes_of("fooba")), "MZXW6YTB", 6);
  if r != 0 { return r; }
  r = expect_str("foobar", base32.base32_encode(&bytes_of("foobar")), "MZXW6YTBOI======", 7);
  if r != 0 { return r; }

  // ---- base32hex alphabet (0-9, A-V) ----
  r = expect_str("hex f", base32.base32hex_encode(&bytes_of("f")), "CO======", 8);
  if r != 0 { return r; }
  r = expect_str("hex foobar", base32.base32hex_encode(&bytes_of("foobar")), "CPNMUOJ1E8======", 9);
  if r != 0 { return r; }

  // ---- decode round-trip on the padded canonical forms ----
  var encs = ["MY======", "MZXQ====", "MZXW6===", "MZXW6YQ=", "MZXW6YTB", "MZXW6YTBOI======"];
  var wants = ["f", "fo", "foo", "foob", "fooba", "foobar"];
  var i = 0;
  while i < 6 {
    match base32.base32_decode(encs[i]) {
      Ok(out) => {
        var w = bytes_of(wants[i]);
        if out.len() != w.len() { io.println("b32 decode len at " + encs[i]); return 10; }
        var j = 0;
        while j < w.len() {
          if out[j] != w[j] { io.println("b32 decode byte at " + encs[i]); return 11; }
          j += 1;
        }
      },
      Err(e) => { io.println("b32 decode failed for " + encs[i] + ": " + e); return 12; },
    }
    i += 1;
  }

  io.println("kat_encoding_base32_rfc4648 OK");
  return 0;
}
