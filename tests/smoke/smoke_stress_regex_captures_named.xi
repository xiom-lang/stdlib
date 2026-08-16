module smoke_stress_regex_captures_named
use xiom.regex;

fn main() -> Int {
  var re = regex.Regex.new("(?P<word>[a-z]+)(?P<num>[0-9]+)");
  match re.captures("test99") {
    Some(caps) => {
      match caps.get_named("word") {
        Some(m) => {
          if m.as_str() == "test" { return 0; } else { return 3; }
        }
        None => { return 2; }
      }
    }
    None => { return 1; }
  }
}
