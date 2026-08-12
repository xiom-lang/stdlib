// XIOM stdlib smoke test — xiom.encoding.punycode and xiom.encoding.idna
// RFC 3492 punycode known answer, round trips, IDNA A-label conversion.
// Returns 0 on success, nonzero on failure.

module smoke_encoding_punycode
use xiom.encoding.punycode;
use xiom.encoding.idna;
use xiom.io;
use xiom.string;

fn main() -> Int {
  // RFC 3492 known answer: "bücher" -> "bcher-kva"
  var enc = punycode.punycode_encode("bücher");
  match enc {
    Ok(v) => {
      if v != "bcher-kva" { io.println("puny-bucher"); return 1; }
    },
    Err(_) => { io.println("puny-bucher-err"); return 2; },
  }
  var dec = punycode.punycode_decode("bcher-kva");
  match dec {
    Ok(v) => {
      if v != "bücher" { io.println("puny-bucher-back"); return 3; }
    },
    Err(_) => { io.println("puny-bucher-dec-err"); return 4; },
  }

  // Japanese label (no basic code points, no delimiter)
  var enc2 = punycode.punycode_encode("日本語");
  match enc2 {
    Ok(v) => {
      if v != "wgv71a119e" { io.println("puny-jp"); return 5; }
      var dec2 = punycode.punycode_decode(v);
      match dec2 {
        Ok(v2) => { if v2 != "日本語" { io.println("puny-jp-back"); return 6; } },
        Err(_) => { io.println("puny-jp-dec-err"); return 7; },
      }
    },
    Err(_) => { io.println("puny-jp-err"); return 8; },
  }

  // all-basic label: basic part followed by the delimiter
  var enc3 = punycode.punycode_encode("abc");
  match enc3 {
    Ok(v) => {
      if v != "abc-" { io.println("puny-abc"); return 9; }
      var dec3 = punycode.punycode_decode(v);
      match dec3 {
        Ok(v3) => { if v3 != "abc" { io.println("puny-abc-back"); return 10; } },
        Err(_) => { io.println("puny-abc-dec-err"); return 11; },
      }
    },
    Err(_) => { io.println("puny-abc-err"); return 12; },
  }

  // digit helpers and adapt
  if punycode.punycode_encode_digit(0) != 'a' { io.println("digit-0"); return 13; }
  if punycode.punycode_encode_digit(25) != 'z' { io.println("digit-25"); return 14; }
  if punycode.punycode_encode_digit(26) != '0' { io.println("digit-26"); return 15; }
  if punycode.punycode_decode_digit('z') != 25 { io.println("digit-z"); return 16; }
  if punycode.punycode_decode_digit('0') != 26 { io.println("digit-0-dec"); return 17; }
  if punycode.punycode_decode_digit('!') != -1 { io.println("digit-invalid"); return 18; }
  if punycode.punycode_adapt(745, 6, true) != 0 { io.println("adapt"); return 19; }

  // invalid digit -> Err
  var bad = punycode.punycode_decode("abc!");
  match bad {
    Ok(_) => { io.println("puny-bad-digit-not-err"); return 20; },
    Err(_) => {},
  }

  // full domains
  var d1 = punycode.punycode_encode_domain("münchen.example");
  match d1 {
    Ok(v) => {
      if v != "xn--mnchen-3ya.example" { io.println("puny-domain"); return 21; }
      var d2 = punycode.punycode_decode_domain(v);
      match d2 {
        Ok(v2) => { if v2 != "münchen.example" { io.println("puny-domain-back"); return 22; } },
        Err(_) => { io.println("puny-domain-dec-err"); return 23; },
      }
    },
    Err(_) => { io.println("puny-domain-err"); return 24; },
  }

  // ---- idna ----
  var ascii = idna.idna_to_ascii("münchen.example");
  match ascii {
    Ok(v) => {
      if v != "xn--mnchen-3ya.example" { io.println("idna-to-ascii"); return 25; }
    },
    Err(_) => { io.println("idna-to-ascii-err"); return 26; },
  }
  var unicode = idna.idna_to_unicode("xn--mnchen-3ya.example");
  match unicode {
    Ok(v) => {
      if v != "münchen.example" { io.println("idna-to-unicode"); return 27; }
    },
    Err(_) => { io.println("idna-to-unicode-err"); return 28; },
  }

  if !idna.idna_is_valid("example.com") { io.println("idna-valid-ok"); return 29; }
  if !idna.idna_is_valid("xn--mnchen-3ya.example") { io.println("idna-valid-alabel"); return 30; }
  if idna.idna_is_valid("-example.com") { io.println("idna-valid-hyphen"); return 31; }
  if idna.idna_is_valid("exa mple.com") { io.println("idna-valid-space"); return 32; }
  if idna.idna_is_valid("") { io.println("idna-valid-empty"); return 33; }

  var norm = idna.idna_uts46_normalize("EXAMPLE.COM");
  match norm {
    Ok(v) => { if v != "example.com" { io.println("idna-uts46"); return 34; } },
    Err(_) => { io.println("idna-uts46-err"); return 35; },
  }
  var prep = idna.idna_nameprep("Hello.COM");
  match prep {
    Ok(v) => { if v != "hello.com" { io.println("idna-nameprep"); return 36; } },
    Err(_) => { io.println("idna-nameprep-err"); return 37; },
  }

  // split/join round trip
  var labels = idna.idna_split_labels("a.b.c");
  if labels.len() != 3 { io.println("idna-split"); return 38; }
  var joined = idna.idna_join_labels(&labels);
  if joined != "a.b.c" { io.println("idna-join"); return 39; }

  if !idna.idna_is_bidi_valid("example.com") { io.println("idna-bidi-ltr"); return 40; }
  if idna.idna_is_bidi_valid("abcא") { io.println("idna-bidi-mix"); return 41; }

  io.println("OK");
  return 0;
}
