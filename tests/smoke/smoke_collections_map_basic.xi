module smoke_collections_map_basic
use xiom.collections;

fn main() -> Int {
  var m = Map[Str, Int].new();
  if m.len() != 0 { return 1; }

  m.insert("one", 1);
  m.insert("two", 2);
  m.insert("three", 3);
  if m.len() != 3 { return 2; }

  if !m.contains("one") { return 3; }
  if !m.contains("two") { return 4; }
  if m.contains("four") { return 5; }

  match m.get("one") {
    Some(v) => { if v != 1 { return 6; } },
    None => { return 7; },
  };
  match m.get("three") {
    Some(v) => { if v != 3 { return 8; } },
    None => { return 9; },
  };
  match m.get("four") {
    Some(_) => { return 10; },
    None => {},
  };

  var keys = m.keys();
  if keys.len() != 3 { return 11; }

  var vals = m.values();
  if vals.len() != 3 { return 12; }

  return 0;
}
