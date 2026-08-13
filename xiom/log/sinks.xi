// XIOM - Log: Sinks
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.log.sinks

// Depends on: xiom.log

use xiom.io;

// ============================================================================
// Log output destinations: file, stdout, stderr and null sinks with
// registration, flushing and rotation.
//
// A `Sink` describes a destination: target 0 = null (discard), 1 = stdout,
// 2 = stderr, 3 = file (path in `path`). This module manages a process-wide
// registry of sinks; the actual line emission is performed by xiom.log.
// Flush and rotation are no-ops in this build: output is synchronous and no
// byte accounting is performed.
//
// The registry stores parallel primitive vectors (ids/targets/paths) because
// module-level Vec[Struct] element writes miscompile in this build.
// ============================================================================

/// A log output destination wrapping a file or stream target.
pub type Sink = {
  id: Int;
  target: Int;
  path: Str;
  bytes: Int;
} derive[Clone]

/// Registry of registered sinks, stored as parallel primitive vectors.
/// Public so the compiler can allocate the module-level instance.
pub type SinkList = {
  ids: Vec[Int];
  targets: Vec[Int];
  paths: Vec[Str];
}

/// Process-wide registered sinks.
var sink_list: SinkList = SinkList{ ids: Vec[Int]::new(); targets: Vec[Int]::new(); paths: Vec[Str]::new(); };

/// Next sink id handed out (1-based).
var next_id: Int = 1;

/// Wrap a raw fd as a log sink. The sink is NOT auto-registered; call
/// `log_add_sink` to register it.
/// Complexity: O(1).
pub fn log_sink_new(target: Int) -> Sink {
  let id = next_id;
  next_id = next_id + 1;
  Sink{ id: id; target: target; path: ""; bytes: 0; }
}

/// Open a file sink for appending. Returns Err when the file cannot be
/// opened for append.
/// Complexity: O(1).
pub fn log_sink_file(path: Str) -> Result[Sink, Str] {
  let probe = io.append_file(path, "");
  match probe {
    Ok(_) => {
      let id = next_id;
      next_id = next_id + 1;
      Ok(Sink{ id: id; target: 3; path: path; bytes: 0; })
    };
    Err(e) => Err(e.message);
  }
}

/// A sink that writes to stdout.
/// Complexity: O(1).
pub fn log_sink_stdout() -> Sink {
  let id = next_id;
  next_id = next_id + 1;
  Sink{ id: id; target: 1; path: ""; bytes: 0; }
}

/// A sink that writes to stderr.
/// Complexity: O(1).
pub fn log_sink_stderr() -> Sink {
  let id = next_id;
  next_id = next_id + 1;
  Sink{ id: id; target: 2; path: ""; bytes: 0; }
}

/// A sink that discards output.
/// Complexity: O(1).
pub fn log_sink_null() -> Sink {
  let id = next_id;
  next_id = next_id + 1;
  Sink{ id: id; target: 0; path: ""; bytes: 0; }
}

/// Register a sink for future log lines. Duplicate ids are ignored.
/// Complexity: O(registered sinks).
pub fn log_add_sink(s: Sink) {
  var i: Int = 0;
  var present = false;
  while i < sink_list.ids.len() {
    let id = sink_list.ids[i];
    if id == s.id {
      present = true;
    };
    i = i + 1;
  };
  if !present {
    sink_list.ids.push(s.id);
    sink_list.targets.push(s.target);
    sink_list.paths.push(s.path);
  };
}

/// Unregister a sink (matched by id).
/// Complexity: O(registered sinks).
pub fn log_remove_sink(s: Sink) {
  var out_ids = Vec[Int].new();
  var out_targets = Vec[Int].new();
  var out_paths = Vec[Str].new();
  var i: Int = 0;
  while i < sink_list.ids.len() {
    let id = sink_list.ids[i];
    if id != s.id {
      out_ids.push(id);
      let t = sink_list.targets[i];
      out_targets.push(t);
      let p = sink_list.paths[i];
      out_paths.push(p);
    };
    i = i + 1;
  };
  sink_list.ids = out_ids;
  sink_list.targets = out_targets;
  sink_list.paths = out_paths;
}

/// The currently registered sinks.
/// Complexity: O(registered sinks).
pub fn log_sinks() -> Vec[Sink] {
  var out = Vec[Sink].new();
  var i: Int = 0;
  while i < sink_list.ids.len() {
    let id = sink_list.ids[i];
    let t = sink_list.targets[i];
    let p = sink_list.paths[i];
    out.push(Sink{ id: id; target: t; path: p; bytes: 0; });
    i = i + 1;
  };
  out
}

/// Flush every registered sink. No-op in this build (output is synchronous).
/// Complexity: O(1).
pub fn log_flush_all() {
}

/// Rotate a file sink once it exceeds `max_bytes`. This build performs no
/// byte accounting, so the sink's byte counter is never advanced and rotation
/// is a no-op (documented).
/// Complexity: O(1).
pub fn log_sink_rotate(s: Sink, max_bytes: Int) {
  if s.bytes > max_bytes {
    // Rotation unsupported in this build (see header).
  };
}

/// Close a sink and release its resources: unregisters it from the registry.
/// File handles in this build are per-write and need no explicit release.
/// Complexity: O(registered sinks).
pub fn log_sink_close(s: Sink) {
  log_remove_sink(s);
}
