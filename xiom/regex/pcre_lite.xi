// XIOM - Regex: PCRE-Lite
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.regex.pcre_lite

// Depends on: xiom.string

// ============================================================================
// Lightweight PCRE-style API: opaque compiled handles and C-like calls.
// NOTE: current implementation lives in regex.xi - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

// fn pcre_compile(pattern: Str, flags: Int) -> Result[Int, Str] - compile pattern to an integer handle, or Err. TODO(compiler): implement.
// fn pcre_match(compiled: Int, s: Str) -> Bool - true if the compiled pattern matches s. TODO(compiler): implement.
// fn pcre_exec(compiled: Int, s: Str) -> Vec[Int] - (start, end) index pairs of every match. TODO(compiler): implement.
// fn pcre_replace(compiled: Int, s, replacement) -> Str - replace the first match with replacement. TODO(compiler): implement.
// fn pcre_split(compiled: Int, s) -> Vec[Str] - split s around matches of the compiled pattern. TODO(compiler): implement.
// fn pcre_free(compiled: Int) - release the resources of a compiled handle. TODO(compiler): implement.
// fn pcre_version() -> Str - version string of the embedded PCRE implementation. TODO(compiler): implement.
// fn pcre_capture_count(compiled) -> Int - number of capture groups in the compiled pattern. TODO(compiler): implement.
