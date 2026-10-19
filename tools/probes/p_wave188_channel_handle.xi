// p_wave188_channel_handle.xi -- wave 188 lock: handle-based
// xiom.sync.channel (wishlist row 47 / relay REL-20261018-1518-xvector-2).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Rows (0 = all hold):
//  1 -- channel_open returns a non-zero handle; capacity clamp and accessors
//  2 -- bounded try_send FIFO; full rejects; try_recv drains; empty is None
//  3 -- close: sends fail, queued items stay readable, drained recv is None
//  4 -- free after close/drain; free with queued items drains and deallocs
//  5 -- generic Str instantiation works through the same handle ops
//  6 -- unbounded (capacity 0) accepts beyond any bound
//  7 -- cross-thread: 2 producers x 100 sends under one external SyncMutex,
//       joined, then 200 exact items with per-producer FIFO order
//  8 -- open on a live cell never yields addr == 0
// Setup failures use 20+.

module p_wave188_channel_handle

use xiom.sync.channel;
use xiom.sync.mutex;
use xiom.io;
use xiom.convert;
use xiom.thread.spawn;

var g_addr: Int = 0;
var g_mutex: mutex.SyncMutex = mutex.SyncMutex{ locked: 0 as *Int; };

fn produce(base: Int) -> Int {
  var i: Int = 0;
  while i < 100 {
    let h = ChannelHandle[Int]{ addr: g_addr; };
    mutex.mutex_lock(&mut g_mutex);
    let ok = channel.channel_handle_try_send[Int](h, base + i);
    mutex.mutex_unlock(&mut g_mutex);
    if !ok {
      return 1;
    }
    i = i + 1;
  }
  return 0;
}

fn produce_a() -> Int {
  return produce(0);
}

fn produce_b() -> Int {
  return produce(1000);
}

fn expect_recv(h: ChannelHandle[Int], want: Int, code: Int) -> Int {
  let got = channel.channel_handle_try_recv[Int](h);
  match got {
    Some(v) => {
      if v != want { return code; }
    }
    None => { return code + 100; }
  }
  return 0;
}

fn main() -> Int {
  // Row 1: open/accessors/capacity clamp.
  let h = channel.channel_open[Int](3);
  if h.addr == 0 { return 20; }
  if channel.channel_handle_is_closed[Int](h) != false { return 1; }
  if channel.channel_handle_len[Int](h) != 0 { return 2; }
  if channel.channel_handle_capacity[Int](h) != 3 { return 3; }
  let neg = channel.channel_open[Int](-5);
  if neg.addr == 0 { return 21; }
  if channel.channel_handle_capacity[Int](neg) != 0 { return 4; }
  channel.channel_handle_free[Int](neg);

  // Row 2: bounded FIFO/full/empty.
  if channel.channel_handle_try_send[Int](h, 10) == false { return 5; }
  if channel.channel_handle_try_send[Int](h, 20) == false { return 6; }
  if channel.channel_handle_try_send[Int](h, 30) == false { return 7; }
  if channel.channel_handle_try_send[Int](h, 40) { return 8; }
  if channel.channel_handle_len[Int](h) != 3 { return 9; }
  let r1 = expect_recv(h, 10, 10);
  if r1 != 0 { return r1; }
  let r2 = expect_recv(h, 20, 11);
  if r2 != 0 { return r2; }

  // Row 3: close keeps queued items readable, then drains to None.
  channel.channel_handle_close[Int](h);
  if channel.channel_handle_is_closed[Int](h) != true { return 12; }
  if channel.channel_handle_try_send[Int](h, 50) { return 13; }
  let r3 = expect_recv(h, 30, 14);
  if r3 != 0 { return r3; }
  let drained = channel.channel_handle_try_recv[Int](h);
  match drained {
    Some(_) => { return 15; }
    None => {}
  }
  if channel.channel_handle_len[Int](h) != 0 { return 16; }
  if channel.channel_handle_capacity[Int](h) != 3 { return 17; }
  channel.channel_handle_free[Int](h);

  // Row 4: free with queued items drains and deallocs.
  let q = channel.channel_open[Str](2);
  if channel.channel_handle_try_send[Str](q, "alpha") == false { return 22; }
  if channel.channel_handle_try_send[Str](q, "beta") == false { return 23; }
  channel.channel_handle_free[Str](q);

  // Row 5: generic Str instantiation.
  let s = channel.channel_open[Str](2);
  if channel.channel_handle_try_send[Str](s, "gamma") == false { return 18; }
  if channel.channel_handle_len[Str](s) != 1 { return 19; }
  let sv = channel.channel_handle_try_recv[Str](s);
  match sv {
    Some(v) => { if v != "gamma" { return 24; } }
    None => { return 25; }
  }
  channel.channel_handle_close[Str](s);
  channel.channel_handle_free[Str](s);

  // Row 6: unbounded.
  let u = channel.channel_open[Int](0);
  var i: Int = 0;
  while i < 64 {
    if channel.channel_handle_try_send[Int](u, i) == false { return 26; }
    i = i + 1;
  }
  if channel.channel_handle_len[Int](u) != 64 { return 27; }
  channel.channel_handle_free[Int](u);

  // Row 7: cross-thread producers under one external lock.
  g_addr = channel.channel_open[Int](0).addr;
  g_mutex = mutex.mutex_new();
  let ta = spawn.spawn(produce_a);
  let tb = spawn.spawn(produce_b);
  let ja = spawn.join(ta);
  if ja.is_err { return 28; }
  let jb = spawn.join(tb);
  if jb.is_err { return 29; }
  let gh = ChannelHandle[Int]{ addr: g_addr; };
  if channel.channel_handle_len[Int](gh) != 200 { return 30; }

  var seen_a: Int = 0;
  var seen_b: Int = 0;
  var last_a: Int = -1;
  var last_b: Int = -1000;
  var n: Int = 0;
  while n < 200 {
    let item = channel.channel_handle_try_recv[Int](gh);
    match item {
      Some(v) => {
        if v < 1000 {
          if v <= last_a { return 31; }
          last_a = v;
          seen_a = seen_a + 1;
        } else {
          if v <= last_b { return 32; }
          last_b = v;
          seen_b = seen_b + 1;
        }
      }
      None => { return 33; }
    }
    n = n + 1;
  }
  if seen_a != 100 { return 34; }
  if seen_b != 100 { return 35; }
  let extra = channel.channel_handle_try_recv[Int](gh);
  match extra {
    Some(_) => { return 36; }
    None => {}
  }
  channel.channel_handle_close[Int](gh);
  channel.channel_handle_free[Int](gh);

  io.println("OK");
  return 0;
}
