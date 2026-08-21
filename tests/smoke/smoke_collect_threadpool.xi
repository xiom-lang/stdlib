// XIOM stdlib smoke -- xiom.collect.threadpool / workqueue / blockingqueue
// Pure-XIOM pool simulation (submit/join/shutdown), FIFO work queue, bounded
// blocking queue with close semantics.
// Returns 0 on success, nonzero + tag on failure.

module smoke_collect_threadpool
use xiom.collect.threadpool;
use xiom.collect.workqueue;
use xiom.collect.blockingqueue;
use xiom.io;

fn noop_job() {
}

fn main() -> Int {
  // --- Thread pool (pure data structure) ---
  var p = thread_pool_new(3);
  if pool_size(&p) != 3 { io.println("pool size"); return 1; }
  if pool_idle_count(&p) != 3 { io.println("pool idle initial"); return 2; }
  if pool_busy_count(&p) != 0 { io.println("pool busy initial"); return 3; }
  if !pool_submit(&mut p, noop_job) { io.println("pool submit1"); return 4; }
  if !pool_submit(&mut p, noop_job) { io.println("pool submit2"); return 5; }
  if !pool_submit(&mut p, noop_job) { io.println("pool submit3"); return 6; }
  if pool_busy_count(&p) != 3 { io.println("pool busy full"); return 7; }
  if pool_idle_count(&p) != 0 { io.println("pool idle full"); return 8; }
  if !pool_submit(&mut p, noop_job) { io.println("pool submit queued"); return 9; }
  if pool_busy_count(&p) != 3 { io.println("pool busy queued stays"); return 10; }
  pool_join(&mut p);
  if pool_idle_count(&p) != 3 { io.println("pool idle after join"); return 11; }
  if pool_busy_count(&p) != 0 { io.println("pool busy after join"); return 12; }
  pool_shutdown(&mut p);
  if pool_submit(&mut p, noop_job) { io.println("pool submit after shutdown"); return 13; }

  // --- WorkQueue: FIFO over Int job handles ---
  var wq = workqueue_new();
  if !workqueue_is_empty(&wq) { io.println("wq empty initial"); return 14; }
  workqueue_push(&mut wq, 1);
  workqueue_push(&mut wq, 2);
  workqueue_push(&mut wq, 3);
  if workqueue_len(&wq) != 3 { io.println("wq len"); return 15; }
  var w1 = workqueue_pop(&mut wq);
  match w1 {
    Some(v) => { if v != 1 { io.println("wq pop1"); return 16; } },
    None => { io.println("wq pop1 none"); return 17; },
  }
  var w2 = workqueue_pop(&mut wq);
  match w2 {
    Some(v) => { if v != 2 { io.println("wq pop2"); return 18; } },
    None => { io.println("wq pop2 none"); return 19; },
  }
  if workqueue_len(&wq) != 1 { io.println("wq len after"); return 20; }
  if workqueue_is_empty(&wq) { io.println("wq not empty"); return 21; }
  var w3 = workqueue_pop(&mut wq);
  match w3 {
    Some(v) => { if v != 3 { io.println("wq pop3"); return 22; } },
    None => { io.println("wq pop3 none"); return 23; },
  }
  if !workqueue_is_empty(&wq) { io.println("wq empty"); return 24; }
  var w4 = workqueue_pop(&mut wq);
  match w4 {
    Some(_) => { io.println("wq underflow"); return 25; },
    None => {},
  }

  // --- BlockingQueue: bounded, close semantics ---
  var bq = blocking_queue_new(3);
  if bq_capacity(&bq) != 3 { io.println("bq capacity"); return 26; }
  if bq_is_closed(&bq) { io.println("bq open"); return 27; }
  if !bq_push(&mut bq, 10) { io.println("bq push1"); return 28; }
  if !bq_try_push(&mut bq, 20) { io.println("bq push2"); return 29; }
  if !bq_try_push(&mut bq, 30) { io.println("bq push3"); return 30; }
  if bq_try_push(&mut bq, 40) { io.println("bq full"); return 31; }
  if bq_size(&bq) != 3 { io.println("bq size"); return 32; }
  var b1 = bq_pop(&mut bq);
  match b1 {
    Some(v) => { if v != 10 { io.println("bq pop1"); return 33; } },
    None => { io.println("bq pop1 none"); return 34; },
  }
  var b2 = bq_try_pop(&mut bq);
  match b2 {
    Some(v) => { if v != 20 { io.println("bq pop2"); return 35; } },
    None => { io.println("bq pop2 none"); return 36; },
  }
  bq_close(&mut bq);
  if !bq_is_closed(&bq) { io.println("bq closed flag"); return 37; }
  if bq_push(&mut bq, 50) { io.println("bq push closed"); return 38; }
  var b3 = bq_try_pop(&mut bq);
  match b3 {
    Some(v) => { if v != 30 { io.println("bq drain"); return 39; } },
    None => { io.println("bq drain none"); return 40; },
  }
  var b4 = bq_try_pop(&mut bq);
  match b4 {
    Some(_) => { io.println("bq drained"); return 41; },
    None => {},
  }

  io.println("OK");
  return 0;
}
