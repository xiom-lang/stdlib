// smoke_misc_soundex_parity.xi -- locks the consolidated soundex surface
// (misc.soundex -> text.similarity delegation, 2026-09-10).
// 1. All three public paths agree on the classic vectors.
// 2. Canonical empty-string semantics across all paths ("" not "0000").
// 3. Extended surface: compare / encode / key / similarity / variants.
module smoke_misc_soundex_parity
use xiom.text.similarity;
use xiom.io;
use xiom.convert;

fn chk_vec(m: Str, want: Str) -> Int {
  // m: misc path, s: string path, t: canonical
  var via_misc = xiom.misc.soundex.soundex(m);
  var via_string = xiom.string.soundex.soundex(m);
  var via_canon = similarity.soundex(m);
  if via_misc != want { io.println("misc:" + m); return 1; }
  if via_string != want { io.println("string:" + m); return 2; }
  if via_canon != want { io.println("canon:" + m); return 3; }
  return 0;
}

fn main() -> Int {
  var r = chk_vec("Robert", "R163");
  if r != 0 { return 10 + r; }
  r = chk_vec("Rupert", "R163");
  if r != 0 { return 20 + r; }
  r = chk_vec("Ashcraft", "A261");
  if r != 0 { return 30 + r; }
  r = chk_vec("Tymczak", "T522");
  if r != 0 { return 40 + r; }
  r = chk_vec("Pfister", "P236");
  if r != 0 { return 50 + r; }
  r = chk_vec("", "");
  if r != 0 { return 60 + r; }

  // extended surface (misc path)
  if !xiom.misc.soundex.soundex_compare("Robert", "Rupert") { io.println("compare"); return 70; }
  if xiom.misc.soundex.soundex_compare("Robert", "Tymczak") { io.println("compare2"); return 71; }
  if xiom.misc.soundex.soundex_encode("Robert") != "R163" { io.println("encode"); return 72; }
  if xiom.misc.soundex.soundex_key("Ashcraft") != "A261" { io.println("key"); return 73; }

  var sim_same = xiom.misc.soundex.soundex_similarity("Robert", "Rupert");
  if sim_same != 1.0 { io.println("sim-same"); return 74; }
  var sim_empty = xiom.misc.soundex.soundex_similarity("", "");
  if sim_empty != 1.0 { io.println("sim-empty"); return 75; }
  var sim_one = xiom.misc.soundex.soundex_similarity("", "Robert");
  if sim_one != 0.0 { io.println("sim-one"); return 76; }

  var vs = xiom.misc.soundex.soundex_variants("Robert");
  if vs.len() != 2 { io.println("variants-len"); return 77; }
  if vs[0] != "R163" { io.println("variants-first"); return 78; }
  if vs[1].len() != 4 { io.println("variants-second"); return 79; }
  var vs_empty = xiom.misc.soundex.soundex_variants("");
  if vs_empty.len() != 2 { io.println("variants-empty-len"); return 80; }

  io.println("OK");
  return 0;
}
