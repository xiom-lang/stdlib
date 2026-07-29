// XIOM stdlib smoke test — xiom.regex
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_regex
use xiom.regex;

fn main() -> Int {
  var re = match xiom.regex.Regex.new("h.*o") { Ok(r) => r; Err(_) => { return 1; } };
  if re.is_match("hello") && not re.is_match("world") {
    return 0;
  }
  return 1;
}
