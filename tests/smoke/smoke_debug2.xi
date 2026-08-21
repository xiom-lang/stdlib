// XIOM stdlib smoke -- xiom.debug.trace + heap_report + disasm
// Returns 0 on success, nonzero (and a tag) on failure.

module smoke_debug2
use xiom.debug.trace;
use xiom.debug.heap_report;
use xiom.debug.disasm;
use xiom.io;
use xiom.convert;
use xiom.string;

fn fail(tag: Str) -> Int {
  io.println("smoke_debug2 FAIL: " + tag);
  return 1;
}

fn main() -> Int {
  // trace: enable / depth / enter / exit / backtrace / location / symbols
  if trace.trace_enabled() { return fail("t-enabled-default"); }
  trace.trace_set_enabled(true);
  if !trace.trace_enabled() { return fail("t-enabled-set"); }
  if trace.trace_depth() != 0 { return fail("t-depth0"); }
  trace.trace_enter("alpha");
  if trace.trace_depth() != 1 { return fail("t-depth1"); }
  trace.trace_enter("beta");
  if trace.trace_depth() != 2 { return fail("t-depth2"); }
  if trace.trace_source_location() != "beta" { return fail("t-location"); }
  if trace.trace_current_function() != "beta" { return fail("t-function"); }
  if trace.trace_current_line() != 0 { return fail("t-line"); }
  let bt = trace.trace_backtrace();
  if bt.len() != 2 { return fail("t-bt-len"); }
  let b0 = bt[0];
  if b0 != "beta" { return fail("t-bt-0"); }
  trace.trace_exit("beta");
  if trace.trace_depth() != 1 { return fail("t-depth-after-exit"); }
  trace.trace_exit("alpha");
  if trace.trace_depth() != 0 { return fail("t-depth-clear"); }
  trace.trace_exit("nope");
  if trace.trace_depth() != 0 { return fail("t-depth-clamped"); }
  var frames = Vec[Int].new();
  frames.push(0);
  frames.push(255);
  let syms = trace.trace_backtrace_symbols(&frames);
  if syms.len() != 2 { return fail("t-syms-len"); }
  let s0 = syms[0];
  let s1 = syms[1];
  if s0 != "0x0" { return fail("t-syms-0"); }
  if s1 != "0xff" { return fail("t-syms-1"); }
  trace.trace_set_enabled(false);

  // heap_report: counters / reports / reset / snapshot / top / is_empty
  if heap_report.heap_usage() != 0 { return fail("h-usage"); }
  if heap_report.heap_allocations() != 0 { return fail("h-alloc"); }
  if heap_report.heap_frees() != 0 { return fail("h-frees"); }
  if heap_report.heap_live_objects() != 0 { return fail("h-live"); }
  if !heap_report.heap_is_empty() { return fail("h-empty"); }
  let rep = heap_report.heap_report();
  if rep.len() == 0 { return fail("h-report-empty"); }
  if !string.str_contains(rep, "heap usage") { return fail("h-report-text"); }
  let repj = heap_report.heap_report_json();
  if repj.len() == 0 { return fail("h-report-json-empty"); }
  if !string.str_contains(repj, "\"usage_bytes\":0") { return fail("h-report-json"); }
  if heap_report.heap_peak_usage() != 0 { return fail("h-peak"); }
  heap_report.heap_reset_stats();
  if heap_report.heap_allocations() != 0 { return fail("h-reset"); }
  let snap = heap_report.heap_snapshot();
  if snap.len() != 0 { return fail("h-snapshot"); }
  let top = heap_report.heap_top_allocations(3);
  if top.len() != 0 { return fail("h-top"); }

  // disasm: documented-unavailable entry points
  if disasm.disasm_arch_supported("x86_64") { return fail("d-arch"); }
  var empty_bytes = Vec[UInt8].new();
  let db = disasm.disasm_bytes(&empty_bytes, "x86_64");
  if db.is_ok { return fail("d-bytes"); }
  let df = disasm.disasm_function(0, 16);
  if df.is_ok { return fail("d-func"); }
  let di = disasm.disasm_instruction_length(&empty_bytes, 0);
  if di.is_ok { return fail("d-ilen"); }
  let ds = disasm.disasm_syntax("x86_64", true);
  if ds.is_ok { return fail("d-syntax"); }
  let dsym = disasm.disasm_symbolize(1234);
  if dsym.is_some { return fail("d-symbolize"); }
  let dinfo = disasm.disasm_debug_info(1234);
  if dinfo.is_some { return fail("d-debuginfo"); }

  io.println("smoke_debug2 OK");
  return 0;
}
