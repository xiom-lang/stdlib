module p_only_sg
use xiom.io.console;
fn main() -> Int {
  console.console_write_line("pre");
  console.console_flush();
  var g = xiom.string.glob.glob_match("*.xi", "main.xi");
  console.console_write_line("post");
  console.console_flush();
  return 0;
}
