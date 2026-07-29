module smoke_math_exp_log
use xiom.math;

fn main() -> Int {
  var e0 = math.exp(0.0);
  if e0 < 0.99 || e0 > 1.01 { return 1; }

  var e1 = math.exp(1.0);
  if e1 < 2.71 || e1 > 2.72 { return 2; }

  var l1 = math.ln(1.0);
  if l1 < -0.01 || l1 > 0.01 { return 3; }

  var le = math.ln(math.E);
  if le < 0.99 || le > 1.01 { return 4; }

  var lg = math.log10(100.0);
  if lg < 1.99 || lg > 2.01 { return 5; }

  var l2 = math.log2(8.0);
  if l2 < 2.99 || l2 > 3.01 { return 6; }

  return 0;
}
