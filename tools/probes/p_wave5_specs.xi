// p_wave5_specs.xi -- wave-5 contract validation: compare/collate sign bounds,
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
// collate_key length preservation, bloom false-positive rate >= 0.
module p_wave5_specs
use xiom.string.compare;
use xiom.string.collate;
use xiom.collect.hash;
use xiom.io;

fn main() -> Int {
  let pairs = Vec[Str].new();
  var a = "abc";
  var b = "abd";
  if compare.str_compare("abc", "abd") != -1 { return 1; };
  if compare.str_compare("abd", "abc") != 1 { return 2; };
  if compare.str_compare("abc", "abc") != 0 { return 3; };
  if compare.str_compare("", "a") != -1 { return 4; };
  if compare.str_compare("a", "") != 1 { return 5; };
  if compare.str_compare_ignore_case("ABC", "abc") != 0 { return 6; };
  if compare.str_compare_ignore_case("Abc", "abd") != -1 { return 7; };
  if compare.str_compare_natural("x2", "x10") != -1 { return 8; };
  if compare.str_compare_natural("x10", "x2") != 1 { return 9; };
  if compare.str_compare_natural("a1b", "a1b") != 0 { return 10; };

  if collate.collate_compare("a", "b") != -1 { return 11; };
  if collate.collate_compare("b", "a") != 1 { return 12; };
  if collate.collate_compare("same", "same") != 0 { return 13; };
  if collate.collate_key("MiXeD").len() != 5 { return 14; };
  if collate.collate_key("").len() != 0 { return 15; };
  if collate.collate_key("a\u{00E9}b").len() != 4 { return 16; };

  var bf = bloom_new(1024, 4);
  if bloom_false_positive_rate(&bf) < 0.0 { return 17; };
  var data = Vec[UInt8].new();
  data.push(65);
  data.push(66);
  bloom_insert(&mut bf, &data);
  if bloom_false_positive_rate(&bf) < 0.0 { return 18; };

  io.println("P_WAVE5_SPECS OK");
  io.flush_stdout();
  0
}
