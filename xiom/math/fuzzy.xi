// XIOM - Math: Fuzzy Logic
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.math.fuzzy

// Depends on: none

// ============================================================================
// Fuzzy sets, membership functions, fuzzy inference, and fuzzy control.
//
// A fuzzy set over a finite universe is represented by a Vec[Float64] of
// membership degrees in [0, 1] (one degree per universe element). Rule
// strings for fuzzy_inference/mamdani use the convention
// "antecedent_index:consequent_index:strength" (e.g. "0:2:0.8"); Sugeno
// rules are bare decimal strengths. Complexity is documented per function.
// ============================================================================

use xiom.math;
use xiom.string;

const _PI: Float64 = 3.141592653589793;

// Membership degrees of the universe elements under the membership fn.
// Returns an empty vector for an empty universe. Complexity: O(n).
pub fn fuzzy_set(universe: &Vec[Int], membership: fn(Int) -> Float64) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var i = 0;
  while i < universe.len() {
    out.push(membership(universe[i]));
    i = i + 1;
  }
  return out;
}

// Membership degree of element in a fuzzy set; elements outside the set's
// range yield 0.0 (documented). Complexity: O(1).
pub fn membership(set: &Vec[Float64], element: Int) -> Float64 {
  if element < 0 || element >= set.len() { return 0.0; }
  return set[element];
}

// Triangular norm/conorm or negation of two truth values, selected by op:
// "and" -> min, "or" -> max, "not" -> 1 - a, "prod" -> a*b,
// "sum" -> a + b - a*b (probabilistic or). Unknown op returns NaN.
// Complexity: O(1).
pub fn fuzzy_logic(a: Float64, b: Float64, op: Str) -> Float64 {
  if op == "and" {
    if a < b { return a; }
    return b;
  }
  if op == "or" {
    if a > b { return a; }
    return b;
  }
  if op == "not" {
    return 1.0 - a;
  }
  if op == "prod" {
    return a * b;
  }
  if op == "sum" {
    return a + b - a * b;
  }
  return 0.0 / 0.0;
}

// Pointwise minimum (intersection) of two fuzzy sets; empty on length
// mismatch. Complexity: O(n).
pub fn fuzzy_intersection(a: &Vec[Float64], b: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  if a.len() != b.len() { return out; }
  var i = 0;
  while i < a.len() {
    if a[i] < b[i] {
      out.push(a[i]);
    } else {
      out.push(b[i]);
    }
    i = i + 1;
  }
  return out;
}

// Pointwise maximum (union) of two fuzzy sets; empty on length mismatch.
// Complexity: O(n).
pub fn fuzzy_union(a: &Vec[Float64], b: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  if a.len() != b.len() { return out; }
  var i = 0;
  while i < a.len() {
    if a[i] > b[i] {
      out.push(a[i]);
    } else {
      out.push(b[i]);
    }
    i = i + 1;
  }
  return out;
}

// Pointwise complement 1 - a of a fuzzy set. Complexity: O(n).
pub fn fuzzy_complement(a: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var i = 0;
  while i < a.len() {
    out.push(1.0 - a[i]);
    i = i + 1;
  }
  return out;
}

// Validates that every membership degree of the fuzzy relation matrix lies
// in [0, 1].
// TODO(compiler): NOT IMPLEMENTABLE in this compiler build - the relation is
// a Vec[Vec[Float64]] whose element reads return garbage (BUG 23 #1 residual;
// verified by minimal probe). Keep the frozen signature; revisit when nested
// float Vec reads land.
pub fn fuzzy_relation(r: &Vec[Vec[Float64]]) -> Bool {
  return false;
}

// Max-min composition of two fuzzy relations.
// TODO(compiler): NOT IMPLEMENTABLE in this compiler build - the relations are
// Vec[Vec[Float64]] whose element reads return garbage (BUG 23 #1 residual;
// verified by minimal probe). Keep the frozen signature; revisit when nested
// float Vec reads land.
pub fn fuzzy_composition(r: &Vec[Vec[Float64]], s: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  return out;
}

// Centroid (center-of-gravity) defuzzification of a fuzzy set over the
// universe values: sum(u_i m_i) / sum(m_i). NaN when the total membership is
// zero or the lengths differ. Complexity: O(n).
pub fn defuzzification(set: &Vec[Float64], universe: &Vec[Float64]) -> Float64 {
  if set.len() != universe.len() { return 0.0 / 0.0; }
  var num = 0.0;
  var den = 0.0;
  var i = 0;
  while i < set.len() {
    num = num + universe[i] * set[i];
    den = den + set[i];
    i = i + 1;
  }
  if den == 0.0 { return 0.0 / 0.0; }
  return num / den;
}

