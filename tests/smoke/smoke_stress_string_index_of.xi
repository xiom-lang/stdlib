// XIOM stdlib stress — xiom.string.index_of / last_index_of
// Tests first and last occurrence positions including not-found case.
// Returns 0 on success.

module smoke_stress_string_index_of
use xiom.string;

fn main() -> Int {
  var s = "ababa";
  var first = xiom.string.index_of(s, "ba");
  var last = xiom.string.last_index_of(s, "ba");
  var none = xiom.string.index_of(s, "zz");
  var first_ok = false;
  var last_ok = false;
  var none_ok = false;
  match first {
    Some(n) => { if n == 1 { first_ok = true; } }
    None => {}
  }
  match last {
    Some(n) => { if n == 3 { last_ok = true; } }
    None => {}
  }
  match none {
    Some(_) => {}
    None => { none_ok = true; }
  }
  if first_ok && last_ok && none_ok { return 0; } else { return 1; }
}
