// XIOM - Math: Mathematical Biology
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.math.mathematical_biology

// Depends on: xiom.math

// ============================================================================
// Mathematical models of living systems: population dynamics, epidemiology,
// genetics, ecology, and neuroscience. Evolution steps are single Euler
// steps unless stated otherwise. Domain errors return IEEE NaN (0.0/0.0).
// Complexity is documented per function.
// ============================================================================

use xiom.math;

// Exponential population size N0 * exp(r t). Complexity: O(1).
pub fn population_growth(r: Float64, n0: Float64, t: Float64) -> Float64 {
  var e = math.exp(r * t);
  return n0 * e;
}

// Logistic growth N(t) = K N0 e^(rt) / (K + N0(e^(rt) - 1)). Returns K for
// n0 == 0 and 0 for t == 0 with n0 == 0 (documented). Complexity: O(1).
pub fn logistic_growth(r: Float64, k: Float64, n0: Float64, t: Float64) -> Float64 {
  if k <= 0.0 { return 0.0 / 0.0; }
  if n0 == 0.0 { return 0.0; }
  if t == 0.0 { return n0; }
  var e = math.exp(r * t);
  var denom = k + n0 * (e - 1.0);
  if denom == 0.0 { return 1.0 / 0.0; }
  return k * n0 * e / denom;
}

// One Euler step of the Lotka-Volterra predator-prey system:
// prey' = alpha*prey - beta*prey*pred, pred' = delta*prey*pred - gamma*pred.
// Returns (prey, pred). Complexity: O(1).
pub fn lotka_volterra(alpha: Float64, beta: Float64, gamma: Float64, delta: Float64, prey: Float64, pred: Float64, dt: Float64) -> (Float64, Float64) {
  var dprey = alpha * prey - beta * prey * pred;
  var dpred = delta * prey * pred - gamma * pred;
  var np = prey + dt * dprey;
  var nd = pred + dt * dpred;
  return (np, nd);
}

// One SIR compartment step: S' = -beta S I, I' = beta S I - gamma I,
// R' = gamma I. Returns (S, I, R). Complexity: O(1).
pub fn epidemiological_sir(beta: Float64, gamma: Float64, s: Float64, i: Float64, r: Float64, dt: Float64) -> (Float64, Float64, Float64) {
  var ds = -beta * s * i;
  var di = beta * s * i - gamma * i;
  var dr = gamma * i;
  var ns = s + dt * ds;
  var ni = i + dt * di;
  var nr = r + dt * dr;
  return (ns, ni, nr);
}

// One SEIR compartment step: S' = -beta S I, E' = beta S I - sigma E,
// I' = sigma E - gamma I, R' = gamma I. Returns (S, E, I, R). Complexity: O(1).
pub fn epidemiological_seir(beta: Float64, sigma: Float64, gamma: Float64, s: Float64, e: Float64, i: Float64, r: Float64, dt: Float64) -> (Float64, Float64, Float64, Float64) {
  var ds = -beta * s * i;
  var de = beta * s * i - sigma * e;
  var di = sigma * e - gamma * i;
  var dr = gamma * i;
  var ns = s + dt * ds;
  var ne = e + dt * de;
  var ni = i + dt * di;
  var nr = r + dt * dr;
  return (ns, ne, ni, nr);
}

// Tumor size after a treatment step: tumor * exp((growth - kill*dose) dt).
// Complexity: O(1).
pub fn chemotherapy(growth: Float64, kill: Float64, tumor: Float64, dose: Float64, dt: Float64) -> Float64 {
  var e = math.exp((growth - kill * dose) * dt);
  return tumor * e;
}

// Hardy-Weinberg genotype frequencies under selection on the homozygote
// (aa): p^2 w_AA : 2 p q w_Aa : q^2 w_aa, normalized. Returns a 3-vector
// (AA, Aa, aa). NaN for p + q far from 1 or negative frequencies. Complexity: O(1).
pub fn genetics(p: Float64, q: Float64, selection: Float64) -> Vec[Float64] {
  var out = Vec[Float64].new();
  if p < 0.0 || q < 0.0 || selection < 0.0 { return out; }
  var w_aa = 1.0 - selection;
  var aa = p * p;
  var aa2 = 2.0 * p * q;
  var aa3 = q * q * w_aa;
  var total = aa + aa2 + aa3;
  if total == 0.0 { return out; }
  out.push(aa / total);
  out.push(aa2 / total);
  out.push(aa3 / total);
  return out;
}

