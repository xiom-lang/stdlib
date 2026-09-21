// p_wave6_specs.xi -- wave-6 contract validation: sync counts + iter lengths.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_wave6_specs
use xiom.sync.barrier;
use xiom.sync.channel;
use xiom.io;

fn main() -> Int {
  var b = barrier.barrier_new(4);
  if barrier.barrier_count(&b) < 1 { return 1; };
  var b0 = barrier.barrier_new(0);
  if barrier.barrier_count(&b0) < 1 { return 2; };
  var bn = barrier.barrier_new(-7);
  if barrier.barrier_count(&bn) < 1 { return 3; };

  var ch = channel.channel_new(8);
  if channel.channel_capacity(&ch) < 0 { return 4; };
  var chn = channel.channel_new(-3);
  if channel.channel_capacity(&chn) < 0 { return 5; };
  if channel.channel_len(&ch) < 0 { return 6; };
  let s = channel.channel_try_send(&mut ch, 41);
  if !s { return 7; };
  if channel.channel_len(&ch) != 1 { return 8; };
  let g = channel.channel_try_recv(&mut ch);
  match g {
    Some(v) => { if v != 41 { return 9; }; },
    None => { return 10; }
  };
  if channel.channel_len(&ch) != 0 { return 11; };

  io.println("P_WAVE6_SPECS OK");
  io.flush_stdout();
  0
}
