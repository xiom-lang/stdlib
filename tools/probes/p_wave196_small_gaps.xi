// p_wave196_small_gaps.xi -- wave 196: small-gap contract-clause lock.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the wave-196 clauses that carry real information:
// 1. collections: sort length preservation, empty-vector lookups, Map
//    get-or default, Set subset membership laws. The other generic Map/Set
//    free helpers are excluded by a pre-existing v0.64.8 codegen AV when
//    several are instantiated together (reproduced on the pristine stdlib).
// 2. array.dynamic: push/insert/remove/extend/sort length laws.
// 3. cell: Cell.new/get/set value round-trips.
// 4. format.terminal: progress clamp/ETA, spinner cursor, ANSI clamp/range.
// 5. ffi: FFIBuffer length laws, Result error conventions, SafePtr copy
//    length, errno_is_error.
// 6. simd.vec4/vec8: lane arithmetic postconditions (div/dot/sum, lane
//    construction) exercised at runtime.
// Every call also re-evaluates the new runtime ensures; a violation aborts.
// Returns 0 when every case holds.

module p_wave196_small_gaps

use xiom.collections;
use xiom.array.dynamic;
use xiom.cell;
use xiom.ffi;
use xiom.ffi.errno;
use xiom.format.terminal;
use xiom.simd.vec4;
use xiom.simd.vec8;

fn near(a: Float32, b: Float32) -> Bool {
  var d = a - b;
  if d < 0.0 {
    d = -d;
  };
  return d < 0.001;
}

fn cmp_int(a: &Int, b: &Int) -> Int {
  return *a - *b;
}