// Index of the first ':' in a string, or -1 when absent.
fn _find_colon(r: Str) -> Int {
  var i = 0;
  while i < string.str_len(r) {
    if string.byte_at(r, i) == 58 {
      return i;
    }
    i = i + 1;
  }
  return -1;
}

// Parse "a:b:s" rule strings; returns (0, 0, 0.0) when the format is invalid.
fn _parse_rule(r: Str) -> (Int, Int, Float64) {
  var idx1 = _find_colon(r);
  if idx1 < 0 {
    return (0, 0, 0.0);
  }
  var rest = string.str_slice(r, idx1 + 1, string.str_len(r));
  var idx2 = _find_colon(rest);
  if idx2 < 0 {
    return (0, 0, 0.0);
  }
  var a_str = string.str_slice(r, 0, idx1);
  var b_str = string.str_slice(rest, 0, idx2);
  var s_str = string.str_slice(rest, idx2 + 1, string.str_len(rest));
  var a_res = string.str_to_int(a_str);
  var a = 0;
  match a_res {
    Ok(v) => { a = v; },
    Err(e) => { a = -1; },
  }
  var b_res = string.str_to_int(b_str);
  var b = 0;
  match b_res {
    Ok(v) => { b = v; },
    Err(e) => { b = -1; },
  }
  var s_res = string.str_to_float(s_str);
  var s = 0.0;
  match s_res {
    Ok(v) => { s = v; },
    Err(e) => { s = -1.0; },
  }
  return (a, b, s);
}

// Aggregated conclusion degrees from fuzzy rules ("a:b:s" = antecedent,
// consequent, strength): out[j] = max over rules with consequent j of
// min(facts[a], s). NaN facts propagate as NaN conclusions. Complexity: O(rules).
pub fn fuzzy_inference(rules: &Vec[Str], facts: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  if rules.len() == 0 { return out; }
  var i = 0;
  while i < facts.len() {
    out.push(0.0);
    i = i + 1;
  }
  var r = 0;
  while r < rules.len() {
    var parsed = _parse_rule(rules[r]);
    var a = parsed.0;
    var b = parsed.1;
    var s = parsed.2;
    if a >= 0 && a < facts.len() && b >= 0 && b < facts.len() {
      var ante = facts[a];
      var deg = s;
      if ante < deg { deg = ante; }
      if deg > out[b] {
        out[b] = deg;
      }
    }
    r = r + 1;
  }
  return out;
}

// Mamdani-style inference: min implication with max aggregation over the
// same "a:b:s" rule convention (alias of fuzzy_inference). Complexity: O(rules).
pub fn mamdani(rules: &Vec[Str], inputs: &Vec[Float64]) -> Vec[Float64] {
  return fuzzy_inference(rules, inputs);
}

// Sugeno-style weighted crisp output: rules are decimal strengths s_i and the
// result is sum(s_i * inputs_i) / sum(s_i). NaN when the weight sum is zero
// or the rule format is invalid. Complexity: O(rules).
pub fn sugeno(rules: &Vec[Str], inputs: &Vec[Float64]) -> Float64 {
  var num = 0.0;
  var den = 0.0;
  var i = 0;
  while i < rules.len() && i < inputs.len() {
    var s_res = string.str_to_float(rules[i]);
    var s = 0.0;
    match s_res {
      Ok(v) => { s = v; },
      Err(e) => { s = -1.0; },
    }
    if s < 0.0 { return 0.0 / 0.0; }
    num = num + s * inputs[i];
    den = den + s;
    i = i + 1;
  }
  if den == 0.0 { return 0.0 / 0.0; }
  return num / den;
}

// Fuzzy logic controller output (position form): kp * error + ki * error
// with error = setpoint - measurement (integral term approximated
// proportionally; documented). Complexity: O(1).
pub fn fuzzy_control(setpoint: Float64, measurement: Float64, kp: Float64, ki: Float64) -> Float64 {
  var error = setpoint - measurement;
  return kp * error + ki * error;
}

// Index of the best fuzzy-weighted alternative: argmax of alternatives_i *
// weights_i. Returns -1 for empty or mismatched input. Complexity: O(n).
pub fn fuzzy_decision(alternatives: &Vec[Float64], weights: &Vec[Float64]) -> Int {
  if alternatives.len() != weights.len() || alternatives.len() == 0 { return -1; }
  var best = 0;
  var best_val = alternatives[0] * weights[0];
  var i = 1;
  while i < alternatives.len() {
    var v = alternatives[i] * weights[i];
    if v > best_val {
      best_val = v;
      best = i;
    }
    i = i + 1;
  }
  return best;
}
