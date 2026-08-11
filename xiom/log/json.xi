// XIOM - Log: JSON
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.log.json

// Depends on: xiom.log

// ============================================================================
// Structured JSON log entry construction, parsing, formatting and threading.
// NOTE: current implementation lives in log.xi - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

// type LogEntry - a parsed structured log record: timestamp, level, message and fields.
// fn log_json_entry(level: Int, msg: Str) -> Str - build a JSON line for a level and message. TODO(compiler): implement.
// fn log_json_fields(fields: &Vec[(Str, Str)]) -> Str - render extra key/value fields; each tuple is (key, value). TODO(compiler): implement.
// fn log_json_timestamp() -> Str - the current time as an ISO 8601 JSON string. TODO(compiler): implement.
// fn log_json_parse(line: Str) -> Result[LogEntry, Str] - parse a JSON log line into an entry. TODO(compiler): implement.
// fn log_json_format(entry: LogEntry) -> Str - re-serialize a log entry to JSON. TODO(compiler): implement.
// fn log_json_thread_id() -> Int - the current thread id for logging. TODO(compiler): implement.
