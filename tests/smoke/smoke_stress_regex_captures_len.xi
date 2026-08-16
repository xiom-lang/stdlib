module smoke_stress_regex_captures_len
use xiom.regex;

fn main() -> Int {
  var re = regex.Regex.new("([a-z]+)([0-9]+)");
  match re.captures("foo7") {
    Some(caps) => {
      if caps.len() > 0 { return 0; } else { return 2; }
    }
    None => { return 1; }
}
