// XIOM — Async Library
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.async

// === Spawn ===
// Launches an async task
fn spawn(task: fn());

// === Channel type ===
type Channel[T] = {
  // Internal ring buffer
}

fn Channel.bounded[T](capacity: Int) -> Channel[T];

fn Channel.unbounded[T]() -> Channel[T];

fn Channel.send[T](value: T);

fn Channel.recv[T]() -> T;

fn Channel.try_recv[T]() -> Option[T];

fn Channel.close[T]();
