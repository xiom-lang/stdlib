module smoke_env_dir
use xiom.env;

fn main() -> Int {
  match env.current_dir() {
    Ok(d) => { if d == "" { return 1; } },
    Err(_) => {},
  };

  match env.home_dir() {
    Some(h) => { if h == "" { return 2; } },
    None => {},
  };

  return 0;
}
