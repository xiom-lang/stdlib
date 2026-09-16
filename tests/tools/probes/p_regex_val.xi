module p_regex_val
use xiom.io;
use xiom.convert;
use xiom.regex;
fn main() -> Int {
  var rn = regex.Regex.new("([a-z]+)([0-9]+)");
  match rn {
    Err(e) => { io.println("new err"); return 3; }
    Ok(re) => {
      match re.captures("abc123") {
        None => { io.println("no captures"); return 1; }
        Some(caps) => {
          io.println("caps.len=" + convert.int_to_string(caps.len()));
          var g0 = caps.get(0);
          if g0.is_some { io.println("g0=" + g0.unwrap().text); }
          var g1 = caps.get(1);
          if g1.is_some { io.println("g1=" + g1.unwrap().text); }
          return 0;
        }
      }
    }
  }
}
