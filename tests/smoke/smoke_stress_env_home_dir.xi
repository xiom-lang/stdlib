module smoke_stress_env_home_dir
  use xiom.env;

  fn main() -> Int {
    var home = env.home_dir();
    match home {
      Some(_) => { return 0; }
      None => { return 1; }
    }
  }
