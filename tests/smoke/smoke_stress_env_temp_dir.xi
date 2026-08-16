module smoke_stress_env_temp_dir
use xiom.env;

fn main() -> Int {
    var tmp = env.temp_dir();
    if tmp.len() > 0 {
      return 0;
    }
    return 1;
}
