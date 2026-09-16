// p_pct_probe.xi -- characterize the convert.percent shim binding.
// Full-URL mode must return "/a?b=1&c=2" (reserved separators pass through);
// component mode encodes them.
module p_pct_probe
use xiom.convert.percent;
use xiom.convert.percent as cvt;
use xiom.io;

fn main() -> Int {
  let a = percent.percent_encode("/a?b=1&c=2");
  let b = cvt.percent_encode("/a?b=1&c=2");
  io.println("alias=" + a);
  io.println("as-alias=" + b);
  if a != "/a?b=1&c=2" { return 1; };
  if b != "/a?b=1&c=2" { return 2; };
  0
}
