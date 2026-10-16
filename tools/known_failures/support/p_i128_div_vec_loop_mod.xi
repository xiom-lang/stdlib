// Support module for p_i128_div_vec_loop_av.xi (compiler finding, wave 165).
// This file is NOT compiled in place: the repro recipe copies it to
// <stdlib-root>/xiom/math/p_i128_div_vec_loop_mod.xi so that the runner can
// import it as xiom.math.p_i128_div_vec_loop_mod (the miscompile reproduces
// for xiom.*-namespace modules; a plain user-namespace copy runs green).
module xiom.math.p_i128_div_vec_loop_mod

/// A vector element-load loop followed by one runtime 128-bit division in
/// the SAME function. Pre-fix this compiles (rc 0) and the caller AVs with
/// 0xC0000005 at run time on the pinned compiler.
pub fn ta4(values: &Vec[Int], scale: Int) -> Int {
  var acc = 0;
  var i = 0;
  var n = values.len();
  while i < n {
    acc = acc + values[i];
    i = i + 1;
  }
  var a: Int128 = acc as Int128;
  var s: Int128 = scale as Int128;
  var q: Int128 = (a + a + s) / (s + s);
  return q as Int;
}
