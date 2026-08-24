// kat_encoding_base64_rfc4648.xi -- RFC 4648 section 10 test vectors
// Covers standard alphabet (padded/unpadded) and URL-safe alphabet.
// NOTE: the xiom.convert.base64 twin gets its own file
// (kat_convert_base64_parity.xi) -- importing both twins in one module risks
// the same-name collision family documented in the audit.
module kat_encoding_base64_rfc4648
use xiom.encoding.base64;
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
    io.println("rfc4648 " + tag + ": got " + got);
    return code;
  }
  return 0;
}

fn main() -> Int {
  // ---- RFC 4648 section 10 encode table (standard alphabet, padded) ----
  var empty = Vec[UInt8].new();
  var r = expect_str("enc empty", base64.base64_encode(&empty), "", 1);
  if r != 0 { return r; }

  r = expect_str("enc f", base64.base64_encode_padded(&bytes_of("f")), "Zg==", 2);
  if r != 0 { return r; }
  r = expect_str("enc fo", base64.base64_encode_padded(&bytes_of("fo")), "Zm8=", 3);
  if r != 0 { return r; }
  r = expect_str("enc foo", base64.base64_encode_padded(&bytes_of("foo")), "Zm9v", 4);
  if r != 0 { return r; }
  r = expect_str("enc foob", base64.base64_encode_padded(&bytes_of("foob")), "Zm9vYg==", 5);
  if r != 0 { return r; }
  r = expect_str("enc fooba", base64.base64_encode_padded(&bytes_of("fooba")), "Zm9vYmE=", 6);
  if r != 0 { return r; }
  r = expect_str("enc foobar", base64.base64_encode_padded(&bytes_of("foobar")), "Zm9vYmFy", 7);
  if r != 0 { return r; }

  // ---- decode side: all six valid forms must round-trip ----
  var inputs = ["Zg==", "Zm8=", "Zm9v", "Zm9vYg==", "Zm9vYmE=", "Zm9vYmFy"];
  var wants = ["f", "fo", "foo", "foob", "fooba", "foobar"];
  var i = 0;
  while i < 6 {
    match base64.base64_decode_padded(inputs[i]) {
      Ok(out) => {
        var w = bytes_of(wants[i]);
        if out.len() != w.len() {
          io.println("decode len mismatch at " + inputs[i]);
          return 8;
        }
        var j = 0;
        while j < w.len() {
          if out[j] != w[j] { io.println("decode byte mismatch at " + inputs[i]); return 9; }
          j += 1;
        }
      },
      Err(e) => { io.println("decode failed for " + inputs[i] + ": " + e); return 10; },
    }
    i += 1;
  }

  // ---- default encode form is PADDED in this module ("foob" -> "Zm9vYg==")
  var def = base64.base64_encode(&bytes_of("foob"));
  if def != "Zm9vYg==" { io.println("default enc: " + def); return 11; }

  // ---- URL-safe alphabet: bytes {251,239} -> sextets 62,62,60 -> "--8"
  // (hand-derived from RFC 4648 §5 alphabet; module is unpadded by design)
  var urlb = Vec[UInt8].new();
  urlb.push(251u8);
  urlb.push(239u8);
  var u = base64.base64url_encode(&urlb);
  if u != "--8" {
    io.println("url alphabet unexpected: " + u);
    return 12;
  }

  io.println("kat_encoding_base64_rfc4648 OK");
  return 0;
}
