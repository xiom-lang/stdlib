// p_wave128_shapes.xi -- wave 128 lock: the strnlen-family batch 4 -- the
// remaining qualified byte_at / char_at accessors in casefold / ea_width /
// emoji / linebreak / compat / cosine / editdistance / lcp / permute /
// strip / template / block / interleave / builder / normalize now read
// through cached raw pointers, and the concat-per-item builders on those
// paths became single-Vec builders (permute pieces, strip scans, interleave
// merges). Byte-exact semantics on every converted path: multibyte,
// malformed and truncated rows included. Values returned from the module
// surface are bound before comparing. Returns 0 when every case holds.

module p_wave128_shapes

use xiom.string;
use xiom.string.casefold;
use xiom.string.ea_width as seaw;
use xiom.string.emoji as semo;
use xiom.string.linebreak as slb;
use xiom.string.compat as scomp;
use xiom.string.cosine as scos;
use xiom.string.editdistance as sed;
use xiom.string.lcp as slcp;
use xiom.string.permute as sperm;
use xiom.string.block as sblk;
use xiom.string.strip as sstrip;
use xiom.string.template as stpl;
use xiom.string.interleave as sil;
use xiom.string.builder as sbuild;
use xiom.string.normalize as snorm;

fn main() -> Int {
  // ---- casefold ----
  let f1 = casefold.str_casefold("AbC");
  if f1 != "abc" { return 1; }
  let f2 = casefold.str_casefold(mk2(0xC3, 0x9F));  // U+00DF -> "ss"
  if f2 != "ss" { return 2; }
  let f3 = casefold.str_casefold_ascii("AbC");
  if f3 != "abc" { return 3; }
  let f4 = casefold.str_casefold_ascii(mk2(0xC3, 0x89));
  if f4 != mk2(0xC3, 0x89) { return 4; }
  let f5 = casefold.str_casefold(mk1(0x80));
  if f5 != mk2(0xC2, 0x80) { return 5; }

  // ---- ea_width ----
  let w1 = seaw.unicode_display_width("abc");
  if w1 != 3 { return 6; }
  let w2 = seaw.unicode_display_width(mk2(0xC3, 0xA9));
  if w2 != 1 { return 7; }

  // ---- emoji ----
  let e1 = semo.unicode_count_emoji("abc");
  if e1 != 0 { return 8; }
  let e2 = semo.unicode_has_emoji("abc");
  if e2 { return 9; }
  let grin = mk4(0xF0, 0x9F, 0x98, 0x80);
  let e3 = semo.unicode_count_emoji(grin);
  if e3 != 1 { return 10; }
  let e4 = semo.unicode_has_emoji(string.str_concat("a", grin));
  if !e4 { return 11; }

  // ---- linebreak ----
  let l1 = slb.unicode_line_break_points("ab\ncd");
  if l1.len() != 1 { return 12; }
  let l1b = l1[0];
  if l1b != 3 { return 13; }
  let l2 = slb.unicode_split_lines("ab\ncd");
  if l2.len() != 2 { return 14; }
  let l2a = l2[0];
  if l2a != "ab\n" { return 15; }

  // ---- compat ----
  let cp1 = scomp.unicode_compatibility_normalize("abc");
  if cp1 != "abc" { return 16; }
  let cp2 = scomp.unicode_decompose("abc");
  if cp2.len() != 3 { return 17; }

  // ---- cosine ----
  let cos1 = scos.cosine_similarity("abc", "abc", 2);
  if !(cos1 > 0.99) { return 18; }

  // ---- editdistance ----
  let ed1 = sed.edit_distance("kitten", "sitting");
  if ed1 != 3 { return 19; }
  let ed2 = sed.edit_distance("abc", "abc");
  if ed2 != 0 { return 20; }
  let ed3 = sed.edit_distance_limited("kitten", "sitting", 2);  // min(exact, max)
  if ed3 != 2 { return 21; }
  let ed4 = sed.edit_distance_limited("abc", "axc", 2);
  if ed4 != 1 { return 22; }
  let ed5 = sed.edit_distance_limited("abc", "xyz", 2);
  if ed5 != 2 { return 49; }

  // ---- lcp ----
  let lc1 = slcp.longest_common_prefix("abc", "abd");
  if lc1 != 2 { return 23; }
  var many = Vec[Str].new();
  many.push("abc");
  many.push("abd");
  many.push("abe");
  let lc2 = slcp.lcp_of_many(&many);
  if lc2 != 2 { return 24; }

  // ---- permute ----
  let pm1 = sperm.str_permutations("ab");
  if pm1.len() != 2 { return 25; }
  let pm2 = sperm.str_permutation_at("abc", 0);
  if pm2.len() != 3 { return 26; }
  let pm3 = sperm.str_permutations_n("abc", 2);
  if pm3.len() != 6 { return 27; }

  // ---- block ----
  let bl1 = sblk.unicode_block_name("41");
  if bl1 != "Basic Latin" { return 28; }
  let bl2 = sblk.unicode_block_name("U+41");
  if bl2 != "Basic Latin" { return 29; }
  let bl3 = sblk.unicode_block_name("zz");
  if bl3 != "Undefined" { return 30; }
  let bl4 = sblk.unicode_block('A');
  if bl4 != "Basic Latin" { return 31; }

  // ---- strip ----
  let st1 = sstrip.str_strip_whitespace(" a\tb\nc ");
  if st1 != "abc" { return 32; }
  let st2 = sstrip.str_strip_whitespace(string.str_concat(mk2(0xC3, 0xA9), " a"));
  if st2 != string.str_concat(mk2(0xC3, 0xA9), "a") { return 33; }
  let st3 = sstrip.str_strip_control(string.str_concat("a", string.str_concat(mk1(0x01), "b")));
  if st3 != "ab" { return 34; }
  let st4 = sstrip.str_strip_control("abc");
  if st4 != "abc" { return 35; }

  // ---- template ----
  let t1 = stpl.template_escape("a{b}c");
  if t1 != "a\\{b\\}c" { return 36; }
  let t2 = stpl.template_unescape("a\\{b\\}c");
  if t2 != "a{b}c" { return 37; }
  let t3 = stpl.template_placeholder_count("x {{a}} y {{b}}");
  if t3 != 2 { return 38; }
  let t4 = stpl.template_has_placeholders("x {{a}}");
  if !t4 { return 39; }

  // ---- interleave ----
  let il1 = sil.str_interleave("abc", "xy");
  if il1 != "axbyc" { return 40; }
  let il2 = sil.str_interleave("", "ab");
  if il2 != "ab" { return 41; }
  let il3 = sil.str_interleave(mk2(0xC3, 0xA9), "ab");
  if il3 != string.str_concat(mk2(0xC3, 0xA9), "ab") { return 42; }
  var parts = Vec[Str].new();
  parts.push("ab");
  parts.push("cd");
  let il4 = sil.str_interleave_n(&parts, "-");
  if il4 != "a-c-b-d" { return 43; }
  var none = Vec[Str].new();
  let il5 = sil.str_interleave_n(&none, "-");
  if il5 != "" { return 44; }

  // ---- builder ----
  var sb: Vec[UInt8] = sbuild.sb_new();
  sbuild.sb_push_str(&mut sb, string.str_concat("a", mk2(0xC3, 0xA9)));
  let sb1 = Str::from_utf8(sb);
  if sb1 != string.str_concat("a", mk2(0xC3, 0xA9)) { return 45; }

  // ---- normalize ----
  let nm1 = snorm.str_normalize_ascii("cafe");
  if nm1 != "cafe" { return 46; }
  let nm2 = snorm.unicode_normalize_nfc("abc");
  if nm2 != "abc" { return 47; }
  let nm3 = snorm.unicode_normalize_nfd(mk2(0xC3, 0xA9));  // e + combining acute
  if nm3 != mk3(0x65, 0xCC, 0x81) { return 48; }

  return 0;
}

// mk1 builds a 1-byte string from a raw byte value.
fn mk1(a: Int) -> Str {
  var v: Vec[UInt8] = Vec[UInt8].new();
  v.push(a as UInt8);
  Str::from_utf8(v)
}

// mk2 builds a 2-byte string from raw byte values.
fn mk2(a: Int, b: Int) -> Str {
  var v: Vec[UInt8] = Vec[UInt8].new();
  v.push(a as UInt8);
  v.push(b as UInt8);
  Str::from_utf8(v)
}

// mk3 builds a 3-byte string from raw byte values.
fn mk3(a: Int, b: Int, c: Int) -> Str {
  var v: Vec[UInt8] = Vec[UInt8].new();
  v.push(a as UInt8);
  v.push(b as UInt8);
  v.push(c as UInt8);
  Str::from_utf8(v)
}

// mk4 builds a 4-byte string from raw byte values.
fn mk4(a: Int, b: Int, c: Int, d: Int) -> Str {
  var v: Vec[UInt8] = Vec[UInt8].new();
  v.push(a as UInt8);
  v.push(b as UInt8);
  v.push(c as UInt8);
  v.push(d as UInt8);
  Str::from_utf8(v)
}
