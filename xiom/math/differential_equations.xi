// XIOM - Math: Differential Equations
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.math.differential_equations

// Depends on: xiom.math

// ============================================================================
// Numerical solvers for ordinary and partial differential equations: Euler,
// Runge-Kutta, adaptive Dormand-Prince, backward Euler (BDF-1), and finite
// difference/finite element discretizations of the 1-D heat equation.
//
// ODE solvers integrate y' = f(t, y) from t0 to t1 and return the sampled
// trajectory (including the initial value); n is the number of steps.
// Validation lives in the bodies (no traps); degenerate inputs return empty
// or NaN results as documented. Complexity is documented per function.
// ============================================================================

use xiom.math;

// Explicit Euler steps of y' = f(t, y) from t0 to t1 in n steps. Returns
// n + 1 values (y(t0), ..., y(t1)); empty for n <= 0. Complexity: O(n).
pub fn solve_ode_euler(f: fn(Float64, Float64) -> Float64, y0: Float64, t0: Float64, t1: Float64, n: Int) -> Vec[Float64] {
  var out = Vec[Float64].new();
  if n <= 0 { return out; }
  var h = (t1 - t0) / (n as Float64);
  var y = y0;
  var t = t0;
  out.push(y);
  var i = 0;
  while i < n {
    y = y + h * f(t, y);
    t = t + h;
    out.push(y);
    i = i + 1;
  }
  return out;
}

// Classical fourth-order Runge-Kutta integration of y' = f(t, y) in n steps.
// Returns n + 1 values; empty for n <= 0. Complexity: O(n).
pub fn solve_ode_rk4(f: fn(Float64, Float64) -> Float64, y0: Float64, t0: Float64, t1: Float64, n: Int) -> Vec[Float64] {
  var out = Vec[Float64].new();
  if n <= 0 { return out; }
  var h = (t1 - t0) / (n as Float64);
  var y = y0;
  var t = t0;
  out.push(y);
  var i = 0;
  while i < n {
    var k1 = f(t, y);
    var k2 = f(t + 0.5 * h, y + 0.5 * h * k1);
    var k3 = f(t + 0.5 * h, y + 0.5 * h * k2);
    var k4 = f(t + h, y + h * k3);
    y = y + h / 6.0 * (k1 + 2.0 * k2 + 2.0 * k3 + k4);
    t = t + h;
    out.push(y);
    i = i + 1;
  }
  return out;
}

// Adaptive Dormand-Prince (RK45) integration of y' = f(t, y) to tolerance
// tol. Returns the accepted trajectory (including the initial value) with
// step-size doubling/halving; at most 100000 internal steps. NaN for tol <= 0.
// Complexity: O(steps * cost(f)).
pub fn solve_ode_rk45(f: fn(Float64, Float64) -> Float64, y0: Float64, t0: Float64, t1: Float64, tol: Float64) -> Vec[Float64] {
  var out = Vec[Float64].new();
  if tol <= 0.0 { return out; }
  out.push(y0);
  var t = t0;
  var y = y0;
  var h = (t1 - t0) / 64.0;
  if h == 0.0 { return out; }
  var guard = 0;
  while t < t1 && guard < 100000 {
    if h > t1 - t {
      h = t1 - t;
    }
    var k1 = f(t, y);
    var k2 = f(t + h / 5.0, y + h * k1 / 5.0);
    var k3 = f(t + 3.0 * h / 10.0, y + h * (3.0 * k1 / 40.0 + 9.0 * k2 / 40.0));
    var k4 = f(t + 4.0 * h / 5.0, y + h * (44.0 * k1 / 45.0 - 56.0 * k2 / 15.0 + 32.0 * k3 / 9.0));
    var k5 = f(t + 8.0 * h / 9.0, y + h * (19372.0 * k1 / 6561.0 - 25360.0 * k2 / 2187.0 + 64448.0 * k3 / 6561.0 - 212.0 * k4 / 729.0));
    var k6 = f(t + h, y + h * (9017.0 * k1 / 3168.0 - 355.0 * k2 / 33.0 + 46732.0 * k3 / 5247.0 + 49.0 * k4 / 176.0 - 5103.0 * k5 / 18656.0));
    var y5 = y + h * (35.0 * k1 / 384.0 + 500.0 * k3 / 1113.0 + 125.0 * k4 / 192.0 - 2187.0 * k5 / 6784.0 + 11.0 * k6 / 84.0);
    var k7 = f(t + h, y5);
    var y4 = y + h * (5179.0 * k1 / 57600.0 + 7571.0 * k3 / 16695.0 + 393.0 * k4 / 640.0 - 92097.0 * k5 / 339200.0 + 187.0 * k6 / 2100.0 + k7 / 40.0);
    var err = math.abs_float(y5 - y4);
    if err <= tol || h <= 1.0e-14 {
      t = t + h;
      y = y5;
      out.push(y);
      h = h * 2.0;
    } else {
      h = h * 0.5;
    }
    guard = guard + 1;
  }
  if t < t1 {
    out.push(y);
  }
  return out;
}

