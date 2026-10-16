// p_wave154_shapes.xi -- wave 154 lock: TLS wave-A scaffolding, backend
// independent (plan item 9 wave-A; refs REL-20261015-2202-pulse item 1):
//   (a) RFC 7301 ALPN codec -- alpn_encode / alpn_decode roundtrips plus
//       the strict rejections (empty list, 256-byte name, truncated
//       bytes, zero-length name, trailing bytes, missing length);
//   (b) dl_open/dl_sym backend loader skeleton -- tls_backend_available
//       false for a missing library and for a loadable library without
//       the symbol contract; tls_backend_load clean Err("backend not
//       found").
// Rows (0 = all hold):
//  1 -- alpn_encode(["h2","http/1.1"]) is wire-exact (14 bytes)
//  2 -- alpn_decode of (1) roundtrips to the same two names
//  3 -- single-name ["h2"] encode + decode roundtrip
//  4 -- 255-byte name encodes (2 + 1 + 255) and roundtrips
//  5 -- empty protocol list -> Err
//  6 -- 256-byte name -> Err
//  7 -- truncated ProtocolNameList -> Err
//  8 -- empty name encode -> Err and zero-length decode name -> Err
//  9 -- trailing byte after a valid list -> Err (strict length)
// 10 -- single byte (missing length) -> Err
// 11 -- tls_backend_available("definitely-missing.dll") == false
// 12 -- tls_backend_load("definitely-missing.dll") -> Err "backend not found"
// 13 -- empty path: availability false + load Err
// 14 -- tls_backend_available("kernel32.dll") == false (loads, wrong symbols)
// Setup failures use 20+.

module p_wave154_shapes

use xiom.net.tls;
use xiom.string;

