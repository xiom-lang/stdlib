// p_wave93_shapes.xi -- wave 93 shape validation: iter remainder + format text
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-93 clause guards:
//   (a) xiom.iter.chain: empty/degenerate-input identities on fold, fold_right,
//       reduce, sum, product, any, all, nth, last, position, max, min,
//       partition and group_by (plus non-empty controls);
//   (b) xiom.iter.fold remainder: empty identities on find/find_map/contains/
//       position_of, the chunks/windows count bounds and the cmp/eq prefix and
//       length-mismatch pins;
//   (c) xiom.iter adapters: the take/skip/enumerate field mirrors on
//       Range/MapIter/FilterIter/EnumerateIter/ChainIter, the Range.next /
//       RangeInclusive.next pre-state guards, TakeIter.next remaining guard and
//       the range_step/repeat_n length bounds;
//   (d) xiom.format.text: the alignment delegation bounds, exact layout
//       lengths (overline/underline/quote/strikethrough), the empty-input
//       identities (wrap/flow/justify/paragraph/reflow/measure), the
//       ellipsis/indent/columns/blockquote size claims.
// Values returned from the module surface are bound before comparing.
// Returns 0 when every case holds.

module p_wave93_shapes

use xiom.iter;
use xiom.iter.chain as chain;
use xiom.iter.fold as fold;
use xiom.format.text as text;

fn add(a: Int, b: &Int) -> Int { return a + *b; }
fn add_ref(a: &Int, b: &Int) -> Int { return *a + *b; }
fn is_even(x: &Int) -> Bool { return *x % 2 == 0; }
fn is_odd(x: &Int) -> Bool { return *x % 2 == 1; }
fn key_mod3(x: &Int) -> Int { return *x % 3; }
fn find_big(x: &Int) -> Option[Int] {
  if *x > 3 { return Some(*x); }
  return None;
}
fn dbl(x: Int) -> Int { return x * 2; }

