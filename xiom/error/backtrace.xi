// XIOM - Error: Error Backtraces
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.error.backtrace

// Depends on: xiom.error

use xiom.string;

// ============================================================================
// Capture, store, symbolize and query backtraces attached to errors.
//
// NOTE: the runtime does not yet expose a stack-walking intrinsic, so
// `error_capture_backtrace` cannot observe the real call stack and returns an
// empty frame list (same behaviour as xiom.error.capture_backtrace). All
// attach/query helpers are fully functional; symbolization renders raw frame
// addresses as `0x...` hex strings.
// ============================================================================

/// An error carrying an optional symbolized backtrace (`frames`) and the raw
/// frame addresses (`raw`) from which the symbols were derived.
///
/// NOTE: named `BtError` (not `Error`) because `Error` is treated as a
/// compiler-reserved type name in this build and breaks cross-module codegen.
pub type BtError = {
  message: Str;
  frames: Vec[Str];
  raw: Vec[Int];
} derive[Clone]

/// Whether backtrace capture is currently enabled.
var capture_enabled: Bool = true;

/// Create an error carrying `message` and no backtrace. Bootstrap helper
/// (the frozen stubs provide no constructor).
/// Complexity: O(1).
pub fn error_backtrace_new(message: Str) -> BtError {
  BtError{ message: message; frames: Vec[Str].new(); raw: Vec[Int].new(); }
}

/// Lowercase hex rendering of a non-negative integer, without a prefix.
fn hex(n: Int) -> Str {
  if n == 0 {
    return "0";
  };
  let digits = "0123456789abcdef";
  var v = n;
  var result = "";
  while v > 0 {
    let d = v % 16;
    let slice = string.str_slice(digits, d, d + 1);
    result = string.str_concat(slice, result);
    v = v / 16;
  };
  result
}

/// The symbolized backtrace of an error, if captured (empty otherwise).
/// Complexity: O(frames).
pub fn error_backtrace(e: BtError) -> Vec[Str] {
  let frames = e.frames;
  frames
}

/// Capture the current stack as symbol strings. The runtime has no stack
/// walking intrinsic yet, so this returns an empty vector (documented).
/// Complexity: O(1).
pub fn error_capture_backtrace() -> Vec[Str] {
  Vec[Str].new()
}

/// Whether backtrace capture is currently enabled.
/// Complexity: O(1).
pub fn error_backtrace_enabled() -> Bool {
  capture_enabled
}

/// Enable or disable backtrace capture. When disabled,
/// `error_with_backtrace` attaches no frames.
/// Complexity: O(1).
pub fn error_set_backtrace_enabled(on: Bool) {
  capture_enabled = on;
}

/// The raw frame addresses of an error backtrace (empty when none captured).
/// Complexity: O(frames).
pub fn error_backtrace_frames(e: BtError) -> Vec[Int] {
  let raw = e.raw;
  raw
}

/// Symbolize raw frame addresses as `0x` hex strings. Invalid or negative
/// addresses render as "0x0".
/// Complexity: O(frames).
pub fn error_backtrace_symbolize(frames: &Vec[Int]) -> Vec[Str] {
  var symbols = Vec[Str].new();
  var i: Int = 0;
  while i < frames.len() {
    let addr = frames[i];
    var a = addr;
    if a < 0 {
      a = 0;
    };
    let sym = string.str_concat("0x", hex(a));
    symbols.push(sym);
    i = i + 1;
  };
  symbols
}

/// Capture the current stack and attach it to an error. In this build the
/// captured stack is empty (see `error_capture_backtrace`), so the returned
/// error carries the same message with empty frames.
/// Complexity: O(1).
pub fn error_with_backtrace(e: BtError) -> BtError {
  if !capture_enabled {
    return e;
  };
  let frames = error_capture_backtrace();
  BtError{ message: e.message; frames: frames; raw: Vec[Int].new(); }
}

/// Whether an error carries a backtrace (has at least one frame).
/// Complexity: O(1).
pub fn error_has_backtrace(e: BtError) -> Bool {
  e.frames.len() > 0
}

/// The number of frames in an error backtrace.
/// Complexity: O(1).
pub fn error_backtrace_depth(e: BtError) -> Int {
  e.frames.len()
}
