// XIOM stdlib smoke test - xiom.collect.deque + ring
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_collect_deque_ring
use xiom.collect.deque;
use xiom.collect.ring;
use xiom.io;

fn main() -> Int {
  // ===================== Deque =====================
  var d = deque_new();
  if !deque_is_empty(&d) { io.println("dq:init"); return 1; }
  if deque_len(&d) != 0 { io.println("dq:len0"); return 2; }
  deque_push_back(&mut d, 10);
  deque_push_back(&mut d, 20);
  deque_push_front(&mut d, 5);
  deque_push_front(&mut d, 1);
  if deque_len(&d) != 4 { io.println("dq:len"); return 3; }
  var f = deque_front(&d);
  if !f.is_some || f.value != 1 { io.println("dq:front"); return 4; }
  var bk = deque_back(&d);
  if !bk.is_some || bk.value != 20 { io.println("dq:back"); return 5; }
  var pf = deque_pop_front(&mut d);
  if !pf.is_some || pf.value != 1 { io.println("dq:popf"); return 6; }
  var pb = deque_pop_back(&mut d);
  if !pb.is_some || pb.value != 20 { io.println("dq:popb"); return 7; }
  if deque_len(&d) != 2 { io.println("dq:len2"); return 8; }
  var f2 = deque_front(&d);
  if !f2.is_some || f2.value != 5 { io.println("dq:front2"); return 9; }
  var bk2 = deque_back(&d);
  if !bk2.is_some || bk2.value != 10 { io.println("dq:back2"); return 10; }
  // interleave: pop_back then push_back must not resurrect stale entries
  deque_pop_back(&mut d);
  deque_push_back(&mut d, 99);
  var bk3 = deque_back(&d);
  if !bk3.is_some || bk3.value != 99 { io.println("dq:rewrite"); return 11; }
  if deque_len(&d) != 2 { io.println("dq:rewlen"); return 12; }
  deque_pop_front(&mut d);
  deque_pop_front(&mut d);
  if !deque_is_empty(&d) { io.println("dq:empty"); return 13; }
  var e1 = deque_pop_front(&mut d);
  if e1.is_some { io.println("dq:popfempty"); return 14; }
  var e2 = deque_pop_back(&mut d);
  if e2.is_some { io.println("dq:popbempty"); return 15; }
  var ef = deque_front(&d);
  if ef.is_some { io.println("dq:frontempty"); return 16; }
  // push_front after pops: window rebuild path
  deque_push_back(&mut d, 1);
  deque_push_back(&mut d, 2);
  deque_pop_front(&mut d);
  deque_push_front(&mut d, 50);
  var nf = deque_front(&d);
  if !nf.is_some || nf.value != 50 { io.println("dq:rebuild"); return 17; }
  var nb = deque_back(&d);
  if !nb.is_some || nb.value != 2 { io.println("dq:rebuildback"); return 18; }
  if deque_len(&d) != 2 { io.println("dq:rebuildlen"); return 19; }

  // ===================== Ring =====================
  var r = ring_new(3);
  if ring_capacity(&r) != 3 { io.println("rg:cap"); return 20; }
  if !ring_is_empty(&r) { io.println("rg:init"); return 21; }
  if !ring_push(&mut r, 10) { io.println("rg:push1"); return 22; }
  if !ring_push(&mut r, 20) { io.println("rg:push2"); return 23; }
  if !ring_push(&mut r, 30) { io.println("rg:push3"); return 24; }
  if ring_push(&mut r, 40) { io.println("rg:full"); return 25; }
  if ring_len(&r) != 3 { io.println("rg:len"); return 26; }
  var q1 = ring_pop(&mut r);
  if !q1.is_some || q1.value != 10 { io.println("rg:pop1"); return 27; }
  var q2 = ring_pop(&mut r);
  if !q2.is_some || q2.value != 20 { io.println("rg:pop2"); return 28; }
  if ring_len(&r) != 1 { io.println("rg:len1"); return 29; }
  // wrap-around: push again after popping past capacity boundary
  if !ring_push(&mut r, 40) { io.println("rg:pushwrap"); return 30; }
  if !ring_push(&mut r, 50) { io.println("rg:pushwrap2"); return 31; }
  var q3 = ring_pop(&mut r);
  if !q3.is_some || q3.value != 30 { io.println("rg:pop3"); return 32; }
  var q4 = ring_pop(&mut r);
  if !q4.is_some || q4.value != 40 { io.println("rg:pop4"); return 33; }
  var q5 = ring_pop(&mut r);
  if !q5.is_some || q5.value != 50 { io.println("rg:pop5"); return 34; }
  if !ring_is_empty(&r) { io.println("rg:empty"); return 35; }
  var q6 = ring_pop(&mut r);
  if q6.is_some { io.println("rg:popempty"); return 36; }
  if ring_len(&r) != 0 { io.println("rg:len0"); return 37; }
  var small = ring_new(0);
  if ring_capacity(&small) != 1 { io.println("rg:clamp"); return 38; }

  io.println("smoke_collect_deque_ring: OK");
  return 0;
}
