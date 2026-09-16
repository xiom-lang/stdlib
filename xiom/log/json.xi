// XIOM - Log: JSON
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.log.json

// Depends on: xiom.log

use xiom.string;
use xiom.convert;
use xiom.time;

// ============================================================================
// Structured JSON log entry construction, parsing, formatting and threading.
//
// The serialized line shape is:
//   {"level":"INFO","message":"...","timestamp":"<iso8601>","thread_id":N,
//    "fields":{...}}
// Parsing accepts this exact shape; extra whitespace inside values is not
// handled. The parser is deliberately a subset JSON reader (string and
// integer values only).
// ============================================================================

/// A parsed structured log record: ISO timestamp, level, message, extra
/// key/value fields and the originating thread id.
pub type JsonLogEntry = {
  timestamp: Str;
  level: Int;
  message: Str;
  fields: Vec[(Str, Str)];
  thread_id: Int;
} derive[Clone]

/// Escape a value for inclusion in a JSON string (`"` and `\`).
/// Complexity: O(len(s)).
fn json_escape(s: Str) -> Str {
  var result = "";
  let len = s.len();
  var i: Int = 0;
  while i < len {
    let b = string.byte_at(s, i);
    if b == 34 {
      result = string.str_concat(result, "\\\"");
    } elif b == 92 {
      result = string.str_concat(result, "\\\\");
    } else {
      result = string.str_concat(result, string.str_slice(s, i, i + 1));
    };
    i = i + 1;
  };
  result
}

/// The level name for the JSON output.
fn level_name(level: Int) -> Str {
  if level <= 0 {
    return "TRACE";
  };
  if level == 1 {
    return "DEBUG";
  };
  if level == 2 {
    return "INFO";
  };
  if level == 3 {
    return "WARN";
  };
  if level == 4 {
    return "ERROR";
  };
  if level >= 5 {
    return "FATAL";
  };
  "UNKNOWN"
}

/// Build a JSON log line for a level and message, with the current timestamp
/// and thread id.
/// Complexity: O(len(msg)).
pub fn log_json_entry(level: Int, msg: Str) -> Str {
  var line = "{\"level\":\"" + level_name(level) + "\",\"message\":\"" + json_escape(msg) + "\",\"timestamp\":\"" + log_json_timestamp() + "\",\"thread_id\":" + convert.int_to_string(log_json_thread_id());
  line = string.str_concat(line, "}");
  line
}

/// Render extra key/value fields as a JSON object: `{"k1":"v1","k2":"v2"}`.
/// Empty input renders `{}`.
/// Complexity: O(sum of field lengths).
pub fn log_json_fields(fields: &Vec[(Str, Str)]) -> Str {
  var result = "{";
  var i: Int = 0;
  while i < fields.len() {
    if i > 0 {
      result = string.str_concat(result, ",");
    };
    result = string.str_concat(result, "\"");
    result = string.str_concat(result, json_escape(fields[i].0));
    result = string.str_concat(result, "\":\"");
    result = string.str_concat(result, json_escape(fields[i].1));
    result = string.str_concat(result, "\"");
    i = i + 1;
  };
  string.str_concat(result, "}")
}

/// The current time as an ISO 8601 string (via xiom.time.iso8601_now).
/// Complexity: O(1).
pub fn log_json_timestamp() -> Str {
  time.iso8601_now()
}

/// Find the position just after the opening quote of the value of a string
/// key `"key":"`. Returns -1 when the key is absent.
fn value_start(line: Str, key: Str) -> Int {
  let needle = string.str_concat("\"", string.str_concat(key, "\":\""));
  let idx = string.str_index_of(line, needle);
  match idx {
    Some(i) => i + needle.len();
    None => -1;
  }
}

/// Extract the raw (unescaped) string value of `"key":"..."`.
fn extract_str(line: Str, key: Str) -> Option[Str] {
  let start = value_start(line, key);
  if start < 0 {
    return None;
  };
  var result = "";
  var i = start;
  let len = line.len();
  while i < len {
    let b = string.byte_at(line, i);
    if b == 34 {
      return Some(result);
    };
    if b == 92 && i + 1 < len {
      result = string.str_concat(result, string.str_slice(line, i + 1, i + 2));
      i = i + 1;
    } else {
      result = string.str_concat(result, string.str_slice(line, i, i + 1));
    };
    i = i + 1;
  };
  None
}

/// Parse a JSON log line into an entry. Returns Err when the line is
/// malformed (missing the level, message or timestamp keys).
/// Complexity: O(len(line)).
pub fn log_json_parse(line: Str) -> Result[JsonLogEntry, Str] {
  let level = extract_str(line, "level");
  match level {
    Some(lv) => {
      let lvl = parse_level(lv);
      let msg = extract_str(line, "message");
      match msg {
        Some(ms) => {
          let ts = extract_str(line, "timestamp");
          match ts {
            Some(tst) => {
              Ok(JsonLogEntry{ timestamp: tst; level: lvl; message: ms; fields: Vec[(Str, Str)].new(); thread_id: 1; })
            };
            None => Err("log_json_parse: missing timestamp");
          }
        };
        None => Err("log_json_parse: missing message");
      }
    };
    None => Err("log_json_parse: missing level");
  }
}

/// Map a level name back to its numeric constant (TRACE=0 .. FATAL=5);
/// unknown names map to 2 (INFO).
fn parse_level(name: Str) -> Int {
  let up = string.str_upper(name);
  if up == "TRACE" {
    return 0;
  };
  if up == "DEBUG" {
    return 1;
  };
  if up == "WARN" || up == "WARNING" {
    return 3;
  };
  if up == "ERROR" {
    return 4;
  };
  if up == "FATAL" {
    return 5;
  };
  2
}

/// Re-serialize a log entry to a JSON line.
/// Complexity: O(len(message) + fields).
pub fn log_json_format(entry: JsonLogEntry) -> Str {
  var line = "{\"level\":\"" + level_name(entry.level) + "\",\"message\":\"" + json_escape(entry.message) + "\",\"timestamp\":\"" + entry.timestamp + "\",\"thread_id\":" + convert.int_to_string(entry.thread_id);
  if entry.fields.len() > 0 {
    line = string.str_concat(line, ",\"fields\":");
    line = string.str_concat(line, log_json_fields(&entry.fields));
  };
  string.str_concat(line, "}")
}

/// The current thread id for logging. This build is single-threaded, so the
/// value is always 1.
/// Complexity: O(1).
pub fn log_json_thread_id() -> Int {
  1
}
