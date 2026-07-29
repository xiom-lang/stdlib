module smoke_core_result_chains
use xiom.core;

fn main() -> Int {
  var r1: Result[Int, Str] = Ok(10);
  var r2 = r1.map(fn(x: Int) -> Int { return x + 1; })
             .and_then(fn(x: Int) -> Result[Int, Str] { return Ok(x * 3); })
             .map(fn(x: Int) -> Int { return x - 5; });
  match r2 {
    Ok(v) => { if v != 28 { return 1; } },
    Err(_) => { return 2; },
  };

  var r3: Result[Int, Str] = Err("fail");
  var r4 = r3.map(fn(x: Int) -> Int { return x + 1; })
             .map_err(fn(e: Str) -> Str { return string.str_concat("ERR: ", e); });
  match r4 {
    Ok(_) => { return 3; },
    Err(e) => { if e != "ERR: fail" { return 4; } },
  };

  return 0;
}
