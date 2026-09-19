// XIOM ? Error Trait Hierarchy
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.error

use xiom.error.chain;
use xiom.error.context;
use xiom.error.backtrace;

/// Common interface for error values (message plus chaining).
pub interface Error {
  fn source(self) -> Option<Error>;
  fn description(self) -> Str;
  fn message(&self) -> Str { return self.description(); }  // M20: default alias
  fn cause(self) -> Option<Error>; // alias for source
}

/// Chain of error messages collected from an error value.
pub type ErrorChain = { errors: Vec<Str>; } derive[Clone]

/// Collect this error's message chain (outermost first).
pub fn Error.chain(self) -> ErrorChain
  ensures: result.errors.len() >= 1
{
  var errors: Vec<Str> = Vec[Str].new();
  errors.push(self.description());
  var opt = self.source();
  while opt.is_some {
    errors.push(opt.value.description());
    opt = opt.value.source();
  };
  return ErrorChain{ errors: errors };
}

/// Render the chain as a single multi-line string.
pub fn ErrorChain.display(self) -> Str {
  var result: Str = "";
  var i: Int = 0;
  while i < self.errors.len() {
    if i > 0 {
      result = result + ": ";
    }
    result = result + self.errors[i];
    i = i + 1;
  };
  return result;
}

/// Wrap the Err payload of `result` with a context message, preserving Ok
/// values unchanged. The Err message becomes just `context` -- the richer
/// `context + ": " + e.description()` form needs the `E: Error` bound, which
/// the checker's builtin-interface matching does not support yet (C001:
/// bound resolves against the OK type; interface-as-value gap). The `Error`
/// interface with `Option[Error]` returns also defaults to i64 (unknown-type
/// warning). Re-enrich once the checker closes those gaps.
pub fn wrap_error[T, E](result: Result[T, E], context: Str) -> Result[T, Str] {
  match result {
    Ok(v) => { return Ok(v); }
    Err(_) => { return Err(context); }
  }
}

/// Wrap a Result error with an additional context message.
pub fn context[T, E](result: Result[T, E], msg: Str) -> Result[T, Str] {
  match result {
    Ok(v) => { return Ok(v); }
    Err(_) => { return Err(msg); }
  }
}

/// Captured call-site frames (best-effort, platform dependent).
pub type Backtrace = { frames: Vec<Str>; } derive[Clone]

/// Capture the current backtrace.
pub fn capture_backtrace() -> Backtrace {
  return Backtrace{ frames: Vec[Str].new() };
}

/// Render the frames as a single multi-line string.
pub fn Backtrace.display(self) -> Str {
  if self.frames.len() == 0 {
    return "";
  }
  var result: Str = "";
  var i: Int = 0;
  while i < self.frames.len() {
    if i > 0 {
      result = result + "\n";
    }
    result = result + self.frames[i];
    i = i + 1;
  };
  return result;
}

// -- Error Construction Helpers -------------------------------------

/// Returns the error message unchanged. Identity helper for code clarity.
/// Complexity: O(1). Pure, no side effects.
pub fn error_message(err: Str) -> Str {
  return err;
}

/// Creates an error message string. Alias for readability at call-sites.
/// Complexity: O(1). Pure, no side effects.
pub fn make_error(msg: Str) -> Str {
  return msg;
}

/// Formats `msg` with additional context: `"msg (context: ctx)"`.
/// Complexity: O(len(msg)+len(ctx)). Pure, no side effects.
pub fn error_context(msg: Str, ctx: Str) -> Str {
  return msg + " (context: " + ctx + ")";
}

/// Joins two error messages with `": "` separator.
/// If `a` is empty, returns `b`. If `b` is empty, returns `a`.
/// Complexity: O(len(a)+len(b)). Pure, no side effects.
pub fn error_join(a: Str, b: Str) -> Str {
  if a.len() == 0 {
    return b;
  };
  if b.len() == 0 {
    return a;
  };
  return a + ": " + b;
}

/// Converts an `Option[T]` into a `Result[T, Str]`.
/// `Some(v)` ? `Ok(v)`, `None` ? `Err(msg)`.
/// Complexity: O(1). Pure, no side effects.
pub fn option_ok_or[T](o: Option[T], msg: Str) -> Result[T, Str] {
  match o {
    Some(v) => Ok(v);
    None => Err(msg);
  };
}


/// D2.1 (Unsafe Confinement Phase 5, requirement g): recoverable hardware-fault
/// error returned when an unsafe block traps (SIGSEGV/SIGILL/SIGFPE/...).
pub type HardwareFault = { signal: Str; pc: UInt64; retried: Bool; }

/// Description of a violated contract (used by the runtime).
pub type ContractViolation = { contract: Str; }
