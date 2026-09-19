// p_wave8_shapes.xi -- contract shape validation for wave 8.
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// STATUS 2026-09-19: RED. Compiler R49 fixed the direct-mutation `@pre`
// shape (p_pre_call_capture.xi passes), but the callee-mutation shape at
// s_pop_len (line ~68) still reads post-state; minimal repro:
// tools/known_failures/p_pre_capture_callee.xi. Do not weaken this file.
// Validates the NEW clause shapes before they are applied to the stdlib:
// 1. `result is Some => result.value >= 0` (Int Option implication)
// 2. `result is Some => result.value >= 0.0` (Float64 Option implication)
// 3. `s.len() == 0 => result == "Zzzz"` (param-length implication)
// 4. `result.len() == 4` / `== 2` (fixed-length Str)
// 5. `result.len() <= s.len()` / `>= s.len()` (Str length bounds)
// 6. `result is Some => ll_len(l) == ll_len(l)@pre - 1` (free-fn @pre)
// 7. `result == true => int_map_size(m) == int_map_size(m)@pre - 1`
// Returns 0 when every shape compiles and holds at runtime.

module p_wave8_shapes

use xiom.string.unicode as unicode;
use xiom.collect.list;
use xiom.collect.intmap;

fn s_opt_int(c: Char) -> Option[Int]
  ensures: result is Some => result.value >= 0
{
  return unicode.unicode_decimal_value(c);
}

fn s_opt_float(c: Char) -> Option[Float64]
  ensures: result is Some => result.value >= 0.0
{
  return unicode.unicode_numeric_value(c);
}

fn s_empty_script(s: Str) -> Str
  ensures: s.len() == 0 => result == "Zzzz"
{
  return unicode.unicode_script_of(s);
}

fn s_script_len(c: Char) -> Str
  ensures: result.len() == 4
{
  return unicode.unicode_script(c);
}

fn s_cat_len(c: Char) -> Str
  ensures: result.len() == 2
{
  return unicode.unicode_general_category(c);
}

fn s_slice_len(s: Str, start: Int, end: Int) -> Str
  ensures: result.len() <= s.len()
{
  return unicode.unicode_display_slice(s, start, end);
}

fn s_pad_len(s: Str, w: Int) -> Str
  ensures: result.len() >= s.len()
{
  return unicode.unicode_pad_display(s, w, "right");
}

fn s_pop_len(l: &mut LinkedList) -> Option[Int]
  ensures: result is Some => ll_len(l) == ll_len(l)@pre - 1
  ensures: result is None => ll_len(l) == ll_len(l)@pre
{
  return ll_pop_front(l);
}

fn s_imap_remove(m: &mut IntMap, key: Int) -> Bool
  ensures: result == true => int_map_size(m) == int_map_size(m)@pre - 1
  ensures: result == false => int_map_size(m) == int_map_size(m)@pre
{
  return int_map_remove(m, key);
}

fn main() -> Int {
  var d = unicode.unicode_decimal_value('7');
  if !d.is_some { return 1; }
  if d.value != 7 { return 2; }
  var nv = unicode.unicode_numeric_value('5');
  if !nv.is_some { return 3; }

  var e = s_empty_script("");
  if e != "Zzzz" { return 4; }
  var sc = s_script_len('A');
  if sc.len() != 4 { return 5; }
  var cat = s_cat_len('A');
  if cat.len() != 2 { return 6; }

  var s = "hello world";
  var sl = s_slice_len(s, 0, 5);
  if sl.len() > s.len() { return 7; }
  var pd = s_pad_len("ab", 6);
  if pd.len() < 2 { return 8; }

  var l = linked_list_new();
  ll_push_back(&l, 1);
  ll_push_back(&l, 2);
  var p1 = s_pop_len(&l);
  if !p1.is_some { return 9; }
  if ll_len(&l) != 1 { return 10; }
  var p2 = s_pop_len(&l);
  if !p2.is_some { return 11; }
  var p3 = s_pop_len(&l);
  if p3.is_some { return 12; }
  if ll_len(&l) != 0 { return 13; }

  var m = int_map_new(4);
  int_map_put(&m, 5, 50);
  var r1 = s_imap_remove(&m, 5);
  if r1 != true { return 14; }
  if int_map_size(&m) != 0 { return 15; }
  var r2 = s_imap_remove(&m, 9);
  if r2 != false { return 16; }
  return 0;
}
