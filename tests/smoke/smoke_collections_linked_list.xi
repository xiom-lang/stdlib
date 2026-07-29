module smoke_collections_linked_list
use xiom.collections;

fn main() -> Int {
  var l = LinkedList[Int].new();
  if !l.is_empty() { return 1; }

  l.push_back(10);
  l.push_back(20);
  l.push_front(5);
  if l.len() != 3 { return 2; }

  match l.pop_front() {
    Some(x) => { if x != 5 { return 3; } },
    None => { return 4; },
  };
  match l.pop_back() {
    Some(x) => { if x != 20 { return 5; } },
    None => { return 6; },
  };
  if l.len() != 1 { return 7; }

  match l.pop_front() {
    Some(x) => { if x != 10 { return 8; } },
    None => { return 9; },
  };
  if !l.is_empty() { return 10; }

  match l.pop_front() { Some(_) => { return 11; }, None => {}, };
  match l.pop_back() { Some(_) => { return 12; }, None => {}, };

  return 0;
}
