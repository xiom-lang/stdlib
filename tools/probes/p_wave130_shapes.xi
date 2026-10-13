// p_wave130_shapes.xi -- wave 130 lock: the builder pass (final leak-class
// sweep in the string dir) -- wrap (str_wrap/soft/hard/join), combine
// (combinations/combination_at), align (justify), permute
// (permutation_at), template (render/escape/unescape) and combinatorics
// (rotate_words/interleave/chunk_bytes/unique_chars) now build through
// single Vec[UInt8] builders with cached raw reads instead of
// concat-per-item loops. Byte-exact outputs. Returns 0 when every case
// holds.

module p_wave130_shapes

use xiom.string;
use xiom.string.wrap as swrap;
use xiom.string.combine as scombine;
use xiom.string.align as salign;
use xiom.string.permute as sperm;
use xiom.string.template as stpl;
use xiom.string.combinatorics as scombi;

fn main() -> Int {
  // ---- wrap ----
  let w1 = swrap.str_wrap("a b c d", 3);
  if w1.len() != 2 { return 1; }
  let w1a = w1[0];
  if w1a != "a b" { return 2; }
  let w1b = w1[1];
  if w1b != "c d" { return 3; }
  let w2 = swrap.str_wrap_soft("a b c d", 3);
  if w2.len() != 2 { return 4; }
  let w2b = w2[1];
  if w2b != "c d" { return 5; }
  let w3 = swrap.str_wrap_hard("abcde", 2);
  if w3.len() != 3 { return 6; }
  let w3c = w3[2];
  if w3c != "e" { return 7; }
  let w4 = swrap.str_wrap_join("a b c d", 3, "|");
  if w4 != "a b|c d" { return 8; }
  let w5 = swrap.str_wrap("abcdef", 2);  // long word is hard-split
  if w5.len() != 3 { return 9; }

  // ---- combine ----
  let c1 = scombine.str_combinations("abc", 2);
  if c1.len() != 3 { return 10; }
  let c1a = c1[0];
  if c1a != "ab" { return 11; }
  let c1c = c1[2];
  if c1c != "bc" { return 12; }
  let c2 = scombine.str_combination_at("abc", 2, 1);
  if c2 != "ac" { return 13; }

  // ---- align ----
  let a1 = salign.str_align_justify("a b c", 7);
  if a1 != "a  b  c" { return 14; }
  let a2 = salign.str_align_left("ab", 4);
  if a2 != "ab  " { return 15; }

  // ---- permute ----
  let p1 = sperm.str_permutation_at("abc", 0);
  if p1 != "abc" { return 16; }
  let p2 = sperm.str_permutation_at("abc", 1);
  if p2 != "acb" { return 17; }

  // ---- template ----
  let t1 = stpl.template_escape("a{b}c");
  if t1 != "a\\{b\\}c" { return 18; }
  let t2 = stpl.template_unescape("a\\{b\\}c");
  if t2 != "a{b}c" { return 19; }
  var m = stpl.map_new();
  stpl.map_insert(&mut m, "name", "World");
  let r1 = stpl.template_render("Hello {{name}}!", &m);
  match r1 {
    Ok(v) => { if v != "Hello World!" { return 20; } },
    Err(_) => { return 21; },
  }

  // ---- combinatorics ----
  let k1 = scombi.str_rotate_word("a b c", 1);
  if k1 != "c a b" { return 22; }
  let k2 = scombi.str_interleave("abc", "12");
  if k2 != "a1b2c" { return 23; }
  let k3 = scombi.str_chunk_bytes("abcde", 3);
  if k3.len() != 2 { return 24; }
  let k3a = k3[0];
  if k3a != "abc" { return 25; }
  let k4 = scombi.str_unique_chars("aabbc");
  if k4 != "abc" { return 26; }

  return 0;
}
