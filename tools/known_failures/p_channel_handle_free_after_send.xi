// Minimal repro: a channel handle with one queued item crashes on free
// (0xC0000005) because channel_handle_try_send/try_recv/free copy the
// owning Channel[T] (with its Vec[T]) through ptr.read/ptr.write, leaving
// the cell and the local copy as two owners of the same items buffer.
//
// Observed on the official v0.65.2 windows-x64 archive (zip sha256
// 0a328560...) and on the 2026-10-28 candidate (HEAD e8180229f): run rc
// 0xC0000005 3/3. The same shape without a send (open; free) is rc 0.
// The candidate's ownership-tagged element drops (6a58a60e1) turn this
// latent corruption into the p_wave188_channel_handle / p_wave162_shapes
// crashes. Tracked as REL-20261028-1533-stdlib + REL-20261028-1617-stdlib.
//
// Expected: run rc 0.
//
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_channel_handle_free_after_send

use xiom.sync.channel;

fn main() -> Int {
  let h = channel.channel_open[Int](3);
  if h.addr == 0 { return 1; }
  let ok = channel.channel_handle_try_send[Int](h, 1);
  if !ok { return 2; }
  let got = channel.channel_handle_try_recv[Int](h);
  match got {
    Some(_) => { },
    None => { return 3; },
  }
  channel.channel_handle_free[Int](h);
  0
}
