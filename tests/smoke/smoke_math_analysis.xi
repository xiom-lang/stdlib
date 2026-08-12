// Smoke: xiom.math.trigonometry, differential_equations, queueing,
// number_systems, interfaces (the analysis-flavoured sublibs).
// Returns 0 on success.
use xiom.math;
use xiom.io;
use xiom.core.to_int;

fn near(a: Float64, b: Float64, tol: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < tol;
}

fn expfn(t: Float64, y: Float64) -> Float64 {
  return y;
}

fn main() -> Int {
  // ---- trigonometry ----
  if !near(math.trigonometry.sin(0.5), 0.4794255386, 1e-9) { io.println("trig-sin"); return 1; }
  if !near(math.trigonometry.cos(0.5), 0.8775825619, 1e-9) { io.println("trig-cos"); return 2; }
  if !near(math.trigonometry.tan(0.5), 0.5463024898, 1e-9) { io.println("trig-tan"); return 3; }
  var sc = math.trigonometry.sincos(0.5);
  if !near(sc.0, 0.4794255386, 1e-9) { io.println("sincos"); return 4; }
  var scp = math.trigonometry.sincospi(0.5);
  if !near(scp.1, 0.0, 1e-9) { io.println("sincospi"); return 5; }
  if !near(math.trigonometry.sin_pure(0.5), 0.4794255386, 1e-6) { io.println("sinpure"); return 6; }
  if !near(math.trigonometry.cos_pure(0.5), 0.8775825619, 1e-6) { io.println("cospure"); return 7; }
  if !near(math.trigonometry.sinpi(0.5), 1.0, 1e-9) { io.println("sinpi"); return 8; }
  if !near(math.trigonometry.cospi(1.0), -1.0, 1e-9) { io.println("cospi"); return 9; }
  if !near(math.trigonometry.csc(0.5), 2.0858296429, 1e-6) { io.println("csc"); return 10; }
  if !near(math.trigonometry.sec(0.5), 1.1394939273, 1e-6) { io.println("sec"); return 11; }
  if !near(math.trigonometry.cot(0.5), 1.8304877217, 1e-6) { io.println("cot"); return 12; }

  // ---- differential equations: dy/dt = y, y(0)=1 over [0,1] -> e ----
  var eul = math.differential_equations.solve_ode_euler(expfn, 1.0, 0.0, 1.0, 200);
  if eul.len() != 201 { io.println("euler-len"); return 13; }
  if !near(eul[200], 2.7169, 0.01) { io.println("euler"); return 14; }
  var rk = math.differential_equations.solve_ode_rk4(expfn, 1.0, 0.0, 1.0, 100);
  if !near(rk[100], 2.7182818, 0.001) { io.println("rk4"); return 15; }
  var rk45 = math.differential_equations.solve_ode_rk45(expfn, 1.0, 0.0, 1.0, 1e-6);
  var last = rk45[rk45.len() - 1];
  if !near(last, 2.7182818, 0.02) { io.println("rk45"); return 16; }
  var bdf = math.differential_equations.solve_ode_bdf(expfn, 1.0, 0.0, 1.0, 100);
  if !near(bdf[100], 2.7182818, 0.02) { io.println("bdf"); return 17; }
  var pde = math.differential_equations.solve_pde_fd(expfn, 0.0, 0.01, 8, 4);
  if pde.len() != 5 { io.println("pde-fd"); return 18; }

  // ---- queueing ----
  var mm = math.queueing.m_m_1(3.0, 10.0);
  if !near(mm.0, 9.0 / 70.0, 1e-9) { io.println("mm1"); return 19; }
  var eb = math.queueing.erlang_b(1.0, 2);
  if !near(eb, 0.2, 1e-9) { io.println("erlangb"); return 20; }
  var ec = math.queueing.erlang_c(1.0, 2);
  if ec != ec { io.println("erlangc"); return 21; }
  if math.queueing.little_law(5.0, 2.0) != 10.0 { io.println("little"); return 22; }
  if !near(math.queueing.utilization(3.0, 10.0, 1), 0.3, 1e-12) { io.println("util"); return 23; }
  var mmc = math.queueing.m_m_c(3.0, 10.0, 2);
  if mmc.0 < 0.0 || mmc.0 > 1.0 { io.println("mmc"); return 24; }
  if !near(math.queueing.m_g_1(2.0, 0.1, 0.01), 0.05, 1e-6) { io.println("mg1"); return 25; }

  // ---- number systems ----
  var b2 = math.number_systems.binary_to_int("1010");
  var b2v = 0;
  match b2 {
    Ok(v) => { b2v = v; },
    Err(e) => { b2v = -1; },
  }
  if b2v != 10 { io.println("bin"); return 26; }
  if math.number_systems.int_to_binary(10) != "1010" { io.println("binout"); return 27; }
  if math.number_systems.int_to_hex(255) != "FF" { io.println("hexout"); return 28; }
  if math.number_systems.int_to_base_n(255, 16) != "FF" { io.println("baseout"); return 29; }
  var hx = math.number_systems.hex_to_int("ff");
  var hxv = 0;
  match hx {
    Ok(v) => { hxv = v; },
    Err(e) => { hxv = -1; },
  }
  if hxv != 255 { io.println("hex"); return 30; }
  var oc = math.number_systems.octal_to_int("17");
  var ocv = 0;
  match oc {
    Ok(v) => { ocv = v; },
    Err(e) => { ocv = -1; },
  }
  if ocv != 15 { io.println("octal"); return 31; }
  if math.number_systems.int_to_roman(1994) != "MCMXCIV" { io.println("roman"); return 32; }
  var rm = math.number_systems.roman_to_int("XIV");
  var rmv = 0;
  match rm {
    Ok(v) => { rmv = v; },
    Err(e) => { rmv = -1; },
  }
  if rmv != 14 { io.println("romanin"); return 33; }
  var fn2 = math.number_systems.fraction_new(6, 8);
  if fn2.0 != 3 || fn2.1 != 4 { io.println("fraction"); return 34; }
  var fa = math.number_systems.fraction_add((1, 2), (1, 3));
  if fa.0 != 5 || fa.1 != 6 { io.println("fadd"); return 35; }
  var cf = math.number_systems.continued_fraction(3.14159, 4);
  if cf.len() != 4 || cf[0] != 3 { io.println("contfrac"); return 36; }
  var cn = math.number_systems.chinese_numerals(101);
  if string_len(cn) == 0 { io.println("chinese"); return 37; }

  io.println("smoke_math_analysis: OK");
  return 0;
}

fn string_len(s: Str) -> Int {
  return s.len();
}
