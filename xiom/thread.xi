// XIOM — Threading
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.thread

pub type Thread = { id: Int; } derive[Eq, Clone]
pub type JoinHandle[T] = { thread: Thread; result: Option[T]; }

pub fn spawn[T](f: fn() -> T) -> JoinHandle[T];
pub fn spawn_with_name[T](name: Str, f: fn() -> T) -> JoinHandle[T];
pub fn JoinHandle.join[T](self) -> Result<T, Str>;
pub fn JoinHandle.is_finished[T](self) -> Bool;
pub fn JoinHandle.thread[T](self) -> Thread;

pub fn Thread.current() -> Thread;
pub fn Thread.id(self) -> Int;
pub fn Thread.name(self) -> Option<Str>;

pub fn sleep(dur: Duration);
pub fn yield_now();

// Scoped threads (borrows from parent scope)
pub fn scope[T](f: fn(&Scope) -> T) -> T;
pub type Scope = { ... }
pub fn Scope.spawn[T](self, f: fn() -> T) -> JoinHandle[T];

pub fn available_parallelism() -> Int;
pub fn hardware_threads() -> Int;
