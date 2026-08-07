module smoke_utf8
use xiom.utf8;
fn main() -> Int {
  var r = xiom.utf8.utf8_encode(0x1F600);
  match r {
    Ok(bytes) => {
      if bytes.len() != 4 { return 1; }
      var d = xiom.utf8.utf8_decode_at(&bytes, 0);
      match d {
        Ok(cp) => { if cp != 0x1F600 { return 1; } }
        Err(_) => { return 1; }
      }
      if !xiom.utf8.utf8_validate(&bytes) { return 1; }
    }
    Err(_) => { return 1; }
  }
  if xiom.utf8.utf8_seq_len(0xF0) != 4 { return 1; }
  return 0;
}
