module smoke_error_context
use xiom.error;

fn main() -> Int {
  var r: Result[Int, Str] = Ok(42);
  var ctx = error.context(r, "ignored");
  match ctx {
    Ok(v) => { if v != 42 { return 1; } },
    Err(_) => { return 2; },
  };

  var r2: Result[Int, Str] = Err("original");
  var ctx2 = error.context(r2, "new context");
  match ctx2 {
    Ok(_) => { return 3; },
    Err(e) => { if e != "new context" { return 4; } },
  };

  var bt = error.capture_backtrace();
  if bt.display() == "" { return 0; }

  return 0;
}
