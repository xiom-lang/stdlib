// p_puny_parity.xi -- dedup parity probe: xiom.convert.punycode vs the
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
// canonical xiom.encoding.punycode / xiom.encoding.idna on the shared
// surface. Prints Ok/Err values side by side; used to decide whether the
// convert side can become a delegating shim.
module p_puny_parity
use xiom.convert.punycode as cvt;
use xiom.encoding.punycode as enc;
use xiom.encoding.idna as eidna;
use xiom.convert;
use xiom.io;

fn show(r: Result[Str, Str]) -> Str {
  match r {
    Ok(v) => { return "Ok:" + v; },
    Err(e) => { return "Err:" + e; },
  }
}

fn cmp(tag: Str, a: Str, b: Str) -> Int {
  if a == b {
    io.println(tag + " == " + a);
    return 0;
  };
  io.println(tag + " DIFF cvt=[" + a + "] enc=[" + b + "]");
  1;
}

fn main() -> Int {
  var bad = 0;
  bad = bad + cmp("enc(empty)", show(cvt.punycode_encode("")), show(enc.punycode_encode("")));
  bad = bad + cmp("enc(a)", show(cvt.punycode_encode("a")), show(enc.punycode_encode("a")));
  bad = bad + cmp("enc(bucher)", show(cvt.punycode_encode("bucher")), show(enc.punycode_encode("bucher")));
  bad = bad + cmp("enc(u-umlaut)", show(cvt.punycode_encode("b\u{00FC}cher")), show(enc.punycode_encode("b\u{00FC}cher")));
  bad = bad + cmp("enc(sharp-s)", show(cvt.punycode_encode("ma\u{00DF}")), show(enc.punycode_encode("ma\u{00DF}")));
  bad = bad + cmp("enc(cjk)", show(cvt.punycode_encode("\u{4ED6}\u{4EEC}")), show(enc.punycode_encode("\u{4ED6}\u{4EEC}")));

  bad = bad + cmp("dec(xn--bcher-kva)", show(cvt.punycode_decode("xn--bcher-kva")), show(enc.punycode_decode("xn--bcher-kva")));
  bad = bad + cmp("dec(xn--mnchen-3ya)", show(cvt.punycode_decode("xn--mnchen-3ya")), show(enc.punycode_decode("xn--mnchen-3ya")));
  bad = bad + cmp("dec(bad)", show(cvt.punycode_decode("!!!")), show(enc.punycode_decode("!!!")));
  bad = bad + cmp("dec(empty)", show(cvt.punycode_decode("")), show(enc.punycode_decode("")));

  bad = bad + cmp("dom-enc(munchen.de)", show(cvt.punycode_encode_domain("munchen.de")), show(enc.punycode_encode_domain("munchen.de")));
  bad = bad + cmp("dom-enc(u-umlaut)", show(cvt.punycode_encode_domain("m\u{00FC}nchen.de")), show(enc.punycode_encode_domain("m\u{00FC}nchen.de")));
  bad = bad + cmp("dom-dec(xn--mnchen-3ya.de)", show(cvt.punycode_decode_domain("xn--mnchen-3ya.de")), show(enc.punycode_decode_domain("xn--mnchen-3ya.de")));

  bad = bad + cmp("idna-to-ascii", show(cvt.idna_to_ascii("m\u{00FC}nchen.de")), show(eidna.idna_to_ascii("m\u{00FC}nchen.de")));
  bad = bad + cmp("idna-to-unicode", show(cvt.idna_to_unicode("xn--mnchen-3ya.de")), show(eidna.idna_to_unicode("xn--mnchen-3ya.de")));
  bad = bad + cmp("idna-uts46", show(cvt.idna_uts46_normalize("M\u{00DC}NCHEN.DE")), show(eidna.idna_uts46_normalize("M\u{00DC}NCHEN.DE")));
  if cvt.idna_is_valid("m\u{00FC}nchen.de") != eidna.idna_is_valid("m\u{00FC}nchen.de") {
    io.println("idna-is-valid DIFF");
    bad = bad + 1;
  } else {
    io.println("idna-is-valid == true");
  };

  io.println("P_PUNY_PARITY mismatches=" + convert.int_to_string(bad));
  io.flush_stdout();
  if bad > 0 { return 1; };
  0
}
