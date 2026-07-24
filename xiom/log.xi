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

// Core logging
pub fn trace(msg: Str)
  requires: msg.len() >= 0
{
  if should_log(LogLevel.Trace) {
    write_entry(make_entry(LogLevel.Trace, msg, Map[Str, Str]::new()));
  };
}

pub fn debug(msg: Str)
  requires: msg.len() >= 0
{
  if should_log(LogLevel.Debug) {
    write_entry(make_entry(LogLevel.Debug, msg, Map[Str, Str]::new()));
  };
}

pub fn info(msg: Str)
  requires: msg.len() > 0
{
  if should_log(LogLevel.Info) {
    write_entry(make_entry(LogLevel.Info, msg, Map[Str, Str]::new()));
  };
}

pub fn warn(msg: Str)
  requires: msg.len() > 0
{
  if should_log(LogLevel.Warn) {
    write_entry(make_entry(LogLevel.Warn, msg, Map[Str, Str]::new()));
  };
}

pub fn error(msg: Str)
  requires: msg.len() > 0
{
  if should_log(LogLevel.Error) {
    write_entry(make_entry(LogLevel.Error, msg, Map[Str, Str]::new()));
  };
}

pub fn fatal(msg: Str)
  requires: msg.len() >= 0
{
  if should_log(LogLevel.Fatal) {
    write_entry(make_entry(LogLevel.Fatal, msg, Map[Str, Str]::new()));
  };
}

// Structured logging (key=value pairs)
pub fn trace_with(msg: Str, data: Map[Str, Str])
  requires: msg.len() >= 0
{
  if should_log(LogLevel.Trace) {
    write_entry(make_entry(LogLevel.Trace, msg, data));
  };
}

pub fn debug_with(msg: Str, data: Map[Str, Str])
  requires: msg.len() >= 0
{
  if should_log(LogLevel.Debug) {
    write_entry(make_entry(LogLevel.Debug, msg, data));
  };
}

pub fn info_with(msg: Str, data: Map[Str, Str])
  requires: msg.len() > 0
{
  if should_log(LogLevel.Info) {
    write_entry(make_entry(LogLevel.Info, msg, data));
  };
}

pub fn warn_with(msg: Str, data: Map[Str, Str])
  requires: msg.len() > 0
{
  if should_log(LogLevel.Warn) {
    write_entry(make_entry(LogLevel.Warn, msg, data));
  };
}

pub fn error_with(msg: Str, data: Map[Str, Str])
  requires: msg.len() > 0
{
  if should_log(LogLevel.Error) {
    write_entry(make_entry(LogLevel.Error, msg, data));
  };
}

// Configuration
pub fn set_level(level: LogLevel) {
  current_level = level;
}

pub fn get_level() -> LogLevel {
  current_level
}

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

pub fn set_output_json(enabled: Bool) {
  json_mode = enabled;
}

pub fn set_output_color(enabled: Bool) {
  color_mode = enabled;
}

// Query
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

pub fn clear_log() {
  entries = Vec[LogEntry]::new();
}
