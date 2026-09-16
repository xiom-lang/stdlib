module p_os_double_nocmp
use xiom.crypto;
use xiom.io;
fn main() -> Int {
  var a = crypto.os_secure_random_bytes(32);
  var b = crypto.os_secure_random_bytes(32);
  if a.len() != 32 || b.len() != 32 { io.println("len"); return 1; }
  io.println("double-nocmp-OK");
  return 0;
}
