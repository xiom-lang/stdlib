// XIOM stdlib smoke test — xiom.regex
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_regex
use xiom.regex;

fn main() -> Int {
  let re = xiom.regex.Regex.new("h.*o").unwrap();
  if re.is_match("hello") && !re.is_match("world") {
    return 0;
  }
  return 1;
}
