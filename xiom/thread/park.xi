// XIOM - Thread: Park
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.thread.park

// Depends on: xiom.thread

// ============================================================================
// Thread parking: efficient blocking and explicit unparking by token.
// NOTE: current implementation lives in thread.xi - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

// fn park() - block the calling thread until it is unparked. TODO(compiler): implement.
// fn park_timeout(ms: Int) -> Bool - block up to ms milliseconds; true if unparked first. TODO(compiler): implement.
// fn unpark(t: Thread) - make the target thread eligible to resume. TODO(compiler): implement.
// type ParkToken - a standalone one-shot park/unpark pair not tied to a thread.
// fn park_token_new() -> ParkToken - create a new park token. TODO(compiler): implement.
// fn park_token_wait(tok) - block until the token is notified. TODO(compiler): implement.
// fn park_token_notify(tok) - release one waiter on the token. TODO(compiler): implement.
// fn unpark_all(threads: &Vec[Thread]) - unpark every thread in the vector. TODO(compiler): implement.
