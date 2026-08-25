// smoke_string_search.xi -- allocation-free search predicates
// Locks the round-14 byte_at semantics through index_of / last_index_of /
// str_contains / starts_with / ends_with after the phase-E2 rewrite
// (these used to malloc a slice per candidate position).
module smoke_string_search
use xiom.string;
use xiom.io;

fn main() -> Int {
  var s = "hello world hello";

  // ---- index_of ----
  match index_of(s, "world") {
    Some(i) => { if i != 6 { io.println("iof:world"); return 1; } }
    None => { io.println("iof:world-miss"); return 2; }
  }
  match index_of(s, "hello") {
    Some(i) => { if i != 0 { io.println("iof:first"); return 3; } }
    None => { io.println("iof:first-miss"); return 4; }
  }
  match index_of(s, "xyz") {
    Some(_) => { io.println("iof:false-hit"); return 5; }
    None => {}
  }
  // needle longer than haystack
  match index_of("ab", "abcdef") {
    Some(_) => { io.println("iof:long-hit"); return 6; }
    None => {}
  }

  // ---- last_index_of ----
  match last_index_of(s, "hello") {
    Some(i) => { if i != 12 { io.println("lio:12"); return 7; } }
    None => { io.println("lio:miss"); return 8; }
  }
  match last_index_of(s, "xyz") {
    Some(_) => { io.println("lio:false-hit"); return 9; }
    None => {}
  }

  // ---- contains ----
  if !str_contains(s, "o w") { io.println("contains:o w"); return 10; }
  if str_contains(s, "o-w") { io.println("contains:false"); return 11; }

  // ---- starts_with / ends_with ----
  if !str_starts_with(s, "hello") { io.println("sw:yes"); return 12; }
  if str_starts_with(s, "world") { io.println("sw:no"); return 13; }
  if !str_ends_with(s, "hello") { io.println("ew:yes"); return 14; }
  if str_ends_with(s, "world") { io.println("ew:no"); return 15; }
  if !str_starts_with(s, "") { io.println("sw:empty"); return 16; }
  if !str_ends_with(s, "") { io.println("ew:empty"); return 17; }
  if str_starts_with("", "x") { io.println("sw:empty-hay"); return 18; }

  // ---- multibyte boundaries ----
  var m = "a\u{00E9}b\u{00E9}c";
  match index_of(m, "\u{00E9}b") {
    Some(i) => {
      // e-acute is bytes 1-2; the match starts at byte 1
      if i != 1 { io.println("iof:mb"); return 19; }
    }
    None => { io.println("iof:mb-miss"); return 20; }
  }
  if !str_starts_with(m, "a\u{00E9}") { io.println("sw:mb"); return 21; }
  if !str_ends_with(m, "c") { io.println("ew:mb"); return 22; }

  io.println("OK");
  return 0;
}
