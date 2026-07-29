// XIOM stdlib stress — LinkedList push_front/back and pop_front/back
// Tests doubly-linked list insertion and removal at both ends.
// Returns 0 on success, nonzero on failure.

module smoke_stress_collections_linkedlist
use xiom.collections;

fn main() -> Int {
  var ll = LinkedList[Int].new();
  ll.push_back(10);
  ll.push_back(20);
  ll.push_front(5);
  if ll.len() != 3 { return 1; }
  match ll.pop_front() {
    Some(v) => { if v != 5 { return 2; } }
    None => { return 3; }
  }
  match ll.pop_back() {
    Some(v) => { if v != 20 { return 4; } }
    None => { return 5; }
  }
  if ll.len() != 1 { return 6; }
  match ll.pop_front() {
    Some(v) => { if v != 10 { return 7; } }
    None => { return 8; }
  }
  if ll.len() != 0 { return 9; }
  match ll.pop_front() {
    Some(_) => { return 10; }
    None => { }
  }
  return 0;
}
