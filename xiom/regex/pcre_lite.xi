// XIOM - Regex: PCRE-Lite
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.regex.pcre_lite

// Depends on: xiom.string

use xiom.string;
use xiom.regex.engine;
use xiom.regex.syntax;

// ============================================================================
// Lightweight PCRE-style API: opaque compiled handles and C-like calls.
//
// `pcre_compile` returns a positive integer handle into a process-wide pattern
// registry; the handle stays valid for the life of the process (pcre_free is
// a documented no-op because the registry is never evicted). The supported
// pattern syntax is the compact engine subset documented in
// xiom.regex.engine; flags are reserved (only 0 is honoured -- case
// insensitivity and the other PCRE flags are not implemented).
// ============================================================================

/// Internal registry of compiled patterns, keyed by handle - 1.
/// Public so the compiler can allocate the module-level registry for
/// imported modules.
pub type PcreRegistry = {
  patterns: Vec[Str];
}

/// Process-wide compiled-pattern registry.
var registry: PcreRegistry = PcreRegistry{ patterns: Vec[Str]::new(); };

/// Next handle to hand out (1-based; 0 is never a valid handle).
var next_handle: Int = 1;

/// Look up the pattern text stored under `handle`, or None when the handle is
/// not a live compiled pattern.
fn pattern_for(handle: Int) -> Option[Str] {
  let idx = handle - 1;
  if idx < 0 || idx >= registry.patterns.len() {
    return None;
  };
  let pat = registry.patterns[idx];
  Some(pat)
}

/// Compile `pattern` to an integer handle, or `Err` on invalid syntax.
/// `flags` is reserved for future PCRE options and is currently ignored
/// (documented: only flags == 0 is honoured).
/// Complexity: O(len(pattern)).
pub fn pcre_compile(pattern: Str, flags: Int) -> Result[Int, Str] {
  if !syntax.regex_validate(pattern) {
    return Err("invalid regex pattern");
  };
  registry.patterns.push(pattern);
  let handle = next_handle;
  next_handle = next_handle + 1;
  Ok(handle)
}

/// True when the compiled pattern `compiled` matches somewhere in `s`
/// (search semantics, not whole-string). False for invalid handles.
/// Complexity: O(len(s) * len(pattern)) worst case.
pub fn pcre_match(compiled: Int, s: Str) -> Bool {
  let pat = pattern_for(compiled);
  match pat {
    Some(p) => engine.regex_is_match(p, s);
    None => false;
  }
}

/// Every match of the compiled pattern `compiled` in `s` as flattened
/// (start, end) byte-index pairs: [s0, e0, s1, e1, ...].
/// Empty for invalid handles or no matches.
/// Complexity: O(len(s) * len(pattern)) worst case.
pub fn pcre_exec(compiled: Int, s: Str) -> Vec[Int] {
  var out = Vec[Int].new();
  let pat = pattern_for(compiled);
  match pat {
    Some(p) => {
      let matches = engine.regex_matches(p, s);
      var i: Int = 0;
      while i < matches.len() {
        out.push(matches[i].start);
        out.push(matches[i].end);
        i = i + 1;
      };
    };
    None => {};
  };
  out
}

/// Replace the first match of the compiled pattern `compiled` in `s` with
/// `replacement`. Returns `s` unchanged for invalid handles.
/// Complexity: O(len(s) + len(replacement)).
pub fn pcre_replace(compiled: Int, s: Str, replacement: Str) -> Str {
  let pat = pattern_for(compiled);
  match pat {
    Some(p) => {
      let r = engine.regex_compile(p);
      match r {
        Ok(re) => engine.regex_replace(re, s, replacement);
        Err(_) => s;
      }
    };
    None => s;
  }
}

/// Split `s` around every match of the compiled pattern `compiled`.
/// Returns [s] (a single segment) for invalid handles.
/// Complexity: O(len(s) * len(pattern)) worst case.
pub fn pcre_split(compiled: Int, s: Str) -> Vec[Str] {
  var out = Vec[Str].new();
  let pat = pattern_for(compiled);
  match pat {
    Some(p) => {
      let r = engine.regex_compile(p);
      match r {
        Ok(re) => engine.regex_split(re, s);
        Err(_) => {
          out.push(s);
          out
        };
      }
    };
    None => {
      out.push(s);
      out
    };
  }
}

/// Release the resources of a compiled handle. The registry keeps patterns
/// alive for the whole process, so this is a documented no-op.
/// Complexity: O(1).
pub fn pcre_free(compiled: Int) {
  // Intentionally empty: handles remain valid for the process lifetime.
}

/// Version string of this embedded PCRE implementation.
/// Complexity: O(1).
pub fn pcre_version() -> Str {
  "xiom-pcre-lite/1.0 (subset)"
}

/// Number of capture groups in the compiled pattern. The engine has no group
/// syntax, so this is always 0 for valid handles; invalid handles also
/// return 0.
/// Complexity: O(1).
pub fn pcre_capture_count(compiled: Int) -> Int {
  let pat = pattern_for(compiled);
  match pat {
    Some(_) => 0;
    None => 0;
  }
}
