module smoke_string_combinatorics
use xiom.string.combinatorics;
use xiom.string.permute;
use xiom.string.shuffle;
use xiom.io;

fn main() -> Int {
  // ---- shuffle (combinatorics) ----
  var r1 = combinatorics.str_shuffle("abc");
  if r1.len() != 3 { io.println("sh-1"); return 1; }
  if r1 != "abc" && r1 != "acb" && r1 != "bac" && r1 != "bca" && r1 != "cab" && r1 != "cba" { io.println("sh-2"); return 2; }
  if combinatorics.str_shuffle("") != "" { io.println("sh-3"); return 3; }

  var s1a = combinatorics.str_shuffle_seeded("abcd", 5);
  var s1b = combinatorics.str_shuffle_seeded("abcd", 5);
  if s1a != s1b { io.println("sh-4"); return 4; }
  if s1a.len() != 4 { io.println("sh-5"); return 5; }
  var s2a = combinatorics.str_shuffle_seeded("abcd", 6);
  if s2a == s1a { io.println("sh-6"); return 6; }
  var s3 = combinatorics.str_shuffle_words("a b c");
  if s3 != "a b c" && s3 != "a c b" && s3 != "b a c" && s3 != "b c a" && s3 != "c a b" && s3 != "c b a" { io.println("sh-7"); return 7; }
  var s4 = combinatorics.str_shuffle_words_seeded("a b c", 3);
  var s5 = combinatorics.str_shuffle_words_seeded("a b c", 3);
  if s4 != s5 { io.println("sh-8"); return 8; }
  if combinatorics.str_shuffle_words("") != "" { io.println("sh-9"); return 9; }

  // ---- rotate ----
  if combinatorics.str_rotate("abcde", 2) != "deabc" { io.println("rot-1"); return 10; }
  if combinatorics.str_rotate("abcde", -1) != "bcdea" { io.println("rot-2"); return 11; }
  if combinatorics.str_rotate("abcde", 5) != "abcde" { io.println("rot-3"); return 12; }
  if combinatorics.str_rotate_left("abcde", 2) != "cdeab" { io.println("rot-4"); return 13; }
  if combinatorics.str_rotate_right("abcde", 2) != "deabc" { io.println("rot-5"); return 14; }
  if combinatorics.str_rotate("", 2) != "" { io.println("rot-6"); return 15; }
  if combinatorics.str_rotate_word("a b c", 1) != "c a b" { io.println("rot-7"); return 16; }
  if combinatorics.str_rotate_word("a b c", -1) != "b c a" { io.println("rot-8"); return 17; }
  if combinatorics.str_rotate_word("single", 3) != "single" { io.println("rot-9"); return 18; }

  // ---- permutations ----
  var perms = combinatorics.str_permutations("abc");
  if perms.len() != 6 { io.println("perm-1"); return 19; }
  var p0 = perms[0];
  var p1 = perms[1];
  var p2 = perms[2];
  var p3 = perms[3];
  var p4 = perms[4];
  var p5 = perms[5];
  if p0 != "abc" { io.println("perm-2"); return 20; }
  if p1 != "acb" { io.println("perm-3"); return 21; }
  if p2 != "bac" { io.println("perm-4"); return 22; }
  if p3 != "bca" { io.println("perm-5"); return 23; }
  if p4 != "cab" { io.println("perm-6"); return 24; }
  if p5 != "cba" { io.println("perm-7"); return 25; }
  var pe = combinatorics.str_permutations("");
  if pe.len() != 1 { io.println("perm-8"); return 26; }
  if combinatorics.str_permutations("abcdefghi").len() != 0 { io.println("perm-9"); return 27; }

  var pn2 = combinatorics.str_permutations_n("abc", 2);
  if pn2.len() != 6 { io.println("permn-1"); return 28; }
  if combinatorics.str_permutations_n("abc", 1).len() != 3 { io.println("permn-2"); return 29; }
  if combinatorics.str_permutations_n("abc", 0).len() != 1 { io.println("permn-3"); return 30; }
  if combinatorics.str_permutations_n("abc", 4).len() != 0 { io.println("permn-4"); return 31; }
  if combinatorics.str_permutations_n("abc", -1).len() != 0 { io.println("permn-5"); return 32; }

  // ---- combinations ----
  var combs = combinatorics.str_combinations("abc", 2);
  if combs.len() != 3 { io.println("comb-1"); return 33; }
  var c0 = combs[0];
  var c1 = combs[1];
  var c2 = combs[2];
  if c0 != "ab" { io.println("comb-2"); return 34; }
  if c1 != "ac" { io.println("comb-3"); return 35; }
  if c2 != "bc" { io.println("comb-4"); return 36; }
  if combinatorics.str_combinations("abc", 1).len() != 3 { io.println("comb-5"); return 37; }
  if combinatorics.str_combinations("abc", 0).len() != 0 { io.println("comb-6"); return 38; }
  if combinatorics.str_combinations("abc", 4).len() != 0 { io.println("comb-7"); return 39; }

  // ---- cartesian ----
  var cart = combinatorics.str_cartesian("ab", "12");
  if cart.len() != 4 { io.println("cart-1"); return 40; }
  var q0 = cart[0];
  var q1 = cart[1];
  var q2 = cart[2];
  var q3 = cart[3];
  if q0 != "a1" { io.println("cart-2"); return 41; }
  if q1 != "a2" { io.println("cart-3"); return 42; }
  if q2 != "b1" { io.println("cart-4"); return 43; }
  if q3 != "b2" { io.println("cart-5"); return 44; }
  if combinatorics.str_cartesian("", "12").len() != 0 { io.println("cart-6"); return 45; }

  // ---- interleave ----
  if combinatorics.str_interleave("abc", "123") != "a1b2c3" { io.println("il-1"); return 46; }
  if combinatorics.str_interleave("ab", "wxyz") != "awbxyz" { io.println("il-2"); return 47; }
  if combinatorics.str_interleave("", "xyz") != "xyz" { io.println("il-3"); return 48; }
  if combinatorics.str_interleave("xyz", "") != "xyz" { io.println("il-4"); return 49; }

  // ---- chunk ----
  var chk = combinatorics.str_chunk("abcdef", 2);
  if chk.len() != 3 { io.println("chunk-1"); return 50; }
  var k0 = chk[0];
  var k1 = chk[1];
  var k2 = chk[2];
  if k0 != "ab" { io.println("chunk-2"); return 51; }
  if k1 != "cd" { io.println("chunk-3"); return 52; }
  if k2 != "ef" { io.println("chunk-4"); return 53; }
  if combinatorics.str_chunk("abc", 0).len() != 0 { io.println("chunk-5"); return 54; }

  var cr = combinatorics.str_chunks_reverse("abcde", 2);
  if cr.len() != 3 { io.println("crs-1"); return 55; }
  var r0 = cr[0];
  var r1 = cr[1];
  var r2 = cr[2];
  if r0 != "a" { io.println("crs-2"); return 56; }
  if r1 != "bc" { io.println("crs-3"); return 57; }
  if r2 != "de" { io.println("crs-4"); return 58; }

  var w = combinatorics.str_windows("abcde", 3);
  if w.len() != 3 { io.println("win-1"); return 59; }
  var w0 = w[0];
  var w1 = w[1];
  var w2 = w[2];
  if w0 != "abc" { io.println("win-2"); return 60; }
  if w1 != "bcd" { io.println("win-3"); return 61; }
  if w2 != "cde" { io.println("win-4"); return 62; }
  if combinatorics.str_windows("abc", 5).len() != 0 { io.println("win-5"); return 63; }

  var cb = combinatorics.str_chunk_bytes("abcde", 2);
  if cb.len() != 3 { io.println("cb-1"); return 64; }
  var b0 = cb[0];
  var b1 = cb[1];
  var b2 = cb[2];
  if b0 != "ab" { io.println("cb-2"); return 65; }
  if b1 != "cd" { io.println("cb-3"); return 66; }
  if b2 != "e" { io.println("cb-4"); return 67; }

  // ---- word order ----
  if combinatorics.str_reverse_words("hello world") != "world hello" { io.println("rw-1"); return 68; }
  if combinatorics.str_reverse_words("a  b") != "b  a" { io.println("rw-2"); return 69; }
  if combinatorics.str_reverse_words("") != "" { io.println("rw-3"); return 70; }
  if combinatorics.str_reverse_words("single") != "single" { io.println("rw-4"); return 71; }

  // ---- character statistics ----
  if combinatorics.str_unique_chars("abac") != "abc" { io.println("uc-1"); return 72; }
  if combinatorics.str_unique_chars("") != "" { io.println("uc-2"); return 73; }
  if combinatorics.str_unique_chars("aaaa") != "a" { io.println("uc-3"); return 74; }

  var freqs = combinatorics.str_frequencies("abca");
  if freqs.len() != 3 { io.println("freq-1"); return 75; }
  var f0 = freqs[0];
  var f1 = freqs[1];
  var f2 = freqs[2];
  var fa0 = f0.0;
  var fb0 = f0.1;
  var fa1 = f1.0;
  var fb1 = f1.1;
  var fa2 = f2.0;
  var fb2 = f2.1;
  if fa0 != 'a' || fb0 != 2 { io.println("freq-2"); return 76; }
  if fa1 != 'b' || fb1 != 1 { io.println("freq-3"); return 77; }
  if fa2 != 'c' || fb2 != 1 { io.println("freq-4"); return 78; }

  var mf = combinatorics.str_most_frequent("abca");
  match mf {
    Some(c) => { if c != 'a' { io.println("mf-1"); return 79; } };
    None => { io.println("mf-2"); return 80; };
  }
  var mf2 = combinatorics.str_most_frequent("");
  match mf2 {
    Some(c) => { io.println("mf-3"); return 81; };
    None => {};
  }

  var cset = combinatorics.str_char_set("abac");
  if cset.len() != 3 { io.println("cs-1"); return 82; }
  var e0 = cset[0];
  var e1 = cset[1];
  var e2 = cset[2];
  if e0 != 'a' { io.println("cs-2"); return 83; }
  if e1 != 'b' { io.println("cs-3"); return 84; }
  if e2 != 'c' { io.println("cs-4"); return 85; }

  // ---- permute module ----
  var pperms = permute.str_permutations("abc");
  if pperms.len() != 6 { io.println("pm-1"); return 86; }
  var pp0 = pperms[0];
  if pp0 != "abc" { io.println("pm-2"); return 87; }
  if permute.str_permutations_n("abc", 2).len() != 6 { io.println("pm-3"); return 88; }
  if permute.str_permutation_at("abc", 0) != "abc" { io.println("pm-4"); return 89; }
  if permute.str_permutation_at("abc", 1) != "acb" { io.println("pm-5"); return 90; }
  if permute.str_permutation_at("abc", 2) != "bac" { io.println("pm-6"); return 91; }
  if permute.str_permutation_at("abc", 5) != "cba" { io.println("pm-7"); return 92; }
  if permute.str_permutation_at("abc", 6) != "" { io.println("pm-8"); return 93; }
  if permute.str_permutation_at("abc", -1) != "" { io.println("pm-9"); return 94; }
  if permute.str_permutation_at("", 0) != "" { io.println("pm-10"); return 95; }

  // ---- shuffle module ----
  var rs = shuffle.str_shuffle("abc");
  if rs.len() != 3 { io.println("shf-1"); return 96; }
  if rs != "abc" && rs != "acb" && rs != "bac" && rs != "bca" && rs != "cab" && rs != "cba" { io.println("shf-2"); return 97; }
  var ss1 = shuffle.str_shuffle_seeded("abcd", 11);
  var ss2 = shuffle.str_shuffle_seeded("abcd", 11);
  if ss1 != ss2 { io.println("shf-3"); return 98; }
  var sw = shuffle.str_shuffle_words("a b c");
  if sw != "a b c" && sw != "a c b" && sw != "b a c" && sw != "b c a" && sw != "c a b" && sw != "c b a" { io.println("shf-4"); return 99; }

  io.println("smoke_string_combinatorics: OK");
  return 0;
}
