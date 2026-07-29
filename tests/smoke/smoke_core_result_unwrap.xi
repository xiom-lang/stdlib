module smoke_core_result_unwrap
use xiom.core;

fn main() -> Int {
  let ok: Result[Int, Str] = Ok(42);
  if ok.unwrap_or(0) != 42 { return 1; }

  let err: Result[Int, Str] = Err("fail");
  if err.unwrap_or(99) != 99 { return 2; }

  if ok.unwrap_or_else(fn(e: Str) -> Int { return 0; }) != 42 { return 3; }
  if err.unwrap_or_else(fn(e: Str) -> Int { return 7; }) != 7 { return 4; }

  return 0;
}
