module smoke_des
use xiom.des;
fn main() -> Int {
  var block = 0x1122334455667788;
  var key = 0x0123456789ABCDEF;
  var enc = xiom.des.des_encrypt_block(block, key);
  var dec = xiom.des.des_decrypt_block(enc, key);
  if dec != block { return 1; }
  return 0;
}
