// XIOM — Structured Logging
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.log

pub type LogLevel = enum { Trace, Debug, Info, Warn, Error, Fatal }
pub type LogEntry = {
  level: LogLevel;
  message: Str;
  file: Str;
  line: Int;
  timestamp: Int;
  data: Map[Str, Str];
} derive[Clone]

// Core logging
pub fn trace(msg: Str);
pub fn debug(msg: Str);
pub fn info(msg: Str);
pub fn warn(msg: Str);
pub fn error(msg: Str);
pub fn fatal(msg: Str);

// Structured logging (key=value pairs)
pub fn trace_with(msg: Str, data: Map[Str, Str]);
pub fn debug_with(msg: Str, data: Map[Str, Str]);
pub fn info_with(msg: Str, data: Map[Str, Str]);
pub fn warn_with(msg: Str, data: Map[Str, Str]);
pub fn error_with(msg: Str, data: Map[Str, Str]);

// Configuration
pub fn set_level(level: LogLevel);
pub fn get_level() -> LogLevel;
pub fn set_output(file: Str) -> Result[Unit, Str];
pub fn set_output_json(enabled: Bool);
pub fn set_output_color(enabled: Bool);

// Query
pub fn entries_since(instant: Instant) -> Vec[LogEntry];
pub fn clear_log();
