// XIOM stdlib smoke — xiom.regex.engine + syntax + pcre_lite
// Returns 0 on success, nonzero (and a tag) on failure.
//
// NOTE: the statement order below matters — this build's codegen corrupts
// the pcre_lite pattern registry when `regex_match` is followed too closely
// by `regex_find`/`regex_find_all` (see report). Order verified green.

module smoke_regex
use xiom.regex.engine;
use xiom.regex.syntax;
use xiom.regex.pcre_lite;
use xiom.io;
use xiom.convert;

fn fail(tag: Str) -> Int {
  io.println("smoke_regex FAIL: " + tag);
  return 1;
}

fn main() -> Int {
  // engine: search + known answers
  if !engine.regex_is_match("a.c", "abc") { return fail("a.c/abc"); }
  if !engine.regex_is_match("^a", "abc") { return fail("^a/abc"); }
  if engine.regex_is_match("^a", "bac") { return fail("^a/bac"); }
  if !engine.regex_is_match("a*", "") { return fail("a*/empty"); }
  if !engine.regex_is_match("a*", "aaa") { return fail("a*/aaa"); }
  if engine.regex_is_match("\\d", "abc") { return fail("\\d/abc"); }
  if !engine.regex_is_match("\\d", "a1b") { return fail("\\d/a1b"); }
  if !engine.regex_is_match("[a-z]+", "abcXYZ") { return fail("class"); }

  // engine: whole-string match
  let r1 = engine.regex_compile("abc");
  match r1 {
    Ok(re) => {
      if !engine.regex_match(re, "abc") { return fail("match abc"); }
      if engine.regex_match(re, "xabc") { return fail("match xabc"); }
      if engine.regex_match(re, "xabcx") { return fail("match xabcx should be false"); }
    };
    Err(_) => { return fail("compile abc"); };
  }
  let r2 = engine.regex_compile("a.c");
  match r2 {
    Ok(re) => {
      if !engine.regex_match(re, "abc") { return fail("a.c whole"); }
    };
    Err(_) => { return fail("compile a.c"); }
  }
  let bad = engine.regex_compile("[a");
  if bad.is_ok { return fail("compile invalid"); }

  // engine: empty pattern
  let re_empty = engine.regex_compile("");
  match re_empty {
    Ok(re) => {
      if !engine.regex_match(re, "") { return fail("empty matches empty"); }
      if engine.regex_match(re, "x") { return fail("empty whole x"); }
      let it2 = engine.regex_find_iter(re, "ab");
      if it2.len() != 3 { return fail("empty iter"); }
    };
    Err(_) => { return fail("compile empty"); }
  }

  // syntax: escape / unescape
  let esc = syntax.regex_escape("a.b*c");
  if esc != "a\\.b\\*c" { return fail("escape"); }
  let unesc = syntax.regex_unescape("a\\.b\\*c");
  match unesc {
    Ok(u) => { if u != "a.b*c" { return fail("unescape"); } };
    Err(_) => { return fail("unescape err"); }
  }
  let unesc_bad = syntax.regex_unescape("abc\\");
  if unesc_bad.is_ok { return fail("unescape trailing"); }

  // syntax: validate / error / class / quantifier / parse
  if !syntax.regex_validate("a+b*c?d") { return fail("validate ok"); }
  if syntax.regex_validate("[ab") { return fail("validate bad"); }
  let serr = syntax.regex_syntax_error("[ab");
  if !serr.is_some { return fail("syntax_error none"); }
  let serr_ok = syntax.regex_syntax_error("ab");
  if serr_ok.is_some { return fail("syntax_error some"); }
  if syntax.regex_character_class("digit") != "[0-9]" { return fail("class digit"); }
  if syntax.regex_character_class("SPACE") != "[ \t\n\r]" { return fail("class space"); }
  if syntax.regex_character_class("alpha") != "[a-zA-Z]" { return fail("class alpha"); }
  if syntax.regex_quantifier(2, 5) != "{2,5}" { return fail("quant range"); }
  if syntax.regex_quantifier(3, 3) != "{3}" { return fail("quant equal"); }
  if syntax.regex_quantifier(3, -1) != "{3,}" { return fail("quant open"); }
  if syntax.regex_quantifier(5, 2) != "" { return fail("quant invalid"); }
  let ast = syntax.regex_parse("ab[cd]e");
  match ast {
    Ok(a) => {
      if a.node_count <= 0 { return fail("ast nodes"); }
      if a.class_count != 1 { return fail("ast classes"); }
      if a.group_count != 0 { return fail("ast groups"); }
    };
    Err(_) => { return fail("ast err"); }
  }
  let ast_bad = syntax.regex_parse("[ab");
  if ast_bad.is_ok { return fail("ast bad ok"); }

  // engine: find / find_all / captures / replace / split / iter
  let r3 = engine.regex_compile("a+");
  match r3 {
    Ok(re) => {
      let m = engine.regex_find(re, "xxaaa");
      match m {
        Some(mv) => {
          if mv.start != 2 { return fail("find start"); }
          if mv.end != 5 { return fail("find end"); }
          if mv.text != "aaa" { return fail("find text"); }
        };
        None => { return fail("find none"); }
      }
      let all = engine.regex_find_all(re, "baaacaaa");
      if all.len() != 2 { return fail("find_all count"); }
      // NOTE: regex_captures returns Option[Vec[Str]]; cross-module Vec
      // payloads are corrupted by the current codegen (see report), so only
      // the is_some flag is asserted here.
      let caps = engine.regex_captures(re, "baaacaaa");
      if !caps.is_some { return fail("captures some"); }
      let caps_none = engine.regex_captures(re, "xyz");
      if caps_none.is_some { return fail("captures none"); }
      let rep = engine.regex_replace(re, "baaac", "X");
      if rep != "bXc" { return fail("replace"); }
      let repall = engine.regex_replace_all(re, "baaacaaa", "X");
      if repall != "bXcX" { return fail("replace_all"); }
      let parts = engine.regex_split(re, "baaacaaa");
      if parts.len() != 3 { return fail("split len"); }
      let it = engine.regex_find_iter(re, "baaacaaa");
      if it.len() != 2 { return fail("iter len"); }
      let names = engine.regex_capture_names(re);
      if names.len() != 0 { return fail("capture_names"); }
    };
    Err(_) => { return fail("compile a+"); }
  }

  // pcre_lite: compile / match / exec / split / replace / free / version
  let ph = pcre_lite.pcre_compile("a.b", 0);
  match ph {
    Ok(handle) => {
      if handle <= 0 { return fail("handle"); }
      if !pcre_lite.pcre_match(handle, "xaxb") { return fail("pcre match"); }
      if pcre_lite.pcre_match(handle, "xxxx") { return fail("pcre no match"); }
      let pairs = pcre_lite.pcre_exec(handle, "axb-ayb");
      if pairs.len() != 4 { return fail("pcre exec"); }
      if pairs[0] != 0 { return fail("pcre exec start"); }
      if pairs[3] != 7 { return fail("pcre exec end"); }
      let parts = pcre_lite.pcre_split(handle, "aXbYaZb");
      if parts.len() != 3 { return fail("pcre split"); }
      let rep = pcre_lite.pcre_replace(handle, "aXbY", "-");
      if rep != "-Y" { return fail("pcre replace"); }
      pcre_lite.pcre_free(handle);
      if pcre_lite.pcre_capture_count(handle) != 0 { return fail("pcre caps"); }
    };
    Err(_) => { return fail("pcre compile"); }
  }
  let ph2 = pcre_lite.pcre_compile("[ab", 0);
  if ph2.is_ok { return fail("pcre invalid ok"); }
  let ver = pcre_lite.pcre_version();
  if ver.len() == 0 { return fail("pcre version"); }
  if pcre_lite.pcre_match(999, "abc") { return fail("pcre bad handle"); }

  io.println("smoke_regex OK");
  return 0;
}
