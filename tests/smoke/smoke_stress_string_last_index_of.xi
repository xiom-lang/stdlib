// XIOM stdlib stress — xiom.string.last_index_of boundary
// Tests last_index_of for single char, multi-char substring, and not-found.
// Returns 0 on success, nonzero on failure.

module smoke_stress_string_last_index_of
use xiom.string;

fn main() -> Int {
  var s = "a1b1c1d";
  var last1 = xiom.string.last_index_of(s, "1");
  var lastb = xiom.string.last_index_of(s, "b");
  var none = xiom.string.last_index_of(s, "zz");
  var ok1 = false;
  var ok2 = false;
  var ok3 = false;
  match last1 {
    Some(n) => { if n == 5 { ok1 = true; } }
    None => {}
  }
  match lastb {
    Some(n) => { if n == 2 { ok2 = true; } }
    None => {}
  }
  match none {
    Some(_) => {}
    None => { ok3 = true; }
  }
  if ok1 && ok2 && ok3 { return 0; } else { return 1; }
}
