module smoke_env_args_exe
use xiom.env;

fn main() -> Int {
  var a = env.args();
  if a.len() < 1 { return 1; }

  match env.current_exe() {
    Ok(e) => { if e == "" { return 2; } },
    Err(_) => {},
  };

  return 0;
}
