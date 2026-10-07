// p_wave84_shapes.xi -- wave 84 shape validation: uri/url/urn families
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-84 clause guards: empty-input Err identities on
// uri_parse/uri_normalize/url_parse, the percent bands of url_encode, the
// canonical url_decode guards, urn_parse's < 7 length guard,
// urn_is_valid false-on-invalid and urn_build's exact length. Returns 0
// when every case holds.

module p_wave84_shapes

use xiom.convert.uri as curi;
use xiom.convert.url as curl;
use xiom.convert.urn as curn;

fn main() -> Int {
  // ---- uri
  if !curi.uri_parse("").is_err { return 1; }
  if !curi.uri_parse("https://a/b").is_ok { return 2; }
  if !curi.uri_normalize("").is_err { return 3; }
  if !curi.uri_normalize("HTTP://A/b").is_ok { return 4; }

  // ---- url
  if !curl.url_parse("").is_err { return 5; }
  if !curl.url_parse("https://a/b").is_ok { return 6; }
  let ue = curl.url_encode("a b");
  if ue.len() < 3 { return 7; }
  if ue.len() > 9 { return 8; }
  if !curl.url_decode("").is_ok { return 9; }
  if !curl.url_decode("a%20b").is_ok { return 10; }

  // ---- urn
  if !curn.urn_parse("urn:").is_err { return 11; }
  if !curn.urn_parse("urn:isbn:12345").is_ok { return 12; }
  if curn.urn_is_valid("x") { return 13; }
  if !curn.urn_is_valid("urn:isbn:12345") { return 14; }
  if curn.urn_build("isbn", "12345") != "urn:isbn:12345" { return 15; }
  if curn.urn_build("isbn", "12345").len() != 14 { return 16; }

  return 0;
}
