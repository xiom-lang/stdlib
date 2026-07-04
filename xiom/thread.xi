// XIOM — Threading
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.thread

use xiom.time;

var next_id: Int = 0;

fn next_thread_id() -> Int {
  let id = next_id;
  next_id = next_id + 1;
  return id;
}

pub type Thread = { id: Int; done: Bool; } derive[Eq, Clone]

pub type JoinHandle[T] = { thread: Thread; result: Option[T]; }

pub fn spawn[T](f: fn() -> T) -> JoinHandle[T] {
  let result = f();
  let thread = Thread{ id: next_thread_id(); done: true; };
  JoinHandle[T]{ thread: thread; result: Some(result); }
}

pub fn spawn_with_name[T](name: Str, f: fn() -> T) -> JoinHandle[T] {
  spawn[T](f)
}

pub fn JoinHandle.join[T](self) -> Result[T, Str] {
  match self.result {
    Some(val) => Ok(val),
    None => Err("thread not finished"),
  }
}

pub fn JoinHandle.is_finished[T](self) -> Bool {
  self.thread.done
}

pub fn JoinHandle.thread[T](self) -> Thread {
  self.thread
}

pub fn Thread.current() -> Thread {
  Thread{ id: 0; done: false; }
}

pub fn Thread.id(self) -> Int {
  self.id
}

pub fn Thread.name(self) -> Option[Str] {
  None
}

pub fn sleep(dur: Duration) {
  time.sleep(dur);
}

pub fn yield_now() {
}

// Scoped threads (borrows from parent scope)
pub type Scope = {}

pub fn scope[T](f: fn(&Scope) -> T) -> T {
  let s = Scope{};
  f(&s)
}

pub fn Scope.spawn[T](self, f: fn() -> T) -> JoinHandle[T] {
  spawn[T](f)
}

pub fn available_parallelism() -> Int {
  1
}

pub fn hardware_threads() -> Int {
  1
}
