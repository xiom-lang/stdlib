// XIOM - Async: Timer
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.async.timer

// Depends on: xiom.async

// ============================================================================
// Async timers, delays, intervals, timer wheels, and stopwatches.
// NOTE: current implementation lives in async.xi - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

// type Timer - a handle for a single deadline-based timer event.
// fn timer_new() -> Timer - create an inert timer handle. TODO(compiler): implement.
// fn timer_sleep(ms: Int) - cooperatively sleep ms milliseconds. TODO(compiler): implement.
// type Future - an opaque handle to a pending async operation.
// fn timer_delay(ms: Int) -> Future - schedule a task to become ready after ms milliseconds. TODO(compiler): implement.
// fn timer_interval(ms: Int) -> Timer - create a repeating interval timer. TODO(compiler): implement.
// fn timer_next(t) -> Option[Int] - the next fire deadline of t, if armed. TODO(compiler): implement.
// type TimerWheel - a hashed timing wheel for many timers with bounded overhead.
// fn timer_wheel_new(slots: Int) -> TimerWheel - create a timing wheel with slots buckets. TODO(compiler): implement.
// fn timer_wheel_add(tw, ms, f: fn()) - schedule f to run after ms milliseconds. TODO(compiler): implement.
// fn timer_wheel_tick(tw) - advance one slot, firing every due timer. TODO(compiler): implement.
// fn timer_wheel_cancel(tw, id: Int) - remove a scheduled timer by id. TODO(compiler): implement.
// type Stopwatch - a monotonic elapsed-time counter.
// fn stopwatch_new() -> Stopwatch - create a stopwatch started now. TODO(compiler): implement.
// fn stopwatch_elapsed_ms(s) -> Int - milliseconds since the stopwatch started. TODO(compiler): implement.
// fn stopwatch_reset(s) - restart the stopwatch from zero. TODO(compiler): implement.
// fn stopwatch_split(s) -> Int - read the elapsed time without resetting. TODO(compiler): implement.
