module smoke_stress_regex_match_count
use xiom.regex;

fn main() -> Int {
  var re = regex.Regex.new("[0-9]+");
  var count = re.match_count("a1b22c333");
  if count == 3 { return 0; } else { return 1; }
}
