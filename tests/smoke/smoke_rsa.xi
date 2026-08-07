module smoke_rsa
use xiom.rsa;
fn main() -> Int {
  var r = xiom.rsa.rsa_keygen(16);
  match r {
    Ok(kp) => {
      var pubk = xiom.rsa.rsa_public_key(&kp);
      var ct = xiom.rsa.rsa_encrypt(42, &pubk);
      var pt = xiom.rsa.rsa_decrypt(ct, &kp);
      if pt != 42 { return 1; }
      var sig = xiom.rsa.rsa_sign(7, &kp);
      if !xiom.rsa.rsa_verify(7, sig, &pubk) { return 1; }
    }
    Err(_) => { return 1; }
  }
  return 0;
}
