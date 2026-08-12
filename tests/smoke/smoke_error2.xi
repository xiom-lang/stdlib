// XIOM stdlib smoke — xiom.error.chain + context + backtrace
// Returns 0 on success, nonzero (and a tag) on failure.

module smoke_error2
use xiom.error.chain;
use xiom.error.backtrace;
use xiom.error.context;
use xiom.io;

fn fail(tag: Str) -> Int {
  io.println("smoke_error2 FAIL: " + tag);
  return 1;
}

fn main() -> Int {
  // chain: new / push / len / top / root / has / pop / iter / messages
  var e = chain.error_chain_new("root");
  if chain.error_chain_len(e) != 1 { return fail("len1"); }
  if chain.error_chain_top(e) != "root" { return fail("top1"); }
  if chain.error_chain_root(e) != "root" { return fail("root1"); }
  e = chain.error_chain_push(e, "mid");
  if chain.error_chain_len(e) != 2 { return fail("len2"); }
  if chain.error_chain_top(e) != "mid" { return fail("top2"); }
  if chain.error_chain_root(e) != "root" { return fail("root2"); }
  e = chain.error_chain_push(e, "top");
  if chain.error_chain_len(e) != 3 { return fail("len3"); }
  if chain.error_chain_top(e) != "top" { return fail("top3"); }
  if chain.error_chain_root(e) != "root" { return fail("root3"); }
  if !chain.error_chain_has(e, "mid") { return fail("has-mid"); }
  if chain.error_chain_has(e, "nope") { return fail("has-nope"); }
  let msgs = chain.error_chain_messages(e);
  if msgs.len() != 3 { return fail("msgs-len"); }
  let m0 = msgs[0];
  let m2 = msgs[2];
  if m0 != "top" { return fail("msgs-0"); }
  if m2 != "root" { return fail("msgs-2"); }
  let nodes = chain.error_chain_iter(e);
  if nodes.len() != 3 { return fail("iter-len"); }
  let n0top = chain.error_chain_top(nodes[0]);
  if n0top != "top" { return fail("iter-0"); }
  let n2 = nodes[2];
  if chain.error_chain_len(n2) != 1 { return fail("iter-2-len"); }
  if chain.error_chain_root(n2) != "root" { return fail("iter-2-root"); }
  let popped = chain.error_chain_pop(e);
  match popped {
    Some(pe) => {
      if chain.error_chain_len(pe) != 2 { return fail("pop-len"); }
      if chain.error_chain_top(pe) != "mid" { return fail("pop-top"); }
    };
    None => { return fail("pop-none"); }
  }
  let e2 = chain.error_chain_new("only");
  let popped2 = chain.error_chain_pop(e2);
  if popped2.is_some { return fail("pop-single"); }

  // context: new / with_context / attach / get / keys / all / wrap / pretty
  var ce = context.error_context_new("base");
  if context.error_unwrap(ce) != "base" { return fail("unwrap"); }
  let ctx_opt = context.error_context(ce);
  if ctx_opt.is_some { return fail("ctx-none"); }
  ce = context.error_with_context(ce, "extra info");
  let ctx_opt2 = context.error_context(ce);
  match ctx_opt2 {
    Some(ct) => {
      if ct != "extra info" { return fail("ctx-value"); }
    };
    None => { return fail("ctx-some"); }
  }
  ce = context.error_attach_context(ce, "key1", "value1");
  let got = context.error_context_get(ce, "key1");
  match got {
    Some(g) => {
      if g != "value1" { return fail("get-value"); }
    };
    None => { return fail("get-none"); }
  }
  let nope = context.error_context_get(ce, "nope");
  if nope.is_some { return fail("get-nope"); }
  let keys = context.error_context_keys(ce);
  if keys.len() != 1 { return fail("keys-len"); }
  let k0 = keys[0];
  if k0 != "key1" { return fail("keys-0"); }
  let pairs = context.error_context_all(ce);
  if pairs.len() != 1 { return fail("all-len"); }
  let pk = pairs[0].0;
  let pv = pairs[0].1;
  if pk != "key1" { return fail("all-k"); }
  if pv != "value1" { return fail("all-v"); }
  let pretty = context.error_pretty_print(ce);
  if pretty.len() == 0 { return fail("pretty-empty"); }
  let ul = context.error_unwrap(ce);
  if ul.len() <= 0 { return fail("unwrap-nonempty"); }
  ce = context.error_wrap(ce, "outer");
  if context.error_unwrap(ce) != "outer" { return fail("wrap-head"); }
  let pchain = context.error_pretty_print_chain(ce);
  if pchain.len() == 0 { return fail("pchain-empty"); }

  // backtrace: new / with_backtrace / enabled / capture / symbolize
  var be = backtrace.error_backtrace_new("boom");
  if backtrace.error_has_backtrace(be) { return fail("bt-false"); }
  if backtrace.error_backtrace_depth(be) != 0 { return fail("bt-depth"); }
  be = backtrace.error_with_backtrace(be);
  if backtrace.error_backtrace_depth(be) != 0 { return fail("bt-attach"); }
  if !backtrace.error_backtrace_enabled() { return fail("bt-enabled"); }
  backtrace.error_set_backtrace_enabled(false);
  if backtrace.error_backtrace_enabled() { return fail("bt-disabled"); }
  backtrace.error_set_backtrace_enabled(true);
  let cap = backtrace.error_capture_backtrace();
  if cap.len() != 0 { return fail("bt-capture"); }
  var frames = Vec[Int].new();
  frames.push(0);
  frames.push(255);
  frames.push(16);
  let syms = backtrace.error_backtrace_symbolize(&frames);
  if syms.len() != 3 { return fail("syms-len"); }
  let s0 = syms[0];
  let s1 = syms[1];
  let s2 = syms[2];
  if s0 != "0x0" { return fail("syms-0"); }
  if s1 != "0xff" { return fail("syms-1"); }
  if s2 != "0x10" { return fail("syms-2"); }

  io.println("smoke_error2 OK");
  return 0;
}
