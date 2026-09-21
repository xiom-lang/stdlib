// XIOM stdlib smoke test - xiom.serialize.toml writer (toml_write)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Round-trips a fixture covering every v1 value kind through
// toml_write -> toml_parse, checks the emitted layout (root keys first,
// [section] blocks, quoted keys, float markers, array separators), the
// escape round-trip, and the empty-table edge case.
// Returns 0 on success, unique error code on failure.

module smoke_serialize_toml_write
use xiom.serialize.toml;
use xiom.io;
use xiom.string;

fn main() -> Int {
  let text = "title = \"root\"\ncount = 3\nratio = 1.0\nflag = true\ntools = [\"a\", \"b\"]\nlevels = [1, 2, 3]\nweights = [0.5, 1.0]\nnote = \"line\\nnext\"\n\"a b\" = 7\n\n[package]\nname = \"demo\"\nversion = \"0.1.0\"\n\n[build]\ntargets = [\"x\", \"y\"]\n";

  match toml_parse(text) {
    Ok(t) => {
      let out = toml_write(&t);
      if !string.str_contains(out, "[package]") { io.println("no package header"); return 2; }
      if !string.str_contains(out, "[build]") { io.println("no build header"); return 3; }
      if !string.str_contains(out, "name = \"demo\"") { io.println("name line"); return 4; }
      if !string.str_contains(out, "ratio = 1.0") { io.println("float marker"); return 5; }
      if !string.str_contains(out, "\"a b\" = 7") { io.println("quoted key"); return 6; }
      if !string.str_contains(out, "weights = [0.5, 1.0]") { io.println("float array"); return 7; }
      if !string.str_contains(out, "tools = [\"a\", \"b\"]") { io.println("str array"); return 8; }

      match toml_parse(out) {
        Ok(t2) => {
          if toml_keys(&t2).len() != toml_keys(&t).len() {
            io.println("keys " + toml_keys(&t2).len());
            return 9;
          }
          match toml_get_str(&t2, "title") {
            Some(s) => { if s != "root" { return 10; } },
            None => { return 11; },
          }
          match toml_get_int(&t2, "count") {
            Some(n) => { if n != 3 { return 12; } },
            None => { return 13; },
          }
          match toml_get_float(&t2, "ratio") {
            Some(f) => { if f != 1.0 { return 14; } },
            None => { return 15; },
          }
          match toml_get_bool(&t2, "flag") {
            Some(b) => { if !b { return 16; } },
            None => { return 17; },
          }
          match toml_get_str(&t2, "note") {
            Some(s) => { if s != "line\nnext" { return 18; } },
            None => { return 19; },
          }
          match toml_get_int(&t2, "a b") {
            Some(n) => { if n != 7 { return 20; } },
            None => { return 21; },
          }
          match toml_get_str(&t2, "package.name") {
            Some(s) => { if s != "demo" { return 22; } },
            None => { return 23; },
          }
          match toml_get_str_array(&t2, "build.targets") {
            Some(a) => {
              if a.len() != 2 { return 24; }
              if a[0] != "x" { return 25; }
            },
            None => { return 26; },
          }
          match toml_get_int_array(&t2, "levels") {
            Some(a) => {
              if a.len() != 3 { return 27; }
              if a[2] != 3 { return 28; }
            },
            None => { return 29; },
          }
        },
        Err(e) => { io.println("reparse: " + e); return 30; },
      }
    },
    Err(e) => { io.println("parse: " + e); return 1; },
  }

  var empty = TomlTable{ keys: Vec[Str].new(); values: Vec[TomlValue].new(); };
  if toml_write(&empty) != "" { io.println("empty write"); return 31; }
  return 0;
}
