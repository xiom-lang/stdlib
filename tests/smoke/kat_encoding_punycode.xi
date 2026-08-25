// kat_encoding_punycode.xi -- RFC 3492 section 7.1-style known-answer tests
// Expected values generated and cross-checked with python's built-in
// punycode codec (RFC 3492 reference behavior). Covers pure-ASCII inputs
// (delimiter-only output), mixed case preservation, sharp-s, CJK, and
// decode round-trips.
module kat_encoding_punycode
use xiom.encoding.punycode;
use xiom.io;

fn case_enc(src: Str, want: Str, code: Int) -> Int {
  match punycode_encode(src) {
    Ok(got) => {
      if got != want {
        io.println("puny enc mismatch: " + got);
        return code;
      }
      return 0;
    }
    Err(e) => { io.println("puny enc err: " + e); return code; }
  }
}

fn case_roundtrip(src: Str, code: Int) -> Int {
  match punycode_encode(src) {
    Ok(pc) => {
      match punycode_decode(pc) {
        Ok(back) => {
          if back != src {
            io.println("puny rt mismatch");
            return code;
          }
          return 0;
        }
        Err(e) => { io.println("puny dec err: " + e); return code; }
      }
    }
    Err(e) => { io.println("puny enc err: " + e); return code; }
  }
}

fn main() -> Int {
  var r = case_enc("", "", 1);
  if r != 0 { return r; }

  r = case_enc("a", "a-", 2);
  if r != 0 { return r; }

  // case distinction is preserved by the basic-code-point pass-through
  r = case_enc("A", "A-", 3);
  if r != 0 { return r; }

  r = case_enc("abc", "abc-", 4);
  if r != 0 { return r; }

  // sharp-s expands to 'ss' in the basic portion
  r = case_enc("ma\u{df}", "ma-hia", 5);
  if r != 0 { return r; }

  // CJK sentence from RFC 3492 section 7.1 (Chinese simplified)
  r = case_enc("\u{4ed6}\u{4eec}\u{4e3a}\u{4ec0}\u{4e48}\u{4e0d}\u{8bf4}\u{4e2d}\u{6587}", "ihqwcrb4cv8a8dqg056pqjye", 6);
  if r != 0 { return r; }

  // pure ASCII keeps its literal form plus the delimiter
  r = case_enc("Hello-World", "Hello-World-", 7);
  if r != 0 { return r; }

  r = case_enc("\u{fc}", "tda", 8);
  if r != 0 { return r; }

  // ---- decode round-trips ----
  r = case_roundtrip("ma\u{df}", 20);
  if r != 0 { return r; }
  r = case_roundtrip("\u{4ed6}\u{4eec}\u{4e3a}\u{4ec0}\u{4e48}\u{4e0d}\u{8bf4}\u{4e2d}\u{6587}", 21);
  if r != 0 { return r; }
  r = case_roundtrip("\u{fc}", 22);
  if r != 0 { return r; }

  io.println("OK");
  return 0;
}
