// XIOM stdlib smoke -- xiom.collect.concurrent / mapch
// Concurrent queues (mpmc/mpsc/spmc), stack, counter; chaining hash map.
// Returns 0 on success, nonzero + tag on failure.

module smoke_collect_concurrent
use xiom.collect.concurrent;
use xiom.collect.mapch;
use xiom.io;

fn main() -> Int {
  // --- Concurrent MPMC ---
  var q = mpmc_queue_new(2);
  if !mpmc_push(&mut q, 1) { io.println("ccq mpmc push1"); return 1; }
  if !mpmc_push(&mut q, 2) { io.println("ccq mpmc push2"); return 2; }
  if mpmc_push(&mut q, 3) { io.println("ccq mpmc full"); return 3; }
  var q1 = mpmc_pop(&mut q);
  match q1 {
    Some(v) => { if v != 1 { io.println("ccq mpmc pop1"); return 4; } },
    None => { io.println("ccq mpmc pop1 none"); return 5; },
  }
  var q2 = mpmc_pop(&mut q);
  match q2 {
    Some(v) => { if v != 2 { io.println("ccq mpmc pop2"); return 6; } },
    None => { io.println("ccq mpmc pop2 none"); return 7; },
  }

  // --- Concurrent MPSC ---
  var ms = mpsc_queue_new(2);
  mpsc_push(&mut ms, 11);
  mpsc_push(&mut ms, 22);
  var m1 = mpsc_pop(&mut ms);
  match m1 {
    Some(v) => { if v != 11 { io.println("ccq mpsc pop1"); return 8; } },
    None => { io.println("ccq mpsc pop1 none"); return 9; },
  }
  var m2 = mpsc_pop(&mut ms);
  match m2 {
    Some(v) => { if v != 22 { io.println("ccq mpsc pop2"); return 10; } },
    None => { io.println("ccq mpsc pop2 none"); return 11; },
  }

  // --- Concurrent SPMC ---
  var sm = spmc_queue_new(2);
  spmc_push(&mut sm, 7);
  spmc_push(&mut sm, 8);
  var s1 = spmc_pop(&mut sm);
  match s1 {
    Some(v) => { if v != 7 { io.println("ccq spmc pop1"); return 12; } },
    None => { io.println("ccq spmc pop1 none"); return 13; },
  }

  // --- Concurrent stack (LIFO) ---
  var st = concurrent_stack_new();
  if !cstack_push(&mut st, 5) { io.println("cstack push1"); return 14; }
  if !cstack_push(&mut st, 6) { io.println("cstack push2"); return 15; }
  if !cstack_push(&mut st, 7) { io.println("cstack push3"); return 16; }
  var c1 = cstack_pop(&mut st);
  match c1 {
    Some(v) => { if v != 7 { io.println("cstack pop1"); return 17; } },
    None => { io.println("cstack pop1 none"); return 18; },
  }
  var c2 = cstack_pop(&mut st);
  match c2 {
    Some(v) => { if v != 6 { io.println("cstack pop2"); return 19; } },
    None => { io.println("cstack pop2 none"); return 20; },
  }
  var c3 = cstack_pop(&mut st);
  match c3 {
    Some(v) => { if v != 5 { io.println("cstack pop3"); return 21; } },
    None => { io.println("cstack pop3 none"); return 22; },
  }
  var c4 = cstack_pop(&mut st);
  match c4 {
    Some(_) => { io.println("cstack underflow"); return 23; },
    None => {},
  }

  // --- Concurrent counter ---
  var cn = concurrent_counter_new();
  ccounter_add(&mut cn, 5);
  ccounter_add(&mut cn, -2);
  ccounter_add(&mut cn, 3);
  if ccounter_get(&cn) != 6 { io.println("ccounter"); return 24; }

  // --- Chaining hash map ---
  var hm = hashmap_new();
  hashmap_put(&mut hm, 1, 10);
  hashmap_put(&mut hm, 2, 20);
  hashmap_put(&mut hm, 1, 99);
  if hashmap_size(&hm) != 2 { io.println("hm size"); return 25; }
  var h1 = hashmap_get(&hm, 1);
  match h1 {
    Some(v) => { if v != 99 { io.println("hm get1"); return 26; } },
    None => { io.println("hm get1 none"); return 27; },
  }
  var h2 = hashmap_get(&hm, 3);
  match h2 {
    Some(_) => { io.println("hm get missing"); return 28; },
    None => {},
  }
  if !hashmap_contains(&hm, 2) { io.println("hm contains"); return 29; }
  if hashmap_contains(&hm, 7) { io.println("hm contains missing"); return 30; }
  if !hashmap_remove(&hm, 2) { io.println("hm remove"); return 31; }
  if hashmap_remove(&hm, 2) { io.println("hm remove twice"); return 32; }
  if hashmap_size(&hm) != 1 { io.println("hm size after remove"); return 33; }
  // growth: force several rehashes, then verify every key survives
  var big = hashmap_new();
  var i: Int = 0;
  while i < 40 {
    hashmap_put(&mut big, i * 7, i);
    i = i + 1;
  }
  if hashmap_size(&big) != 40 { io.println("hm grow size"); return 34; }
  i = 0;
  while i < 40 {
    if !hashmap_contains(&big, i * 7) { io.println("hm grow key"); return 35; }
    i = i + 1;
  }
  hashmap_clear(&mut big);
  if hashmap_size(&big) != 0 { io.println("hm clear"); return 36; }
  if hashmap_contains(&big, 7) { io.println("hm cleared contains"); return 37; }

  io.println("OK");
  return 0;
}
