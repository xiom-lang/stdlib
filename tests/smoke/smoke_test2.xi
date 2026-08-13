// XIOM stdlib smoke — xiom.test.assert
// Returns 0 on success, nonzero (and a tag) on failure.
//
// NOTE: xiom.test.assert and xiom.test.harness cannot be imported together
// in one program — the second sibling import clobbers the first module's
// exports in this build (see report). Harness checks live in smoke_test3.xi.

module smoke_test2
use xiom.test.assert;
use xiom.io;

fn fail(tag: Str) -> Int {
  io.println("smoke_test2 FAIL: " + tag);
  return 1;
}

fn main() -> Int {
  // assert: all passing forms (failing forms panic, which aborts)
  assert.assert(true, "a1");
  assert.assert_true(true, "a2");
  assert.assert_false(false, "a3");
  assert.assert_eq(1, 1, "a4");
  assert.assert_ne(1, 2, "a5");
  assert.assert_lt(1, 2, "a6");
  assert.assert_le(2, 2, "a7");
  assert.assert_gt(3, 2, "a8");
  assert.assert_ge(3, 3, "a9");
  assert.assert_near(1.0, 1.05, 0.1, "a10");
  assert.assert_contains("hello world", "lo wo", "a11");
  assert.assert_matches("abc", "a.c", "a12");
  let okr: Result[Int, Str] = Ok(5);
  let v = assert.assert_ok(okr, "a13");
  if v != 5 { return fail("a13-value"); }
  let errr: Result[Int, Str] = Err("nope");
  assert.assert_err(errr, "a14");
  let someo: Option[Int] = Some(7);
  let sv = assert.assert_some(someo, "a15");
  if sv != 7 { return fail("a15-value"); }
  let noneo: Option[Int] = None;
  assert.assert_none(noneo, "a16");
  var empty_v = Vec[Int].new();
  assert.assert_empty(&empty_v, "a17");
  empty_v.push(1);
  empty_v.push(2);
  assert.assert_len(&empty_v, 2, "a18");

  io.println("smoke_test2 OK");
  return 0;
}
