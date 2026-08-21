// XIOM stdlib smoke -- xiom.collect.pairingheap / bheap / fheap
// Pairing heap (push/pop/peek/merge/decrease-key), binary heap adapter,
// Fibonacci heap adapter with merge.
// Returns 0 on success, nonzero + tag on failure.

module smoke_collect_heaps
use xiom.collect.pairingheap;
use xiom.collect.bheap;
use xiom.collect.fheap;
use xiom.io;

fn main() -> Int {
  // --- Pairing heap: push / peek / pop-min ---
  var ph = pheap_new();
  if !pheap_is_empty(&ph) { io.println("ph empty"); return 1; }
  pheap_push(&mut ph, 5);
  pheap_push(&mut ph, 3);
  pheap_push(&mut ph, 8);
  pheap_push(&mut ph, 1);
  pheap_push(&mut ph, 9);
  if pheap_size(&ph) != 5 { io.println("ph size"); return 2; }
  var pk = pheap_peek(&ph);
  match pk {
    Some(v) => { if v != 1 { io.println("ph peek"); return 3; } },
    None => { io.println("ph peek none"); return 4; },
  }
  var pp1 = pheap_pop(&mut ph);
  match pp1 {
    Some(v) => { if v != 1 { io.println("ph pop1"); return 5; } },
    None => { io.println("ph pop1 none"); return 6; },
  }
  var pp2 = pheap_pop(&mut ph);
  match pp2 {
    Some(v) => { if v != 3 { io.println("ph pop2"); return 7; } },
    None => { io.println("ph pop2 none"); return 8; },
  }
  if pheap_size(&ph) != 3 { io.println("ph size after pops"); return 9; }

  // --- Pairing heap: merge (drains the second heap) ---
  // NOTE: heap.xi's private 3-arg pheap_merge leaks into the global namespace
  // through the delegation import, so the public merge is called qualified.
  var ph2 = pairingheap.pheap_new();
  pairingheap.pheap_push(&mut ph2, 0);
  pairingheap.pheap_push(&mut ph2, 7);
  var merged = pairingheap.pheap_merge(&mut ph, &mut ph2);
  if pairingheap.pheap_size(&ph2) != 0 { io.println("ph merge drains b"); return 10; }
  if pairingheap.pheap_size(&merged) != 5 { io.println("ph merge size"); return 11; }
  var mk = pairingheap.pheap_peek(&merged);
  match mk {
    Some(v) => { if v != 0 { io.println("ph merge peek"); return 12; } },
    None => { io.println("ph merge peek none"); return 13; },
  }
  var m1 = pairingheap.pheap_pop(&mut merged);
  match m1 {
    Some(v) => { if v != 0 { io.println("ph merge pop0"); return 14; } },
    None => { io.println("ph merge pop0 none"); return 15; },
  }
  var m2 = pairingheap.pheap_pop(&mut merged);
  match m2 {
    Some(v) => { if v != 5 { io.println("ph merge pop5"); return 16; } },
    None => { io.println("ph merge pop5 none"); return 17; },
  }

  // --- Pairing heap: decrease-key ---
  var d = pheap_new();
  pheap_push(&mut d, 5);
  pheap_push(&mut d, 7);
  pheap_push(&mut d, 9);
  pheap_decrease_key(&mut d, 2, 1);
  var dk = pheap_peek(&d);
  match dk {
    Some(v) => { if v != 1 { io.println("ph decrease peek"); return 18; } },
    None => { io.println("ph decrease peek none"); return 19; },
  }
  var dp = pheap_pop(&mut d);
  match dp {
    Some(v) => { if v != 1 { io.println("ph decrease pop"); return 20; } },
    None => { io.println("ph decrease pop none"); return 21; },
  }
  var dk2 = pheap_peek(&d);
  match dk2 {
    Some(v) => { if v != 5 { io.println("ph after decrease"); return 22; } },
    None => { io.println("ph after decrease none"); return 23; },
  }

  // --- Binary heap (PHeap adapter) ---
  var bh = bheap_new();
  bheap_push(&mut bh, 4);
  bheap_push(&mut bh, 1);
  bheap_push(&mut bh, 3);
  var bk = bheap_peek(&bh);
  match bk {
    Some(v) => { if v != 1 { io.println("bh peek"); return 24; } },
    None => { io.println("bh peek none"); return 25; },
  }
  var bp1 = bheap_pop(&mut bh);
  match bp1 {
    Some(v) => { if v != 1 { io.println("bh pop1"); return 26; } },
    None => { io.println("bh pop1 none"); return 27; },
  }
  var bp2 = bheap_pop(&mut bh);
  match bp2 {
    Some(v) => { if v != 3 { io.println("bh pop2"); return 28; } },
    None => { io.println("bh pop2 none"); return 29; },
  }
  var bp3 = bheap_pop(&mut bh);
  match bp3 {
    Some(v) => { if v != 4 { io.println("bh pop3"); return 30; } },
    None => { io.println("bh pop3 none"); return 31; },
  }
  if bheap_len(&bh) != 0 { io.println("bh len"); return 32; }

  // --- Fibonacci heap (FibHeap adapter) ---
  var fh = fheap_new();
  fheap_push(&mut fh, 9);
  fheap_push(&mut fh, 2);
  fheap_push(&mut fh, 7);
  var fk = fheap_peek(&fh);
  match fk {
    Some(v) => { if v != 2 { io.println("fh peek"); return 33; } },
    None => { io.println("fh peek none"); return 34; },
  }
  var fp1 = fheap_pop(&mut fh);
  match fp1 {
    Some(v) => { if v != 2 { io.println("fh pop1"); return 35; } },
    None => { io.println("fh pop1 none"); return 36; },
  }
  if fheap_len(&fh) != 2 { io.println("fh len"); return 37; }
  var fp2 = fheap_pop(&mut fh);
  match fp2 {
    Some(v) => { if v != 7 { io.println("fh pop2"); return 38; } },
    None => { io.println("fh pop2 none"); return 39; },
  }
  var fp3 = fheap_pop(&mut fh);
  match fp3 {
    Some(v) => { if v != 9 { io.println("fh pop3"); return 40; } },
    None => { io.println("fh pop3 none"); return 41; },
  }
  if fheap_len(&fh) != 0 { io.println("fh drained"); return 42; }
  // merge drains the other heap
  var fh2 = fheap_new();
  fheap_push(&mut fh2, 1);
  fheap_push(&mut fh2, 5);
  var fh3 = fheap_new();
  fheap_push(&mut fh3, 3);
  fheap_merge(&mut fh3, &mut fh2);
  if fheap_len(&fh2) != 0 { io.println("fh merge drains"); return 43; }
  if fheap_len(&fh3) != 3 { io.println("fh merge size"); return 44; }
  var fm1 = fheap_pop(&mut fh3);
  match fm1 {
    Some(v) => { if v != 1 { io.println("fh merge pop1"); return 45; } },
    None => { io.println("fh merge pop1 none"); return 46; },
  }
  var fm2 = fheap_pop(&mut fh3);
  match fm2 {
    Some(v) => { if v != 3 { io.println("fh merge pop3"); return 47; } },
    None => { io.println("fh merge pop3 none"); return 48; },
  }
  var fm3 = fheap_pop(&mut fh3);
  match fm3 {
    Some(v) => { if v != 5 { io.println("fh merge pop5"); return 49; } },
    None => { io.println("fh merge pop5 none"); return 50; },
  }

  io.println("OK");
  return 0;
}
