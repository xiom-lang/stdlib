module smoke_io_path
use xiom.io;

fn main() -> Int {
  if io.join_paths("base", "child") != "base/child" { return 1; }
  if io.join_paths("base/", "child") != "base/child" { return 2; }
  if io.join_paths("", "child") != "child" { return 3; }
  if io.join_paths("base", "") != "base" { return 4; }
  if io.join_paths("", "") != "" { return 5; }

  if io.is_absolute("/usr/bin") != true { return 6; }
  if io.is_absolute("relative") != false { return 7; }
  if io.is_absolute("") != false { return 8; }

  match io.parent_path("/usr/bin/xiom") {
    Some(p) => { if p != "/usr/bin" { return 9; } },
    None => { return 10; },
  };
  match io.parent_path("noparent") {
    Some(_) => { return 11; },
    None => {},
  };

  match io.file_name("/usr/bin/xiom") {
    Some(n) => { if n != "xiom" { return 12; } },
    None => { return 13; },
  };

  match io.extension("file.xi") {
    Some(e) => { if e != "xi" { return 14; } },
    None => { return 15; },
  };
  match io.extension("noext") {
    Some(_) => { return 16; },
    None => {},
  };

  return 0;
}
