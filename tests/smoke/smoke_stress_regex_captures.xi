// XIOM stdlib stress -- Regex.captures surface.
// API reality (documented in regex.xi): Regex.new returns Result[Regex, Str];
// captures() exposes the WHOLE match only (no group extraction), so len() is
// 1 for any successful match. This smoke pins that honest surface; group
// extraction is future work, not silently assumed.
module smoke_stress_regex_captures
use xiom.regex;

fn main() -> Int {
  var rn = regex.Regex.new("[a-z]+");
  match rn {
    Err(_) => { return 3; },
    Ok(re) => {
      match re.captures("abc123") {
        None => { return 1; },
        Some(caps) => {
          if caps.len() >= 1 { return 0; } else { return 2; }
        },
      }
    },
  }
}
