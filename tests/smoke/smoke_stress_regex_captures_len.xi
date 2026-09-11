// XIOM stdlib stress -- Captures.len surface.
// Exactly 1 for a successful match (whole match only; no group extraction).
module smoke_stress_regex_captures_len
use xiom.regex;

fn main() -> Int {
  var rn = regex.Regex.new("[a-z]+");
  match rn {
    Err(_) => { return 3; },
    Ok(re) => {
      match re.captures("foo7") {
        None => { return 1; },
        Some(caps) => {
          if caps.len() == 1 { return 0; } else { return 2; }
        },
      }
    },
  }
}
