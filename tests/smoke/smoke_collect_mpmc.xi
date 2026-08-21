// XIOM stdlib smoke -- xiom.collect.mpmc / mpsc / spmc
// Bounded ring queues: FIFO push/pop, overflow/underflow behaviour, size.
// Returns 0 on success, nonzero + tag on failure.

module smoke_collect_mpmc
use xiom.collect.mpmc;
use xiom.collect.mpsc;
use xiom.collect.spmc;
use xiom.io;

fn main() -> Int {
  // --- MPMC: FIFO with overflow rejection and ring wrap ---
  var q = mpmc_queue_new(3);
  if !mpmc_push(&mut q, 10) { io.println("mpmc push1"); return 1; }
  if !mpmc_push(&mut q, 20) { io.println("mpmc push2"); return 2; }
  if !mpmc_push(&mut q, 30) { io.println("mpmc push3"); return 3; }
  if mpmc_size(&q) != 3 { io.println("mpmc size"); return 4; }
  if mpmc_push(&mut q, 40) { io.println("mpmc overflow"); return 5; }
  var p1 = mpmc_pop(&mut q);
  match p1 {
    Some(v) => { if v != 10 { io.println("mpmc pop1"); return 6; } },
    None => { io.println("mpmc pop1 none"); return 7; },
  }
  var p2 = mpmc_pop(&mut q);
  match p2 {
    Some(v) => { if v != 20 { io.println("mpmc pop2"); return 8; } },
    None => { io.println("mpmc pop2 none"); return 9; },
  }
  var p3 = mpmc_pop(&mut q);
  match p3 {
    Some(v) => { if v != 30 { io.println("mpmc pop3"); return 10; } },
    None => { io.println("mpmc pop3 none"); return 11; },
  }
  if mpmc_size(&q) != 0 { io.println("mpmc drained size"); return 12; }
  var p4 = mpmc_pop(&mut q);
  match p4 {
    Some(_) => { io.println("mpmc underflow"); return 13; },
    None => {},
  }
  if !mpmc_push(&mut q, 7) { io.println("mpmc refill"); return 14; }
  var p5 = mpmc_pop(&mut q);
  match p5 {
    Some(v) => { if v != 7 { io.println("mpmc refill pop"); return 15; } },
    None => { io.println("mpmc refill pop none"); return 16; },
  }

  // --- MPSC: FIFO ---
  var ms = mpsc_queue_new(2);
  if !mpsc_push(&mut ms, 11) { io.println("mpsc push1"); return 17; }
  if !mpsc_push(&mut ms, 22) { io.println("mpsc push2"); return 18; }
  if mpsc_push(&mut ms, 33) { io.println("mpsc overflow"); return 19; }
  if mpsc_size(&ms) != 2 { io.println("mpsc size"); return 20; }
  var mp1 = mpsc_pop(&mut ms);
  match mp1 {
    Some(v) => { if v != 11 { io.println("mpsc pop1"); return 21; } },
    None => { io.println("mpsc pop1 none"); return 22; },
  }
  var mp2 = mpsc_pop(&mut ms);
  match mp2 {
    Some(v) => { if v != 22 { io.println("mpsc pop2"); return 23; } },
    None => { io.println("mpsc pop2 none"); return 24; },
  }
  var mp3 = mpsc_pop(&mut ms);
  match mp3 {
    Some(_) => { io.println("mpsc underflow"); return 25; },
    None => {},
  }

  // --- SPMC: FIFO ---
  var sm = spmc_queue_new(2);
  if !spmc_push(&mut sm, 5) { io.println("spmc push1"); return 26; }
  if !spmc_push(&mut sm, 6) { io.println("spmc push2"); return 27; }
  if spmc_size(&sm) != 2 { io.println("spmc size"); return 28; }
  var sp1 = spmc_pop(&mut sm);
  match sp1 {
    Some(v) => { if v != 5 { io.println("spmc pop1"); return 29; } },
    None => { io.println("spmc pop1 none"); return 30; },
  }
  var sp2 = spmc_pop(&mut sm);
  match sp2 {
    Some(v) => { if v != 6 { io.println("spmc pop2"); return 31; } },
    None => { io.println("spmc pop2 none"); return 32; },
  }
  if spmc_size(&sm) != 0 { io.println("spmc drained size"); return 33; }

  io.println("OK");
  return 0;
}
