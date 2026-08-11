module smoke_string_split_join
use xiom.string.split;
use xiom.string.join;
use xiom.io;

fn main() -> Int {
  var p = split.str_split("a,b,c", ",");
  if p.len() != 3 { io.println("split len"); return 1; }
  var e0 = p[0];
  var e1 = p[1];
  var e2 = p[2];
  if e0 != "a" { io.println("split[0]"); return 2; }
  if e1 != "b" { io.println("split[1]"); return 3; }
  if e2 != "c" { io.println("split[2]"); return 4; }

  var pn = split.str_split_n("a,b,c", ",", 2);
  if pn.len() != 2 { io.println("split_n len"); return 5; }
  var n0 = pn[0];
  var n1 = pn[1];
  if n0 != "a" { io.println("split_n[0]"); return 6; }
  if n1 != "b,c" { io.println("split_n[1]"); return 7; }

  let (ob, oa) = split.str_split_once("a,b,c", ",");
  if ob != "a" { io.println("split_once before"); return 8; }
  if oa != "b,c" { io.println("split_once after"); return 9; }
  let (nb, na) = split.str_split_once("abc", ",");
  if nb != "abc" { io.println("split_once no delim before"); return 10; }
  if na != "" { io.println("split_once no delim after"); return 11; }

  var ln = split.str_lines("a\nb\nc");
  if ln.len() != 3 { io.println("lines len"); return 12; }
  var l0 = ln[0];
  if l0 != "a" { io.println("lines[0]"); return 13; }

  var w = split.str_words("a b  c");
  if w.len() != 3 { io.println("words len"); return 14; }

  var rp = split.str_rsplit("a,b,c", ",");
  if rp.len() != 3 { io.println("rsplit len"); return 15; }
  var r0 = rp[0];
  var r1 = rp[1];
  var r2 = rp[2];
  if r0 != "a" { io.println("rsplit[0]"); return 16; }
  if r1 != "b" { io.println("rsplit[1]"); return 17; }
  if r2 != "c" { io.println("rsplit[2]"); return 18; }

  var delims = Vec[Str].new();
  delims.push(",");
  delims.push(";");
  var pa = split.str_split_any("a;b,c", &delims);
  if pa.len() != 3 { io.println("split_any len"); return 19; }
  var a0 = pa[0];
  var a1 = pa[1];
  var a2 = pa[2];
  if a0 != "a" { io.println("split_any[0]"); return 20; }
  if a1 != "b" { io.println("split_any[1]"); return 21; }
  if a2 != "c" { io.println("split_any[2]"); return 22; }

  var jv = Vec[Str].new();
  jv.push("a");
  jv.push("b");
  var joined = join.str_join(&jv, "-");
  if joined != "a-b" { io.println("join"); return 23; }
  var je = Vec[Str].new();
  var joined_empty = join.str_join(&je, ",");
  if joined_empty != "" { io.println("join empty"); return 24; }

  var ja = Vec[Str].new();
  ja.push("a");
  ja.push("b");
  ja.push("c");
  ja.push("d");
  var joined_after = join.str_join_after(&ja, ",", 2);
  if joined_after != "ab,cd" { io.println("join_after"); return 25; }

  var iv = Vec[Int].new();
  iv.push(1);
  iv.push(2);
  iv.push(3);
  var int_joined = join.vec_int_join(&iv, "-");
  if int_joined != "1-2-3" { io.println("int join"); return 26; }

  var fv = Vec[Float64].new();
  fv.push(1.5);
  fv.push(2.5);
  var float_joined = join.vec_float_join(&fv, ";");
  if float_joined != "1.5;2.5" { io.println("float join"); return 27; }

  io.println("smoke_string_split_join: OK");
  return 0;
}
