module smoke_collections_vecdeque
use xiom.collections;

fn main() -> Int {
  var d = VecDeque[Int].new();
  if d.len() != 0 { return 1; }

  d.push_back(20);
  d.push_front(10);
  d.push_back(30);
  if d.len() != 3 { return 2; }

  match d.front() {
    Some(x) => { if x != 10 { return 3; } },
    None => { return 4; },
  };
  match d.back() {
    Some(x) => { if x != 30 { return 5; } },
    None => { return 6; },
  };

  match d.pop_front() {
    Some(x) => { if x != 10 { return 7; } },
    None => { return 8; },
  };
  match d.pop_back() {
    Some(x) => { if x != 30 { return 9; } },
    None => { return 10; },
  };
  if d.len() != 1 { return 11; }

  d.pop_front();
  match d.pop_front() { Some(_) => { return 12; }, None => {}, };
  match d.pop_back() { Some(_) => { return 13; }, None => {}, };
  match d.front() { Some(_) => { return 14; }, None => {}, };
  match d.back() { Some(_) => { return 15; }, None => {}, };

  return 0;
}
