module smoke_core_result_deep_chain
use xiom.core;

fn div10(x: Int) -> Result[Int, Str] {
  if x % 10 == 0 { return Ok(x / 10); }
  return Err("not divisible by 10");
}

fn mul3(x: Int) -> Result[Int, Str] {
  return Ok(x * 3);
}

fn main() -> Int {
  var r: Result[Int, Str] = Ok(100);
  var result = r
    .map(fn(x: Int) -> Int { return x + 20; })
    .and_then(div10)
    .and_then(mul3)
    .map_err(fn(e: Str) -> Str { return string.str_concat("E: ", e); });
  match result {
    Ok(v) => { if v != 36 { return 1; } },
    Err(_) => { return 2; },
  };

  var r2: Result[Int, Str] = Err("bad");
  var result2 = r2.map(fn(x: Int) -> Int { return x * 2; })
                  .map_err(fn(e: Str) -> Str { return string.str_concat("wrapped: ", e); });
  match result2 {
    Ok(_) => { return 3; },
    Err(e) => { if e != "wrapped: bad" { return 4; } },
  };

  return 0;
}
