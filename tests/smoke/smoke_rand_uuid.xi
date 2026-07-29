module smoke_rand_uuid
use xiom.rand;

fn main() -> Int {
  var u4 = rand.uuid_v4();
  if u4.len() != 36 { return 1; }

  var u7 = rand.uuid_v7();
  if u7.len() != 36 { return 2; }

  if u4 == u7 { return 0; }

  return 0;
}
