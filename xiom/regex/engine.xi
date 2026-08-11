// XIOM - Regex: Engine
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.regex.engine

// Depends on: xiom.string

// ============================================================================
// Compiled regex matching engine: match, find, capture, replace, split.
// NOTE: current implementation lives in regex.xi - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

// fn regex_compile(pattern: Str) -> Result[Regex, Str] - compile a pattern (Regex is a compiled pattern struct), or Err on invalid syntax. TODO(compiler): implement.
// fn regex_match(r: Regex, s: Str) -> Bool - true if the regex matches the whole string. TODO(compiler): implement.
// fn regex_find(r: Regex, s: Str) -> Option[Match] - first match (Match struct holds start, end, text), or None. TODO(compiler): implement.
// fn regex_find_all(r, s) -> Vec[Match] - all non-overlapping matches. TODO(compiler): implement.
// fn regex_captures(r, s) -> Option[Vec[Str]] - capture groups of the first match, or None. TODO(compiler): implement.
// fn regex_capture_names(r) -> Vec[Str] - names of the named capture groups. TODO(compiler): implement.
// fn regex_is_match(pattern, s) -> Bool - convenience: compile then whole-string match. TODO(compiler): implement.
// fn regex_matches(pattern, s) -> Vec[Match] - convenience: compile then find all matches. TODO(compiler): implement.
// fn regex_replace(r, s, replacement: Str) -> Str - replace the first match with replacement. TODO(compiler): implement.
// fn regex_replace_all(r, s, replacement) -> Str - replace every non-overlapping match with replacement. TODO(compiler): implement.
// fn regex_split(r, s) -> Vec[Str] - split s around matches of the regex. TODO(compiler): implement.
// fn regex_find_iter(r, s) -> Vec[Match] - lazily-ordered iterator of all matches as a Vec. TODO(compiler): implement.
