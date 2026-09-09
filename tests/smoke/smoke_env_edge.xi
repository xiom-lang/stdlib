module smoke_env_edge
use xiom.env;

fn main() -> Int {
  var p = env.path_separator();
  if p == "" { return 1; }

  match env.get_var("NONEXISTENT_VAR_12345_XYZ") {
    Ok(_) => {},
    Err(_) => {},
  };

  return 0;
}
