module smoke_core_result_map
use xiom.core;

fn main() -> Int {
  let ok: Result[Int, Str] = Ok(10);
  let mapped = ok.map(fn(x: Int) -> Int { return x * 2; });
  match mapped {
    Ok(v) => { if v != 20 { return 1; } },
    Err(_) => { return 2; },
  };

  let err: Result[Int, Str] = Err("oops");
  let mapped_err = err.map(fn(x: Int) -> Int { return x * 2; });
  if mapped_err.is_ok { return 3; }

  let mapped_err2 = err.map_err(fn(e: Str) -> Str { return string.str_concat("ERR_", e); });
  match mapped_err2 {
    Ok(_) => { return 4; },
    Err(e) => { if e != "ERR_oops" { return 5; } },
  };

  return 0;
}
