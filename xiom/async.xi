// XIOM — Async Library
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

use xiom.collections;

module xiom.async

// === Spawn ===
// Launches an async task
pub fn spawn(task: fn()) {
  task();
}

// === Channel type ===
pub type Channel[T] = {
  items: Vec[T];
  closed: Bool;
  cap: Int;
  invariant: items.len() <= cap || cap == 0;
}

pub fn Channel.bounded[T](capacity: Int) -> Channel[T] {
  return Channel[T]{ items: Vec[T].with_capacity(capacity), closed: false, cap: capacity };
}

pub fn Channel.unbounded[T]() -> Channel[T] {
  return Channel[T]{ items: Vec[T].new(), closed: false, cap: 0 };
}

pub fn Channel.send[T](value: T) {
  if cap > 0 && items.len() >= cap {
    panic("Channel.send: channel is full");
  }
  items.push(value);
}

pub fn Channel.recv[T]() -> T {
  if items.len() == 0 {
    panic("Channel.recv: channel is empty");
  }
  var val = items[0];
  var i = 0;
  while i + 1 < items.len() {
    items[i] = items[i + 1];
    i = i + 1;
  }
  items.pop();
  return val;
}

pub fn Channel.try_recv[T]() -> Option[T] {
  if items.len() == 0 { return None; }
  var val = items[0];
  var i = 0;
  while i + 1 < items.len() {
    items[i] = items[i + 1];
    i = i + 1;
  }
  items.pop();
  return Some(val);
}

pub fn Channel.close[T]() {
  closed = true;
}
