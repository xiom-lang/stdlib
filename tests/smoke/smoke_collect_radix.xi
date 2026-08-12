// XIOM stdlib smoke test - xiom.collect.radix
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_collect_radix
use xiom.collect.radix;
use xiom.string;
use xiom.convert;
use xiom.io;

fn main() -> Int {
  var r = radix_new();
  if radix_size(&r) != 0 { io.println("radix: initial size"); return 1; }
  radix_insert(&mut r, "12345", 1);
  radix_insert(&mut r, "123", 2);
  radix_insert(&mut r, "98765", 3);
  radix_insert(&mut r, "12", 4);
  if radix_size(&r) != 4 { io.println("radix: size"); return 2; }
  if !radix_contains(&r, "12345") { io.println("radix: contains 12345"); return 3; }
  if !radix_contains(&r, "123") { io.println("radix: contains 123"); return 4; }
  if !radix_contains(&r, "98765") { io.println("radix: contains 98765"); return 5; }
  if !radix_contains(&r, "12") { io.println("radix: contains 12"); return 6; }
  if radix_contains(&r, "1234") { io.println("radix: contains 1234"); return 7; }
  if radix_contains(&r, "") { io.println("radix: empty key"); return 8; }
  // duplicate insert is a no-op
  radix_insert(&mut r, "123", 99);
  if radix_size(&r) != 4 { io.println("radix: dup size"); return 9; }
  // longest stored prefix
  if radix_longest_prefix(&r, "12345") != 5 { io.println("radix: prefix 12345"); return 10; }
  if radix_longest_prefix(&r, "12399") != 3 { io.println("radix: prefix 12399"); return 11; }
  if radix_longest_prefix(&r, "12999") != 2 { io.println("radix: prefix 12999"); return 12; }
  if radix_longest_prefix(&r, "99999") != 0 { io.println("radix: prefix 99999"); return 13; }
  if radix_longest_prefix(&r, "12") != 2 { io.println("radix: prefix exact"); return 14; }
  // prefix sharing stress
  var i: Int = 0;
  while i < 200 {
    var k = "";
    var j: Int = 0;
    while j <= i {
      k = str_concat(k, int_to_string(1));
      j = j + 1;
    }
    radix_insert(&mut r, k, i);
    i = i + 1;
  }
  if radix_size(&r) != 204 { io.println("radix: stress size"); return 15; }
  // remove
  if !radix_remove(&mut r, "123") { io.println("radix: remove"); return 16; }
  if radix_contains(&r, "123") { io.println("radix: contains after remove"); return 17; }
  if !radix_contains(&r, "12345") { io.println("radix: contains longer after remove"); return 18; }
  if radix_longest_prefix(&r, "12399") != 2 { io.println("radix: prefix after remove"); return 19; }
  if radix_remove(&mut r, "123") { io.println("radix: remove again"); return 20; }
  if radix_size(&r) != 203 { io.println("radix: size after remove"); return 21; }

  io.println("smoke_collect_radix: OK");
  return 0;
}
