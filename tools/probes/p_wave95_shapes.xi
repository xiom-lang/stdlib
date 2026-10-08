// p_wave95_shapes.xi -- wave 95 shape validation: markup + textual + fmt
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-95 clause guards:
//   (a) xiom.format.markup: the wrapper length claims (bold/italic/code/
//       strike len+2, link text+url+4), the escape empty/expansion bands,
//       the parse empty-Ok and unclosed-Err guards, the empty render/
//       strip identities and the parse_inline empty identity;
//   (b) xiom.format.textual: the box/border exact byte lengths (plain and
//       3-byte box characters), separator widths, header/title/section
//       length claims, section_number, the list empty identities, toc/
//       toc_indent bounds, text_wrap_center/text_justify empty claims and
//       the textual text_columns empty identity;
//   (c) xiom.format.fmt: the to_str zero pins, format1/2/3 no-placeholder
//       identity, the empty/degenerate guards on table/columns/wrap/indent/
//       hexdump/join, the pad-number and repeat width bands, float_fixed
//       negative-decimals pin, format_bool/line/align claims and the
//       sprintf/sscanf empty-spec Ok pins (plus a sscanf mismatch Err).
// Values returned from the module surface are bound before comparing.
// Returns 0 when every case holds.

module p_wave95_shapes

use xiom.format.markup;
use xiom.format.textual;
use xiom.format.fmt;

