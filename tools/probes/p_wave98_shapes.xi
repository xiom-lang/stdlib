// p_wave98_shapes.xi -- wave 98 shape validation: M7 fix + contracts + array
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-98 surface:
//   (a) the closure-based M7 adapters (Range.step_by/take_while/skip_while/
//       inspect) -- constructor field claims and the next() sequences;
//   (b) to_string_char checks live in the companion probe
//       p_wave98_tostring_shapes.xi (importing xiom.convert.tostring
//       corrupts closure predicate dispatch -- filed compiler finding);
//   (c) read_file_lines: an empty file yields Ok with zero lines (the old
//       len>=1 ensures was false); non-empty control;
//   (d) array_zip: BOTH truncation directions now claimed (M<N and N<=M
//       plus zero-length sides);
//   (e) array.fold: the empty-array identity (zero-length `[0]Int` by
//       value is fixed compiler-side, m238).
// Values returned from the module surface are bound before comparing.
// Returns 0 when every case holds.

module p_wave98_shapes

use xiom.iter;
use xiom.io;
use xiom.array;
use xiom.array.fixed as afix;

fn lt3(x: &Int) -> Bool { return *x < 3; }
fn noop(_x: &Int) {}
fn add_arr(acc: Int, x: Int) -> Int { return acc + x; }

fn main() -> Int {
  // ---- M7: step_by
  var r1 = iter.range(0, 10);
  let sb = r1.step_by(2);
  if sb.step != 2 { return 1; }
  if sb.first == false { return 2; }
  let s0 = sb.next();
  match s0 {
    Some(v) => { if v != 0 { return 3; } },
    None => { return 4; },
  }
  let s1 = sb.next();
  match s1 {
    Some(v2) => { if v2 != 2 { return 5; } },
    None => { return 6; },
  }
  let s2 = sb.next();
  match s2 {
    Some(v3) => { if v3 != 4 { return 7; } },
    None => { return 8; },
  }
  let s3 = sb.next();
  match s3 {
    Some(v4) => { if v4 != 6 { return 9; } },
    None => { return 10; },
  }
  let s4 = sb.next();
  match s4 {
    Some(v5) => { if v5 != 8 { return 11; } },
    None => { return 12; },
  }
  let s5 = sb.next();
  if s5.is_some { return 13; }

  // ---- M7: take_while
  var r2 = iter.range(0, 6);
  let tw = r2.take_while(lt3);
  if tw.done { return 14; }
  let t0 = tw.next();
  match t0 {
    Some(v6) => { if v6 != 0 { return 15; } },
    None => { return 16; },
  }
  let t1 = tw.next();
  match t1 {
    Some(v7) => { if v7 != 1 { return 17; } },
    None => { return 18; },
  }
  let t2 = tw.next();
  match t2 {
    Some(v8) => { if v8 != 2 { return 19; } },
    None => { return 20; },
  }
  let t3 = tw.next();
  if t3.is_some { return 21; }
  let t4 = tw.next();
  if t4.is_some { return 22; }

  // ---- M7: skip_while
  var r3 = iter.range(0, 6);
  let sw = r3.skip_while(lt3);
  if sw.skipped { return 23; }
  let k0 = sw.next();
  match k0 {
    Some(v9) => { if v9 != 3 { return 24; } },
    None => { return 25; },
  }
  let k1 = sw.next();
  match k1 {
    Some(v10) => { if v10 != 4 { return 26; } },
    None => { return 27; },
  }
  let k2 = sw.next();
  match k2 {
    Some(v11) => { if v11 != 5 { return 28; } },
    None => { return 29; },
  }
  let k3 = sw.next();
  if k3.is_some { return 30; }

  // ---- M7: inspect pass-through
  var r4 = iter.range(0, 3);
  let ins = r4.inspect(noop);
  let i0 = ins.next();
  match i0 {
    Some(v12) => { if v12 != 0 { return 31; } },
    None => { return 32; },
  }
  let i1 = ins.next();
  match i1 {
    Some(v13) => { if v13 != 1 { return 33; } },
    None => { return 34; },
  }
  let i2 = ins.next();
  if i2.is_none { return 35; }
  let i3 = ins.next();
  if i3.is_some { return 36; }

  // (to_string_char checks live in p_wave98_tostring_shapes.xi: importing
  // xiom.convert.tostring corrupts closure predicate dispatch, filed as
  // tools/known_failures/p_tostring_import_breaks_adapters.xi)

  // ---- read_file_lines: empty file yields zero lines
  let path = "__p_wave98_empty.txt";
  match io.write_file(path, "") {
    Ok(_) => {},
    Err(_) => { return 40; },
  };
  let rr = io.read_file_lines(path);
  match rr {
    Ok(lines) => {
      if lines.len() != 0 { return 41; }
    },
    Err(_) => { return 42; },
  };
  match io.write_file(path, "a\nb") {
    Ok(_) => {},
    Err(_) => { return 43; },
  };
  let rr2 = io.read_file_lines(path);
  match rr2 {
    Ok(lines2) => {
      if lines2.len() != 2 { return 44; }
    },
    Err(_) => { return 45; },
  };
  match io.remove_file(path) {
    Ok(_) => {},
    Err(_) => { return 46; },
  };

  // ---- array_zip: both truncation directions
  let a0: [0]Int = [];
  let a2 = [1, 2];
  let a3 = [1, 2, 3];
  let b2 = [7, 8];
  let z0 = afix.array_zip(&a3, &b2);
  if z0.len() != 2 { return 47; }
  let z1 = afix.array_zip(&a2, &a3);
  if z1.len() != 2 { return 48; }
  let z2 = afix.array_zip(&a3, &a3);
  if z2.len() != 3 { return 49; }
  let z3 = afix.array_zip(&a3, &a0);
  if z3.len() != 0 { return 50; }
  let z4 = afix.array_zip(&a0, &a3);
  if z4.len() != 0 { return 51; }

  // ---- array.fold: empty identity (zero-length by value)
  let fo0 = array.fold(a0, 42, add_arr);
  if fo0 != 42 { return 52; }
  let fo3 = array.fold(a3, 0, add_arr);
  if fo3 != 6 { return 53; }

  return 0;
}
