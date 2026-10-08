// p_wave90_shapes.xi -- wave 90 shape validation: toml + yaml_lite
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-90 clause guards: the toml empty-document Ok and
// malformed-header Err pins, the empty-table None/False identities on the
// getter family, toml_keys length mirror and the toml_write empty + length
// band; the yaml empty-document Err pins, the scalar/sequence/mapping empty
// emits and the emit length bands. Values returned from the module surface
// are bound before comparing/reading. Returns 0 when every case holds.

module p_wave90_shapes

use xiom.serialize.toml as ctoml;
use xiom.serialize.yaml_lite as cyaml;

fn main() -> Int {
  // ---- toml parser pins
  let p_empty = ctoml.toml_parse("");
  if p_empty.is_ok == false { return 1; }
  let p_one = ctoml.toml_parse("a = 1");
  if p_one.is_ok == false { return 2; }
  let p_bad = ctoml.toml_parse("[a");
  if p_bad.is_err == false { return 3; }

  // ---- toml empty-table identities
  let et = ctoml.toml_parse("");
  match et {
    Ok(t0) => {
      let g0 = ctoml.toml_get(&t0, "a");
      if g0.is_some { return 4; }
      if ctoml.toml_has(&t0, "a") { return 5; }
      let gs = ctoml.toml_get_str(&t0, "a");
      if gs.is_some { return 6; }
      let gi = ctoml.toml_get_int(&t0, "a");
      if gi.is_some { return 7; }
      let gf = ctoml.toml_get_float(&t0, "a");
      if gf.is_some { return 8; }
      let gb = ctoml.toml_get_bool(&t0, "a");
      if gb.is_some { return 9; }
      let gsa = ctoml.toml_get_str_array(&t0, "a");
      if gsa.is_some { return 10; }
      let gia = ctoml.toml_get_int_array(&t0, "a");
      if gia.is_some { return 11; }
      let ks0 = ctoml.toml_keys(&t0);
      if ks0.len() != 0 { return 12; }
      let w0 = ctoml.toml_write(&t0);
      if w0 != "" { return 13; }
    },
    Err(_) => { return 14; },
  };

  // ---- toml populated table
  let pt = ctoml.toml_parse("a = 1\n[sec]\nb = 2");
  match pt {
    Ok(t1) => {
      if ctoml.toml_has(&t1, "a") == false { return 15; }
      if ctoml.toml_has(&t1, "zz") { return 16; }
      let gi1 = ctoml.toml_get_int(&t1, "a");
      if gi1.is_none { return 17; }
      let gs1 = ctoml.toml_get_str(&t1, "a");
      if gs1.is_some { return 18; }
      let gb1 = ctoml.toml_get_bool(&t1, "a");
      if gb1.is_some { return 19; }
      let ks1 = ctoml.toml_keys(&t1);
      if ks1.len() != 2 { return 20; }
      let w1 = ctoml.toml_write(&t1);
      if w1.len() < 2 { return 21; }
      if w1 != "a = 1\n[sec]\nb = 2\n" { return 22; }
    },
    Err(_) => { return 23; },
  };

  // ---- yaml parser pins
  let y_empty = cyaml.yaml_parse("");
  if y_empty.is_err == false { return 24; }
  let y_one = cyaml.yaml_parse("a: 1");
  if y_one.is_ok == false { return 25; }
  let y_doc = cyaml.yaml_parse_document("");
  if y_doc.is_err == false { return 26; }
  let y_doc2 = cyaml.yaml_parse_document("a: 1");
  if y_doc2.is_ok == false { return 27; }

  // ---- yaml emits
  let es0 = cyaml.yaml_emit_scalar("");
  if es0 != "\"\"" { return 28; }
  let es1 = cyaml.yaml_emit_scalar("abc");
  if es1 != "abc" { return 29; }
  if es1.len() < 3 { return 30; }
  let seq0 = Vec[Str].new();
  let se0 = cyaml.yaml_emit_sequence(&seq0);
  if se0 != "" { return 31; }
  var seq1 = Vec[Str].new();
  seq1.push("a");
  seq1.push("b");
  let se1 = cyaml.yaml_emit_sequence(&seq1);
  if se1.len() < 2 { return 32; }
  if se1 != "- a\n- b" { return 33; }
  let mk0 = Vec[Str].new();
  let mv0 = Vec[Str].new();
  let me0 = cyaml.yaml_emit_mapping(&mk0, &mv0);
  if me0 != "" { return 34; }
  var mk1 = Vec[Str].new();
  mk1.push("a");
  var mv1 = Vec[Str].new();
  mv1.push("1");
  let me1 = cyaml.yaml_emit_mapping(&mk1, &mv1);
  if me1 != "a: 1" { return 35; }

  return 0;
}
