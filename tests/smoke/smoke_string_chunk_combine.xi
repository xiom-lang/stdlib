module smoke_string_chunk_combine
use xiom.string.chunk;
use xiom.string.combine;
use xiom.string.interleave;
use xiom.io;

fn main() -> Int {
  // ---- chunk ----
  var ch = chunk.str_chunk("abcdef", 2);
  if ch.len() != 3 { io.println("chunk-1"); return 1; }
  var x0 = ch[0];
  var x1 = ch[1];
  var x2 = ch[2];
  if x0 != "ab" { io.println("chunk-2"); return 2; }
  if x1 != "cd" { io.println("chunk-3"); return 3; }
  if x2 != "ef" { io.println("chunk-4"); return 4; }

  var ch2 = chunk.str_chunk("abcde", 2);
  if ch2.len() != 3 { io.println("chunk-5"); return 5; }
  var y0 = ch2[0];
  var y1 = ch2[1];
  var y2 = ch2[2];
  if y0 != "ab" { io.println("chunk-6"); return 6; }
  if y1 != "cd" { io.println("chunk-7"); return 7; }
  if y2 != "e" { io.println("chunk-8"); return 8; }

  if chunk.str_chunk("abc", 0).len() != 0 { io.println("chunk-9"); return 9; }
  if chunk.str_chunk("abc", -1).len() != 0 { io.println("chunk-10"); return 10; }
  if chunk.str_chunk("", 2).len() != 0 { io.println("chunk-11"); return 11; }

  // ---- chunks_reverse ----
  var cr = chunk.str_chunks_reverse("abcde", 2);
  if cr.len() != 3 { io.println("crs-1"); return 15; }
  var r0 = cr[0];
  var r1 = cr[1];
  var r2 = cr[2];
  if r0 != "a" { io.println("crs-2"); return 16; }
  if r1 != "bc" { io.println("crs-3"); return 17; }
  if r2 != "de" { io.println("crs-4"); return 18; }
  var cr2 = chunk.str_chunks_reverse("abcdef", 2);
  if cr2.len() != 3 { io.println("crs-5"); return 19; }
  var s0 = cr2[0];
  var s1 = cr2[1];
  var s2 = cr2[2];
  if s0 != "ab" { io.println("crs-6"); return 20; }
  if s1 != "cd" { io.println("crs-7"); return 21; }
  if s2 != "ef" { io.println("crs-8"); return 22; }

  // ---- windows ----
  var w = chunk.str_windows("abcde", 3);
  if w.len() != 3 { io.println("win-1"); return 25; }
  var w0 = w[0];
  var w1 = w[1];
  var w2 = w[2];
  if w0 != "abc" { io.println("win-2"); return 26; }
  if w1 != "bcd" { io.println("win-3"); return 27; }
  if w2 != "cde" { io.println("win-4"); return 28; }
  if chunk.str_windows("abc", 5).len() != 0 { io.println("win-5"); return 29; }
  if chunk.str_windows("abc", 0).len() != 0 { io.println("win-6"); return 30; }

  // ---- combine: combinations ----
  var cb = combine.str_combinations("abc", 2);
  if cb.len() != 3 { io.println("cob-1"); return 35; }
  var b0 = cb[0];
  var b1 = cb[1];
  var b2 = cb[2];
  if b0 != "ab" { io.println("cob-2"); return 36; }
  if b1 != "ac" { io.println("cob-3"); return 37; }
  if b2 != "bc" { io.println("cob-4"); return 38; }
  var cb1 = combine.str_combinations("abc", 1);
  if cb1.len() != 3 { io.println("cob-5"); return 39; }
  var c0 = cb1[0];
  var c1 = cb1[1];
  var c2 = cb1[2];
  if c0 != "a" { io.println("cob-6"); return 40; }
  if c1 != "b" { io.println("cob-7"); return 41; }
  if c2 != "c" { io.println("cob-8"); return 42; }
  if combine.str_combinations("abc", 4).len() != 0 { io.println("cob-9"); return 43; }
  if combine.str_combinations("abc", 0).len() != 0 { io.println("cob-10"); return 44; }

  // ---- combine: combination_at ----
  if combine.str_combination_at("abc", 2, 0) != "ab" { io.println("cat-1"); return 48; }
  if combine.str_combination_at("abc", 2, 1) != "ac" { io.println("cat-2"); return 49; }
  if combine.str_combination_at("abc", 2, 2) != "bc" { io.println("cat-3"); return 50; }
  if combine.str_combination_at("abc", 2, 3) != "" { io.println("cat-4"); return 51; }
  if combine.str_combination_at("abc", 4, 0) != "" { io.println("cat-5"); return 52; }
  if combine.str_combination_at("abc", 2, -1) != "" { io.println("cat-6"); return 53; }

  // ---- interleave ----
  if interleave.str_interleave("abc", "123") != "a1b2c3" { io.println("il-1"); return 58; }
  if interleave.str_interleave("ab", "wxyz") != "awbxyz" { io.println("il-2"); return 59; }
  if interleave.str_interleave("", "xyz") != "xyz" { io.println("il-3"); return 60; }
  if interleave.str_interleave("xyz", "") != "xyz" { io.println("il-4"); return 61; }
  if interleave.str_interleave("", "") != "" { io.println("il-5"); return 62; }

  // ---- interleave_n ----
  var parts = Vec[Str].new();
  parts.push("ab");
  parts.push("cd");
  if interleave.str_interleave_n(&parts, ",") != "a,c,b,d" { io.println("iln-1"); return 66; }
  var parts2 = Vec[Str].new();
  parts2.push("abc");
  parts2.push("12");
  if interleave.str_interleave_n(&parts2, "") != "a1b2c" { io.println("iln-2"); return 67; }
  var parts3 = Vec[Str].new();
  if interleave.str_interleave_n(&parts3, ",") != "" { io.println("iln-3"); return 68; }
  var parts4 = Vec[Str].new();
  parts4.push("x");
  if interleave.str_interleave_n(&parts4, "-") != "x" { io.println("iln-4"); return 69; }

  io.println("smoke_string_chunk_combine: OK");
  return 0;
}
