module smoke_num_float_classify
use xiom.num;

fn main() -> Int {
  if !num.is_finite(1.0) { return 1; }
  if !num.is_finite(0.0) { return 2; }
  if num.is_finite(1.0 / 0.0) { return 3; }
  if num.is_finite(0.0 / 0.0) { return 4; }

  if !num.is_normal(1.0) { return 5; }
  if num.is_normal(0.0) { return 6; }

  if num.classify(0.0 / 0.0) != 0 { return 7; }
  if num.classify(1.0 / 0.0) != 1 { return 8; }
  if num.classify(0.0) != 2 { return 9; }
  if num.classify(1.0) != 4 { return 10; }

  if num.floor(3.9) != 3 { return 11; }
  if num.floor(-3.9) != -4 { return 12; }
  if num.floor(0.0) != 0 { return 13; }

  if num.ceil(3.1) != 4 { return 14; }
  if num.ceil(-3.1) != -3 { return 15; }

  if num.round(3.5) != 4 { return 16; }
  if num.round(-3.5) != -4 { return 17; }

  if num.trunc(3.9) != 3 { return 18; }
  if num.trunc(-3.9) != -3 { return 19; }

  if num.fract(3.75) < 0.74 || num.fract(3.75) > 0.76 { return 20; }

  if num.recip(4.0) != 0.25 { return 21; }

  return 0;
}
