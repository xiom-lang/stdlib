// p_path_chain.xi -- R21 regression probe (compiler lane, 2026-09-15).
// r40: compiles+runs (exit 0). r41 (HEAD + R21 WIP): type errors on the
// chained method receivers -- "cannot call 'join' on this expression".
// Controls: (a) single join + as_path on a named local works; (b) chained
// join on a method-call result fails.
module p_path_chain
use xiom.path;
use xiom.io;

fn main() -> Int {
  var p = path.Path.new("/home/user");

  // control: join result stored in a local, then method-called -- OK on r40/r41
  var one = p.join("docs");
  if one.as_path().to_str() != "/home/user" + path.path_separator() + "docs" { return 1; };

  // regression: method call directly on a method-call result (chain)
  var two = p.join("a").join("b");
  if two.as_path().to_str() != "/home/user" + path.path_separator() + "a" + path.path_separator() + "b" { return 2; };

  // regression: three-deep chain
  var three = p.join("a").join("b").join("c");
  if three.as_path().to_str() != "/home/user" + path.path_separator() + "a" + path.path_separator() + "b" + path.path_separator() + "c" { return 3; };

  io.println("P_PATH_CHAIN OK");
  io.flush_stdout();
  0
}
