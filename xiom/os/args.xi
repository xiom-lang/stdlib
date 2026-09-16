// XIOM - Command-line argument access and parsing
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Thin binding over the runtime's captured argc/argv (xiom_get_argc /
// xiom_get_argv, filled by the generated main) plus pure helpers for the
// common flag / --key=value / positional conventions.
//
// Ownership: argument strings are COPIED out of the runtime's static argv
// into fresh buffers ([COPY] per docs/STR_OWNERSHIP.md) -- callers never
// alias runtime memory.
//
// Parsing conventions supported:
//   --flag            boolean flag        -> args_has_flag / flag_lookup
//   --key=value       inline option       -> option_value
//   --key value       spaced option       -> option_value
//   everything else   positional          -> positionals
//
// Complexity: O(n) per scan over the argument vector. Pure (helpers).

module xiom.os.args

extern "C" {
  fn xiom_get_argc() -> Int32;
  fn xiom_get_argv(i: Int32) -> *UInt8;
}

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
}

use xiom.string;

/// Copy a NUL-terminated C string into a fresh heap-backed Str.
/// [COPY] per docs/STR_OWNERSHIP.md: we measure, allocate exactly, copy,
/// terminate, and transfer ownership into the result.
fn copy_c_string(p: *UInt8) -> Str
  requires: p != null
{
  unsafe {
    var n = 0;
    while p[n] != 0 {
      n = n + 1;
    };
    var buf = malloc(n + 1);
    var i = 0;
    while i < n {
      buf[i] = p[i];
      i = i + 1;
    }
    buf[n] = 0;
    return Str.from_cstring(buf);
  }
}

/// All arguments as freshly-owned strings. Index 0 is conventionally the
/// program name when the host provides one. Complexity: O(total bytes).
pub fn args_raw() -> Vec[Str]
  requires: true  // extern argc/argv calls below (T002 confinement)
{
  var result = Vec[Str].new();
  let argc = xiom_get_argc();
  var i = 0;
  while (i as Int32) < argc {
    var p = xiom_get_argv(i as Int32);
    result.push(copy_c_string(p));
    i = i + 1;
  }
  return result;
}

/// True when args contains exactly `flag`.
/// Complexity: O(n * flag.len()). Pure.
pub fn flag_lookup(args: &Vec[Str], flag: Str) -> Bool {
  var i = 0;
  while i < args.len() {
    if args[i] == flag {
      return true;
    }
    i = i + 1;
  }
  return false;
}

/// Value for `key`: supports both `--key=value` and `--key value`.
/// Later occurrences win (last-one-wins convention, matching most CLI
/// frameworks). Returns None when absent.
/// Complexity: O(n * key.len()). Pure.
pub fn option_value(args: &Vec[Str], key: Str) -> Option[Str] {
  var found: Option[Str] = None;
  var i = 0;
  while i < args.len() {
    var a = args[i];
    if str_starts_with(a, key) {
      let klen = key.len();
      if a.len() == klen {
        // spaced form: --key value
        if i + 1 < args.len() {
          found = Some(args[i + 1]);
        }
      } else {
        // inline form requires the next char to be '='
        if string.byte_at(a, klen) == 61u8 {
          found = Some(string.str_slice(a, klen + 1, a.len()));
        }
      }
    }
    i = i + 1;
  }
  return found;
}

/// Positional arguments: every entry that does not start with '--' and is
/// not consumed as a spaced-option value of a preceding '--key'. Note this
/// simple scanner treats any '--' entry as a flag/key, never as a negative
/// number or literal.
/// Complexity: O(n). Pure.
pub fn positionals(args: &Vec[Str]) -> Vec[Str] {
  var result = Vec[Str].new();
  var i = 0;
  while i < args.len() {
    var a = args[i];
    if str_starts_with(a, "--") {
      // spaced-form key consumes the following entry
      if i + 1 < args.len() && !str_starts_with(args[i + 1], "--") {
        i = i + 1;
      }
    } else {
      result.push(a);
    }
    i = i + 1;
  }
  return result;
}

/// Convenience: flag lookup over the process's own arguments.
pub fn args_has_flag(flag: Str) -> Bool {
  var raw = args_raw();
  return flag_lookup(&raw, flag);
}

/// Convenience: option lookup over the process's own arguments.
pub fn args_option(key: Str) -> Option[Str] {
  var raw = args_raw();
  return option_value(&raw, key);
}