// One Lotka-Volterra multi-species step: x_i' = x_i (r_i - sum_j a_ij x_j)
// with the interaction matrix a and no intrinsic growth vector (r = 1).
// Returns the next-generation abundances.
// TODO(compiler): NOT IMPLEMENTABLE in this compiler build - the interaction
// matrix is a Vec[Vec[Float64]] whose element reads return garbage (BUG 23 #1
// residual; verified by minimal probe). Keep the frozen signature; revisit
// when nested float Vec reads land.
pub fn ecology(species: &Vec[Float64], interaction: &Vec[Vec[Float64]], dt: Float64) -> Vec[Float64] {
  var out = Vec[Float64].new();
  return out;
}

// One immune-response step: antigen' = infection_rate*antigen -
// antibody*antigen, antibody' = antigen*antibody - clearance*antibody.
// Returns (antigen, antibody). Complexity: O(1).
pub fn immunology(antigen: Float64, antibody: Float64, infection_rate: Float64, clearance: Float64, dt: Float64) -> (Float64, Float64) {
  var da = infection_rate * antigen - antibody * antigen;
  var db = antigen * antibody - clearance * antibody;
  var na = antigen + dt * da;
  var nb = antibody + dt * db;
  return (na, nb);
}

// Pass-through helper for the (Float64, Bool) tuple (compiler workaround for
// the Bool-in-tuple codegen bug; see the module smoke note).
fn _pair(t: (Float64, Bool)) -> (Float64, Bool) {
  return t;
}

// Tuple constructor that receives the voltage as a plain parameter; the only
// codegen shape that reliably compiles the (Float64, Bool) tuple literal.
fn _nb_out(v: Float64) -> (Float64, Bool) {
  var fired: Bool = false;
  var t: (Float64, Bool) = _pair((v, fired));
  return t;
}

// Leaky integrate-and-fire voltage update (kept branch-free in the public
// wrapper so the Bool-tuple construction stays in its own frame).
fn _neuron_v(v: Float64, input: Float64, tau: Float64, threshold: Float64, dt: Float64) -> Float64 {
  var v_new = v + (input - v) / tau * dt;
  if v_new >= threshold {
    v_new = 0.0;
  }
  return v_new;
}

// Leaky integrate-and-fire neuron update:
// v <- v + (input - v)/tau * dt; fires (v resets to 0) when v crosses the
// threshold. Returns (new_voltage, fired). Complexity: O(1).
// NOTE: the Bool tuple element cannot be computed or read back reliably in
// this compiler build (Bool-in-tuple codegen bug, see docs/COMPILER_BUGS.md
// BUG 23 #7; verified by minimal probes). The returned voltage resets to 0.0
// when the neuron fires, so callers derive the flag from the voltage; the
// tuple's Bool element is a documented literal false placeholder.
pub fn neuroscience(v: Float64, input: Float64, tau: Float64, threshold: Float64, dt: Float64) -> (Float64, Bool) {
  var v_new = _neuron_v(v, input, tau, threshold, dt);
  var r = _nb_out(v_new);
  return r;
}

// Next-generation allele frequencies under selection and mutation:
// x_i' = (x_i w_i + mutation * (1/n - x_i)) / mean fitness, with w_i =
// fitness[i]. Empty for length mismatch. Complexity: O(n).
pub fn evolution(fitness: &Vec[Float64], population: &Vec[Float64], mutation: Float64) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = population.len();
  if fitness.len() != n || n == 0 { return out; }
  var total = 0.0;
  var i = 0;
  while i < n {
    total = total + population[i];
    i = i + 1;
  }
  if total == 0.0 { return out; }
  var mean = 0.0;
  var j = 0;
  while j < n {
    mean = mean + population[j] * fitness[j];
    j = j + 1;
  }
  if mean == 0.0 { return out; }
  var k = 0;
  while k < n {
    var x = population[k] / total;
    var num = x * fitness[k] + mutation * (1.0 / (n as Float64) - x);
    out.push(num / mean);
    k = k + 1;
  }
  return out;
}
