module smoke_probe_sv7
use xiom.string;
use xiom.io;

fn is_number(s: Str) -> Bool {
  if s.len() == 0 { return false; }
  if s.len() > 1 && s.char_at(0) == '0' { return false; }
  var i = 0;
  while i < s.len() {
    var v = s.char_at(i) as Int;
    if v < 48 || v > 57 { return false; }
    i = i + 1;
  }
  true
}

fn valid_identifiers(s: Str) -> Bool {
  if s.len() == 0 { return true; }
  var parts = xiom.string.str_split(s, ".");
  var i = 0;
  while i < parts.len() {
    var part = parts[i];
    if part.len() == 0 { return false; }
    var j = 0;
    while j < part.len() {
      var c = part.char_at(j);
      var v = c as Int;
      var ok = (v >= 48 && v <= 57) || (v >= 65 && v <= 90) || (v >= 97 && v <= 122) || v == 45;
      if !ok { return false; }
      j = j + 1;
    }
    i = i + 1;
  }
  true
}

fn my_parse(s: Str) -> Int {
  var text = s;
  var core = text;
  var prerelease = "";
  var build = "";
  var plus = xiom.string.str_index_of(text, "+");
  if plus is Some {
    match plus {
      Some(pos) => {
        core = xiom.string.str_slice(text, 0, pos);
        build = xiom.string.str_slice(text, pos + 1, text.len());
      },
      None => {},
    }
  }
  var dash = xiom.string.str_index_of(core, "-");
  if dash is Some {
    match dash {
      Some(pos) => {
        prerelease = xiom.string.str_slice(core, pos + 1, core.len());
        core = xiom.string.str_slice(core, 0, pos);
      },
      None => {},
    }
  }
  var parts = xiom.string.str_split(core, ".");
  if parts.len() != 3 { return 1; }
  var maj = parts[0];
  var min = parts[1];
  var pat = parts[2];
  if !is_number(maj) || !is_number(min) || !is_number(pat) { return 2; }
  if !valid_identifiers(prerelease) { return 3; }
  if !valid_identifiers(build) { return 4; }
  return 0;
}

fn main() -> Int {
  var r = my_parse("1.2.3-alpha");
  if r != 0 { io.println("parse-err"); return r; }
  io.println("OK");
  return 0;
}
