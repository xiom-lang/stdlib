// XIOM - Thread: Spawn
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.thread.spawn

// Depends on: xiom.thread

// ============================================================================
// Raw thread spawning, joining, detaching, and thread introspection.
// NOTE: current implementation lives in thread.xi - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

// type Thread - a handle to an OS thread with an id and native handle.
// fn spawn(f: fn()) -> Thread - start a new thread running f. TODO(compiler): implement.
// fn spawn_with(f: fn(Int), arg: Int) -> Thread - start a new thread running f(arg). TODO(compiler): implement.
// fn join(t: Thread) -> Result[Int, Str] - block until the thread exits; returns its exit code. TODO(compiler): implement.
// fn detach(t) - let the thread run independently and free its resources on exit. TODO(compiler): implement.
// fn sleep_ms(ms: Int) - suspend the calling thread for ms milliseconds. TODO(compiler): implement.
// fn yield_now() - voluntarily give up the CPU timeslice. TODO(compiler): implement.
// fn thread_id() -> Int - the id of the calling thread. TODO(compiler): implement.
// fn thread_count() -> Int - the number of running threads. TODO(compiler): implement.
// fn is_main_thread() -> Bool - true if the calling thread is the main thread. TODO(compiler): implement.
// fn spawn_scoped(f: fn()) -> Result[Int, Str] - spawn a thread scoped to the current stack frame. TODO(compiler): implement.
