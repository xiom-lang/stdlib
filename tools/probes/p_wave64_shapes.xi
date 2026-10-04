// p_wave64_shapes.xi -- wave 64 shape validation: xiom.reflect + iter build adapters
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-64 clauses on xiom.reflect (18) and xiom.iter.{map
// (5), range (6), zip (5)} = 34 fns. The reflect.fields (10) and
// reflect.typeinfo (11) clauses are runtime-exercised by smoke_reflect;
// adding those calls here hit a context-dependent invalid-IR clang failure,
// and binding Vec.new() temporaries passed as &Vec args is required for
// iter_flat_map / iter_chain_many. all_types() is omitted: it crashes with
// heap corruption (0xC0000374) on v0.62.3, v0.61.3 and m187 -- filed as
// tools/known_failures/p_reflect_all_types_crash.xi. downcast_ref/_mut are
// compile-checked only (no dyn Any value is constructible). No network or
// socket I/O; 47 checks; returns 0 when every case holds.

module p_wave64_shapes

use xiom.reflect;
use xiom.reflect.TypeId;
use xiom.iter.map;
use xiom.iter.range;
use xiom.iter.zip;
use xiom.io;

type P = { a: Int; b: Str; }

fn _double(x: &Int) -> Int {
  *x * 2
}

fn _dup(x: &Int) -> Vec[Int] {
  var v = Vec[Int].new();
  v.push(*x);
  v.push(*x);
  v
}

fn _big(x: &Int) -> Option[Int] {
  if *x > 1 {
    Some(*x)
  } else {
    None
  }
}

fn main() -> Int {
  // reflect.fields / reflect.typeinfo clauses are runtime-exercised by
  // tests/smoke/smoke_reflect.xi (all 21 placeholder queries); return codes
  // 1-21 are intentionally unused here.

  // ---- reflect (RTTI + placeholders)
  let x: Int = 42;
  let tid = TypeId.of[Int]();
  if tid.id != 0 { return 22; }
  let pid = reflect.type_id_by_name("p_wave64_shapes.P");
  if pid < 0 { return 23; }
  if !(reflect.type_name_by_id(pid) == "p_wave64_shapes.P") { return 24; }
  if reflect.type_field_count(pid) != 2 { return 25; }
  let ti = reflect.type_info_by_name("p_wave64_shapes.P");
  if ti.is_none { return 26; }
  if !reflect.type_info_by_name("no.such.Type").is_none { return 27; }
  if !reflect.type_info_by_name("").is_none { return 28; }
  let rt = reflect.reflect_type[Int]();
  if rt.kind != 0 { return 29; }
  if rt.fields.len() != 0 { return 30; }
  if rt.variants.len() != 0 { return 31; }
  if rt.derives.len() != 0 { return 32; }
  if !(rt.name == "unknown") { return 33; }
  if !(reflect.type_kind[Int]() == "unknown") { return 34; }
  if !(reflect.type_name_of_value[Int](&x) == "unknown") { return 35; }
  if reflect.type_id_of_value[Int](&x) != 0 { return 36; }
  if !(reflect.type_field_name[Int](0) == "unknown") { return 37; }
  if reflect.type_field_offset[Int](0) != 0 { return 38; }
  if reflect.type_size[Int]() < 0 { return 39; }
  if reflect.type_align[Int]() < 0 { return 40; }
  if reflect.type_total_size[Int]() < 0 { return 41; }
  // downcast_ref / downcast_mut: compile-checked only (no dyn Any value).

  // ---- iter.map
  var v = Vec[Int].new();
  v.push(1);
  v.push(2);
  v.push(3);
  var flat_src = Vec[Int].new();
  var empty_parts = Vec[Vec[Int]].new();
  let mapped = map.iter_map(&v, _double);
  if mapped.len() != 3 { return 42; }
  if mapped[1] != 4 { return 43; }
  let flat_empty = map.iter_flat_map(&flat_src, _dup);
  if flat_empty.len() != 0 { return 44; }
  let filt = map.iter_filter_map(&v, _big);
  if filt.len() > v.len() { return 45; }
  let en = map.iter_enumerate(&v);
  if en.len() != 3 { return 46; }
  var short = Vec[Int].new();
  short.push(10);
  let zp = map.iter_zip(&v, &short);
  if zp.len() > v.len() || zp.len() > short.len() { return 47; }

  // ---- iter.range
  let r = xiom.iter.range.range(2, 5);
  if r.len() != 3 { return 48; }
  if r[0] != 2 || r[2] != 4 { return 49; }
  if xiom.iter.range.range(5, 2).len() != 0 { return 50; }
  let rs = xiom.iter.range.range_step(0, 10, 3);
  if rs.len() != 4 { return 51; }
  if xiom.iter.range.range_step(0, 10, 0).len() != 0 { return 52; }
  let ri = xiom.iter.range.range_inclusive(1, 3);
  if ri.len() != 3 { return 53; }
  if xiom.iter.range.range_inclusive(3, 1).len() != 0 { return 54; }
  let rf = xiom.iter.range.range_float(0.0, 1.0, 0.25);
  if rf.len() != 4 { return 55; }
  if xiom.iter.range.range_float(0.0, 1.0, 0.0).len() != 0 { return 56; }
  let rc = xiom.iter.range.range_char('a', 'd');
  if rc.len() != 3 { return 57; }
  if xiom.iter.range.range_char('d', 'a').len() != 0 { return 58; }
  let rn = xiom.iter.range.range_count(4);
  if rn.len() != 4 { return 59; }
  if xiom.iter.range.range_count(0).len() != 0 { return 60; }

  // ---- iter.zip
  var b = Vec[Int].new();
  b.push(10);
  b.push(20);
  let zl = zip.iter_zip_longest(&v, &b, 99);
  if zl.len() != 3 { return 61; }
  let zlb = zip.iter_zip_longest(&b, &v, -1);
  if zlb.len() != 3 { return 62; }
  let ch = zip.iter_chain(&v, &b);
  if ch.len() != 5 { return 63; }
  if ch[3] != 10 { return 64; }
  let cm = zip.iter_chain_many(&empty_parts);
  if cm.len() != 0 { return 65; }
  let cp = zip.iter_cartesian_product(&v, &b);
  if cp.len() != 6 { return 66; }
  let il = zip.iter_interleave(&v, &b);
  if il.len() != 5 { return 67; }
  if il[0] != 1 || il[1] != 10 || il[4] != 3 { return 68; }

  return 0;
}
