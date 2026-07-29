module smoke_cross_string_collections_iter
use xiom.string;
use xiom.iter;
use xiom.collections;

fn main() -> Int {
  var words = string.words("one two three four five");
  if words.len() != 5 { return 1; }

  var lengths = Vec[Int].new();
  var i: Int = 0;
  while i < words.len() {
    match words.get(i) {
      Some(w) => { lengths.push(string.str_len(w)); },
      None => {},
    };
    i = i + 1;
  }

  var total: Int = 0;
  var j: Int = 0;
  while j < lengths.len() {
    match lengths.get(j) {
      Some(l) => { total = total + l; },
      None => {},
    };
    j = j + 1;
  }
  if total != 19 { return 2; }

  return 0;
}