fn main() -> Int {
  // 1: collections -- Vec length/lookup laws.
  var v = Vec[Int].new();
  v.push(9);
  v.push(1);
  v.push(5);
  vec_sort_asc(&mut v);
  if v.len() != 3 { return 1; }
  if v[0] != 1 || v[2] != 9 { return 2; }
  vec_sort_desc(&mut v);
  if v.len() != 3 || v[0] != 9 { return 3; }
  vec_sort_by(&mut v, cmp_int);
  if v.len() != 3 || v[0] != 1 { return 4; }
  var empty = Vec[Int].new();
  if vec_contains(&empty, 3) { return 5; }
  if vec_get_or(&empty, 0, -7) != -7 { return 6; }
  if vec_get_or(&v, 99, -8) != -8 { return 7; }

  // 1: collections -- Map laws (mutating Map/Set free helpers are excluded:
  // v0.64.8 miscompiles programs instantiating several of those generic
  // wrappers together and AVs; reproduced on the pristine stdlib).
  var m = Map[Int, Int].new();
  var k = 1;
  if map_get_or(&m, &k, 42) != 42 { return 8; }

  // 1: collections -- Set laws.
  var sub = Set[Int].new();
  var sup = Set[Int].new();
  sup.insert(2);
  if !set_is_subset(&sub, &sup) { return 9; }
  sub.insert(2);
  if !set_is_subset(&sub, &sup) { return 10; }
  sub.insert(3);
  if set_is_subset(&sub, &sup) { return 11; }

  // 2: array.dynamic -- push/insert/remove/extend/sort length laws.
  var a = Vec[Int].new();
  array_push(&mut a, 1);
  if a.len() != 1 { return 24; }
  array_insert(&mut a, 5, 9);
  if a.len() != 1 { return 25; }
  array_insert(&mut a, 1, 2);
  if a.len() != 2 { return 26; }
  var rbad = array_remove(&mut a, 5);
  if rbad.is_some || a.len() != 2 { return 27; }
  var rgood = array_remove(&mut a, 0);
  if !rgood.is_some || rgood.value != 1 || a.len() != 1 { return 28; }
  var b = Vec[Int].new();
  b.push(7);
  b.push(8);
  array_extend(&mut a, &b);
  if a.len() != 3 { return 29; }
  array_sort(&mut a);
  if a.len() != 3 || a[0] != 2 || a[2] != 8 { return 30; }

  // 3: Cell value round-trips.
  var c = cell.Cell.new(5);
  if c.get() != 5 { return 31; }
  c.set(11);
  if c.get() != 11 { return 32; }

  // 4: format.terminal -- progress/spinner/ANSI laws.
  var p = progress_new(10);
  progress_update(&mut p, 99);
  if p.done != 10 { return 33; }
  if progress_percent(&p) != 100 { return 34; }
  var bar = progress_render(&p);
  if bar.len() < 3 { return 35; }
  progress_update(&mut p, -4);
  if p.done != 0 { return 36; }
  if progress_eta(&p) != -1 { return 37; }
  var sp = spinner_new();
  var f1 = spinner_tick(&mut sp);
  var f2 = spinner_tick(&mut sp);
  if sp.index != 2 || f1 == f2 { return 38; }
  if ansi_fg_256(-1) != "\u{001b}[38;5;0m" { return 39; }
  if ansi_fg_256(999) != "\u{001b}[38;5;255m" { return 40; }
  if ansi_bg_256(-1) != "\u{001b}[48;5;0m" { return 41; }
  if ansi_cursor_up(-1) != "\u{001b}[0A" { return 42; }
  if ansi_cursor_to(0, 0) != "\u{001b}[1;1H" { return 43; }
  if ansi_fg_rgb(-1, -1, -1) != "\u{001b}[38;2;0;0;0m" { return 44; }
  var dark = color_256_to_rgb(-1);
  if dark.0 != 0 || dark.1 != 0 || dark.2 != 0 { return 45; }
  var gray = color_256_to_rgb(999);
  if gray.0 != 238 || gray.1 != 238 || gray.2 != 238 { return 46; }
  var idx = rgb_to_ansi256(255, 0, 0);
  if idx < 16 || idx > 231 || idx != 196 { return 47; }

  // 5: ffi -- buffer/result/safe-pointer/errno laws.
  var rbuf = ffi.buffer_new(4);
  if !rbuf.is_ok { return 48; }
  var buf = rbuf.value;
  var bytes = Vec[Int].new();
  bytes.push(1);
  bytes.push(2);
  var wr = ffi.buffer_write(&mut buf, &bytes);
  if !wr.is_ok || wr.value != 2 { return 49; }
  if ffi.buffer_len(&buf) != 2 || ffi.buffer_is_empty(&buf) { return 50; }
  ffi.buffer_clear(&mut buf);
  if ffi.buffer_len(&buf) != 0 || !ffi.buffer_is_empty(&buf) { return 51; }
  var bad = ffi.ffi_check(-1, "neg");
  if bad.is_ok || bad.error.code != -1 { return 52; }
  var good = ffi.ffi_check(0, "zero");
  if !good.is_ok || good.value != 0 { return 53; }
  var nz = ffi.ffi_check_nonzero(3, "nz");
  if nz.is_ok || nz.error.code != 3 { return 54; }
  var z = ffi.ffi_check_nonzero(0, "z");
  if !z.is_ok || z.value != 0 { return 55; }
  var rsp = ffi.safe_ptr_alloc(4);
  if !rsp.is_ok { return 56; }
  var sp = rsp.value;
  var bv = ffi.safe_ptr_to_vec(&sp);
  if !bv.is_ok || bv.value.len() != 4 { return 57; }
  ffi.safe_ptr_free(sp);
  if errno.errno_is_error(0) || !errno.errno_is_error(2) { return 58; }

  // 6: SIMD lane arithmetic (vec4/vec8 modules).
  let x = vec4.f32x4_new(1.0, 2.0, 3.0, 4.0);
  let y = vec4.f32x4_new(2.0, 4.0, 6.0, 8.0);
  let q = vec4.f32x4_div(y, x);
  if !near(vec4.f32x4_extract(q, 0), 2.0) { return 59; }
  if !near(vec4.f32x4_extract(q, 3), 2.0) { return 60; }
  if !near(vec4.f32x4_dot(x, y), 60.0) { return 61; }
  if !near(vec4.f32x4_sum(x), 10.0) { return 62; }
  var f8: [8]Float32;
  f8[0] = 1.0;
  f8[1] = 2.0;
  f8[2] = 3.0;
  f8[3] = 4.0;
  f8[4] = 5.0;
  f8[5] = 6.0;
  f8[6] = 7.0;
  f8[7] = 8.0;
  let fv = vec8.f32x8_new(f8);
  if !near(vec8.f32x8_extract(fv, 0), 1.0) { return 63; }
  if !near(vec8.f32x8_extract(fv, 7), 8.0) { return 64; }
  let fq = vec8.f32x8_div(vec8.f32x8_splat(8.0), vec8.f32x8_splat(2.0));
  if !near(vec8.f32x8_extract(fq, 5), 4.0) { return 65; }
  if !near(vec8.f32x8_sum(vec8.f32x8_splat(3.0)), 24.0) { return 66; }
  var i8: [8]Int;
  i8[0] = 1;
  i8[1] = 2;
  i8[2] = 3;
  i8[3] = 4;
  i8[4] = 5;
  i8[5] = 6;
  i8[6] = 7;
  i8[7] = 8;
  let iv = vec8.i32x8_new(i8);
  if vec8.i32x8_extract(iv, 0) != 1 { return 67; }
  if vec8.i32x8_extract(iv, 7) != 8 { return 68; }

  return 0;
}
