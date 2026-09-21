// XIOM - Debug: Tracing
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.debug.trace

// Depends on: xiom.string

use xiom.string;
use xiom.convert;
use xiom.io;

// ============================================================================
// Stack backtraces, source-location and function-name introspection, and
// enable/disable tracing with an entry/exit depth counter.
//
// The runtime has no stack-walking or source-location intrinsics yet, so the
// real backtrace/source-location functions report best-effort data: the
// backtrace mirrors the traced scope stack, and source location returns the
// last recorded scope name (see trace_enter). Tracing itself -- enablement,
// depth counting, enter/exit and log emission -- is fully functional.
// ============================================================================

/// Whether tracing is currently enabled.
var tracing_enabled: Bool = false;

/// Current entry/exit nesting depth.
var trace_depth_value: Int = 0;

/// Trace scope stack (module-level struct with a Vec[Str] -- primitive
/// element type, which is codegen-safe in this build).
pub type TraceStack = {
  names: Vec[Str];
}

/// The traced scope stack.
var scope_stack: TraceStack = TraceStack{ names: Vec[Str]::new(); };

/// True when `a` and `b` hold the same bytes.
fn str_eq(a: Str, b: Str) -> Bool {
  let la = a.len();
  let lb = b.len();
  if la != lb {
    return false;
  };
  var i: Int = 0;
  while i < la {
    if string.byte_at(a, i) != string.byte_at(b, i) {
      return false;
    };
    i = i + 1;
  };
  true
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

/// Capture the current call stack as symbol strings. Without a stack-walking
/// intrinsic this returns the traced scope stack (deepest scope first);
/// empty when tracing has not recorded any scopes.
/// Complexity: O(scope depth).
pub fn trace_backtrace() -> Vec[Str] {
  var out = Vec[Str].new();
  let n = scope_stack.names.len();
  var i = n;
  while i > 0 {
    i = i - 1;
    let name = scope_stack.names[i];
    out.push(name);
  };
  out
}

/// Symbolize raw frame addresses as `0x` hex strings. Invalid or negative
/// addresses render as "0x0".
/// Complexity: O(frames).
pub fn trace_backtrace_symbols(frames: &Vec[Int]) -> Vec[Str] {
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

/// The current source location as "file:line". Without source-location
/// intrinsics this returns the top of the traced scope stack (or "unknown").
/// Complexity: O(1).
pub fn trace_source_location() -> Str {
  if scope_stack.names.len() > 0 {
    let name = scope_stack.names[scope_stack.names.len() - 1];
    return name;
  };
  "unknown"
}

/// The name of the calling function: the top of the traced scope stack, or
/// "unknown".
/// Complexity: O(1).
pub fn trace_current_function() -> Str {
  if scope_stack.names.len() > 0 {
    let name = scope_stack.names[scope_stack.names.len() - 1];
    return name;
  };
  "unknown"
}

/// The file of the calling site. Not available in this build -- "unknown".
/// Complexity: O(1).
pub fn trace_current_file() -> Str {
  "unknown"
}

/// The line of the calling site. Not available in this build -- 0.
/// Complexity: O(1).
pub fn trace_current_line() -> Int {
  0
}

/// Print the current backtrace to the console (io.println; a raw stderr
/// writer is not exposed in this build).
/// Complexity: O(scope depth).
pub fn trace_print() {
  let frames = trace_backtrace();
  var i: Int = 0;
  while i < frames.len() {
    let f = frames[i];
    io.println(f);
    i = i + 1;
  };
}

/// Emit a trace log line when tracing is enabled.
/// Complexity: O(1).
pub fn trace_log(msg: Str) {
  if tracing_enabled {
    io.println("[trace] " + msg);
  };
}

/// Whether tracing is currently enabled.
/// Complexity: O(1).
pub fn trace_enabled() -> Bool {
  tracing_enabled
}

/// Enable or disable tracing.
/// Complexity: O(1).
pub fn trace_set_enabled(on: Bool) {
  tracing_enabled = on;
}

/// The current entry/exit nesting depth.
/// Complexity: O(1).
pub fn trace_depth() -> Int {
  trace_depth_value
}

/// Record entry to a named scope: pushes `name` and increments the depth.
/// Complexity: O(1).
pub fn trace_enter(name: Str) {
  if tracing_enabled {
    scope_stack.names.push(name);
    trace_depth_value = trace_depth_value + 1;
  };
}

/// Record exit from a named scope: pops the matching scope and decrements the
/// depth (clamped at 0). No-op when the stack is empty.
/// Complexity: O(scope depth).
pub fn trace_exit(name: Str) {
  if !tracing_enabled {
    return;
  };
  if scope_stack.names.len() == 0 {
    return;
  };
  let n = scope_stack.names.len();
  var top = scope_stack.names[n - 1];
  if str_eq(top, name) {
    scope_stack.names.pop();
    if trace_depth_value > 0 {
      trace_depth_value = trace_depth_value - 1;
    };
  };
}
