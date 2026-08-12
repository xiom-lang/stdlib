// XIOM stdlib smoke test - xiom.collect.priority
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_collect_priority
use xiom.collect.priority;
use xiom.io;

fn main() -> Int {
  var q = pqueue_new();
  if !pqueue_is_empty(&q) { io.println("pq:init"); return 1; }
  if pqueue_len(&q) != 0 { io.println("pq:len0"); return 2; }
  var ep = pqueue_peek(&q);
  if ep.is_some { io.println("pq:peekempty"); return 3; }
  var eo = pqueue_pop(&q);
  if eo.is_some { io.println("pq:popempty"); return 4; }

  pqueue_push(&mut q, 5);
  pqueue_push(&mut q, 3);
  pqueue_push(&mut q, 7);
  pqueue_push(&mut q, 1);
  pqueue_push(&mut q, 9);
  if pqueue_len(&q) != 5 { io.println("pq:len"); return 5; }
  var pk = pqueue_peek(&q);
  if !pk.is_some || pk.value != 9 { io.println("pq:peek"); return 6; }
  if pqueue_len(&q) != 5 { io.println("pq:peeklen"); return 7; }

  var p1 = pqueue_pop(&mut q);
  if !p1.is_some || p1.value != 9 { io.println("pq:pop1"); return 8; }
  var p2 = pqueue_pop(&mut q);
  if !p2.is_some || p2.value != 7 { io.println("pq:pop2"); return 9; }
  var p3 = pqueue_pop(&mut q);
  if !p3.is_some || p3.value != 5 { io.println("pq:pop3"); return 10; }
  pqueue_push(&mut q, 8);
  var p4 = pqueue_pop(&mut q);
  if !p4.is_some || p4.value != 8 { io.println("pq:pop4"); return 11; }
  var p5 = pqueue_pop(&mut q);
  if !p5.is_some || p5.value != 3 { io.println("pq:pop5"); return 12; }
  var p6 = pqueue_pop(&mut q);
  if !p6.is_some || p6.value != 1 { io.println("pq:pop6"); return 13; }
  if !pqueue_is_empty(&q) { io.println("pq:empty"); return 14; }
  var p7 = pqueue_pop(&mut q);
  if p7.is_some { io.println("pq:popempty2"); return 15; }

  // ordering stress: push interleaved low/high values
  var q2 = pqueue_new();
  var i: Int = 0;
  while i < 40 {
    pqueue_push(&mut q2, i % 7);
    pqueue_push(&mut q2, 100 - i);
    i = i + 1;
  }
  var prev = pqueue_pop(&mut q2);
  var ok = true;
  while !pqueue_is_empty(&q2) {
    var cur = pqueue_pop(&mut q2);
    if prev.is_some && cur.is_some {
      if prev.value < cur.value { ok = false; }
    }
    prev = cur;
  }
  if !ok { io.println("pq:order"); return 16; }
  if !prev.is_some || prev.value != 0 { io.println("pq:last"); return 17; }

  io.println("smoke_collect_priority: OK");
  return 0;
}
