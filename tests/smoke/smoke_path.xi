module smoke_path
use xiom.path;

fn main() -> Int {
  // Test Path.new and basic accessors
  let p = path.Path.new("/home/user/file.txt");

  // is_absolute / is_relative / has_root
  if !p.is_absolute() { return 1; }
  let rel = path.Path.new("docs/readme.md");
  if !rel.is_relative() { return 2; }
  if p.to_str() != "/home/user/file.txt" { return 3; }
  if !p.has_root() { return 4; }

  // PathBuf push (value-type, returns modified PathBuf)
  var pb = path.PathBuf.from("/tmp");
  pb = pb.push("test.xi");
  if pb.as_path().to_str() != "/tmp/test.xi" { return 5; }

  // components
  var comps = p.components();
  if comps.len() < 2 { return 6; }

  // path_separator
  if path.path_separator() != "/" { return 7; }

  return 0;
}
