module smoke_array_len_empty
use xiom.array;

fn main() -> Int {
  // VAR array literals are fixed arrays; LET literals convert to Vec
  // (M33 -- satisfies core/slice fns but not the array module's &[N]T
  // fns). Compiler-blocked shapes: repeated array.len calls on DIFFERENT
  // arrays reuse the FIRST call's const N (probe_stale: len(&[7,8]) = 2,
  // then len(&[1,2,3,4]) = 2 and len(&[9]) = 2); the empty literal `[]`
  // infers a stale N; typed [0]Int annotations lose the const N.
  var arr5 = [1, 2, 3, 4, 5];
  if array.len(&arr5) != 5 { return 1; }
  if array.is_empty(&arr5) { return 2; }

  return 0;
}
