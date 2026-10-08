// p_wave89_shapes.xi -- wave 89 shape validation: serialize + json modules
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-89 clause guards: the SerializeError format pin, the
// validators' empty-input identities, the JSON literal helper pins and length
// bands, the parser empty-Err / null-Ok pins, JsonValue.index's negative-index
// guard, the endianness constants, the escape/unescape/minify/pretty empty
// identities and bands, the type-of pins, the varint/hex helper guards and the
// serialize.json constructor type claims. Values returned from the module
// surface are bound before comparing/reading. Returns 0 when every case holds.

module p_wave89_shapes

use xiom.serialize as ser;
use xiom.serialize.json as sjson;

fn main() -> Int {
  // ---- serialize: error formatting
  let e0 = SerializeError{ kind: 0; message: ""; path: ""; line: 0; col: 0; };
  let f0 = e0.format_error();
  if f0 != "SerializeError[0]:  (line 0, col 0)" { return 1; }
  if f0.len() < 15 { return 2; }

  // ---- serialize: validators
  if ser.is_valid_json("") { return 3; }
  if ser.is_valid_json("{}") == false { return 4; }
  let eb = Vec[UInt8].new();
  if ser.is_valid_bytes(&eb) { return 5; }

  // ---- serialize: JSON literal helpers
  let js0 = ser.json_string("");
  if js0 != "\"\"" { return 6; }
  let js1 = ser.json_string("a\"b");
  if js1.len() < 5 { return 7; }
  let jn0 = ser.json_number(0.0);
  if jn0 != "0" { return 8; }
  let nan = 0.0 / 0.0;
  let jnn = ser.json_number(nan);
  if jnn != "nan" { return 9; }
  let jbt = ser.json_bool(true);
  if jbt != "true" { return 10; }
  let jbf = ser.json_bool(false);
  if jbf != "false" { return 11; }
  let jnull = ser.json_null();
  if jnull != "null" { return 12; }
  let a0 = Vec[Str].new();
  let ja0 = ser.json_array(a0);
  if ja0 != "[]" { return 13; }
  var a1 = Vec[Str].new();
  a1.push("1");
  a1.push("2");
  let ja1 = ser.json_array(a1);
  if ja1.len() < 4 { return 14; }
  if ja1 != "[1, 2]" { return 15; }
  let p0 = Vec[(Str, Str)].new();
  let jo0 = ser.json_object(p0);
  if jo0 != "{}" { return 16; }
  var p1 = Vec[(Str, Str)].new();
  p1.push(("a", "1"));
  let jo1 = ser.json_object(p1);
  if jo1.len() < 4 { return 17; }
  if jo1 != "{\"a\": 1}" { return 18; }

  // ---- serialize: parser
  if ser.json_parse("").is_err == false { return 19; }
  if ser.json_parse("null").is_ok == false { return 20; }
  if ser.parse_json("").is_err == false { return 21; }
  if ser.parse_json("null").is_ok == false { return 22; }

  // ---- serialize: JsonValue.index via a parsed array
  let pa = ser.json_parse("[10]");
  match pa {
    Ok(v) => {
      let ineg = v.index(0 - 1);
      if ineg.is_some { return 23; }
      let izero = v.index(0);
      if izero.is_none { return 24; }
    },
    Err(_) => { return 25; },
  }

  // ---- serialize: endianness + escape family
  if ser.little_endian() == false { return 26; }
  if ser.big_endian() { return 27; }
  let je0 = ser.json_escape("");
  if je0 != "" { return 28; }
  let je1 = ser.json_escape("a\"b");
  if je1.len() < 3 { return 29; }
  if ser.json_unescape("").is_ok == false { return 30; }
  if ser.json_minify("").is_ok == false { return 31; }
  let mm = ser.json_minify(" a ");
  match mm {
    Ok(mv) => { if mv.len() > 3 { return 32; } },
    Err(_) => { return 33; },
  }
  if ser.json_pretty("").is_ok == false { return 34; }
  let gp0 = ser.json_get_path("", "a");
  if gp0.is_some { return 35; }
  let gp1 = ser.json_get_path("null", "");
  if gp1.is_none { return 36; }
  let t0 = ser.json_type_of("");
  if t0 != "invalid" { return 37; }
  let t1 = ser.json_type_of("{}");
  if t1 != "object" { return 38; }
  let t2 = ser.json_type_of("[1]");
  if t2 != "array" { return 39; }
  let t3 = ser.json_type_of("\"x\"");
  if t3 != "string" { return 40; }
  let t4 = ser.json_type_of("true");
  if t4 != "bool" { return 41; }
  let t5 = ser.json_type_of("x");
  if t5 != "invalid" { return 42; }

  // ---- serialize: varint/hex helpers
  let ve0 = ser.varint_encode(0);
  if ve0.len() != 1 { return 43; }
  let ve300 = ser.varint_encode(300);
  if ve300.len() != 2 { return 44; }
  let vem = ser.varint_encode(0 - 300);
  if vem.len() != 2 { return 45; }
  let vd0 = ser.varint_decode(&eb, 0);
  if vd0.is_err == false { return 46; }
  let vda = ser.varint_decode_at(&eb, 0);
  if vda.is_err == false { return 47; }
  let vel = ser.varint_encoded_len(&eb, 0);
  if vel != 0 { return 48; }
  var vb = Vec[UInt8].new();
  vb.push(5 as UInt8);
  let vel2 = ser.varint_encoded_len(&vb, 0);
  if vel2 != 1 { return 49; }
  let hx0 = ser.bytes_to_hex_str(&eb);
  if hx0 != "" { return 50; }
  var hb = Vec[UInt8].new();
  hb.push(0xAB as UInt8);
  hb.push(0xCD as UInt8);
  let hx1 = ser.bytes_to_hex_str(&hb);
  if hx1.len() != 4 { return 51; }
  let hb0 = ser.hex_str_to_bytes("");
  if hb0.is_ok == false { return 52; }
  let hb1 = ser.hex_str_to_bytes("zz");
  if hb1.is_err == false { return 53; }

  // ---- serialize.json module
  if sjson.json_parse("").is_err == false { return 54; }
  if sjson.json_parse("null").is_ok == false { return 55; }
  let nn = sjson.json_null();
  let pt = Vec[Str].new();
  let gpath = sjson.json_get_path(nn, &pt);
  if gpath.is_none { return 56; }
  let setv = sjson.json_set(nn, "k", nn);
  let setty = sjson.json_type(setv);
  if setty != "object" { return 57; }
  let pushv = sjson.json_array_push(nn, nn);
  let pushty = sjson.json_type(pushv);
  if pushty != "array" { return 58; }
  let onew = sjson.json_object_new();
  let onety = sjson.json_type(onew);
  if onety != "object" { return 59; }
  let anew = sjson.json_array_new();
  let anety = sjson.json_type(anew);
  if anety != "array" { return 60; }
  let numv = sjson.json_number(1.5);
  let numty = sjson.json_type(numv);
  if numty != "number" { return 61; }
  let strv = sjson.json_string("x");
  let strty = sjson.json_type(strv);
  if strty != "string" { return 62; }
  let boolv = sjson.json_bool(true);
  let boolty = sjson.json_type(boolv);
  if boolty != "bool" { return 63; }
  let nullv = sjson.json_null();
  let nullty = sjson.json_type(nullv);
  if nullty != "null" { return 64; }
  let sv = sjson.json_escape("");
  if sv != "" { return 65; }
  let sv2 = sjson.json_escape("a\"b");
  if sv2.len() < 3 { return 66; }
  if nullty.len() < 4 { return 67; }

  return 0;
}
