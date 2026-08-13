// XIOM stdlib smoke — xiom.text.diff + transliterate
// Returns 0 on success, nonzero (and a tag) on failure.

module smoke_text2
use xiom.text.diff;
use xiom.text.transliterate;
use xiom.io;
use xiom.convert;
use xiom.string;

fn fail(tag: Str) -> Int {
  io.println("smoke_text2 FAIL: " + tag);
  return 1;
}

fn main() -> Int {
  // transliterate: known answers
  if transliterate.transliterate("café") != "cafe" { return fail("t-cafe"); }
  if transliterate.transliterate_accented("café") != "cafe" { return fail("t-accent"); }
  if transliterate.transliterate_accented("àéîöü") != "aeiou" { return fail("t-accent2"); }
  if transliterate.transliterate_cyrillic("Привет") != "Privet" { return fail("t-cyr"); }
  if transliterate.transliterate_cyrillic("мир") != "mir" { return fail("t-cyr2"); }
  if transliterate.transliterate_greek("Αθήνα") != "athina" { return fail("t-greek"); }
  if transliterate.transliterate_to_ascii("Привет") != "Privet" { return fail("t-ascii-cyr"); }
  if transliterate.transliterate_to_ascii("café") != "cafe" { return fail("t-ascii-cafe"); }
  if transliterate.transliterate("Привет") != "Privet" { return fail("t-main"); }
  if transliterate.transliterate("ABC") != "ABC" { return fail("t-ascii-pass"); }
  var table = Vec[(Char, Str)].new();
  let xch = convert.int_to_char(20320);
  match xch {
    Some(ch) => {
      table.push((ch, "ni"));
    };
    None => { return fail("t-custom-char"); }
  }
  let cust = transliterate.transliterate_custom("你好", &table);
  if cust != "ni好" { return fail("t-custom"); }

  // diff: word-level / lines / patch+apply / unified / similarity / ratio
  let wops = diff.diff_word_level("kitten", "sitting");
  if wops.len() != 2 { return fail("d-word-len"); }
  let w0k = diff.diffop_kind_at(&wops, 0);
  let w1k = diff.diffop_kind_at(&wops, 1);
  let w0t = diff.diffop_text_at(&wops, 0);
  let w1t = diff.diffop_text_at(&wops, 1);
  if (w0k != "ins" && w0k != "del") { return fail("d-word-kind0"); }
  if (w1k != "ins" && w1k != "del") { return fail("d-word-kind1"); }
  if w0k == w1k { return fail("d-word-kinds-eq"); }
  if w0t != "sitting" && w0t != "kitten" { return fail("d-word-text0"); }
  if w1t != "kitten" && w1t != "sitting" { return fail("d-word-text1"); }
  if w0t == w1t { return fail("d-word-same"); }

  let lops = diff.diff_myers_lines("a\nb", "a\nc");
  if lops.len() != 3 { return fail("d-lines-len"); }
  if diff.diffop_kind_at(&lops, 0) != "eq" && diff.diffop_kind_at(&lops, 2) != "eq" { return fail("d-lines-eq"); }

  let patch = diff.diff_patch("a\nb", "a\nc");
  if patch.len() == 0 { return fail("d-patch-empty"); }
  let applied = diff.diff_apply("a\nb", patch);
  match applied {
    Ok(res) => {
      if res != "a\nc" { return fail("d-apply-result"); }
    };
    Err(_) => { return fail("d-apply-err"); }
  }
  let bad_apply = diff.diff_apply("x", patch);
  if bad_apply.is_ok { return fail("d-apply-bad"); }

  let uni = diff.diff_unified("a\nb", "a\nc", 3);
  if !string.str_contains(uni, "@@") { return fail("d-unified"); }
  if !string.str_contains(uni, "-b") { return fail("d-unified-del"); }
  if !string.str_contains(uni, "+c") { return fail("d-unified-ins"); }

  let sim = diff.diff_similarity("kitten", "sitting");
  if !(sim > 0.55 && sim < 0.6) { return fail("d-sim"); }
  let ratio = diff.diff_ratio("kitten", "sitting");
  if !(ratio > 0.6 && ratio < 0.65) { return fail("d-ratio"); }
  if diff.diff_ratio("abc", "abc") < 0.999 { return fail("d-ratio-eq"); }

  var ba = Vec[UInt8].new();
  ba.push(65);
  ba.push(66);
  ba.push(67);
  var bb = Vec[UInt8].new();
  bb.push(65);
  bb.push(68);
  bb.push(67);
  let bops = diff.diff_byte_level(&ba, &bb);
  if bops.len() != 4 { return fail("d-byte-len"); }

  io.println("smoke_text2 OK");
  return 0;
}
