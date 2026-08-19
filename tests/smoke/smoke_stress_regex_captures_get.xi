module smoke_stress_regex_captures_get
use xiom.regex;

fn main() -> Int {
  var re = regex.Regex.new("([a-z]+)([0-9]+)");
  match re.captures("hello42") {
    Some(caps) => {
      match caps.get(1) {
        Some(m) => {
          if m.text == "hello" { return 0; } else { return 3; }
        }
        None => { return 2; }
      }
    }
    None => { return 1; }
  }
}
