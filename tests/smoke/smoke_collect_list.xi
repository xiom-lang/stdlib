// XIOM stdlib smoke test - xiom.collect.list + vector + stack
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_collect_list
use xiom.collect.list;
use xiom.collect.vector;
use xiom.collect.stack;
use xiom.io;

fn main() -> Int {
  // ===================== Vector =====================
  var v = vec_new();
  vec_push(&mut v, 10);
  vec_push(&mut v, 20);
  vec_push(&mut v, 30);
  if vec_len(&v) != 3 { io.println("vec:len"); return 1; }
  var v0 = vec_get(&v, 0);
  if !v0.is_some || v0.value != 10 { io.println("vec:get0"); return 2; }
  var v2 = vec_get(&v, 2);
  if !v2.is_some || v2.value != 30 { io.println("vec:get2"); return 3; }
  var vmiss = vec_get(&v, 9);
  if vmiss.is_some { io.println("vec:oob"); return 4; }
  var vneg = vec_get(&v, -1);
  if vneg.is_some { io.println("vec:neg"); return 5; }
  vec_set(&mut v, 1, 99);
  var v1 = vec_get(&v, 1);
  if !v1.is_some || v1.value != 99 { io.println("vec:set"); return 6; }
  vec_insert(&mut v, 1, 55);
  if vec_len(&v) != 4 { io.println("vec:inslen"); return 7; }
  var vi = vec_get(&v, 1);
  if !vi.is_some || vi.value != 55 { io.println("vec:ins"); return 8; }
  var vr = vec_remove(&mut v, 2);
  if !vr.is_some || vr.value != 99 { io.println("vec:rm"); return 9; }
  var vrmiss = vec_remove(&mut v, 100);
  if vrmiss.is_some { io.println("vec:rmoob"); return 10; }
  if vec_len(&v) != 3 { io.println("vec:rmlen"); return 11; }
  var vp = vec_pop(&mut v);
  if !vp.is_some || vp.value != 30 { io.println("vec:pop"); return 12; }
  if vec_is_empty(&v) { io.println("vec:notempty"); return 13; }
  vec_clear(&mut v);
  if !vec_is_empty(&v) { io.println("vec:clear"); return 14; }
  var ve = vec_pop(&mut v);
  if ve.is_some { io.println("vec:popempty"); return 15; }

  // ===================== Linked List =====================
  var l = linked_list_new();
  if !ll_is_empty(&l) { io.println("ll:init"); return 16; }
  if ll_len(&l) != 0 { io.println("ll:len0"); return 17; }
  ll_push_back(&mut l, 10);
  ll_push_back(&mut l, 20);
  ll_push_back(&mut l, 30);
  ll_push_front(&mut l, 5);
  if ll_len(&l) != 4 { io.println("ll:len"); return 18; }
  var f = ll_front(&l);
  if !f.is_some || f.value != 5 { io.println("ll:front"); return 19; }
  var b = ll_back(&l);
  if !b.is_some || b.value != 30 { io.println("ll:back"); return 20; }
  var g0 = ll_get(&l, 0);
  if !g0.is_some || g0.value != 5 { io.println("ll:get0"); return 21; }
  var g3 = ll_get(&l, 3);
  if !g3.is_some || g3.value != 30 { io.println("ll:get3"); return 22; }
  var gmiss = ll_get(&l, 7);
  if gmiss.is_some { io.println("ll:getoob"); return 23; }
  var pf = ll_pop_front(&mut l);
  if !pf.is_some || pf.value != 5 { io.println("ll:popf"); return 24; }
  var pb = ll_pop_back(&mut l);
  if !pb.is_some || pb.value != 30 { io.println("ll:popb"); return 25; }
  if ll_len(&l) != 2 { io.println("ll:len2"); return 26; }
  var g1 = ll_get(&l, 1);
  if !g1.is_some || g1.value != 20 { io.println("ll:get1"); return 27; }
  ll_pop_front(&mut l);
  ll_pop_front(&mut l);
  if !ll_is_empty(&l) { io.println("ll:empty"); return 28; }
  var epf = ll_pop_front(&mut l);
  if epf.is_some { io.println("ll:popfempty"); return 29; }
  var epb = ll_pop_back(&mut l);
  if epb.is_some { io.println("ll:popbempty"); return 30; }
  var ef = ll_front(&l);
  if ef.is_some { io.println("ll:frontempty"); return 31; }
  ll_push_front(&mut l, 7);
  var f2 = ll_front(&l);
  if !f2.is_some || f2.value != 7 { io.println("ll:refill"); return 32; }
  if ll_len(&l) != 1 { io.println("ll:reflen"); return 33; }

  // ===================== Stack =====================
  var s = stack_new();
  if !stack_is_empty(&s) { io.println("st:init"); return 34; }
  stack_push(&mut s, 1);
  stack_push(&mut s, 2);
  stack_push(&mut s, 3);
  if stack_len(&s) != 3 { io.println("st:len"); return 35; }
  var pk = stack_peek(&s);
  if !pk.is_some || pk.value != 3 { io.println("st:peek"); return 36; }
  if stack_len(&s) != 3 { io.println("st:peeklen"); return 37; }
  var p1 = stack_pop(&mut s);
  if !p1.is_some || p1.value != 3 { io.println("st:pop1"); return 38; }
  var p2 = stack_pop(&mut s);
  if !p2.is_some || p2.value != 2 { io.println("st:pop2"); return 39; }
  var p3 = stack_pop(&mut s);
  if !p3.is_some || p3.value != 1 { io.println("st:pop3"); return 40; }
  var p4 = stack_pop(&mut s);
  if p4.is_some { io.println("st:popempty"); return 41; }
  var epk = stack_peek(&s);
  if epk.is_some { io.println("st:peekempty"); return 42; }
  if !stack_is_empty(&s) { io.println("st:empty"); return 43; }
  stack_push(&mut s, 42);
  stack_clear(&mut s);
  if !stack_is_empty(&s) { io.println("st:clear"); return 44; }
  if stack_len(&s) != 0 { io.println("st:clearlen"); return 45; }

  io.println("smoke_collect_list: OK");
  return 0;
}