fn main() -> Int {
  // ---- markup: escape
  let me0 = markup.markup_escape("");
  if me0.len() != 0 { return 1; }
  let me1 = markup.markup_escape("a*b");
  if me1.len() < 3 { return 2; }
  if me1.len() != 4 { return 3; }

  // ---- markup: wrappers
  let mb0 = markup.markup_bold("x");
  if mb0.len() != 3 { return 4; }
  let mb1 = markup.markup_bold("");
  if mb1.len() != 2 { return 5; }
  let mi0 = markup.markup_italic("x");
  if mi0.len() != 3 { return 6; }
  let mc0 = markup.markup_code("x");
  if mc0.len() != 3 { return 7; }
  let ms0 = markup.markup_strike("x");
  if ms0.len() != 3 { return 8; }
  let ml0 = markup.markup_link("x", "y");
  if ml0.len() != 6 { return 9; }
  let ml1 = markup.markup_link("", "");
  if ml1.len() != 4 { return 10; }

  // ---- markup: parse / inline
  let mp0 = markup.markup_parse("");
  if mp0.is_ok == false { return 11; }
  let mp1 = markup.markup_parse("*x");
  if mp1.is_err == false { return 12; }
  let mp2 = markup.markup_parse("*x*");
  if mp2.is_ok == false { return 13; }
  let mpi0 = markup.markup_parse_inline("");
  if mpi0.len() != 0 { return 14; }

  // ---- markup: render / strip
  var nm = Vec[MarkupNode].new();
  let mr0 = markup.markup_render(&nm);
  if mr0.len() != 0 { return 15; }
  let mra0 = markup.markup_render_ansi(&nm);
  if mra0.len() != 0 { return 16; }
  let mrh0 = markup.markup_render_html(&nm);
  if mrh0.len() != 0 { return 17; }
  let mrp0 = markup.markup_render_plain(&nm);
  if mrp0.len() != 0 { return 18; }
  let mst0 = markup.markup_strip("");
  if mst0.len() != 0 { return 19; }
  let mst1 = markup.markup_strip("*x*");
  if mst1 != "x" { return 20; }

  // ---- textual: boxes
  var be = Vec[Str].new();
  let bx0 = textual.box_around(&be, 10);
  if bx0.len() != 21 { return 21; }
  let bx1 = textual.box_rounded(&be, 10);
  if bx1.len() != 61 { return 22; }
  let bx2 = textual.box_double(&be, 10);
  if bx2.len() != 61 { return 23; }

  // ---- textual: borders / separators
  let bt0 = textual.border_top(10, 0);
  if bt0.len() != 10 { return 24; }
  let bt1 = textual.border_top(10, 1);
  if bt1.len() != 30 { return 25; }
  let bt2 = textual.border_top(10, 2);
  if bt2.len() != 30 { return 26; }
  let bb0 = textual.border_bottom(10, 0);
  if bb0.len() != 10 { return 27; }
  let bb1 = textual.border_bottom(10, 2);
  if bb1.len() != 30 { return 28; }
  let sl0 = textual.separator_line('=', 5);
  if sl0.len() != 5 { return 29; }
  let sl1 = textual.separator_line('=', -1);
  if sl1.len() != 0 { return 30; }
  let sd0 = textual.separator_double(5);
  if sd0.len() != 15 { return 31; }
  let sd1 = textual.separator_dashed(5);
  if sd1.len() != 5 { return 32; }

  // ---- textual: headers / titles / sections
  let hb0 = textual.header_block("t", 10);
  if hb0.len() != 32 { return 33; }
  let fb0 = textual.footer_block("t", 10);
  if fb0.len() != 32 { return 34; }
  let hbar0 = textual.header_bar("t", 10);
  if hbar0.len() != 21 { return 35; }
  let tc0 = textual.title_center("ab", 10);
  if tc0.len() < 2 { return 36; }
  let tov0 = textual.title_overline("t", 10);
  if tov0.len() != 32 { return 37; }
  let tul0 = textual.title_underline("t", 10);
  if tul0.len() != 21 { return 38; }
  let sh0 = textual.section_header("t", 10);
  if sh0.len() != 32 { return 39; }
  let sn0 = textual.section_number(0, "z");
  if sn0.len() != 4 { return 40; }

  // ---- textual: lists / toc
  var le = Vec[Str].new();
  let bl0 = textual.bullet_list(&le, "-");
  if bl0.len() != 0 { return 41; }
  let nl0 = textual.numbered_list(&le);
  if nl0.len() != 0 { return 42; }
  var de = Vec[Str].new();
  let dl0 = textual.definition_list(&le, &de);
  if dl0.len() != 0 { return 43; }
  var pe = Vec[Int].new();
  let toc0 = textual.toc(&le, &pe);
  if toc0.len() != 0 { return 44; }
  let ti0 = textual.toc_indent(0);
  if ti0.len() != 0 { return 45; }
  let ti1 = textual.toc_indent(3);
  if ti1.len() != 6 { return 46; }

  // ---- textual: wrap/justify/columns
  let twc0 = textual.text_wrap_center("", 10);
  if twc0.len() != 10 { return 47; }
  let tj0 = textual.text_justify("", 10);
  if tj0.len() != 0 { return 48; }
  var ce = Vec[Str].new();
  let tcl0 = textual.text_columns(&ce, 3);
  if tcl0.len() != 0 { return 49; }

  // ---- fmt: to_str pins
  var iz = 0;
  let its0 = iz.to_str();
  if its0 != "0" { return 50; }
  var fz = 0.0;
  let fts0 = fz.to_str();
  if fts0 != "0" { return 51; }
  var bt = true;
  let bts0 = bt.to_str();
  if bts0 != "true" { return 52; }
  var bf = false;
  let bts1 = bf.to_str();
  if bts1 != "false" { return 53; }
  var sx = "keep";
  let sts0 = sx.to_str();
  if sts0 != "keep" { return 54; }

  // ---- fmt: format1/2/3 no-placeholder identity
  let f10 = fmt.format1("plain", 7);
  if f10 != "plain" { return 55; }
  let f20 = fmt.format2("b", 7, 8);
  if f20 != "b" { return 56; }
  let f30 = fmt.format3("c", 7, 8, 9);
  if f30 != "c" { return 57; }

  // ---- fmt: table / columns / wrap / indent / hexdump
  var he = Vec[Str].new();
  var ce2 = Vec[Str].new();
  let ft0 = fmt.format_table(&he, &ce2, 2);
  if ft0.len() != 0 { return 58; }
  var he2 = Vec[Str].new();
  var ce3 = Vec[Str].new();
  let ft1 = fmt.format_table(&he2, &ce3, 0);
  if ft1.len() != 0 { return 59; }
  var ice = Vec[Str].new();
  let fc0 = fmt.format_columns(&ice, 40);
  if fc0.len() != 0 { return 60; }
  let fw0 = fmt.format_wrap("", 10);
  if fw0.len() != 0 { return 61; }
  let fw1 = fmt.format_wrap("x", 0);
  if fw1 != "x" { return 62; }
  let fi0 = fmt.format_indent("x", 0);
  if fi0 != "x" { return 63; }
  var de2 = Vec[UInt8].new();
  let fh0 = fmt.format_hexdump(&de2, 16);
  if fh0.len() != 0 { return 64; }

  // ---- fmt: pad number / float fixed / bool
  let fp0 = fmt.format_pad_number(0, -1);
  if fp0 != "0" { return 65; }
  let fp1 = fmt.format_pad_number(5, 3);
  if fp1.len() < 3 { return 66; }
  let fp2 = fmt.format_pad_number(-5, 4);
  if fp2.len() < 4 { return 67; }
  let ff0 = fmt.format_float_fixed(0.0, -1);
  if ff0 != "0" { return 68; }
  let fb0 = fmt.format_bool(true);
  if fb0 != "true" { return 69; }
  let fb1 = fmt.format_bool(false);
  if fb1 != "false" { return 70; }

  // ---- fmt: align / join / repeat / line
  let fal0 = fmt.format_align_left("abcdef", 3);
  if fal0.len() < 6 { return 71; }
  let far0 = fmt.format_align_right("abcdef", 3);
  if far0.len() < 6 { return 72; }
  var je = Vec[Str].new();
  let fj0 = fmt.format_join(&je, ",");
  if fj0.len() != 0 { return 73; }
  let fr0 = fmt.format_repeat("ab", 0);
  if fr0.len() != 0 { return 74; }
  let fr1 = fmt.format_repeat("ab", 3);
  if fr1.len() != 6 { return 75; }
  let fl0 = fmt.format_line("Name", "Alice");
  if fl0.len() != 11 { return 76; }

  // ---- fmt: sprintf empty-spec Ok pins
  var ie = Vec[Int].new();
  let sp0 = fmt.sprintf_i("", &ie);
  if sp0.is_ok == false { return 77; }
  var se = Vec[Str].new();
  let sp1 = fmt.sprintf_s("", &se);
  if sp1.is_ok == false { return 78; }
  let sp2 = fmt.sprintf_i1("", 7);
  if sp2.is_ok == false { return 79; }
  let sp3 = fmt.sprintf_i2("", 7, 8);
  if sp3.is_ok == false { return 80; }
  let sp4 = fmt.sprintf_f1("", 1.5);
  if sp4.is_ok == false { return 81; }
  let sp5 = fmt.sprintf_f2("", 1.5, 2.5);
  if sp5.is_ok == false { return 82; }
  let sp6 = fmt.sprintf_s1("", "x");
  if sp6.is_ok == false { return 83; }
  let sp7 = fmt.sprintf_s2("", "x", "y");
  if sp7.is_ok == false { return 84; }

  // ---- fmt: sprintf value pins (controls)
  let spv0 = fmt.sprintf_i1("%d", 42);
  if spv0.is_ok == false { return 85; }
  let spv1 = fmt.sprintf_s1("%s", "hi");
  if spv1.is_ok == false { return 86; }

  // ---- fmt: sscanf
  let ss0 = fmt.sscanf("x", "");
  if ss0.is_ok == false { return 87; }
  let ss1 = fmt.sscanf("", "%d");
  if ss1.is_err == false { return 88; }
  let ss2 = fmt.sscanf_ints("x", "");
  if ss2.is_ok == false { return 89; }
  let ss3 = fmt.sscanf_floats("x", "");
  if ss3.is_ok == false { return 90; }
  let ssv0 = fmt.sscanf("42", "%d");
  if ssv0.is_ok == false { return 91; }

  return 0;
}
