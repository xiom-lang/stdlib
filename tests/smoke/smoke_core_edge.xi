module smoke_core_edge
use xiom.core;

fn main() -> Int {
  let n: Option[Int] = None;
  if n.unwrap_or(0) != 0 { return 1; }

  let ok: Result[Int, Str] = Ok(42);
  if ok.unwrap_or(0) != 42 { return 2; }
  let err: Result[Int, Str] = Err("x");
  if err.unwrap_or(99) != 99 { return 3; }

  let r: Result[Int, Str] = Ok(1);
  let chained = r.map(fn(x: Int) -> Int { return x + 1; })
                  .and_then(fn(x: Int) -> Result[Int, Str] { return Ok(x * 5); });
  match chained {
    Ok(v) => { if v != 10 { return 4; } },
    Err(_) => { return 5; },
  };

  let o = Some(3);
  let mapped = o.map(fn(x: Int) -> Int { return x * 2; })
                 .and_then(fn(x: Int) -> Option[Int] { return Some(x + 1); });
  match mapped {
    Some(v) => { if v != 7 { return 6; } },
    None => { return 7; },
  };

  return 0;
}
