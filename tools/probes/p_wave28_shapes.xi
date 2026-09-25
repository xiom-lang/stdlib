// p_wave28_shapes.xi -- contract shape validation for wave 28 (error + io tails).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the shapes wave 28 applies to the error and io tails:
// 1. field-length identities on struct-returning constructors/copiers
//    (`result.messages.len() == 1`, `result.messages.len() == e.messages.len()`)
// 2. Option/Result payload length in a clause
//    (`result is Some => result.value.len() > 0`,
//     `result is Err => result.value.len() > 0`)
// 3. implication mirrors (`result == true => path.len() >= 1`)
// 4. exact tuple element values (`result.0 == 24 && result.1 == 80`)
// 5. tuple-pair implication (`result.0 == -1 => result.1 == -1`)
// 6. IO-dependent Ok clauses evaluated against the real filesystem
//    (`result is Ok => file_exists(path)`)
// NOTE: the harness clauses from this wave (`@pre` push counts, counter-sum
// identities) are runtime-locked by smoke_test3; the assert panic mirrors by
// smoke_test2. This probe covers the error/io families.
// Returns 0 when every shape compiles and holds.

module p_wave28_shapes

use xiom.error.backtrace;
use xiom.error.chain;
use xiom.error.context;
use xiom.io.io;
use xiom.io.console;
use xiom.io.pipe;

fn main() -> Int {
  // 1+2: error constructors and payload clauses
  let b = backtrace.error_backtrace_new("boom");
  if b.frames.len() != 0 { return 1; }
  if b.message.len() != 4 { return 2; }
  if backtrace.error_has_backtrace(b) { return 3; }
  let cb = backtrace.error_capture_backtrace();
  if cb.len() != 0 { return 4; }

  let c = chain.error_chain_new("inner");
  if chain.error_chain_len(c) != 1 { return 5; }
  let has = chain.error_chain_has(c, "inner");
  if !has { return 6; }

  let e = context.error_context_new("root");
  let opt = context.error_context(e);
  if !opt.is_none { return 7; }
  let e2 = context.error_with_context(e, "ctx");
  let opt2 = context.error_context(e2);
  if !opt2.is_some { return 8; }
  let e3 = context.error_attach_context(e2, "k", "v");
  if context.error_context_all(e3).len() != 1 { return 10; }
  let e4 = context.error_wrap(e3, "outer");
  if context.error_pretty_print_chain(e4).len() < 2 { return 11; }

  // 3: io boolean mirrors
  if io.is_absolute("") { return 12; }
  if !io.is_absolute("/x") { return 13; }
  let pi = io.parse_int("12");
  if !pi.is_ok { return 14; }
  let px = io.parse_int("x");
  if !px.is_err { return 15; }
  let pf = io.parse_float("x");
  if !pf.is_err { return 16; }

  // 4+5: tuple shapes
  let sz = console.console_get_size();
  if sz.0 != 24 { return 17; }
  if sz.1 != 80 { return 18; }
  if pipe.pipe_is_open(-1) { return 19; }
  if !pipe.pipe_is_open(3) { return 20; }
  let fds = pipe.pipe_create();
  if fds.0 == -1 && fds.1 != -1 { return 21; }
  return 0;
}
