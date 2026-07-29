module smoke_collections_btree_map
use xiom.collections;

fn main() -> Int {
  var m = BTreeMap[Int, Str].new();
  if m.len() != 0 { return 1; }

  m.insert(3, "three");
  m.insert(1, "one");
  m.insert(2, "two");
  if m.len() != 3 { return 2; }

  if !m.contains_key(1) { return 3; }
  if m.contains_key(4) { return 4; }

  match m.get(2) {
    Some(v) => { if v != "two" { return 5; } },
    None => { return 6; },
  };

  match m.first_entry() {
    Some((k, _)) => { if k != 1 { return 7; } },
    None => { return 8; },
  };
  match m.last_entry() {
    Some((k, _)) => { if k != 3 { return 9; } },
    None => { return 10; },
  };

  match m.insert(2, "TWO") {
    Some(old) => { if old != "two" { return 11; } },
    None => { return 12; },
  };

  match m.remove(2) {
    Some(v) => { if v != "TWO" { return 13; } },
    None => { return 14; },
  };
  if m.len() != 2 { return 15; }
  if m.contains_key(2) { return 16; }

  return 0;
}
