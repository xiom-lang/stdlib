// XIOM - Debug: Tracing
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.debug.trace

// Depends on: xiom.string

// ============================================================================
// Stack backtraces, source-location and function-name introspection, and
// enable/disable tracing with an entry/exit depth counter. NOTE: current
// implementation lives in debug.xi - move the functions here during the
// implementation phase. TODO(compiler): implement.
// ============================================================================

// fn trace_backtrace() -> Vec[Str] - capture the current call stack as symbol strings. TODO(compiler): implement.
// fn trace_backtrace_symbols(frames: &Vec[Int]) -> Vec[Str] - symbolize raw frame addresses. TODO(compiler): implement.
// fn trace_source_location() -> Str - the current file and line as "file:line". TODO(compiler): implement.
// fn trace_current_function() -> Str - the name of the calling function. TODO(compiler): implement.
// fn trace_current_file() -> Str - the file of the calling site. TODO(compiler): implement.
// fn trace_current_line() -> Int - the line of the calling site. TODO(compiler): implement.
// fn trace_print() - print the current backtrace to stderr. TODO(compiler): implement.
// fn trace_log(msg: Str) - emit a trace log line when tracing is enabled. TODO(compiler): implement.
// fn trace_enabled() -> Bool - whether tracing is currently enabled. TODO(compiler): implement.
// fn trace_set_enabled(on: Bool) - enable or disable tracing. TODO(compiler): implement.
// fn trace_depth() -> Int - the current entry/exit nesting depth. TODO(compiler): implement.
// fn trace_enter(name: Str) - record entry to a named scope. TODO(compiler): implement.
// fn trace_exit(name: Str) - record exit from a named scope. TODO(compiler): implement.
