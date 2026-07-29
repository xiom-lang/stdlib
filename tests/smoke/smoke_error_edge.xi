module smoke_error_edge
use xiom.error;

fn main() -> Int {
  var r: Result[Int, Str] = Ok(0);
  var w = error.wrap_error(r, "context");
  match w {
    Ok(v) => { if v != 0 { return 1; } },
    Err(_) => { return 2; },
  };

  var r2: Result[Int, Str] = Err("fail");
  var w2 = error.wrap_error(r2, "wrap");
  match w2 {
    Ok(_) => { return 3; },
    Err(e) => { if e == "" { return 4; } },
  };

  var r3: Result[Int, Str] = Err("x");
  var ctx = error.context(r3, "ctx");
  match ctx {
    Ok(_) => { return 5; },
    Err(e) => { if e != "ctx" { return 6; } },
  };

  return 0;
}
