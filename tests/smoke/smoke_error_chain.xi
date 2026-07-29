module smoke_error_chain
use xiom.error;

fn main() -> Int {
  var err1 = "root error";
  var err2 = "wrapped error";

  var r: Result[Int, Str] = Err(err1);
  var wrapped = error.wrap_error(r, err2);
  match wrapped {
    Ok(_) => { return 1; },
    Err(e) => {
      if e == "" { return 2; }
    },
  };

  return 0;
}
