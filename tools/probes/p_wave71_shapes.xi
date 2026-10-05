// p_wave71_shapes.xi -- wave 71 shape validation: log (levels/color/sinks/json/core)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-71 clause guards on xiom.log.levels (12),
// xiom.log.color (8), xiom.log.sinks (8), xiom.log.json (4) and xiom.log
// core (28); returns 0 when every case holds. Log lines go to stdout
// (captured by the runner); no network I/O. Enum results are exercised
// through write-count proxies (no enum equality).

module p_wave71_shapes

use xiom.log;
use xiom.log.levels;
use xiom.log.color;
use xiom.log.sinks;
use xiom.log.json;

fn _esc() -> Str {
  "\u{001b}"
}

fn main() -> Int {
  // ---- levels: constants
  if levels.log_level_trace() != 0 { return 1; }
  if levels.log_level_debug() != 1 { return 2; }
  if levels.log_level_info() != 2 { return 3; }
  if levels.log_level_warn() != 3 { return 4; }
  if levels.log_level_error() != 4 { return 5; }
  if levels.log_level_fatal() != 5 { return 6; }

  // ---- levels: name mapping
  if levels.log_level_name(0) != "TRACE" { return 7; }
  if levels.log_level_name(0 - 1) != "TRACE" { return 8; }
  if levels.log_level_name(1) != "DEBUG" { return 9; }
  if levels.log_level_name(2) != "INFO" { return 10; }
  if levels.log_level_name(3) != "WARN" { return 11; }
  if levels.log_level_name(4) != "ERROR" { return 12; }
  if levels.log_level_name(5) != "FATAL" { return 13; }
  if levels.log_level_name(99) != "FATAL" { return 14; }

  // ---- levels: from-name presence bands
  if !levels.log_level_from_name("").is_none { return 15; }
  if !levels.log_level_from_name("trace").is_some { return 16; }
  if !levels.log_level_from_name("WARNING").is_some { return 17; }
  if !levels.log_level_from_name("nope").is_none { return 18; }

  // ---- levels: threshold control
  levels.log_set_level(4);
  if levels.log_level_threshold() != 4 { return 19; }
  if !levels.log_enabled(4) { return 20; }
  if levels.log_enabled(3) { return 21; }
  levels.log_set_level(2);
  let all = levels.log_level_all();
  if all.len() != 6 { return 22; }
  if all[0] != 0 { return 23; }
  if all[5] != 5 { return 24; }

  // ---- color: mapping and control
  if color.log_color_by_level(4) != 31 { return 25; }
  if color.log_color_by_level(2) != 32 { return 26; }
  if color.log_color_by_level(0) != 90 { return 27; }
  if color.log_color_by_level(0 - 1) != 90 { return 28; }
  if color.log_color_by_level(9) != 35 { return 29; }
  if color.log_color_reset().len() != 4 { return 30; }
  if color.log_color(2) != _esc() + "[32m" { return 31; }
  color.log_set_color_enabled(false);
  if color.log_color_enabled() { return 32; }
  if color.log_colorize(2, "x") != "x" { return 33; }
  color.log_set_color_enabled(true);
  if !color.log_color_enabled() { return 34; }
  let colored = color.log_colorize(2, "x");
  if colored.len() <= 1 { return 35; }
  if !color.log_has_color(&colored) { return 36; }
  if color.log_has_color("plain") { return 37; }
  if color.log_has_color("") { return 38; }
  if color.log_strip_color(&colored) != "x" { return 39; }
  if color.log_strip_color("plain") != "plain" { return 40; }

  // ---- sinks: constructors
  let s_out = sinks.log_sink_stdout();
  if s_out.target != 1 { return 41; }
  if s_out.path.len() != 0 { return 42; }
  if s_out.bytes != 0 { return 43; }
  if s_out.id < 1 { return 44; }
  let s_err = sinks.log_sink_stderr();
  if s_err.target != 2 { return 45; }
  let s_null = sinks.log_sink_null();
  if s_null.target != 0 { return 46; }
  let s_raw = sinks.log_sink_new(9);
  if s_raw.target != 9 { return 47; }

  // ---- sinks: registry add/remove/survey/close
  if sinks.log_sinks().len() != 0 { return 48; }
  sinks.log_add_sink(s_null);
  if sinks.log_sinks().len() != 1 { return 49; }
  sinks.log_add_sink(s_null);
  if sinks.log_sinks().len() != 1 { return 50; }
  sinks.log_sink_close(s_null);
  if sinks.log_sinks().len() != 0 { return 51; }
  sinks.log_add_sink(s_out);
  sinks.log_remove_sink(s_out);
  if sinks.log_sinks().len() != 0 { return 52; }
  sinks.log_flush_all();
  sinks.log_sink_rotate(s_raw, 0);
  if sinks.log_sinks().len() != 0 { return 53; }

  // ---- json: entry building and formatting
  if json.log_json_thread_id() != 1 { return 54; }
  var no_fields = Vec[(Str, Str)].new();
  if json.log_json_fields(&no_fields) != "{}" { return 55; }
  let line = json.log_json_entry(2, "hello");
  if line.len() < 60 { return 56; }
  let ln2 = json.log_json_entry(5, "hello");
  if ln2.len() < 60 { return 57; }
  let parsed = json.log_json_parse(line);
  match parsed {
    Ok(e) => {
      let formatted = json.log_json_format(e);
      if formatted.len() < 40 { return 58; }
    }
    Err(_) => { return 58; }
  }

  // ---- log core: buffer state via write-count proxies
  log.log_clear_entries();
  if log.log_entry_count() != 0 { return 59; }
  if !log.log_last_entry().is_none { return 60; }
  log.log_set_min_level(log.LogLevel.Fatal);
  log.trace("filtered");
  if log.log_entry_count() != 0 { return 61; }
  log.log_set_min_level(log.LogLevel.Trace);
  let lv = log.get_level();
  log.clear_log();
  if log.log_entry_count() != 0 { return 62; }
  log.trace("t");
  if log.log_entry_count() != 1 { return 63; }
  log.debug("d");
  if log.log_entry_count() != 2 { return 64; }
  log.info("i");
  if log.log_entry_count() != 3 { return 65; }
  log.warn("w");
  if log.log_entry_count() != 4 { return 66; }
  log.error("e");
  if log.log_entry_count() != 5 { return 67; }
  log.fatal("f");
  if log.log_entry_count() != 6 { return 68; }
  log.set_level(log.LogLevel.Warn);
  log.trace("filtered2");
  if log.log_entry_count() != 6 { return 69; }
  log.set_level(log.LogLevel.Trace);

  // ---- log core: _with variants and aliases
  log.trace_with("t", Map[Str, Str]::new());
  if log.log_entry_count() != 7 { return 70; }
  log.debug_with("d", Map[Str, Str]::new());
  if log.log_entry_count() != 8 { return 71; }
  log.info_with("i", Map[Str, Str]::new());
  if log.log_entry_count() != 9 { return 72; }
  log.warn_with("w", Map[Str, Str]::new());
  if log.log_entry_count() != 10 { return 73; }
  log.error_with("e", Map[Str, Str]::new());
  if log.log_entry_count() != 11 { return 74; }
  log.log_debug_msg("d");
  if log.log_entry_count() != 12 { return 75; }
  log.log_info_msg("i");
  if log.log_entry_count() != 13 { return 76; }
  log.log_warn_msg("w");
  if log.log_entry_count() != 14 { return 77; }
  log.log_error_msg("e");
  if log.log_entry_count() != 15 { return 78; }

  // ---- log core: structured entry, last-entry, serializations
  let m = Map[Str, Str]::new();
  let e1 = log.log_with_fields(log.LogLevel.Info, "with", m);
  if e1.message != "with" { return 79; }
  if e1.file.len() != 0 { return 80; }
  if e1.line != 0 { return 81; }
  if e1.message.len() != 4 { return 82; }
  if !log.log_last_entry().is_some { return 83; }
  let txt = log.log_entries_as_text();
  if txt.len() < log.log_entry_count() { return 84; }
  let js = log.log_entries_as_json();
  if js.len() < 2 { return 85; }
  log.log_clear_entries();
  if log.log_entries_as_json() != "[]" { return 86; }
  if log.log_entries_as_text().len() != 0 { return 87; }
  log.log_set_min_level(log.LogLevel.Info);
  log.set_output_json(false);
  log.set_output_color(true);
  log.set_output_color(false);
  log.set_output_json(false);
  log.log_flush();

  return 0;
}
