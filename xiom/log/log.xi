// XIOM -- Structured Logging
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.log

use xiom.log.levels;
use xiom.log.sinks;
use xiom.log.json;
use xiom.log.color;
use xiom.convert;
use xiom.io;

/// Severity levels, from most to least verbose.
pub type LogLevel = enum { Trace, Debug, Info, Warn, Error, Fatal }
/// One log record (level, message, timestamp, fields).
pub type LogEntry = {
  level: LogLevel;
  message: Str;
  file: Str;
  line: Int;
  timestamp: Int;
  data: Map[Str, Str];
} derive[Clone]

var current_level: LogLevel = LogLevel.Info;
var output_file: Option[Str] = None;
var json_mode: Bool = false;
var color_mode: Bool = true;
var entries: Vec[LogEntry] = Vec[LogEntry]::new();

fn level_to_int(level: LogLevel) -> Int {
  match level {
    LogLevel.Trace => 0;
    LogLevel.Debug => 1;
    LogLevel.Info => 2;
    LogLevel.Warn => 3;
    LogLevel.Error => 4;
    LogLevel.Fatal => 5;
  }
}

fn level_name(level: LogLevel) -> Str {
  match level {
    LogLevel.Trace => "TRACE";
    LogLevel.Debug => "DEBUG";
    LogLevel.Info => "INFO";
    LogLevel.Warn => "WARN";
    LogLevel.Error => "ERROR";
    LogLevel.Fatal => "FATAL";
  }
}

fn should_log(level: LogLevel) -> Bool {
  level_to_int(level) >= level_to_int(current_level)
}

fn make_entry(level: LogLevel, msg: Str, data: Map[Str, Str]) -> LogEntry {
  LogEntry{
    level: level;
    message: msg;
    file: "";
    line: 0;
    timestamp: io.time_now();
    data: data;
  }
}

fn format_entry(entry: LogEntry) -> Str {
  "[" + level_name(entry.level) + "] " + entry.message
}

fn format_entry_json(entry: LogEntry) -> Str {
  "{\"level\":\"" + level_name(entry.level) + "\",\"message\":\"" + entry.message + "\",\"timestamp\":" + convert.int_to_string(entry.timestamp) + "}"
}

fn write_entry(entry: LogEntry) {
  let formatted = if json_mode { format_entry_json(entry) } else { format_entry(entry) };
  entries.push(entry);
  match output_file {
    Some(path) => {
      let _ = io.append_file(path, formatted + "\n");
    };
    None => {
      io.println(formatted);
    };
  };
}

/// Core logging
pub fn trace(msg: Str)
  requires: msg.len() >= 0
{
  if should_log(LogLevel.Trace) {
    write_entry(make_entry(LogLevel.Trace, msg, Map[Str, Str]::new()));
  };
}

/// Log at debug level.
pub fn debug(msg: Str)
  requires: msg.len() >= 0
{
  if should_log(LogLevel.Debug) {
    write_entry(make_entry(LogLevel.Debug, msg, Map[Str, Str]::new()));
  };
}

/// Log at info level.
pub fn info(msg: Str)
  requires: msg.len() > 0
{
  if should_log(LogLevel.Info) {
    write_entry(make_entry(LogLevel.Info, msg, Map[Str, Str]::new()));
  };
}

/// Log at warn level.
pub fn warn(msg: Str)
  requires: msg.len() > 0
{
  if should_log(LogLevel.Warn) {
    write_entry(make_entry(LogLevel.Warn, msg, Map[Str, Str]::new()));
  };
}

/// Log at error level.
pub fn error(msg: Str)
  requires: msg.len() > 0
{
  if should_log(LogLevel.Error) {
    write_entry(make_entry(LogLevel.Error, msg, Map[Str, Str]::new()));
  };
}

/// Log at fatal level.
pub fn fatal(msg: Str)
  requires: msg.len() >= 0
{
  if should_log(LogLevel.Fatal) {
    write_entry(make_entry(LogLevel.Fatal, msg, Map[Str, Str]::new()));
  };
}

/// Structured logging (key=value pairs)
pub fn trace_with(msg: Str, data: Map[Str, Str])
  requires: msg.len() >= 0
{
  if should_log(LogLevel.Trace) {
    write_entry(make_entry(LogLevel.Trace, msg, data));
  };
}

/// Log at debug level with structured fields.
pub fn debug_with(msg: Str, data: Map[Str, Str])
  requires: msg.len() >= 0
{
  if should_log(LogLevel.Debug) {
    write_entry(make_entry(LogLevel.Debug, msg, data));
  };
}

/// Log at info level with structured fields.
pub fn info_with(msg: Str, data: Map[Str, Str])
  requires: msg.len() > 0
{
  if should_log(LogLevel.Info) {
    write_entry(make_entry(LogLevel.Info, msg, data));
  };
}

/// Log at warn level with structured fields.
pub fn warn_with(msg: Str, data: Map[Str, Str])
  requires: msg.len() > 0
{
  if should_log(LogLevel.Warn) {
    write_entry(make_entry(LogLevel.Warn, msg, data));
  };
}

