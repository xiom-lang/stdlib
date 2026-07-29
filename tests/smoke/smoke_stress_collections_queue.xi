// XIOM stdlib stress — Queue enqueue, dequeue, peek
// Tests FIFO queue operations including empty queue behavior.
// Returns 0 on success, nonzero on failure.

module smoke_stress_collections_queue
use xiom.collections;

fn main() -> Int {
  var q = Queue[Int].new();
  if q.len() != 0 { return 1; }
  q.enqueue(100);
  q.enqueue(200);
  q.enqueue(300);
  if q.len() != 3 { return 2; }
  match q.peek() {
    Some(v) => { if v != 100 { return 3; } }
    None => { return 4; }
  }
  match q.dequeue() {
    Some(v) => { if v != 100 { return 5; } }
    None => { return 6; }
  }
  match q.dequeue() {
    Some(v) => { if v != 200 { return 7; } }
    None => { return 8; }
  }
  match q.dequeue() {
    Some(v) => { if v != 300 { return 9; } }
    None => { return 10; }
  }
  if q.len() != 0 { return 11; }
  match q.dequeue() {
    Some(_) => { return 12; }
    None => { }
  }
  return 0;
}
