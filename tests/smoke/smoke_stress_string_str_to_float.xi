// XIOM stdlib stress — xiom.string.str_to_float valid and edge
// Parses a valid float, verifies invalid input returns Err.
// Returns 0 on success.

module smoke_stress_string_str_to_float
use xiom.string;

fn main() -> Int {
  var ok = xiom.string.str_to_float("3.14");
  var bad = xiom.string.str_to_float("xyz");
  var is_ok = false;
  var is_err = false;
  match ok {
    Ok(_) => { is_ok = true; }
    Err(_) => {}
  }
  match bad {
    Ok(_) => {}
    Err(_) => { is_err = true; }
  }
  if is_ok && is_err { return 0; } else { return 1; }
}
