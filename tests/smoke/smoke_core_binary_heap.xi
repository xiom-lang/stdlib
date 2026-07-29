module smoke_core_binary_heap
use xiom.core;

fn main() -> Int {
  var h = BinaryHeap[Int].new();
  if h.len() != 0 { return 1; }
  if !h.is_empty() { return 2; }

  h.push(3);
  h.push(1);
  h.push(5);
  h.push(2);
  if h.len() != 4 { return 3; }

  match h.peek() {
    Some(v) => { if v != 5 { return 4; } },
    None => { return 5; },
  };

  match h.pop() {
    Some(v) => { if v != 5 { return 6; } },
    None => { return 7; },
  };
  match h.pop() {
    Some(v) => { if v != 3 { return 8; } },
    None => { return 9; },
  };
  match h.pop() {
    Some(v) => { if v != 2 { return 10; } },
    None => { return 11; },
  };
  match h.pop() {
    Some(v) => { if v != 1 { return 12; } },
    None => { return 13; },
  };
  if h.len() != 0 { return 14; }
  match h.pop() {
    Some(_) => { return 15; },
    None => {},
  };

  return 0;
}
