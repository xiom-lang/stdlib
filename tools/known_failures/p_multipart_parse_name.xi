// p_multipart_parse_name.xi -- multipart_parse result fields corrupt
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Open finding 2026-10-03 (pre-existing on v0.61.3 AND official v0.62.3):
// the Part values returned by multipart.multipart_parse have corrupt field
// reads. Minimal flow: build one `multipart_part("f", "v")`, parse it back
// with the same boundary, then `out[0].name` is neither "f" nor "" (its
// `.len()` reads -1); the same fields on a directly constructed Part are
// correct, and parse itself returns the right part count. Found while
// writing the wave-62 multipart probe (name assertions removed there;
// presence-only). Expected: `out[0].name == "f"`; rc=1 while open.

module p_multipart_parse_name

use xiom.net.multipart;
use xiom.net.multipart.Part;

fn main() -> Int {
  var parts = Vec[Part].new();
  parts.push(multipart.multipart_part("f", "v"));
  let body = multipart.multipart_build(&parts, "bnd");
  match multipart.multipart_parse(&body, "bnd") {
    Ok(out) => {
      if out.len() != 1 { return 2; }
      if !(out[0].name == "f") { return 1; }
    },
    Err(_) => { return 3; },
  }
  return 0;
}
