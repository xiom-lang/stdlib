module smoke_collections_stack_queue
use xiom.collections;

fn main() -> Int {
  var s = Stack[Int].new();
  if !s.is_empty() { return 1; }
  match s.pop() { Some(_) => { return 2; }, None => {}, };
  match s.peek() { Some(_) => { return 3; }, None => {}, };

  s.push(10); s.push(20); s.push(30);
  if s.len() != 3 { return 4; }
  match s.peek() {
    Some(x) => { if x != 30 { return 5; } },
    None => { return 6; },
  };
  match s.pop() {
    Some(x) => { if x != 30 { return 7; } },
    None => { return 8; },
  };
  if s.len() != 2 { return 9; }

  var q = Queue[Int].new();
  if !q.is_empty() { return 10; }
  match q.dequeue() { Some(_) => { return 11; }, None => {}, };

  q.enqueue(100); q.enqueue(200); q.enqueue(300);
  if q.len() != 3 { return 12; }
  match q.peek() {
    Some(x) => { if x != 100 { return 13; } },
    None => { return 14; },
  };
  match q.dequeue() {
    Some(x) => { if x != 100 { return 15; } },
    None => { return 16; },
  };
  if q.len() != 2 { return 17; }

  return 0;
}
