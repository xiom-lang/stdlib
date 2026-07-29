module smoke_io_env
use xiom.io;

fn main() -> Int {
  var home = io.env_var("PATH");
  match home {
    Some(_) => { return 0; },
    None => { return 0; },
  };

  return 0;
}
