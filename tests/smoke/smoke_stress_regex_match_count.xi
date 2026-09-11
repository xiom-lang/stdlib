// XIOM stdlib stress -- Regex.match_count surface.
// Regex.new returns Result[Regex, Str]; unwrap before calling methods.
module smoke_stress_regex_match_count
use xiom.regex;

fn main() -> Int {
  var rn = regex.Regex.new("[0-9]+");
  match rn {
    Err(_) => { return 2; },
    Ok(re) => {
      var count = re.match_count("a1b22c333");
      if count == 3 { return 0; } else { return 1; }
    },
  }
}
