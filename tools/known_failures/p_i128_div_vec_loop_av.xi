// Minimal repro (stdlib lane, wave 165, 2026-10-16, compiler v0.64.5,
// official archive): a RUNTIME 128-bit division (`sdiv i128`, emitted from
// `/` or `%` on Int128 with a non-constant divisor) that sits inside a
// function which also contains a vector element-load loop compiles rc 0 and
// the program AVs with 0xC0000005 (-1073741819) at run time when that
// function lives in an xiom.*-namespace module and is called across the
// module boundary.
//
// Expected: run rc 0 (the loop sums 3000 + 4000 = 7000 and the division
// returns round(2*7000 + 4000 / (2*4000)) = 2).
// Observed pre-workaround: compile rc 0, run rc 0xC0000005.
//
// Isolated during wave 165 while implementing xiom.math.fixed (several
// variants: the division INLINED into the loop function crashes; a private
// same-module helper marked alwaysinline crashes after inlining; a
// cross-module pub helper left as a real call runs green -- so the trigger
// is the sdiv i128 being merged into the vector-loop body). Shipped
// workaround: the wave-165 helpers implement 128-bit division with a
// 127-step shift/mask long division (no sdiv/srem i128 anywhere), which
// makes every probe green (p_wave165_shapes / p_wave165_vectors).
//
// RECIPE (two files; the module must live under the stdlib root):
//   1. copy tools/known_failures/support/p_i128_div_vec_loop_mod.xi to
//      <stdlib-root>/xiom/math/p_i128_div_vec_loop_mod.xi
//   2. XIOM_STDLIB=<stdlib-root>
//      xiom --force -o out.exe tools/known_failures/p_i128_div_vec_loop_av.xi
//   3. run out.exe; pre-fix rc 0xC0000005, expected rc 0.
module p_i128_div_vec_loop_av

use xiom.math.p_i128_div_vec_loop_mod;

fn main() -> Int {
  var v = Vec[Int].new();
  v.push(3000);
  v.push(4000);
  var sc = v[1];
  var r = p_i128_div_vec_loop_mod.ta4(&v, sc);
  if r != 2 { return 1; }
  return 0;
}
