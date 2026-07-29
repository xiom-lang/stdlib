// XIOM stdlib stress — VecDeque push_front/back and pop_front/back
// Tests double-ended queue insertion and removal at both ends.
// Returns 0 on success, nonzero on failure.

module smoke_stress_collections_vecdeque
use xiom.collections;

fn main() -> Int {
  var dq = VecDeque[Int].new();
  dq.push_back(20);
  dq.push_front(10);
  dq.push_back(30);
  if dq.len() != 3 { return 1; }
  match dq.pop_front() {
    Some(v) => { if v != 10 { return 2; } }
    None => { return 3; }
  }
  match dq.pop_back() {
    Some(v) => { if v != 30 { return 4; } }
    None => { return 5; }
  }
  match dq.pop_front() {
    Some(v) => { if v != 20 { return 6; } }
    None => { return 7; }
  }
  if dq.len() != 0 { return 8; }
  dq.push_front(99);
  dq.push_back(100);
  if dq.len() != 2 { return 9; }
  match dq.pop_front() {
    Some(v) => { if v != 99 { return 10; } }
    None => { return 11; }
  }
  match dq.pop_back() {
    Some(v) => { if v != 100 { return 12; } }
    None => { return 13; }
  }
  return 0;
}