fn main() -> Int {
  // Row 1: wire-exact encode of the canonical pair.
  var pair = Vec[Str].new();
  pair.push("h2");
  pair.push("http/1.1");
  let enc1 = tls.alpn_encode(&pair);
  var wire: Vec[UInt8] = Vec[UInt8].new();
  match enc1 {
    Err(_) => { return 1; },
    Ok(b) => {
      if b.len() != 14 { return 1; }
      var i = 0;
      while i < b.len() {
        wire.push(b[i]);
        i = i + 1;
      }
    },
  }
  if wire.len() != 14 { return 1; }
  if wire[0] != 0 as UInt8 { return 1; }
  if wire[1] != 12 as UInt8 { return 1; }
  if wire[2] != 2 as UInt8 { return 1; }
  if wire[3] != 104 as UInt8 { return 1; }
  if wire[4] != 50 as UInt8 { return 1; }
  if wire[5] != 8 as UInt8 { return 1; }
  if wire[6] != 104 as UInt8 { return 1; }
  if wire[7] != 116 as UInt8 { return 1; }
  if wire[8] != 116 as UInt8 { return 1; }
  if wire[9] != 112 as UInt8 { return 1; }
  if wire[10] != 47 as UInt8 { return 1; }
  if wire[11] != 49 as UInt8 { return 1; }
  if wire[12] != 46 as UInt8 { return 1; }
  if wire[13] != 49 as UInt8 { return 1; }

  // Row 2: decode roundtrip of the canonical pair.
  let dec2 = tls.alpn_decode(&wire);
  match dec2 {
    Err(_) => { return 2; },
    Ok(names) => {
      if names.len() != 2 { return 2; }
      if names[0] != "h2" { return 2; }
      if names[1] != "http/1.1" { return 2; }
    },
  }

  // Row 3: single-name roundtrip.
  var one = Vec[Str].new();
  one.push("h2");
  let enc3 = tls.alpn_encode(&one);
  var wire3: Vec[UInt8] = Vec[UInt8].new();
  match enc3 {
    Err(_) => { return 3; },
    Ok(b) => {
      if b.len() != 5 { return 3; }
      var i = 0;
      while i < b.len() {
        wire3.push(b[i]);
        i = i + 1;
      }
    },
  }
  if wire3[0] != 0 as UInt8 { return 3; }
  if wire3[1] != 3 as UInt8 { return 3; }
  if wire3[2] != 2 as UInt8 { return 3; }
  if wire3[3] != 104 as UInt8 { return 3; }
  if wire3[4] != 50 as UInt8 { return 3; }
  let dec3 = tls.alpn_decode(&wire3);
  match dec3 {
    Err(_) => { return 3; },
    Ok(names) => {
      if names.len() != 1 { return 3; }
      if names[0] != "h2" { return 3; }
    },
  }

  // Row 4: 255-byte (max-length) name encodes and roundtrips.
  var a255 = Vec[UInt8].new();
  var z4 = 0;
  while z4 < 255 {
    a255.push(97 as UInt8);
    z4 = z4 + 1;
  }
  let big4 = Str::from_utf8(a255);
  var biglist4 = Vec[Str].new();
  biglist4.push(big4);
  let enc4 = tls.alpn_encode(&biglist4);
  var wire4: Vec[UInt8] = Vec[UInt8].new();
  match enc4 {
    Err(_) => { return 4; },
    Ok(b) => {
      if b.len() != 258 { return 4; }
      var i = 0;
      while i < b.len() {
        wire4.push(b[i]);
        i = i + 1;
      }
    },
  }
  if wire4[0] != 1 as UInt8 { return 4; }
  if wire4[1] != 0 as UInt8 { return 4; }
  if wire4[2] != 255 as UInt8 { return 4; }
  let dec4 = tls.alpn_decode(&wire4);
  match dec4 {
    Err(_) => { return 4; },
    Ok(names) => {
      if names.len() != 1 { return 4; }
      if names[0].len() != 255 { return 4; }
      if names[0].byte_at(0) != 97 { return 4; }
      if names[0].byte_at(254) != 97 { return 4; }
    },
  }

  // Row 5: empty list -> Err.
  var none5 = Vec[Str].new();
  let enc5 = tls.alpn_encode(&none5);
  if enc5.is_ok { return 5; }

  // Row 6: 256-byte name -> Err.
  var a256 = Vec[UInt8].new();
  var z6 = 0;
  while z6 < 256 {
    a256.push(97 as UInt8);
    z6 = z6 + 1;
  }
  let big6 = Str::from_utf8(a256);
  var biglist6 = Vec[Str].new();
  biglist6.push(big6);
  let enc6 = tls.alpn_encode(&biglist6);
  if enc6.is_ok { return 6; }

  // Row 7: truncated ProtocolNameList -> Err.
  var trunc7 = Vec[UInt8].new();
  trunc7.push(0 as UInt8);
  trunc7.push(5 as UInt8);
  trunc7.push(2 as UInt8);
  trunc7.push(104 as UInt8);
  let dec7 = tls.alpn_decode(&trunc7);
  if dec7.is_ok { return 7; }

  // Row 8: empty name encode -> Err; zero-length decode name -> Err.
  var zn8 = Vec[Str].new();
  zn8.push("");
  let enc8 = tls.alpn_encode(&zn8);
  if enc8.is_ok { return 8; }
  var zb8 = Vec[UInt8].new();
  zb8.push(0 as UInt8);
  zb8.push(2 as UInt8);
  zb8.push(0 as UInt8);
  zb8.push(97 as UInt8);
  let dec8 = tls.alpn_decode(&zb8);
  if dec8.is_ok { return 8; }

  // Row 9: trailing byte after a valid list -> Err (strict length).
  let enc9 = tls.alpn_encode(&one);
  match enc9 {
    Err(_) => { return 9; },
    Ok(b9) => {
      var tb9 = Vec[UInt8].new();
      var i9 = 0;
      while i9 < b9.len() {
        tb9.push(b9[i9]);
        i9 = i9 + 1;
      }
      tb9.push(99 as UInt8);
      let dec9 = tls.alpn_decode(&tb9);
      if dec9.is_ok { return 9; }
    },
  }

  // Row 10: single byte (missing length) -> Err.
  var b10 = Vec[UInt8].new();
  b10.push(0 as UInt8);
  let dec10 = tls.alpn_decode(&b10);
  if dec10.is_ok { return 10; }

  // Row 11: missing library is not available.
  if tls.tls_backend_available("definitely-missing.dll") { return 11; }

  // Row 12: clean Err("backend not found") from the loader.
  let load12 = tls.tls_backend_load("definitely-missing.dll");
  match load12 {
    Ok(_) => { return 12; },
    Err(e) => {
      if !string.str_contains(e, "backend not found") { return 12; }
    },
  }

  // Row 13: empty path: availability false + load Err.
  if tls.tls_backend_available("") { return 13; }
  let load13 = tls.tls_backend_load("");
  if load13.is_ok { return 13; }

  // Row 14: a library that loads but lacks the symbol contract is not
  // available (kernel32.dll on Windows; trivially missing on POSIX).
  if tls.tls_backend_available("kernel32.dll") { return 14; }

  return 0;
}
