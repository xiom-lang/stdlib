// XIOM - Error: Error Backtraces
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.error.backtrace

// Depends on: xiom.error

// ============================================================================
// Capture, store, symbolize and query backtraces attached to errors.
// NOTE: current implementation lives in error.xi - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

// fn error_backtrace(e: Error) -> Vec[Str] - the symbolized backtrace of an error, if captured. TODO(compiler): implement.
// fn error_capture_backtrace() -> Vec[Str] - capture the current stack as symbol strings. TODO(compiler): implement.
// fn error_backtrace_enabled() -> Bool - whether backtrace capture is on. TODO(compiler): implement.
// fn error_set_backtrace_enabled(on: Bool) - enable or disable backtrace capture. TODO(compiler): implement.
// fn error_backtrace_frames(e) -> Vec[Int] - the raw frame addresses of an error backtrace. TODO(compiler): implement.
// fn error_backtrace_symbolize(frames: &Vec[Int]) -> Vec[Str] - symbolize raw frame addresses. TODO(compiler): implement.
// fn error_with_backtrace(e: Error) -> Error - capture the current stack and attach it to an error. TODO(compiler): implement.
// fn error_has_backtrace(e) -> Bool - whether an error carries a backtrace. TODO(compiler): implement.
// fn error_backtrace_depth(e) -> Int - the number of frames in an error backtrace. TODO(compiler): implement.
