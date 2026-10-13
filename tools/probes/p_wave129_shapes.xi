// p_wave129_shapes.xi -- wave 129 lock: the str_slice core fast path --
// str_slice itself keeps its exact clamping semantics (OOB rows), while the
// hot per-part / per-character call sites (str_split, words, case
// _split_words, segment _split_chars, shuffle _sh_split, sentence/word
// splits, combinatorics splits/chunks/windows/reverse-words/joins, unicode
// combining sequences, builder sb_push_str) now use a bounds-guaranteed
// _slice_fast and raw reads. Also re-locks the combinatorics catch-up
// (its _byte body) with byte-exact outputs. Returns 0 when every case holds.

module p_wave129_shapes

use xiom.string;
use xiom.string.case as scase;
use xiom.string.segment as sseg;
use xiom.string.shuffle as ssh;
use xiom.string.sentencebreak as ssb;
use xiom.string.wordbreak as swb;
use xiom.string.combinatorics as scomb;
use xiom.string.builder as sbuild;

fn main() -> Int {
  // ---- str_slice keeps its exact clamp semantics (unchanged core) ----
  let s1 = string.str_slice("abc", 1, 3);
  if s1 != "bc" { return 1; }
  let s2 = string.str_slice("abc", 10, 12);  // start past len -> ""
  if s2 != "" { return 2; }
  let s3 = string.str_slice("abc", 0, 10);   // end past len -> clamped
  if s3 != "abc" { return 3; }
  let s4 = string.str_slice("abc", 0 - 2, 2);  // negative start -> 0
  if s4 != "ab" { return 4; }
  let s5 = string.str_slice("abc", 2, 2);    // empty range
  if s5 != "" { return 5; }
  let s6 = string.str_slice("", 0, 5);
  if s6 != "" { return 6; }

  // ---- fast-slice call sites: identical outputs ----
  let sp = string.str_split("a,b,c", ",");
  if sp.len() != 3 { return 7; }
  let spb = sp[1];
  if spb != "b" { return 8; }
  let sp2 = string.str_split(",x,", ",");
  if sp2.len() != 3 { return 9; }
  let sp2a = sp2[0];
  if sp2a != "" { return 10; }
  let wd = string.words(" a b ");
  if wd.len() != 2 { return 11; }
  let wda = wd[0];
  if wda != "a" { return 12; }
  let cs = scase.str_to_snake_case("helloWorld");
  if cs != "hello_world" { return 13; }
  let gc = sseg.unicode_grapheme_clusters("abc");
  if gc.len() != 3 { return 14; }
  let sh = ssh.str_shuffle_seeded("abcd", 7);
  if sh.len() != 4 { return 15; }
  if !string.str_contains(sh, "d") { return 16; }
  let sb1 = ssb.unicode_split_sentences("One. Two");
  if sb1.len() != 2 { return 17; }
  let sb1a = sb1[0];
  if sb1a != "One. " { return 18; }
  let wb1 = swb.unicode_split_words("Hello,world");
  if wb1.len() != 3 { return 19; }
  let wb1b = wb1[1];
  if wb1b != "," { return 20; }

  // ---- combinatorics catch-up (decoder + slices + joins + builders) ----
  let ch = scomb.str_chunk("abcdef", 2);
  if ch.len() != 3 { return 21; }
  let cha = ch[0];
  if cha != "ab" { return 22; }
  let chc = ch[2];
  if chc != "ef" { return 23; }
  let chr = scomb.str_chunks_reverse("abcde", 2);
  if chr.len() != 3 { return 24; }
  let chr0 = chr[0];
  if chr0 != "a" { return 25; }
  let win = scomb.str_windows("abc", 2);
  if win.len() != 2 { return 26; }
  let winb = win[1];
  if winb != "bc" { return 27; }
  let rw = scomb.str_reverse_words("a b  c");
  if rw != "c  b a" { return 28; }
  let rot = scomb.str_rotate("abcde", 2);
  if rot != "deabc" { return 29; }
  let ro2 = scomb.str_rotate_left("abcde", 2);
  if ro2 != "cdeab" { return 30; }
  let cc = string.str_caesar("abz", 1);
  if cc != "bca" { return 31; }

  // ---- builder ----
  var sbv: Vec[UInt8] = sbuild.sb_new();
  sbuild.sb_push_str(&mut sbv, "ab");
  sbuild.sb_push_byte(&mut sbv, 99);
  let bs = Str::from_utf8(sbv);
  if bs != "abc" { return 32; }

  // ---- strip (mask-fix lock, from wave 128) ----
  let st = string.str_trim("  x  ");
  if st != "x" { return 33; }

  return 0;
}
