// smoke_convert_punycode.xi -- convention lock for xiom.convert.punycode.
//
// AUDIT (dedup wave, 2026-09-16): convert.punycode is NOT a blind twin of
// xiom.encoding.punycode -- both share the module leaf and fn names, but the
// APIs differ:
//   * convert.punycode_encode returns the full ACE label ("xn--bcher-kva",
//     ASCII input passes through unchanged); encoding.punycode_encode
//     returns the RFC 3492 RAW payload ("bcher-kva") and is KAT-locked by
//     kat_encoding_punycode.
//   * convert.punycode_decode expects the ACE label and does not validate
//     non-prefixed input (returns it unchanged); encoding rejects invalid
//     digits.
//   * convert.idna_to_ascii applies the prefix; encoding.idna's convention
//     differs (probe p_puny_parity documents the side-by-side results:
//     cvt=[Ok:xn--mnchen-3ya.de] enc=[Ok:xn--xn--mnchen-3ya.de]).
// Consolidation would change one side's public semantics, so both stay;
// THIS smoke pins the convert-side convention against vectors.

module smoke_convert_punycode
use xiom.convert.punycode;
use xiom.io;

fn show(r: Result[Str, Str]) -> Str {
  match r {
    Ok(v) => { return "Ok:" + v; },
    Err(e) => { return "Err:" + e; },
  }
}

fn expect(tag: Str, got: Str, want: Str, code: Int) -> Int {
  if got != want {
    io.println("convert-puny " + tag + ": got " + got);
    return code;
  };
  0
}

fn main() -> Int {
  var r = 0;
  r = expect("enc-empty", show(punycode.punycode_encode("")), "Ok:", 1);
  if r != 0 { return r; };
  r = expect("enc-ascii", show(punycode.punycode_encode("bucher")), "Ok:bucher", 2);
  if r != 0 { return r; };
  r = expect("enc-umlaut", show(punycode.punycode_encode("b\u{00FC}cher")), "Ok:xn--bcher-kva", 3);
  if r != 0 { return r; };
  r = expect("enc-sharps", show(punycode.punycode_encode("ma\u{00DF}")), "Ok:xn--ma-hia", 4);
  if r != 0 { return r; };
  r = expect("enc-cjk", show(punycode.punycode_encode("\u{4ED6}\u{4EEC}")), "Ok:xn--8mqxb", 5);
  if r != 0 { return r; };

  r = expect("dec-empty", show(punycode.punycode_decode("")), "Ok:", 6);
  if r != 0 { return r; };
  r = expect("dec-passthrough", show(punycode.punycode_decode("!!!")), "Ok:!!!", 7);
  if r != 0 { return r; };

  var pd = punycode.punycode_decode("xn--bcher-kva");
  match pd {
    Ok(dv) => {
      if dv.len() != 7 { io.println("convert-puny dec len"); return 8; };
      if dv.byte_at(0) != 98 { return 9; };   // 'b'
      if dv.byte_at(3) != 99 { return 9; };   // 'c'
      if dv.byte_at(6) != 114 { return 9; };  // 'r'
    },
    Err(_) => { io.println("convert-puny dec err"); return 10; },
  };

  r = expect("dom-enc-ascii", show(punycode.punycode_encode_domain("munchen.de")), "Ok:munchen.de", 11);
  if r != 0 { return r; };
  r = expect("dom-enc-umlaut", show(punycode.punycode_encode_domain("m\u{00FC}nchen.de")), "Ok:xn--mnchen-3ya.de", 12);
  if r != 0 { return r; };
  r = expect("dom-dec", show(punycode.punycode_decode_domain("xn--mnchen-3ya.de")), "Ok:m\u{00FC}nchen.de", 13);
  if r != 0 { return r; };

  r = expect("idna-ascii", show(punycode.idna_to_ascii("m\u{00FC}nchen.de")), "Ok:xn--mnchen-3ya.de", 14);
  if r != 0 { return r; };
  r = expect("idna-unicode", show(punycode.idna_to_unicode("xn--mnchen-3ya.de")), "Ok:m\u{00FC}nchen.de", 15);
  if r != 0 { return r; };
  r = expect("idna-uts46", show(punycode.idna_uts46_normalize("M\u{00DC}NCHEN.DE")), "Ok:m\u{00DC}nchen.de", 16);
  if r != 0 { return r; };
  // idna_is_valid validates the ASCII/ACE form of a domain, not the Unicode
  // form (pinned by p_idna_valid): unicode=false, ace=true, ascii=true.
  if !punycode.idna_is_valid("xn--mnchen-3ya.de") { io.println("convert-puny valid ace"); return 17; };
  if punycode.idna_is_valid("m\u{00FC}nchen.de") { io.println("convert-puny valid unicode"); return 18; };
  if !punycode.idna_is_valid("munchen.de") { io.println("convert-puny valid ascii"); return 19; };

  io.println("smoke_convert_punycode OK");
  return 0;
}
