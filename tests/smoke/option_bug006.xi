module bug006_test

type Point = { x: Int; y: Int; }

fn main() -> Int {
  var opt = Some(Point{ x: 10; y: 20; });
  let p: Point = opt.unwrap();
  if p.x == 10 && p.y == 20 { return 0; }
  return 1;
}
