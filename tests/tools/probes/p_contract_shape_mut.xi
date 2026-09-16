module p_contract_shape_mut
use xiom.io;

type MutBox = { count: Int; }

fn mutbox_size(m: &mut MutBox) -> Int {
  return m.count;
}

fn mutbox_clear(m: &mut MutBox)
  ensures: mutbox_size(m) == 0
{
  m.count = 0;
}

fn main() -> Int {
  var b = MutBox{ count: 7; };
  mutbox_clear(&b);
  if mutbox_size(&b) != 0 { return 1; }
  io.println("MUT SHAPE OK");
  return 0;
}
