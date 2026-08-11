// XIOM - OS: Error
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.os.err

// Depends on: xiom.ffi

// ============================================================================
// Error introspection via FFI: errno access, errno names and messages,
// perror-style reporting, stack backtraces, symbol demangling, and the last
// captured error. Zero external dependencies.
// ============================================================================

// fn errno() -> Int - return the current errno value. TODO(compiler): implement.
// fn errno_name(code: Int) -> Str - return the symbolic name (e.g. "ENOENT") for an errno code. TODO(compiler): implement.
// fn strerror(code: Int) -> Str - return the human-readable message for an errno code. TODO(compiler): implement.
// fn perror(msg: Str) -> Unit - print msg plus the current errno message to stderr. TODO(compiler): implement.
// fn errno_message() -> Str - return the message for the current errno value. TODO(compiler): implement.
// fn errno_set(code: Int) -> Unit - set the errno value. TODO(compiler): implement.
// fn backtrace() -> Vec[Str] - capture the current call stack as formatted frame strings. TODO(compiler): implement.
// fn backtrace_symbols(frames: &Vec[Int]) -> Vec[Str] - resolve raw frame addresses to symbols. TODO(compiler): implement.
// fn demangle(symbol: Str) -> Str - demangle a compiler-mangled symbol name. TODO(compiler): implement.
// fn last_error() -> Str - return the most recently captured error string. TODO(compiler): implement.
// fn errno_to_string(code: Int) -> Str - format an errno code as "name (code): message". TODO(compiler): implement.
