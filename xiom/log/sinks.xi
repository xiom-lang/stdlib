// XIOM - Log: Sinks
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.log.sinks

// Depends on: xiom.log

// ============================================================================
// Log output destinations: file, stdout, stderr and null sinks with
// registration, flushing and rotation. NOTE: current implementation lives in
// log.xi - move the functions here during the implementation phase.
// TODO(compiler): implement.
// ============================================================================

// type Sink - a log output destination wrapping a file or stream target.
// fn log_sink_new(target: Int) -> Sink - wrap a raw fd as a log sink. TODO(compiler): implement.
// fn log_sink_file(path: Str) -> Result[Sink, Str] - open a file sink for appending. TODO(compiler): implement.
// fn log_sink_stdout() -> Sink - a sink that writes to stdout. TODO(compiler): implement.
// fn log_sink_stderr() -> Sink - a sink that writes to stderr. TODO(compiler): implement.
// fn log_sink_null() -> Sink - a sink that discards output. TODO(compiler): implement.
// fn log_add_sink(s: Sink) - register a sink for future log lines. TODO(compiler): implement.
// fn log_remove_sink(s: Sink) - unregister a sink. TODO(compiler): implement.
// fn log_sinks() -> Vec[Sink] - the currently registered sinks. TODO(compiler): implement.
// fn log_flush_all() - flush every registered sink. TODO(compiler): implement.
// fn log_sink_rotate(s, max_bytes: Int) - rotate a file sink once it exceeds max_bytes. TODO(compiler): implement.
// fn log_sink_close(s) - close a sink and release its resources. TODO(compiler): implement.
