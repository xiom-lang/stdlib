module smoke_bigint
use xiom.bigint;
use xiom.string;
fn main() -> Int {
  var r = xiom.bigint.bigint_from_str("12345678901234567890");
  match r {
    Ok(b) => {
      var s = xiom.bigint.bigint_to_str(&b);
      if s != "12345678901234567890" { return 1; }
      var b2 = xiom.bigint.bigint_mul(&b, xiom.bigint.bigint_from_int(2));
      var s2 = xiom.bigint.bigint_to_str(&b2);
      if s2 != "24691357802469135780" { return 1; }
      var cmp = xiom.bigint.bigint_compare(&b, &b2);
      if cmp != -1 { return 1; }
    }
    Err(_) => { return 1; }
  }
  return 0;
}
