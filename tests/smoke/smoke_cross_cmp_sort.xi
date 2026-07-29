module smoke_cross_cmp_sort
use xiom.cmp;
use xiom.collections;

fn sort_vec(items: &mut Vec[Int]) {
  var n = items.len();
  var i: Int = 1;
  while i < n {
    var j = i;
    while j > 0 {
      match items.get(j) {
        Some(cur) => {
          match items.get(j - 1) {
            Some(prev) => {
              if cmp.max(cur, prev) != cur {
                items.set(j, prev);
                items.set(j - 1, cur);
              };
            },
            None => {},
          };
        },
        None => {},
      };
      j = j - 1;
    };
    i = i + 1;
  };
}

fn main() -> Int {
  var v = Vec[Int].new();
  v.push(5); v.push(3); v.push(8); v.push(1); v.push(9);

  sort_vec(&mut v);

  match v.get(0) { Some(x) => { if x != 1 { return 1; } }, None => { return 2; }, };
  match v.get(4) { Some(x) => { if x != 9 { return 3; } }, None => { return 4; }, };

  return 0;
}
