module smoke_collections_map_edge
use xiom.collections;

fn main() -> Int {
  var m = Map[Int, Str].new();
  match m.get(0) { Some(_) => { return 1; }, None => {}, };
  match m.remove(0) { Some(_) => { return 2; }, None => {}, };
  if m.contains(0) { return 3; }

  m.insert(42, "answer");
  m.insert(42, "override");
  match m.get(42) {
    Some(v) => { if v != "override" { return 4; } },
    None => { return 5; },
  };
  if m.len() != 1 { return 6; }

  match m.remove(42) {
    Some(v) => { if v != "override" { return 7; } },
    None => { return 8; },
  };
  if m.len() != 0 { return 9; }
  if m.contains(42) { return 10; }

  var i: Int = 0;
  while i < 50 {
    m.insert(i, "val");
    i = i + 1;
  }
  if m.len() != 50 { return 11; }
  m.clear();
  if m.len() != 0 { return 12; }

  return 0;
}