/// Log at error level with structured fields.
pub fn error_with(msg: Str, data: Map[Str, Str])
  requires: msg.len() > 0
{
  if should_log(LogLevel.Error) {
    write_entry(make_entry(LogLevel.Error, msg, data));
  };
}

/// Configuration
pub fn set_level(level: LogLevel) {
  current_level = level;
}

/// Current minimum level that is emitted.
pub fn get_level() -> LogLevel {
  current_level
}

/// Redirect log output to a file; Err when it cannot be opened.
pub fn set_output(file: Str) -> Result[Unit, Str]
  requires: file.len() > 0
{
  let result = io.write_file(file, "");
  match result {
    Ok(_) => {
      output_file = Some(file);
      Ok(());
    };
    Err(e) => Err(e.message);
  }
}

/// Enable/disable JSON-lines output.
pub fn set_output_json(enabled: Bool) {
  json_mode = enabled;
}

/// Enable/disable ANSI color output.
pub fn set_output_color(enabled: Bool) {
  color_mode = enabled;
}

/// Query
pub fn entries_since(instant: Instant) -> Vec[LogEntry]
  ensures: result.len() >= 0
{
  var result: Vec[LogEntry] = Vec[LogEntry]::new();
  let threshold = instant.t;
  var i = entries.len();
  while i > 0 {
    i = i - 1;
    if entries[i].timestamp >= threshold {
      result.push(entries[i]);
    };
  };
  result
}

/// Clear any file output and revert to the default sink.
pub fn clear_log() {
  entries = Vec[LogEntry]::new();
}

// -- Level-Aware Message Helpers ------------------------------------

/// Logs a debug-level message. Alias for `log.debug` for discoverability.
/// Complexity: O(1) if level is filtered, O(1) otherwise.
pub fn log_debug_msg(msg: Str) {
  debug(msg);
}

/// Logs an info-level message. Alias for `log.info`.
/// Complexity: O(1).
pub fn log_info_msg(msg: Str) {
  info(msg);
}

/// Logs a warning-level message. Alias for `log.warn`.
/// Complexity: O(1).
pub fn log_warn_msg(msg: Str) {
  warn(msg);
}

/// Logs an error-level message. Alias for `log.error`.
/// Complexity: O(1).
pub fn log_error_msg(msg: Str) {
  error(msg);
}

// -- Structured Logging ---------------------------------------------

/// Creates and writes a log entry with the given level, message, and key-value fields.
/// Returns the created `LogEntry`.
/// Complexity: O(1).
pub fn log_with_fields(level: LogLevel, msg: Str, fields: Map[Str, Str]) -> LogEntry {
  let entry = make_entry(level, msg, fields);
  write_entry(entry);
  return entry;
}

// -- Configuration Helpers ------------------------------------------

/// Sets the minimum log level. Messages below this level are filtered out.
/// Alias for `set_level`.
/// Complexity: O(1). Thread-safe: modifies global state.
pub fn log_set_min_level(level: LogLevel) {
  set_level(level);
}

/// Enables or disables JSON output format for log entries.
/// Alias for `set_output_json`.
/// Complexity: O(1). Thread-safe: modifies global state.
pub fn log_enable_json(enable: Bool) {
  set_output_json(enable);
}

// -- Entry Management -----------------------------------------------

/// Clears all buffered log entries.
/// Alias for `clear_log`.
/// Complexity: O(1). Thread-safe: modifies global state.
pub fn log_clear_entries() {
  clear_log();
}

/// Returns the number of buffered log entries.
/// Complexity: O(1). Thread-safe: reads global state.
pub fn log_entry_count() -> Int {
  return entries.len();
}

/// Returns the most recent log entry, or `None` if the buffer is empty.
/// Complexity: O(1). Thread-safe: reads global state.
pub fn log_last_entry() -> Option[LogEntry] {
  if entries.len() == 0 {
    return None;
  };
  return Some(entries[entries.len() - 1]);
}

// -- Entry Serialization --------------------------------------------

/// Returns all buffered entries as a newline-separated text string.
/// Complexity: O(n).
pub fn log_entries_as_text() -> Str {
  var output: Str = "";
  var i: Int = 0;
  while i < entries.len() {
    if i > 0 {
      output = output + "\n";
    };
    output = output + format_entry(entries[i]);
    i = i + 1;
  };
  return output;
}

/// Returns all buffered entries as a JSON array string.
/// Complexity: O(n).
pub fn log_entries_as_json() -> Str {
  var output: Str = "[";
  var i: Int = 0;
  while i < entries.len() {
    if i > 0 {
      output = output + ",";
    };
    output = output + format_entry_json(entries[i]);
    i = i + 1;
  };
  output = output + "]";
  return output;
}

/// Flushes log output. No-op in this implementation (output is synchronous).
/// Complexity: O(1).
pub fn log_flush() {
}
