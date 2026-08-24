// kat_convert_base64_parity.xi -- RFC 4648 section 10 through the
// xiom.convert.base64 twin (4-fn surface: encode/decode/encode_str/decode_str).
// Exists because the convert/encoding twins diverged once already (audit 5.1):
// this file pins the twin to the same RFC table as kat_encoding_base64_rfc4648.
module kat_convert_base64_parity
use xiom.convert.base64;
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
    io.println("parity " + tag + ": got " + got);
    return code;
  }
  return 0;
}

fn main() -> Int {
  var empty = Vec[UInt8].new();
  var r = expect_str("enc empty", base64.base64_encode(&empty), "", 1);
  if r != 0 { return r; }

  r = expect_str("enc f", base64.base64_encode(&bytes_of("f")), "Zg==", 2);
  if r != 0 { return r; }
  r = expect_str("enc fo", base64.base64_encode(&bytes_of("fo")), "Zm8=", 3);
  if r != 0 { return r; }
  r = expect_str("enc foo", base64.base64_encode(&bytes_of("foo")), "Zm9v", 4);
  if r != 0 { return r; }
  r = expect_str("enc foob", base64.base64_encode(&bytes_of("foob")), "Zm9vYg==", 5);
  if r != 0 { return r; }
  r = expect_str("enc fooba", base64.base64_encode(&bytes_of("fooba")), "Zm9vYmE=", 6);
  if r != 0 { return r; }
  r = expect_str("enc foobar", base64.base64_encode(&bytes_of("foobar")), "Zm9vYmFy", 7);
  if r != 0 { return r; }

  // str-typed variants must agree with byte-typed ones
  r = expect_str("enc_str foobar", base64.base64_encode_str("foobar"), "Zm9vYmFy", 8);
  if r != 0 { return r; }

  // decode side
  match base64.base64_decode("Zm9vYmFy") {
    Ok(out) => {
      var w = bytes_of("foobar");
      if out.len() != w.len() { io.println("decode len"); return 9; }
      var j = 0;
      while j < w.len() {
        if out[j] != w[j] { io.println("decode byte"); return 10; }
        j += 1;
      }
    },
    Err(e) => { io.println("decode failed: " + e); return 11; },
  }

  match base64.base64_decode_str("Zg==") {
    Ok(s) => {
      if s != "f" { io.println("decode_str got " + s); return 12; }
    },
    Err(e) => { io.println("decode_str failed: " + e); return 13; },
  }

  io.println("kat_convert_base64_parity OK");
  return 0;
}
