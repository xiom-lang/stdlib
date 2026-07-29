module smoke_core_result_basic
use xiom.core;

fn main() -> Int {
  let ok: Result[Int, Str] = Ok(42);
  match ok {
    Ok(v) => { if v != 42 { return 1; } },
    Err(_) => { return 2; },
  };
  if !ok.is_ok { return 3; }

  let err: Result[Int, Str] = Err("fail");
  match err {
    Ok(_) => { return 4; },
    Err(e) => { if e != "fail" { return 5; } },
  };
  if err.is_ok { return 6; }

  return 0;
}
