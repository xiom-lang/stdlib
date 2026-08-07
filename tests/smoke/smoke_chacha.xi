module smoke_chacha
use xiom.chacha;
fn main() -> Int {
  var key = Vec[Int].new();
  var nonce = Vec[Int].new();
  var i = 0;
  while i < 32 { key.push(i); i = i + 1; }
  i = 0;
  while i < 12 { nonce.push(i); i = i + 1; }
  var msg = Vec[UInt8].new();
  msg.push(104); msg.push(105);
  var enc = xiom.chacha.chacha20_encrypt(&key, &nonce, &msg);
  var dec = xiom.chacha.chacha20_decrypt(&key, &nonce, &enc);
  if !(dec.len() == 2 && dec[0] == 104 && dec[1] == 105) { return 1; }
  return 0;
}
