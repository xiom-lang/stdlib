// XIOM stdlib stress -- Captures.get_named surface.
// Named captures are NOT implemented: get_named always returns None
// (documented stub in regex.xi). This smoke pins that contract so a future
// implementation flips it deliberately.
module smoke_stress_regex_captures_named
use xiom.regex;

fn main() -> Int {
  var rn = regex.Regex.new("[a-z]+");
  match rn {
    Err(_) => { return 3; },
    Ok(re) => {
      match re.captures("test99") {
        None => { return 1; },
        Some(caps) => {
          match caps.get_named("word") {
            Some(_) => { return 2; },
            None => { return 0; },
          }
        },
      }
    },
  }
}