// Generic adaptive step-size integrator of y' = f(t, y) to tolerance tol.
// Uses the Dormand-Prince pair (same trajectory semantics as solve_ode_rk45).
// Complexity: O(steps * cost(f)).
pub fn solve_ode_adaptive(f: fn(Float64, Float64) -> Float64, y0: Float64, t0: Float64, t1: Float64, tol: Float64) -> Vec[Float64] {
  return solve_ode_rk45(f, y0, t0, t1, tol);
}

// Backward differentiation formula of order 1 (implicit backward Euler):
// y_{n+1} = y_n + h f(t_{n+1}, y_{n+1}) solved by fixed-point iteration
// (8 iterations per step). Returns n + 1 values; empty for n <= 0.
// Complexity: O(n * iters * cost(f)).
pub fn solve_ode_bdf(f: fn(Float64, Float64) -> Float64, y0: Float64, t0: Float64, t1: Float64, n: Int) -> Vec[Float64] {
  var out = Vec[Float64].new();
  if n <= 0 { return out; }
  var h = (t1 - t0) / (n as Float64);
  var y = y0;
  var t = t0;
  out.push(y);
  var i = 0;
  while i < n {
    t = t + h;
    var guess = y;
    var it = 0;
    while it < 8 {
      guess = y + h * f(t, guess);
      it = it + 1;
    }
    y = guess;
    out.push(y);
    i = i + 1;
  }
  return out;
}

// Explicit finite-difference (FTCS) solution of the 1-D heat equation
// u_t = u_xx + f(t, x) on x in [0, 1], u(x, 0) = sin(pi x), zero boundary
// conditions. Returns nt + 1 rows of nx + 1 spatial samples. Empty for
// degenerate input. Complexity: O(nt * nx).
pub fn solve_pde_fd(f: fn(Float64, Float64) -> Float64, t0: Float64, t1: Float64, nx: Int, nt: Int) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  if nx <= 1 || nt <= 0 { return out; }
  var dx = 1.0 / (nx as Float64);
  var dt = (t1 - t0) / (nt as Float64);
  var kappa = dt / (dx * dx);
  if kappa > 0.5 { kappa = 0.5; }
  var u = Vec[Float64].new();
  var i = 0;
  while i <= nx {
    u.push(math.sin(3.141592653589793 * (i as Float64) / (nx as Float64)));
    i = i + 1;
  }
  var row = Vec[Float64].new();
  var j = 0;
  while j <= nx {
    row.push(u[j]);
    j = j + 1;
  }
  out.push(row);
  var step = 1;
  while step <= nt {
    var un = Vec[Float64].new();
    var k = 0;
    while k <= nx {
      var val = 0.0;
      if k == 0 || k == nx {
        val = 0.0;
      } else {
        var lap = (u[k + 1] - 2.0 * u[k] + u[k - 1]) / (dx * dx);
        var src = f(t0 + (step as Float64) * dt, (k as Float64) * dx);
        val = u[k] + dt * lap + dt * src;
      }
      un.push(val);
      k = k + 1;
    }
    u = un;
    var row2 = Vec[Float64].new();
    var m = 0;
    while m <= nx {
      row2.push(u[m]);
      m = m + 1;
    }
    out.push(row2);
    step = step + 1;
  }
  return out;
}

// Linear finite-element (Galerkin, hat functions, lumped mass) solution of
// u_t = u_xx + f(t, x) on x in [0, 1] with zero boundaries and initial
// u = sin(pi x). Returns nt + 1 rows of nx + 1 samples. Empty for degenerate
// input. Complexity: O(nt * nx).
pub fn solve_pde_fem(f: fn(Float64, Float64) -> Float64, t0: Float64, t1: Float64, nx: Int, nt: Int) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  if nx <= 1 || nt <= 0 { return out; }
  var dx = 1.0 / (nx as Float64);
  var dt = (t1 - t0) / (nt as Float64);
  var dt2 = dx * dx;
  var u = Vec[Float64].new();
  var i = 0;
  while i <= nx {
    u.push(math.sin(3.141592653589793 * (i as Float64) / (nx as Float64)));
    i = i + 1;
  }
  var row = Vec[Float64].new();
  var j = 0;
  while j <= nx {
    row.push(u[j]);
    j = j + 1;
  }
  out.push(row);
  var step = 1;
  while step <= nt {
    var un = Vec[Float64].new();
    var k = 0;
    while k <= nx {
      var val = 0.0;
      if k == 0 || k == nx {
        val = 0.0;
      } else {
        var lap = (u[k + 1] - 2.0 * u[k] + u[k - 1]) / dt2;
        var src = f(t0 + (step as Float64) * dt, (k as Float64) * dx);
        val = u[k] + dt * lap + dt * src;
      }
      un.push(val);
      k = k + 1;
    }
    u = un;
    var row2 = Vec[Float64].new();
    var m = 0;
    while m <= nx {
      row2.push(u[m]);
      m = m + 1;
    }
    out.push(row2);
    step = step + 1;
  }
  return out;
}
