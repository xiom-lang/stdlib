// p_wave21_shapes.xi -- contract shape validation for wave 21 (error).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the shapes wave 21 applies to xiom.error:
// 1. identity result equality with a Str parameter: `result == err`
// 2. length arithmetic with a constant: `result.len() == msg.len() +
//    ctx.len() + 12`
// 3. conditional identity: `a.len() == 0 => result == b`
// 4. combined-hypothesis length: `a.len() > 0 && b.len() > 0 =>
//    result.len() == a.len() + b.len() + 2`
// 5. accessor relation across functions: `result.len() ==
//    error_chain_len(e)`
// 6. constructor relation on the result: `error_chain_len(result) ==
//    error_chain_len(e) + 1`
// 7. Option-result split: `result is Some => ...` / `result is None => ...`
// 8. Option parameter into a Result: `o is Some => result is Ok` /
//    `o is None => result is Err`
// main() drives the real functions and asserts the properties the clauses
// will require. Returns 0 when every shape compiles and holds.

module p_wave21_shapes

use xiom.error;
use xiom.error.backtrace;
use xiom.error.backtrace.BtError;
use xiom.error.chain;
use xiom.error.chain.ChainError;
use xiom.error.context;
use xiom.error.context.ContextError;

// Shape 1: identity.
fn s_ident(err: Str) -> Str
  ensures: result == err
{
  return error.error_message(err);
}

// Shape 2: constant length arithmetic.
fn s_ctx(msg: Str, ctx: Str) -> Str
  ensures: result.len() == msg.len() + ctx.len() + 12
{
  return error.error_context(msg, ctx);
}

// Shapes 3+4: conditional and combined identities.
fn s_join(a: Str, b: Str) -> Str
  ensures: a.len() == 0 => result == b
  ensures: b.len() == 0 => result == a
  ensures: a.len() > 0 && b.len() > 0 => result.len() == a.len() + b.len() + 2
{
  return error.error_join(a, b);
}

// Shape 5: accessor relation across functions.
fn s_bt_frames(e: BtError) -> Vec[Str]
  ensures: result.len() == backtrace.error_backtrace_depth(e)
{
  return backtrace.error_backtrace(e);
}

fn s_chain_messages(e: ChainError) -> Vec[Str]
  ensures: result.len() == chain.error_chain_len(e)
{
  return chain.error_chain_messages(e);
}

fn s_chain_iter(e: ChainError) -> Vec[ChainError]
  ensures: result.len() == chain.error_chain_len(e)
{
  return chain.error_chain_iter(e);
}

// Shape 6: constructor relation on the result.
fn s_push(e: ChainError, m: Str) -> ChainError
  ensures: chain.error_chain_len(result) == chain.error_chain_len(e) + 1
{
  return chain.error_chain_push(e, m);
}

// Shape 7: Option-result split.
fn s_pop(e: ChainError) -> Option[ChainError]
  ensures: result is Some => chain.error_chain_len(e) >= 2
  ensures: result is None => chain.error_chain_len(e) <= 1
{
  return chain.error_chain_pop(e);
}

// Shape 8: Option parameter into a Result.
fn s_okor(o: Option[Int], msg: Str) -> Result[Int, Str]
  ensures: o is Some => result is Ok
  ensures: o is None => result is Err
{
  match o {
    Some(v) => Ok(v);
    None => Err(msg);
  };
}

fn main() -> Int {
  if s_ident("boom") != "boom" { return 1; }
  let c = s_ctx("m", "k=v");
  if c.len() != 1 + 3 + 12 { return 2; }
  if s_join("", "b") != "b" { return 3; }
  if s_join("a", "") != "a" { return 4; }
  if s_join("a", "b") != "a: b" { return 5; }

  var e = chain.error_chain_new("root");
  e = chain.error_chain_push(e, "outer");
  if chain.error_chain_len(e) != 2 { return 6; }
  let msgs = s_chain_messages(e);
  if msgs.len() != 2 { return 7; }
  let nodes = s_chain_iter(e);
  if nodes.len() != 2 { return 8; }
  let popped = s_pop(e);
  if popped is Some {
    if chain.error_chain_len(popped.value) != 1 { return 9; }
  }
  let single = chain.error_chain_new("only");
  if chain.error_chain_len(single) != 1 { return 10; }

  let bt = backtrace.error_backtrace_new("boom");
  let frames = s_bt_frames(bt);
  if frames.len() != 0 { return 11; }
  let empty_frames: Vec[Int] = Vec[Int].new();
  let syms = backtrace.error_backtrace_symbolize(&empty_frames);
  if syms.len() != 0 { return 12; }

  let ce = context.error_context_new("boom");
  let c2 = context.error_attach_context(ce, "k", "v");
  let keys = context.error_context_keys(c2);
  let all = context.error_context_all(c2);
  if keys.len() != all.len() { return 13; }

  let some_ok = s_okor(Some(3), "missing");
  if some_ok is Err { return 14; }
  let none_err = s_okor(None, "missing");
  if none_err is Ok { return 15; }
  return 0;
}
