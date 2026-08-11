// XIOM - Error: Error Context
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.error.context

// Depends on: xiom.error

// ============================================================================
// Attach and query key/value context on errors, wrap errors with messages,
// and render pretty error text. NOTE: current implementation lives in
// error.xi - move the functions here during the implementation phase.
// TODO(compiler): implement.
// ============================================================================

// fn error_with_context(e: Error, context: Str) -> Error - attach a free-form context string to an error. TODO(compiler): implement.
// fn error_context(e) -> Option[Str] - the free-form context string, if any. TODO(compiler): implement.
// fn error_wrap(e: Error, message: Str) -> Error - wrap an error with an outer message. TODO(compiler): implement.
// fn error_unwrap(e: Error) -> Str - the underlying message of an error. TODO(compiler): implement.
// fn error_attach_context(e, key: Str, value: Str) -> Error - attach a named key/value pair. TODO(compiler): implement.
// fn error_context_get(e, key) -> Option[Str] - the value stored under a key, if any. TODO(compiler): implement.
// fn error_context_keys(e) -> Vec[Str] - all context keys. TODO(compiler): implement.
// fn error_context_all(e) -> Vec[(Str, Str)] - all context pairs; each tuple is (key, value). TODO(compiler): implement.
// fn error_pretty_print(e) -> Str - format an error for display. TODO(compiler): implement.
// fn error_pretty_print_chain(e) -> Str - format an error and its full chain. TODO(compiler): implement.
