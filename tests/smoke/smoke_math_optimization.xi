// Smoke: xiom.math.optimization, signal, control_theory, operations_research.
// Returns 0 on success.
use xiom.math;
use xiom.io;
use xiom.core.to_int;

fn near(a: Float64, b: Float64, tol: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < tol;
}

fn sqobj(x: &Vec[Float64]) -> Float64 {
  return x[0] * x[0];
}

fn cooling(t: Float64, i: Float64) -> Float64 {
  return t * 0.99;
}

fn cost_tour(t: &Vec[Int]) -> Float64 {
  var n = t.len();
  var s = 0.0;
  var i = 0;
  while i < n {
    var a = t[i];
    var b = t[(i + 1) % n];
    var d = (a - b) as Float64;
    if d < 0.0 { d = -d; }
    s = s + d;
    i = i + 1;
  }
  return s;
}

fn quad(x: Float64) -> Float64 {
  return (x - 1.0) * (x - 1.0);
}

fn main() -> Int {
  // ---- optimization ----
  var x0 = Vec[Float64].new();
  x0.push(5.0);
  var sa = math.optimization.simulated_annealing(sqobj, &x0, 10.0, cooling);
  if sa.len() != 1 { io.println("sa-len"); return 1; }
  if !near(sa[0], 0.0, 0.5) { io.println("sa"); return 2; }
  var ants = math.optimization.ant_colony(cost_tour, 4, 60);
  if ants.len() != 4 { io.println("aco"); return 3; }
  var total = 0;
  var seen = Vec[Int].new();
  var i = 0;
  while i < 4 {
    seen.push(0);
    i = i + 1;
  }
  var j = 0;
  while j < ants.len() {
    if ants[j] >= 0 && ants[j] < 4 {
      seen[ants[j]] = 1;
    }
    j = j + 1;
  }
  var k = 0;
  while k < 4 {
    total = total + seen[k];
    k = k + 1;
  }
  if total != 4 { io.println("aco-perm"); return 4; }

  // ---- signal ----
  var sig = Vec[Float64].new();
  sig.push(1.0);
  sig.push(2.0);
  sig.push(3.0);
  sig.push(4.0);
  var f = math.signal.fft(&sig);
  if f.len() != 8 { io.println("fft-len"); return 5; }
  if !near(f[0], 10.0, 1e-6) { io.println("fft-dc"); return 6; }
  var back = math.signal.ifft(&f);
  if !near(back[0], 1.0, 1e-6) { io.println("ifft"); return 7; }
  var conv = math.signal.convolve(&sig, &Vec[Float64].new());
  if conv.len() != 0 { io.println("conv-empty"); return 8; }
  var kern = Vec[Float64].new();
  kern.push(1.0);
  kern.push(1.0);
  var conv2 = math.signal.convolve(&sig, &kern);
  if conv2.len() != 5 { io.println("conv-len"); return 9; }
  if !near(conv2[2], 5.0, 1e-9) { io.println("conv"); return 10; }
  var win = math.signal.window_hamming(5);
  if win.len() != 5 { io.println("win"); return 11; }
  var w0 = win[0];
  if !near(w0, 0.08, 1e-9) { io.println("hamming"); return 12; }
  var dct = math.signal.dct(&sig);
  if !near(dct[0], 5.0, 1e-9) { io.println("dct"); return 13; }
  var wh = math.signal.wavelet_haar(&sig, 1);
  var ih = math.signal.wavelet_idwt(&wh, 1);
  if !near(ih[0], 1.0, 1e-9) { io.println("haar"); return 14; }
  var fir = math.signal.filter_lowpass(&sig, 1.0, 1);
  if fir.len() != 4 { io.println("fir"); return 15; }
  var lp = fir[3];
  if lp < 2.0 || lp > 4.0 { io.println("lowpass"); return 16; }
  var sp = math.signal.spectrum(&sig);
  if !near(sp[0], 10.0, 1e-6) { io.println("spectrum"); return 17; }
  var ac = math.signal.autocorrelate(&sig);
  if ac.len() != 4 { io.println("ac"); return 18; }

  // ---- control theory ----
  var num = Vec[Float64].new();
  num.push(1.0);
  var den = Vec[Float64].new();
  den.push(1.0);
  den.push(1.0);
  var tf = math.control_theory.transfer_function(&num, &den, 2.0);
  if !near(tf, 1.0 / 3.0, 1e-9) { io.println("tf"); return 19; }
  var rd = Vec[Float64].new();
  rd.push(1.0);
  rd.push(3.0);
  rd.push(2.0);
  if !math.control_theory.stability_routh_hurwitz(&rd) { io.println("routh"); return 20; }
  var ud = Vec[Float64].new();
  ud.push(1.0);
  ud.push(-1.0);
  ud.push(2.0);
  if math.control_theory.stability_routh_hurwitz(&ud) { io.println("routh-unstable"); return 21; }
  var pid = math.control_theory.pid_controller(2.0, 1.0, 0.0, 0.5, 0.1, 1.0);
  if !near(pid.0, 2.05, 1e-9) { io.println("pid"); return 22; }
  if !math.control_theory.robust_control(quad, 0.01) { io.println("robust"); return 23; }
  var gains = Vec[Float64].new();
  gains.push(0.5);
  var rl = math.control_theory.root_locus(&num, &den, &gains);
  if rl.len() != 1 { io.println("rootlocus"); return 24; }

  // ---- operations research ----
  var jobs = Vec[(Int, Int, Int)].new();
  jobs.push((0, 3, 1));
  jobs.push((1, 2, 1));
  jobs.push((2, 1, 1));
  var sched = math.operations_research.scheduling(&jobs, 2);
  if sched.len() != 3 { io.println("sched"); return 25; }
  var bounds = Vec[(Float64, Float64)].new();
  bounds.push((-5.0, 5.0));
  var opt = math.operations_research.stochastic_optimization(sqobj, &bounds, 1500);
  if opt.len() != 1 { io.println("stoch-len"); return 26; }
  if !near(opt[0], 0.0, 0.5) { io.println("stoch"); return 27; }
  var fcs = Vec[(Float64, Float64)].new();
  fcs.push((300.0, 10.0));
  fcs.push((100.0, 50.0));
  var rv = math.operations_research.revenue_management(100, &fcs);
  if rv.len() != 2 { io.println("revenue"); return 28; }

  io.println("smoke_math_optimization: OK");
  return 0;
}
