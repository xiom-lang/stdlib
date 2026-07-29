module smoke_stress_path_pop_clear
use xiom.path;

fn main() -> Int {
  var pb = path.PathBuf.new();
  pb.push("a");
  pb.push("b");
  pb.push("c");
  if pb.as_path().ends_with(path.Path.new("c")) {
    pb.pop();
    if pb.as_path().ends_with(path.Path.new("b")) {
      pb.clear();
      var s = pb.as_path().to_str();
      if s.len() == 0 { return 0; } else { return 3; }
    } else { return 2; }
  } else { return 1; }
}
