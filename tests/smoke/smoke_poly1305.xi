module smoke_poly1305
use xiom.poly1305;
fn main() -> Int {
  var key = Vec[Int].new();
  var i = 0;
  while i < 32 { key.push(i); i = i + 1; }
  var msg = Vec[UInt8].new();
  msg.push(1); msg.push(2); msg.push(3);
  var t1 = xiom.poly1305.poly1305_mac(&key, &msg);
  var t2 = xiom.poly1305.poly1305_mac(&key, &msg);
  if t1.len() != 16 { return 1; }
  if t1[0] != t2[0] { return 1; }
  return 0;
}
