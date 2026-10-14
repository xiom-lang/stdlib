// p_wave134_shapes.xi -- wave 134 lock: the escape family (convert/escape.xi)
// converted to cached-pointer raw reads + single-Vec builders: html/xml/
// csv/tsv/regex/glob/shell/cmd escape+unescape, the entity decoder and the
// private scanners. Byte-exact outputs incl. multibyte passthrough and
// unrecognized-sequence fallbacks. Returns 0 when every case holds.

module p_wave134_shapes

use xiom.string;
use xiom.convert.escape as esc;

fn mk2(a: Int, b: Int) -> Str {
  var v: Vec[UInt8] = Vec[UInt8].new();
  v.push(a as UInt8);
  v.push(b as UInt8);
  Str::from_utf8(v)
}

fn main() -> Int {
  // ---- html ----
  let h1 = esc.html_escape("a<b&c\"d'e");
  if h1 != "a&lt;b&amp;c&quot;d&#39;e" { return 1; }
  let h2 = esc.html_unescape("a&lt;b&amp;c&quot;d&#39;e");
  if h2 != "a<b&c\"d'e" { return 2; }
  let h3 = esc.html_unescape("&#65;&#x41;");
  if h3 != "AA" { return 3; }
  let h4 = esc.html_unescape("&zz;");  // unknown entity: '&'+inner, ';' consumed
  if h4 != "&zz" { return 4; }
  let h4b = esc.html_unescape("&amp");  // no ';': passes through unchanged
  if h4b != "&amp" { return 33; }
  let h5 = esc.html_escape(mk2(0xC3, 0xA9));
  if h5 != mk2(0xC3, 0xA9) { return 5; }
  let h6 = esc.html_escape_attr("<");
  if h6 != "&lt;" { return 6; }

  // ---- xml ----
  let x1 = esc.xml_escape("a\"b'c<d>e&f");
  if x1 != "a&quot;b&apos;c&lt;d&gt;e&amp;f" { return 7; }
  let x2 = esc.xml_unescape("a&quot;b&apos;c&lt;d&gt;e&amp;f");
  if x2 != "a\"b'c<d>e&f" { return 8; }

  // ---- csv ----
  let c1 = esc.csv_escape_field("a,b");
  if c1 != "\"a,b\"" { return 9; }
  let c2 = esc.csv_escape_field("ab");
  if c2 != "ab" { return 10; }
  let c3 = esc.csv_escape_field("a\"b");
  if c3 != "\"a\"\"b\"" { return 11; }
  let c4 = esc.csv_unescape_field("\"a,b\"");
  if c4 != "a,b" { return 12; }
  let c5 = esc.csv_unescape_field("\"a\"\"b\"");
  if c5 != "a\"b" { return 13; }
  let c6 = esc.csv_unescape_field("ab");
  if c6 != "ab" { return 14; }
  let c7 = esc.csv_escape_field("a\nb");
  if c7 != "\"a\nb\"" { return 15; }

  // ---- tsv ----
  let t1 = esc.tsv_escape_field("a\tb\r\nc");
  if t1 != "a\\tb\\r\\nc" { return 16; }
  let t2 = esc.tsv_unescape_field("a\\tb\\r\\nc");
  if t2 != "a\tb\r\nc" { return 17; }
  let t3 = esc.tsv_unescape_field("a\\qb");
  if t3 != "a\\qb" { return 18; }

  // ---- regex / glob ----
  let r1 = esc.regex_escape("a.b*c");
  if r1 != "a\\.b\\*c" { return 19; }
  let g1 = esc.glob_escape("a*b?c[d]");
  if g1 != "a\\*b\\?c\\[d\\]" { return 20; }
  let g2 = esc.glob_unescape("a\\*b\\?c\\[d\\]");
  if g2 != "a*b?c[d]" { return 21; }
  let g3 = esc.glob_unescape("a\\qb");
  if g3 != "a\\qb" { return 22; }

  // ---- shell ----
  let s1 = esc.shell_escape("a b");
  if s1 != "a\\ b" { return 23; }
  let s2 = esc.shell_escape("abc-_.:/");
  if s2 != "abc-_.:/" { return 24; }
  let s3 = esc.shell_quote("a'b");
  if s3 != "'a'\\''b'" { return 25; }
  let s4 = esc.shell_quote("ab");
  if s4 != "'ab'" { return 26; }

  // ---- cmd ----
  let d1 = esc.cmd_escape("a&b|c");
  if d1 != "a^&b^|c" { return 27; }
  let d2 = esc.cmd_escape("ab");
  if d2 != "ab" { return 28; }
  let d3 = esc.cmd_quote("a\"b");
  if d3 != "\"a\"\"b\"" { return 29; }
  let d4 = esc.cmd_quote("ab");
  if d4 != "\"ab\"" { return 30; }

  // ---- unescape multibyte passthrough ----
  let m1 = esc.tsv_unescape_field(mk2(0xC3, 0xA9));
  if m1 != mk2(0xC3, 0xA9) { return 31; }
  let m2 = esc.cmd_quote(mk2(0xC3, 0xA9));
  if m2 != string.str_concat("\"", string.str_concat(mk2(0xC3, 0xA9), "\"")) { return 32; }

  return 0;
}
