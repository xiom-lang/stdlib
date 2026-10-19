// p_wave189_string_contracts.xi -- wave 189 string contract-shape validation
// Copyright (c) 2026 Eleftheros Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the wave-189 clauses across the low-coverage xiom.string modules:
// template map/render invariants, chunk/window length laws, mirror involution,
// permutation/combination length laws, segmentation bounds, unicode numeric
// payload bounds, and the category/script/bidi shape guarantees. Every call
// also re-evaluates the new requires/ensures at runtime (debug contracts).
// Returns 0 when every case holds.

module p_wave189_string_contracts

use xiom.string.template;
use xiom.string.chunk;
use xiom.string.mirror;
use xiom.string.permute;
use xiom.string.shuffle;
use xiom.string.combine;
use xiom.string.linebreak;
use xiom.string.compat;
use xiom.string.unescape;
use xiom.string.indent;
use xiom.string.segment;
use xiom.string.unicode;
use xiom.string.category;
use xiom.string.script;
use xiom.string.bidi;
use xiom.string.nfkc;
use xiom.string.wordbreak;
use xiom.string.sentencebreak;

fn main() -> Int {
  // ---- template: parallel-map invariant, compile/render shapes ----
  var m = xiom.string.template.map_new();
  if m.keys.len() != 0 { return 1; }
  if m.values.len() != 0 { return 2; }
  xiom.string.template.map_insert(&mut m, "name", "world");
  if m.keys.len() != m.values.len() { return 3; }
  let tr = xiom.string.template.template_render("Hello {{name}}!", &m);
  if !tr.is_ok { return 4; }
  if tr.value != "Hello world!" { return 5; }
  let tc = xiom.string.template.template_compile("{{a}}-{{b}}");
  if !tc.is_ok { return 6; }
  if tc.value.source != "{{a}}-{{b}}" { return 7; }
  if tc.value.placeholders.len() != 2 { return 8; }
  if xiom.string.template.template_placeholder_count("{{a}}{{a}}") != 2 { return 9; }
  if !xiom.string.template.template_has_placeholders("x{{a}}") { return 10; }
  if xiom.string.template.template_escape("a{b}").len() < 4 { return 11; }
  if xiom.string.template.template_unescape("\\{x\\}") != "{x}" { return 12; }

  // ---- chunk: fixed-size, reverse and sliding-window length laws ----
  if xiom.string.chunk.str_chunk("abcdef", 4).len() != 2 { return 13; }
  if xiom.string.chunk.str_chunk("abc", 0).len() != 0 { return 14; }
  if xiom.string.chunk.str_chunks_reverse("abcde", 2).len() != 3 { return 15; }
  if xiom.string.chunk.str_windows("abcd", 2).len() != 3 { return 16; }
  if xiom.string.chunk.str_windows("ab", 3).len() != 0 { return 17; }

  // ---- mirror: involution and mirroredness consistency ----
  if xiom.string.mirror.unicode_mirror_char('(') != ')' { return 18; }
  if xiom.string.mirror.unicode_mirror_char(')') != '(' { return 19; }
  if xiom.string.mirror.unicode_mirror_char('x') != 'x' { return 20; }
  if !xiom.string.mirror.unicode_is_mirrored('[') { return 21; }
  if xiom.string.mirror.unicode_is_mirrored('x') { return 22; }

  // ---- permute: empty/guarded/ranked length laws ----
  if xiom.string.permute.str_permutations("").len() != 1 { return 23; }
  if xiom.string.permute.str_permutations("abc").len() != 6 { return 24; }
  if xiom.string.permute.str_permutations("abcdefghi").len() != 0 { return 25; }
  if xiom.string.permute.str_permutations_n("abc", 0).len() != 1 { return 26; }
  if xiom.string.permute.str_permutations_n("abc", 4).len() != 0 { return 27; }
  if xiom.string.permute.str_permutation_at("abc", 0) != "abc" { return 28; }
  if xiom.string.permute.str_permutation_at("abc", 5) != "cba" { return 29; }
  if xiom.string.permute.str_permutation_at("abc", 6) != "" { return 30; }

  // ---- shuffle: byte-length preservation and word-join bound ----
  if xiom.string.shuffle.str_shuffle("").len() != 0 { return 31; }
  if xiom.string.shuffle.str_shuffle_seeded("abcdef", 42).len() != 6 { return 32; }
  if xiom.string.shuffle.str_shuffle_words("a  bb ccc").len() > 9 { return 33; }

  // ---- combine: binomial-count and ranked length laws ----
  if xiom.string.combine.str_combinations("abc", 2).len() != 3 { return 34; }
  if xiom.string.combine.str_combinations("abc", 0).len() != 0 { return 35; }
  if xiom.string.combine.str_combination_at("abc", 2, 0) != "ab" { return 36; }
  if xiom.string.combine.str_combination_at("abc", 2, 3) != "" { return 37; }

  // ---- line/word/sentence break bounds ----
  if xiom.string.linebreak.unicode_line_break_points("a b\nc").len() > 5 { return 38; }
  if xiom.string.linebreak.unicode_split_lines("").len() < 1 { return 39; }
  if xiom.string.wordbreak.unicode_word_boundaries("a b").len() > 3 { return 40; }
  if xiom.string.wordbreak.unicode_split_words("a b").len() > 3 { return 41; }
  if xiom.string.sentencebreak.unicode_sentence_boundaries("A. B.").len() > 5 { return 42; }
  if xiom.string.sentencebreak.unicode_split_sentences("A. B.").len() > 5 { return 43; }
  if xiom.string.segment.unicode_grapheme_clusters("ab").len() > 2 { return 44; }
  if xiom.string.segment.unicode_segment_graphemes("ab").len() != 3 { return 45; }

  // ---- compat / unescape / indent length laws ----
  if xiom.string.compat.unicode_compatibility_normalize("").len() != 0 { return 46; }
  if xiom.string.compat.unicode_decompose("abc").len() != 3 { return 47; }
  if xiom.string.unescape.str_unescape("a\\nb").len() > 4 { return 48; }
  if xiom.string.unescape.str_unescape_ascii("\\x41").len() > 4 { return 49; }
  if xiom.string.unescape.str_unescape_unicode("\\u0041").len() > 6 { return 50; }
  if xiom.string.indent.str_indent("a\nb", 0) != "a\nb" { return 51; }
  if xiom.string.indent.str_indent("a\nb", 2).len() < 4 { return 52; }
  if xiom.string.indent.str_indent_with("a", 0, ">") != "a" { return 53; }
  if xiom.string.indent.str_dedent("  a\n  b").len() > 7 { return 54; }
  if xiom.string.indent.str_unindent("\ta").len() > 2 { return 55; }

  // ---- unicode: normalization, case, numeric payload bounds ----
  if xiom.string.unicode.unicode_normalize("").len() != 0 { return 56; }
  if xiom.string.unicode.unicode_normalize_form("", "NFKD").len() != 0 { return 57; }
  if xiom.string.unicode.unicode_casefold("ABC") != "abc" { return 58; }
  if xiom.string.unicode.unicode_casefold_turkic("").len() != 0 { return 59; }
  if xiom.string.unicode.unicode_titlecase("").len() != 0 { return 60; }
  if xiom.string.unicode.unicode_titlecase_word("").len() != 0 { return 61; }
  if xiom.string.unicode.unicode_tolower_full("").len() != 0 { return 62; }
  if xiom.string.unicode.unicode_toupper_full("AB").len() < 2 { return 63; }
  if xiom.string.unicode.unicode_casefold_char('A') != 'a' { return 64; }
  if xiom.string.unicode.unicode_lowercase_map('A') != 'a' { return 65; }
  if xiom.string.unicode.unicode_uppercase_map('a') != 'A' { return 66; }
  if xiom.string.unicode.unicode_titlecase_map('a') != 'A' { return 67; }
  if xiom.string.unicode.unicode_decompose('A').len() != 1 { return 68; }
  let dv = xiom.string.unicode.unicode_decimal_value('7');
  if !dv.is_some { return 69; }
  if dv.value != 7 { return 70; }
  let dgv = xiom.string.unicode.unicode_digit_value('7');
  if !dgv.is_some { return 71; }
  if dgv.value != 7 { return 72; }
  let nv = xiom.string.unicode.unicode_numeric_value('7');
  if !nv.is_some { return 73; }
  if nv.value != 7.0 { return 74; }

  // ---- unicode: category/script/bidi shape guarantees ----
  if xiom.string.unicode.unicode_script('A') != "Latn" { return 75; }
  if xiom.string.unicode.unicode_script_name("Latn") != "Latin" { return 76; }
  if xiom.string.unicode.unicode_block('A') != "Basic Latin" { return 77; }
  if xiom.string.unicode.unicode_general_category('A') != "Lu" { return 78; }
  if xiom.string.unicode.unicode_general_category_name('A') != "Uppercase_Letter" { return 79; }
  if xiom.string.unicode.unicode_age('A') != "1.1" { return 80; }
  if xiom.string.unicode.unicode_combining_class('A') != 0 { return 81; }
  if !xiom.string.unicode.unicode_is_letter('A') { return 82; }
  if !xiom.string.unicode.unicode_is_digit('7') { return 83; }
  if !xiom.string.unicode.unicode_is_punct(',') { return 84; }
  if !xiom.string.unicode.unicode_is_symbol('+') { return 85; }
  if !xiom.string.unicode.unicode_is_separator(' ') { return 86; }
  if !xiom.string.unicode.unicode_is_control('\n') { return 87; }
  if !xiom.string.unicode.unicode_is_printable('A') { return 88; }
  if xiom.string.unicode.unicode_script_of("") != "Zzzz" { return 89; }
  if xiom.string.unicode.unicode_scripts("AB").len() > 2 { return 90; }
  if xiom.string.unicode.unicode_bidi_class('A') != "L" { return 91; }
  if !xiom.string.unicode.unicode_mirrored('(') { return 92; }
  if xiom.string.unicode.unicode_mirror_char('(') != ')' { return 93; }
  if xiom.string.unicode.unicode_bidi_brackets("(a)").len() > 3 { return 94; }
  if xiom.string.unicode.unicode_bidi_level('A') != 0 { return 95; }
  if xiom.string.unicode.unicode_bidi_scan("abc").len() > 3 { return 96; }
  if !xiom.string.unicode.unicode_is_whitespace(' ') { return 97; }
  if !xiom.string.unicode.unicode_is_alphabetic('A') { return 98; }
  if !xiom.string.unicode.unicode_is_cased('A') { return 99; }
  if !xiom.string.unicode.unicode_is_numeric('7') { return 100; }
  if !xiom.string.unicode.unicode_is_normalized("", "NFC") { return 101; }
  if xiom.string.unicode.unicode_has_emoji("abc") { return 102; }
  if xiom.string.unicode.unicode_emoji_version() != "15.0" { return 103; }
  if xiom.string.unicode.unicode_ea_width('A') != 1 { return 104; }
  if xiom.string.unicode.unicode_display_width("AB") != 2 { return 105; }
  if xiom.string.unicode.unicode_grapheme_count("ab") != 2 { return 106; }
  if xiom.string.unicode.unicode_word_count("a b") != 2 { return 107; }
  if xiom.string.unicode.unicode_sentence_count("A. B.") != 2 { return 108; }
  if xiom.string.unicode.unicode_next_grapheme("abc", 0) != 1 { return 109; }
  if xiom.string.unicode.unicode_prev_grapheme("abc", 3) != 2 { return 110; }

  // ---- category / script / bidi / nfkc module-level shapes ----
  if xiom.string.category.unicode_general_category('A') != "Lu" { return 111; }
  if !xiom.string.category.unicode_is_letter('A') { return 112; }
  if xiom.string.script.unicode_script('A') != "Latn" { return 113; }
  if xiom.string.script.unicode_script_name("Latn") != "Latin" { return 114; }
  if xiom.string.bidi.unicode_bidi_class('A') != "L" { return 115; }
  if !xiom.string.bidi.unicode_mirrored('(') { return 116; }
  if xiom.string.bidi.unicode_mirror_char('(') != ')' { return 117; }
  if xiom.string.nfkc.unicode_normalize_nfkc("").len() != 0 { return 118; }
  if xiom.string.nfkc.unicode_normalize_nfkd("").len() != 0 { return 119; }

  return 0;
}