fn main() -> Int {
  // ---- setup: empty and small vectors
  var e = Vec[Int].new();
  var v = Vec[Int].new();
  v.push(1); v.push(2); v.push(3); v.push(4);

  // ---- chain: empty-input guards
  let f0 = chain.iter_fold(&e, 42, add);
  if f0 != 42 { return 1; }
  let fr0 = chain.iter_fold_right(&e, 43, add);
  if fr0 != 43 { return 2; }
  let rd0 = chain.iter_reduce(&e, add_ref);
  if rd0.is_some { return 3; }
  let su0 = chain.iter_sum(&e);
  if su0 != 0 { return 4; }
  let pr0 = chain.iter_product(&e);
  if pr0 != 1 { return 5; }
  let an0 = chain.iter_any(&e, is_even);
  if an0 { return 6; }
  let al0 = chain.iter_all(&e, is_even);
  if al0 == false { return 7; }
  let nh0 = chain.iter_nth(&e, 0);
  if nh0.is_some { return 8; }
  let ls0 = chain.iter_last(&e);
  if ls0.is_some { return 9; }
  let po0 = chain.iter_position(&e, is_even);
  if po0.is_some { return 10; }
  let mx0 = chain.iter_max(&e);
  if mx0.is_some { return 11; }
  let mn0 = chain.iter_min(&e);
  if mn0.is_some { return 12; }
  let pt0 = chain.iter_partition(&e, is_even);
  if pt0.0.len() != 0 || pt0.1.len() != 0 { return 13; }
  let gb0 = chain.iter_group_by(&e, key_mod3);
  if gb0.len() != 0 { return 14; }

  // ---- chain: non-empty controls
  let f1 = chain.iter_fold(&v, 0, add);
  if f1 != 10 { return 15; }
  let fr1 = chain.iter_fold_right(&v, 0, add);
  if fr1 != 10 { return 16; }
  let rd1 = chain.iter_reduce(&v, add_ref);
  match rd1 {
    Some(rv) => { if rv != 10 { return 17; } },
    None => { return 18; },
  }
  let su1 = chain.iter_sum(&v);
  if su1 != 10 { return 19; }
  let pr1 = chain.iter_product(&v);
  if pr1 != 24 { return 20; }
  let an1 = chain.iter_any(&v, is_odd);
  if an1 == false { return 21; }
  let al1 = chain.iter_all(&v, is_even);
  if al1 { return 22; }
  let nh1 = chain.iter_nth(&v, 2);
  match nh1 {
    Some(nv) => { if nv != 3 { return 23; } },
    None => { return 24; },
  }
  let nh2 = chain.iter_nth(&v, -1);
  if nh2.is_some { return 25; }
  let nh3 = chain.iter_nth(&v, 4);
  if nh3.is_some { return 26; }
  let ls1 = chain.iter_last(&v);
  match ls1 {
    Some(lv) => { if lv != 4 { return 27; } },
    None => { return 28; },
  }
  let po1 = chain.iter_position(&v, is_even);
  match po1 {
    Some(pv) => { if pv != 1 { return 29; } },
    None => { return 30; },
  }
  let mx1 = chain.iter_max(&v);
  match mx1 {
    Some(mv) => { if mv != 4 { return 31; } },
    None => { return 32; },
  }
  let mn1 = chain.iter_min(&v);
  match mn1 {
    Some(mv2) => { if mv2 != 1 { return 33; } },
    None => { return 34; },
  }
  let pt1 = chain.iter_partition(&v, is_even);
  if pt1.0.len() != 2 || pt1.1.len() != 2 { return 35; }
  let gb1 = chain.iter_group_by(&v, key_mod3);
  if gb1.len() != 4 { return 36; }

  // ---- fold remainder: empty-input guards
  let fd0 = fold.iter_find(&e, is_even);
  if fd0.is_some { return 37; }
  let fm0 = fold.iter_find_map(&e, find_big);
  if fm0.is_some { return 38; }
  let ct0 = fold.iter_contains(&e, 5);
  if ct0 { return 39; }
  let pf0 = fold.iter_position_of(&e, 5);
  if pf0.is_some { return 40; }

  // ---- fold remainder: non-empty controls
  let fd1 = fold.iter_find(&v, is_odd);
  match fd1 {
    Some(fv) => { if fv != 1 { return 41; } },
    None => { return 42; },
  }
  let fm1 = fold.iter_find_map(&v, find_big);
  match fm1 {
    Some(fv2) => { if fv2 != 4 { return 43; } },
    None => { return 44; },
  }
  let ct1 = fold.iter_contains(&v, 3);
  if ct1 == false { return 45; }
  let ct2 = fold.iter_contains(&v, 9);
  if ct2 { return 46; }
  let pf1 = fold.iter_position_of(&v, 3);
  match pf1 {
    Some(pv2) => { if pv2 != 2 { return 47; } },
    None => { return 48; },
  }

  // ---- fold: chunks / windows counts
  let ch0 = fold.iter_chunks(&e, 2);
  if ch0.len() != 0 { return 49; }
  let ch1 = fold.iter_chunks(&v, 0);
  if ch1.len() != 0 { return 50; }
  let ch2 = fold.iter_chunks(&v, -1);
  if ch2.len() != 0 { return 51; }
  let ch3 = fold.iter_chunks(&v, 2);
  if ch3.len() != 2 { return 52; }
  let ch4 = fold.iter_chunks(&v, 3);
  if ch4.len() != 2 { return 53; }
  let ch5 = fold.iter_chunks(&v, 5);
  if ch5.len() != 1 { return 54; }
  let wd0 = fold.iter_windows(&e, 2);
  if wd0.len() != 0 { return 55; }
  let wd1 = fold.iter_windows(&v, 0);
  if wd1.len() != 0 { return 56; }
  let wd2 = fold.iter_windows(&v, 5);
  if wd2.len() != 0 { return 57; }
  let wd3 = fold.iter_windows(&v, 3);
  if wd3.len() != 2 { return 58; }
  let wd4 = fold.iter_windows(&v, 4);
  if wd4.len() != 1 { return 59; }

  // ---- fold: cmp / eq
  let cm0 = fold.iter_cmp(&e, &e);
  if cm0 != 0 { return 60; }
  let cm1 = fold.iter_cmp(&e, &v);
  if cm1 != -1 { return 61; }
  let cm2 = fold.iter_cmp(&v, &e);
  if cm2 != 1 { return 62; }
  let cm3 = fold.iter_cmp(&v, &v);
  if cm3 != 0 { return 63; }
  let cml = fold.iter_cmp(&e, &e);
  if cml < -1 || cml > 1 { return 64; }
  let eq0 = fold.iter_eq(&e, &e);
  if eq0 == false { return 65; }
  let eq1 = fold.iter_eq(&e, &v);
  if eq1 { return 66; }
  let eq2 = fold.iter_eq(&v, &v);
  if eq2 == false { return 67; }

  // ---- adapters: take/skip/enumerate field mirrors
  let r0 = iter.range(0, 5);
  let tk = r0.take(3);
  if tk.remaining != 3 { return 68; }
  let r1 = iter.range(0, 5);
  let sk = r1.skip(2);
  if sk.to_skip != 2 { return 69; }
  let r2 = iter.range(0, 5);
  let en = r2.enumerate();
  if en.index != 0 { return 70; }
  let r3 = iter.range(0, 6);
  let mi = r3.map(dbl);
  let mt = mi.take(2);
  if mt.remaining != 2 { return 71; }
  let r4 = iter.range(0, 6);
  let mi2 = r4.map(dbl);
  let ms = mi2.skip(1);
  if ms.to_skip != 1 { return 72; }
  let r5 = iter.range(0, 6);
  let mi3 = r5.map(dbl);
  let me = mi3.enumerate();
  if me.index != 0 { return 73; }
  let r6 = iter.range(0, 6);
  let fi = r6.filter(is_even);
  let ft = fi.take(2);
  if ft.remaining != 2 { return 74; }
  let r7 = iter.range(0, 6);
  let fi2 = r7.filter(is_even);
  let fs = fi2.skip(1);
  if fs.to_skip != 1 { return 75; }
  let r8 = iter.range(0, 6);
  let fi3 = r8.filter(is_even);
  let fe = fi3.enumerate();
  if fe.index != 0 { return 76; }
  let r9 = iter.range(0, 6);
  let ei = r9.enumerate();
  let et = ei.take(2);
  if et.remaining != 2 { return 77; }
  let r10 = iter.range(0, 3);
  let r11 = iter.range(10, 12);
  let ci = r10.chain(r11);
  let ctk = ci.take(1);
  if ctk.remaining != 1 { return 78; }

  // ---- adapters: Range.next / RangeInclusive.next guards
  var rn0 = iter.range(5, 5);
  let rn0v = rn0.next();
  if rn0v.is_some { return 79; }
  var rn1 = iter.range(1, 3);
  let rn1v = rn1.next();
  match rn1v {
    Some(x) => { if x != 1 { return 80; } },
    None => { return 81; },
  }
  let rn1w = rn1.next();
  match rn1w {
    Some(x2) => { if x2 != 2 { return 82; } },
    None => { return 83; },
  }
  let rn1z = rn1.next();
  if rn1z.is_some { return 84; }
  var ri0 = iter.range_inclusive(3, 1);
  let ri0a = ri0.next();
  if ri0a.is_none { return 85; }
  let ri0b = ri0.next();
  if ri0b.is_some { return 86; }
  var ri1 = iter.range_inclusive(2, 4);
  let ri1a = ri1.next();
  if ri1a.is_none { return 87; }
  let ri1b = ri1.next();
  if ri1b.is_none { return 88; }
  let ri1c = ri1.next();
  if ri1c.is_none { return 89; }
  let ri1d = ri1.next();
  if ri1d.is_some { return 90; }

  // ---- adapters: TakeIter.next remaining guard
  let r12 = iter.range(0, 5);
  let tz = r12.take(0);
  let tzv = tz.next();
  if tzv.is_some { return 91; }
  let r13 = iter.range(0, 5);
  let t2 = r13.take(2);
  let t2v = t2.next();
  match t2v {
    Some(x3) => { if x3 != 0 { return 92; } },
    None => { return 93; },
  }

  // ---- adapters: range_step / repeat_n
  let rs0 = iter.range_step(0, 10, 3);
  if rs0.len() != 4 { return 94; }
  let rs1 = iter.range_step(0, 10, 0);
  if rs1.len() != 0 { return 95; }
  let rs2 = iter.range_step(5, 5, 2);
  if rs2.len() != 0 { return 96; }
  let rp0 = iter.repeat_n(7, 3);
  if rp0.len() != 3 { return 97; }
  let rp1 = iter.repeat_n(7, 0);
  if rp1.len() != 0 { return 98; }
  let rp2 = iter.repeat_n(7, -2);
  if rp2.len() != 0 { return 99; }

  // ---- text: alignment delegation bounds
  let tl0 = text.text_left("ab", 5);
  if tl0.len() != 5 { return 100; }
  let tl1 = text.text_left("abcdef", 3);
  if tl1 != "abcdef" { return 101; }
  let tr0 = text.text_right("ab", 5);
  if tr0.len() != 5 { return 102; }
  let tr1 = text.text_right("abcdef", 3);
  if tr1 != "abcdef" { return 103; }
  let tc0 = text.text_center("ab", 5);
  if tc0.len() != 5 { return 104; }
  let tc1 = text.text_center("abcdef", 3);
  if tc1 != "abcdef" { return 105; }

  // ---- text: justification / wrapping / flowing
  let tj0 = text.text_justify("", 9);
  if tj0.len() != 0 { return 106; }
  let tj1 = text.text_justify("a b c", 9);
  if tj1.len() != 9 { return 107; }
  let tw0 = text.text_wrap("", 10);
  if tw0.len() != 1 { return 108; }
  let tw1 = text.text_wrap("hello world foo bar", 8);
  if tw1.len() != 3 { return 109; }
  var we = Vec[Str].new();
  let tf0 = text.text_flow(&we, 10);
  if tf0.len() != 1 { return 110; }

  // ---- text: indentation
  let ti0 = text.text_indent("x", 0);
  if ti0 != "x" { return 111; }
  let ti1 = text.text_indent("x\ny", 2);
  if ti1.len() < 5 { return 112; }
  let th0 = text.text_hanging_indent("x", 0);
  if th0 != "x" { return 113; }
  let th1 = text.text_hanging_indent("x\ny", 2);
  if th1.len() < 5 { return 114; }

  // ---- text: columns
  var ce = Vec[Str].new();
  let cl0 = text.text_columns(&ce, 3);
  if cl0.len() != 0 { return 115; }
  var cs = Vec[Str].new();
  cs.push("a"); cs.push("b"); cs.push("c");
  let cl1 = text.text_columns(&cs, 2);
  if cl1.len() != 2 { return 116; }
  var cs2 = Vec[Str].new();
  cs2.push("a"); cs2.push("b"); cs2.push("c");
  let cl2 = text.text_columns(&cs2, 0);
  if cl2.len() != 3 { return 117; }
  var cs3 = Vec[Str].new();
  cs3.push("a"); cs3.push("b"); cs3.push("c");
  let cl3 = text.text_columns(&cs3, 5);
  if cl3.len() != 1 { return 118; }

  // ---- text: ellipsis
  let te0 = text.text_ellipsis("hello world", 8);
  if te0 != "hello..." { return 119; }
  let te1 = text.text_ellipsis("hi", 8);
  if te1 != "hi" { return 120; }
  let te2 = text.text_ellipsis("hello", 2);
  if te2.len() > 2 { return 121; }

  // ---- text: decorations
  let to0 = text.text_overline("ab");
  if to0.len() != 5 { return 122; }
  let to1 = text.text_overline("");
  if to1.len() != 1 { return 123; }
  let tu0 = text.text_underline("ab");
  if tu0.len() != 5 { return 124; }
  let tu1 = text.text_underline("");
  if tu1.len() != 1 { return 125; }
  let ts0 = text.text_strikethrough("ab");
  if ts0.len() != 6 { return 126; }
  let ts1 = text.text_strikethrough("");
  if ts1.len() != 0 { return 127; }
  let tq0 = text.text_quote("hi");
  if tq0 != "\"hi\"" { return 128; }
  let tq1 = text.text_quote("");
  if tq1.len() != 2 { return 129; }

  // ---- text: blockquote / paragraph / reflow / measure
  var be = Vec[Str].new();
  let tb0 = text.text_blockquote(&be);
  if tb0.len() != 0 { return 130; }
  var bs = Vec[Str].new();
  bs.push("a"); bs.push("bb");
  let tb1 = text.text_blockquote(&bs);
  if tb1.len() != 8 { return 131; }
  let tp0 = text.text_paragraph("", 8);
  if tp0.len() != 0 { return 132; }
  let tp1 = text.text_paragraph("a b c", 8);
  if tp1.len() < 3 { return 133; }
  let tr2 = text.text_reflow("", 4);
  if tr2.len() != 0 { return 134; }
  let tr3 = text.text_reflow("a b c d", 4);
  if tr3.len() < 5 { return 135; }
  let tm0 = text.text_measure("");
  if tm0 != 0 { return 136; }
  let tm1 = text.text_measure("ab");
  if tm1 != 2 { return 137; }
  let tm2 = text.text_measure("ab");
  if tm2 > 2 { return 138; }
  let tm3 = text.text_measure("\u{00b0}C");
  if tm3 > 3 { return 139; }

  return 0;
}
