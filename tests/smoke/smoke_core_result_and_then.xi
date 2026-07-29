module smoke_core_result_and_then
use xiom.core;

fn main() -> Int {
  let ok: Result[Int, Str] = Ok(10);

  let chained = ok.and_then(fn(x: Int) -> Result[Int, Str] {
    return Ok(x * 2);
  });
  match chained {
    Ok(v) => { if v != 20 { return 1; } },
    Err(_) => { return 2; },
  };

  let err: Result[Int, Str] = Err("fail");
  let chained_err = err.and_then(fn(x: Int) -> Result[Int, Str] {
    return Ok(x * 2);
  });
  if chained_err.is_ok { return 3; }

  if !ok.is_ok_and(fn(x: &Int) -> Bool { return *x == 10; }) { return 4; }
  if ok.is_ok_and(fn(x: &Int) -> Bool { return *x != 10; }) { return 5; }
  if err.is_ok_and(fn(x: &Int) -> Bool { return true; }) { return 6; }

  return 0;
}
