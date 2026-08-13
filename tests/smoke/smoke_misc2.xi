// XIOM stdlib smoke test - xiom.misc submodules
// glob + levenshtein + natural + semver + soundex
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_misc2
use xiom.misc.glob;
use xiom.misc.levenshtein;
use xiom.misc.natural;
use xiom.misc.semver;
use xiom.misc.soundex;
use xiom.io;

fn main() -> Int {
  // glob
  if !xiom.misc.glob.glob_match("*.xi", "main.xi") { io.println("g1:bad"); return 1; }
  if xiom.misc.glob.glob_match("*.xi", "main.xi.bak") { io.println("g2:bad"); return 2; }
  if !xiom.misc.glob.glob_match("a?c", "abc") { io.println("g3:bad"); return 3; }
  if !glob_match_case_insensitive("*.XI", "main.xi") { io.println("g4:bad"); return 4; }
  if glob_has_magic("abc") { io.println("g5:bad"); return 5; }
  if !glob_has_magic("a*c") { io.println("g6:bad"); return 6; }
  var esc = glob_escape("a*b");
  if glob_unescape(esc) != "a*b" { io.println("g7:bad"); return 7; }
  var tr = glob_translate("a?b");
  if tr.len() != 3 { io.println("g8:bad"); return 8; }
  if glob_quote("x?y") == "x?y" { io.println("g9:bad"); return 9; }

  // levenshtein
  if xiom.misc.levenshtein.levenshtein_distance("kitten", "sitting") != 3 { io.println("l1:bad"); return 10; }
  if xiom.misc.levenshtein.levenshtein_distance("", "abc") != 3 { io.println("l2:bad"); return 11; }
  if xiom.misc.levenshtein.levenshtein_distance("same", "same") != 0 { io.println("l3:bad"); return 12; }
  if levenshtein_distance_limited("kitten", "sitting", 2) != 3 { io.println("l4:bad"); return 13; }
  if levenshtein_distance_limited("kitten", "sitting", 5) != 3 { io.println("l5:bad"); return 14; }
  var sim = levenshtein_similarity("kitten", "kitten");
  if sim != 1.0 { io.println("l6:bad"); return 15; }
  if damerau_levenshtein("ab", "ba") != 1 { io.println("l7:bad"); return 16; }
  if osa_distance("ca", "abc") != 3 { io.println("l8:bad"); return 17; }
  if wagner_fischer("kitten", "sitting") != 3 { io.println("l9:bad"); return 18; }
  var mtx = levenshtein_matrix("ab", "cd");
  if mtx.len() != 3 { io.println("l10:bad"); return 19; }
  var al = levenshtein_align("kitten", "sitting");
  if al.0.len() != al.1.len() { io.println("l11:bad"); return 20; }
  var ops = levenshtein_edit_script("abc", "abc");
  if ops.len() != 3 { io.println("l12:bad"); return 21; }

  // natural
  if xiom.misc.natural.natural_compare("a2", "a10") >= 0 { io.println("n1:bad"); return 30; }
  if xiom.misc.natural.natural_compare("a10", "a2") <= 0 { io.println("n2:bad"); return 31; }
  if xiom.misc.natural.natural_compare("file2", "file2") != 0 { io.println("n3:bad"); return 32; }
  if natural_compare_ignore_case("A2", "a10") >= 0 { io.println("n4:bad"); return 33; }
  var slist = Vec[Str].new();
  slist.push("a10");
  slist.push("a2");
  var sorted = natural_sort(&slist);
  if sorted[0] != "a2" || sorted[1] != "a10" { io.println("n5:bad"); return 34; }
  var desc = natural_sort_desc(&slist);
  if desc[0] != "a10" { io.println("n6:bad"); return 35; }
  if natural_compare_numeric("007", "7") != 0 { io.println("n8:bad"); return 37; }
  if natural_compare_numeric("10", "2") <= 0 { io.println("n9:bad"); return 38; }
  var chunks = natural_chunk("ab12cd");
  if chunks.len() != 3 { io.println("n10:bad"); return 39; }
  var keys = natural_key("ab12");
  if keys.len() != 2 { io.println("n11:bad"); return 40; }
  if natural_is_digit_run("a12b", 0) { io.println("n12:bad"); return 41; }
  if !natural_is_digit_run("a12b", 1) { io.println("n13:bad"); return 42; }

  // semver (parse + compare on SemVer values)
  var p1 = semver_parse("1.2.0");
  var p2 = semver_parse("1.10.0");
  var ok1 = false;
  var ok2 = false;
  match p1 {
    Some(_) => { ok1 = true; },
    None => {},
  }
  match p2 {
    Some(_) => { ok2 = true; },
    None => {},
  }
  if !ok1 || !ok2 { io.println("s1:bad"); return 50; }
  var cmp12 = 0;
  match p1 {
    Some(a) => {
      match p2 {
        Some(b) => {
          cmp12 = xiom.misc.semver.semver_compare(a, b);
        },
        None => { return 50; },
      }
    },
    None => { return 50; },
  }
  if cmp12 >= 0 { io.println("s2:bad"); return 51; }

  if !semver_valid("1.2.3") { io.println("s3:bad"); return 52; }
  if semver_valid("1.2") { io.println("s4:bad"); return 53; }
  if semver_valid("01.2.3") { io.println("s5:bad"); return 54; }
  if !semver_valid("1.2.3-alpha.1") { io.println("s6:bad"); return 55; }

  if !semver_matches("1.5.0", "^1.2.3") { io.println("s7:bad"); return 56; }
  if semver_matches("2.0.0", "^1.2.3") { io.println("s8:bad"); return 57; }
  if !semver_matches("1.2.5", "~1.2.3") { io.println("s9:bad"); return 58; }
  if semver_matches("1.3.0", "~1.2.3") { io.println("s10:bad"); return 59; }
  if !semver_matches("1.2.3", ">=1.0.0 <2.0.0") { io.println("s11:bad"); return 60; }
  if semver_matches("2.5.0", ">=1.0.0 <2.0.0") { io.println("s12:bad"); return 61; }
  if !semver_matches("1.2.9", "1.2.x") { io.println("s13:bad"); return 62; }
  if !semver_satisfies("1.5.0", "1.2.0 - 2.0.0") { io.println("s14:bad"); return 63; }
  if semver_satisfies("2.5.0", "1.2.0 - 2.0.0") { io.println("s15:bad"); return 64; }

  var inc = semver_inc("1.2.3", "minor");
  match inc {
    Some(s) => { if s != "1.3.0" { io.println("s16:bad"); return 65; } },
    None => { io.println("s17:bad"); return 66; },
  }
  var inc2 = semver_inc("1.2.3-alpha", "prerelease");
  match inc2 {
    Some(s) => { if s != "1.2.3-alpha.0" { io.println("s18:bad"); return 67; } },
    None => { io.println("s19:bad"); return 68; },
  }

  var v3 = semver_parse("1.2.3-alpha.1+build.7");
  match v3 {
    Some(sv) => {
      var txt = semver_to_string(sv);
      if txt != "1.2.3-alpha.1+build.7" { io.println("s20:bad"); return 69; }
      var pre = semver_prerelease(sv);
      match pre {
        Some(p) => { if p != "alpha.1" { io.println("s21:bad"); return 70; } },
        None => { io.println("s22:bad"); return 71; },
      }
      var bld = semver_build(sv);
      match bld {
        Some(b) => { if b != "build.7" { io.println("s23:bad"); return 72; } },
        None => { io.println("s24:bad"); return 73; },
      }
      match p1 {
        Some(a) => {
          if !semver_gt(sv, a) { io.println("s25:bad"); return 74; }
          if !semver_lt(a, sv) { io.println("s26:bad"); return 75; }
          match p2 {
            Some(b) => {
              if !semver_caret(a, b) { io.println("s27:bad"); return 76; }
            },
            None => { return 76; },
          }
        },
        None => { return 74; },
      }
      match p1 {
        Some(a) => {
          var tv = semver_parse("1.2.9");
          match tv {
            Some(tv2) => {
              if !semver_tilde(a, tv2) { io.println("s28:bad"); return 77; }
            },
            None => { return 77; },
          }
        },
        None => { return 74; },
      }
    },
    None => { io.println("s29:bad"); return 78; },
  }

  // soundex
  if xiom.misc.soundex.soundex("Robert") != "R163" { io.println("x1:bad"); return 80; }
  if xiom.misc.soundex.soundex("Rupert") != "R163" { io.println("x2:bad"); return 81; }
  if xiom.misc.soundex.soundex("Ashcraft") != "A261" { io.println("x3:bad"); return 82; }
  if xiom.misc.soundex.soundex("Tymczak") != "T522" { io.println("x4:bad"); return 83; }
  if !soundex_compare("Robert", "Rupert") { io.println("x5:bad"); return 84; }
  if soundex_compare("Robert", "Ashcraft") { io.println("x6:bad"); return 85; }
  var sxsim = soundex_similarity("Robert", "Robert");
  if sxsim != 1.0 { io.println("x7:bad"); return 86; }
  if soundex_key("Robert") != "R163" { io.println("x8:bad"); return 87; }
  if soundex_encode("Robert") != "R163" { io.println("x9:bad"); return 88; }
  var vars = soundex_variants("Robert");
  if vars.len() < 1 { io.println("x10:bad"); return 89; }

  io.println("OK");
  return 0;
}
