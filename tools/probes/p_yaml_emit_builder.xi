// p_yaml_emit_builder.xi -- byte-exact checks for the wave-209 YAML byte
// builder (scalars, sequences, mappings, nested trees).
// Expected rc 0.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_yaml_emit_builder

use xiom.serialize.yaml_lite;
use xiom.io;

fn expect(label: Str, got: Str, want: Str) -> Int {
  if got != want {
    io.println(label + " got=[" + got + "]");
    return 1;
  }
  return 0;
}

fn main() -> Int {
  if expect("empty", yaml_lite.yaml_emit_scalar(""), "\"\"") != 0 { return 1; }
  if expect("plain", yaml_lite.yaml_emit_scalar("plain"), "plain") != 0 { return 2; }
  if expect("colon", yaml_lite.yaml_emit_scalar("a: b"), "\"a: b\"") != 0 { return 3; }
  if expect("quote", yaml_lite.yaml_emit_scalar("a\"b"), "\"a\\\"b\"") != 0 { return 4; }
  if expect("newline", yaml_lite.yaml_emit_scalar("a\nb"), "\"a\\nb\"") != 0 { return 5; }
  if expect("tab", yaml_lite.yaml_emit_scalar("a\tb"), "\"a\\tb\"") != 0 { return 6; }
  if expect("utf8", yaml_lite.yaml_emit_scalar("h\u{00e9}llo"), "h\u{00e9}llo") != 0 { return 7; }

  var items: Vec[Str] = Vec[Str].new();
  items.push("one");
  items.push("a: b");
  items.push("");
  items.push("two");
  if expect("seq", yaml_lite.yaml_emit_sequence(&items),
      "- one\n- \"a: b\"\n- \"\"\n- two") != 0 { return 8; }

  var keys: Vec[Str] = Vec[Str].new();
  keys.push("k1");
  keys.push("k2");
  keys.push("k3");
  var vals: Vec[Str] = Vec[Str].new();
  vals.push("v");
  vals.push("a: b");
  vals.push("");
  if expect("map", yaml_lite.yaml_emit_mapping(&keys, &vals),
      "k1: v\nk2: \"a: b\"\nk3: \"\"") != 0 { return 9; }

  var ikeys: Vec[Str] = Vec[Str].new();
  ikeys.push("year");
  ikeys.push("related");
  var ivals: Vec[YamlValue] = Vec[YamlValue].new();
  ivals.push(YamlValue.Scalar("1821"));
  ivals.push(YamlValue.Scalar("true"));
  let inner = YamlValue.Mapping(ikeys, ivals);
  var titems: Vec[YamlValue] = Vec[YamlValue].new();
  titems.push(inner);
  titems.push(YamlValue.Scalar("plain item"));
  let seqv = YamlValue.Sequence(titems);
  var rkeys: Vec[Str] = Vec[Str].new();
  rkeys.push("family");
  rkeys.push("publications");
  var rvals: Vec[YamlValue] = Vec[YamlValue].new();
  rvals.push(YamlValue.Scalar("Elephantidae"));
  rvals.push(seqv);
  let root = YamlValue.Mapping(rkeys, rvals);
  if expect("tree", yaml_lite.yaml_stringify(root),
      "family: Elephantidae\npublications: \n    - \n      year: 1821\n      related: true\n    - plain item") != 0 { return 10; }

  let parsed = yaml_lite.yaml_parse("k0: v0\nk1: v1\n");
  if !parsed.is_ok { return 11; }
  if expect("parsed", yaml_lite.yaml_stringify(parsed.value), "k0: v0\nk1: v1") != 0 { return 12; }

  return 0;
}
