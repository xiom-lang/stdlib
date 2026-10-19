// p_async_select_closed_drain.xi -- REL-20261018-1546 acceptance shape.
// A &Vec[AsyncChannel[T]] callee must read closed/items from the real struct
// (the old compiler read erased scalar fields). Closed+item -> Some(0);
// closed+drained -> None. Expected rc 0 on v0.64.8+.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_async_select_closed_drain

use xiom.async.channel;

fn main() -> Int {
  var a: AsyncChannel[Int] = async_channel_new[Int](0);
  var b: AsyncChannel[Int] = async_channel_new[Int](0);
  match async_send(&mut a, 7) {
    Ok(_) => {},
    Err(_) => { return 1; },
  };
  async_channel_close(&mut a);
  async_channel_close(&mut b);
  var chs: Vec[AsyncChannel[Int]] = Vec[AsyncChannel[Int]].new();
  chs.push(a);
  chs.push(b);
  let r1 = async_select(&chs);
  match r1 {
    Some(i) => { if i != 0 { return 2; } },
    None => { return 3; },
  };
  var c: AsyncChannel[Int] = async_channel_new[Int](0);
  async_channel_close(&mut c);
  var chs2: Vec[AsyncChannel[Int]] = Vec[AsyncChannel[Int]].new();
  chs2.push(c);
  let r2 = async_select(&chs2);
  match r2 {
    Some(_) => { return 4; },
    None => {},
  };
  return 0;
}
