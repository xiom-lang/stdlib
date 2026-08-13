// XIOM stdlib smoke — xiom.test.harness
// Returns 0 on success, nonzero (and a tag) on failure.
//
// NOTE: see smoke_test2.xi — assert and harness cannot be imported together
// in this build, so harness checks live here.

module smoke_test3
use xiom.test.harness;
use xiom.io;
use xiom.convert;
use xiom.string;

fn fail(tag: Str) -> Int {
  io.println("smoke_test3 FAIL: " + tag);
  return 1;
}

fn test_pass() -> Result[Unit, Str] {
  Ok(())
}

fn test_fail() -> Result[Unit, Str] {
  Err("boom")
}

fn bench_fn() {
  var i: Int = 0;
  while i < 1000 {
    i = i + 1;
  };
}

fn main() -> Int {
  // harness: add / run / filter / parallel / skip / benchmark / report
  var h = harness.test_harness_new();
  harness.harness_add_test(&h, "pass", test_pass);
  harness.harness_add_test(&h, "fail", test_fail);
  let r1 = harness.harness_run(&h);
  if harness.report_passed(&r1) != 1 { return fail("h-passed"); }
  if harness.report_failed(&r1) != 1 { return fail("h-failed"); }
  if harness.report_skipped(&r1) != 0 { return fail("h-skipped"); }
  harness.harness_skip(&h, "fail");
  let r2 = harness.harness_run(&h);
  if harness.report_passed(&r2) != 1 { return fail("h2-passed"); }
  if harness.report_failed(&r2) != 0 { return fail("h2-failed"); }
  if harness.report_skipped(&r2) != 1 { return fail("h2-skipped"); }
  let r3 = harness.harness_run_filtered(&h, "pass");
  if harness.report_passed(&r3) != 1 { return fail("h3-passed"); }
  let r4 = harness.harness_parallel(&h, 2);
  if harness.report_passed(&r4) != 1 { return fail("h4-passed"); }
  let ms = harness.harness_benchmark(&mut h, "bench", bench_fn, 100);
  if ms < 0 { return fail("h-bench"); }
  let rj = harness.report_json(&r2);
  if !string.str_contains(rj, "\"passed\":1") { return fail("h-json"); }
  harness.report_print(&r2);

  // harness: global registry via test_register / test_main
  if !harness.test_register("g1", test_pass) { return fail("g-reg1"); }
  if !harness.test_register("g2", test_pass) { return fail("g-reg2"); }
  if harness.test_main() != 0 { return fail("g-main"); }
  if !harness.test_register("g3", test_pass) { return fail("g-reg3"); }
  if !harness.test_register("g4", test_pass) { return fail("g-reg4"); }
  if !harness.test_register("g5", test_pass) { return fail("g-reg5"); }
  if !harness.test_register("g6", test_pass) { return fail("g-reg6"); }
  if !harness.test_register("g7", test_pass) { return fail("g-reg7"); }
  if !harness.test_register("g8", test_pass) { return fail("g-reg8"); }
  if harness.test_register("g9", test_pass) { return fail("g-full"); }
  if harness.test_main() != 0 { return fail("g-main-8"); }

  io.println("smoke_test3 OK");
  return 0;
}
