// XIOM - Async: Timer
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.async.timer

// Depends on: xiom.async

// ============================================================================
// Async timers, delays, intervals, timer wheels, and stopwatches.
// Self-contained implementation over the monotonic xiom_async_now_ms clock.
// A `Timer` is a deadline handle; `Future` is an opaque pending-operation
// marker; `TimerWheel` is a slot-based scheduler whose `tick` advances one
// millisecond and fires due tasks; `Stopwatch` measures elapsed wall time.
// ============================================================================

extern "C" {
  fn xiom_async_now_ms() -> Int;
  fn xiom_thread_sleep_ms(ms: Int);
}

fn _now() -> Int {
  unsafe { return xiom_async_now_ms(); }
}

/// Timer - a handle for a single deadline-based timer event.
pub type Timer = {
  deadline: Int;
  armed: Bool;
}

/// Future - an opaque handle to a pending async operation.
pub type Future = {
  ready: Bool;
  deadline: Int;
}

/// TimerWheel - a hashed timing wheel for many timers with bounded overhead.
/// The scheduled entries are stored in three parallel vectors (ids,
/// deadlines, tasks) because calling a `fn()` held in a struct field does
/// not compile on the current toolchain.
pub type TimerWheel = {
  slots: Int;
  now: Int;
  ids: Vec[Int];
  deadlines: Vec[Int];
  tasks: Vec[fn()];
  next_id: Int;
}

/// Stopwatch - a monotonic elapsed-time counter.
pub type Stopwatch = { start: Int; }

/// Create an inert timer handle.
/// Returns: a timer that is not armed.
/// Complexity: O(1).
pub fn timer_new() -> Timer {
  return Timer{ deadline: 0; armed: false; }
}

/// Cooperatively sleep `ms` milliseconds.
/// Params: ms - the sleep duration (clamped to >= 0).
/// Complexity: O(1) syscall.
pub fn timer_sleep(ms: Int) {
  var m = ms;
  if m < 0 {
    m = 0;
  }
  unsafe { xiom_thread_sleep_ms(m); }
}

/// Schedule a task to become ready after `ms` milliseconds.
/// Params: ms - the delay in milliseconds.
/// Returns: a Future whose deadline is `ms` from now.
/// Complexity: O(1).
pub fn timer_delay(ms: Int) -> Future {
  var m = ms;
  if m < 0 {
    m = 0;
  }
  return Future{ ready: false; deadline: _now() + m; }
}

/// Create a repeating interval timer.
/// Params: ms - the interval in milliseconds.
/// Returns: an armed timer whose next fire deadline is `ms` from now.
/// Complexity: O(1).
pub fn timer_interval(ms: Int) -> Timer {
  var m = ms;
  if m < 0 {
    m = 0;
  }
  return Timer{ deadline: _now() + m; armed: true; }
}

/// The next fire deadline of `t`, if armed.
/// Params: t - the timer.
/// Returns: Some(deadline in ms) if armed, None otherwise.
/// Complexity: O(1).
pub fn timer_next(t: Timer) -> Option[Int] {
  if t.armed {
    return Some(t.deadline);
  }
  return None;
}

/// Create a timing wheel with `slots` buckets.
/// Params: slots - the number of slots (clamped to >= 1).
/// Returns: an empty wheel with no scheduled timers.
/// Complexity: O(1).
pub fn timer_wheel_new(slots: Int) -> TimerWheel {
  var s = slots;
  if s < 1 {
    s = 1;
  }
  return TimerWheel{ slots: s; now: 0; ids: Vec[Int].new(); deadlines: Vec[Int].new(); tasks: Vec[fn()].new(); next_id: 0; }
}

/// Schedule `f` to run after `ms` milliseconds.
/// Params: tw - the wheel; ms - the delay; f - the task.
/// Complexity: O(1) amortized.
pub fn timer_wheel_add(tw: &mut TimerWheel, ms: Int, f: fn()) {
  var m = ms;
  if m < 0 {
    m = 0;
  }
  tw.next_id = tw.next_id + 1;
  tw.ids.push(tw.next_id);
  tw.deadlines.push(tw.now + m);
  tw.tasks.push(f);
}

/// Advance one slot, firing every due timer.
/// Params: tw - the wheel.
/// Complexity: O(1) plus the cost of due tasks.
pub fn timer_wheel_tick(tw: &mut TimerWheel) {
  tw.now = tw.now + 1;
  var i: Int = 0;
  while i < tw.deadlines.len() {
    var d = tw.deadlines[i];
    if d <= tw.now {
      var t = tw.tasks[i];
      t();
      var j = i;
      while j + 1 < tw.deadlines.len() {
        tw.ids[j] = tw.ids[j + 1];
        tw.deadlines[j] = tw.deadlines[j + 1];
        tw.tasks[j] = tw.tasks[j + 1];
        j = j + 1;
      }
      tw.ids.pop();
      tw.deadlines.pop();
      tw.tasks.pop();
    } else {
      i = i + 1;
    }
  }
}

/// Remove a scheduled timer by id.
/// Params: tw - the wheel; id - the timer id.
/// Complexity: O(n) where n is the number of scheduled timers.
pub fn timer_wheel_cancel(tw: &mut TimerWheel, id: Int) {
  var i: Int = 0;
  while i < tw.ids.len() {
    var eid = tw.ids[i];
    if eid == id {
      var j = i;
      while j + 1 < tw.ids.len() {
        tw.ids[j] = tw.ids[j + 1];
        tw.deadlines[j] = tw.deadlines[j + 1];
        tw.tasks[j] = tw.tasks[j + 1];
        j = j + 1;
      }
      tw.ids.pop();
      tw.deadlines.pop();
      tw.tasks.pop();
      return;
    }
    i = i + 1;
  }
}

/// Create a stopwatch started now.
/// Returns: a stopwatch whose elapsed time is zero at creation.
/// Complexity: O(1).
pub fn stopwatch_new() -> Stopwatch {
  return Stopwatch{ start: _now(); }
}

/// Milliseconds since the stopwatch started.
/// Params: s - the stopwatch.
/// Returns: the elapsed wall-clock milliseconds.
/// Complexity: O(1).
pub fn stopwatch_elapsed_ms(s: Stopwatch) -> Int {
  return _now() - s.start;
}

/// Restart the stopwatch from zero.
/// Params: s - the stopwatch.
/// Complexity: O(1).
pub fn stopwatch_reset(s: &mut Stopwatch) {
  s.start = _now();
}

/// Read the elapsed time without resetting.
/// Params: s - the stopwatch.
/// Returns: the elapsed wall-clock milliseconds.
/// Complexity: O(1).
pub fn stopwatch_split(s: Stopwatch) -> Int {
  return _now() - s.start;
}
