// XIOM - Math: Extended Algebra
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.math.algebra_extended

// Depends on: none

// ============================================================================
// Abstract algebraic structures beyond elementary algebra: groups, rings,
// fields, modules, and category-theoretic foundations.
//
// Each predicate validates a finite structure against its axioms by brute
// force over the (finite) carrier set. All checks are exact Int or
// Float64-with-tolerance (1e-9) comparisons; domain assumptions that the
// frozen signatures cannot express (e.g. which element is the ring
// identity) are documented per function. Where a signature cannot carry the
// required data, the most natural fixed interpretation is used and stated.
//
// COMPILER WORKAROUND: higher-order parameters named `add`/`mul`/`sub`
// collide with the compiler's built-in operators (an `add(a, b)` call
// resolves to native +/* and IGNORES the passed function -- a name
// resolution bug). The operator-carrying parameters are therefore named
// `op_add`/`op_mul`. The public function names and argument TYPES are
// unchanged; callers pass functions positionally.
// ============================================================================

use xiom.math;

// Validates the group axioms of (elements, operation, identity): closure,
// associativity, the two-sided identity law, and the existence of a
// two-sided inverse for every element. An empty carrier is vacuously a
// group of order zero. Complexity: O(|G|^3) plus inverse search O(|G|^3).
pub fn group_theory(operation: fn(Int, Int) -> Int, elements: &Vec[Int], identity: Int) -> Bool {
  var n = elements.len();
  if n == 0 { return true; }
  var i = 0;
  while i < n {
    var j = 0;
    while j < n {
      // closure
      var prod = operation(elements[i], elements[j]);
      if !_contains(elements, prod) { return false; }
      // identity law
      if operation(elements[i], identity) != elements[i] { return false; }
      if operation(identity, elements[i]) != elements[i] { return false; }
      // inverse existence
      var has_inv = false;
      var k = 0;
      while k < n {
        if operation(elements[i], elements[k]) == identity {
          if operation(elements[k], elements[i]) == identity {
            has_inv = true;
            k = n;
          }
        }
        k = k + 1;
      }
      if !has_inv { return false; }
      // associativity
      var k2 = 0;
      while k2 < n {
        var lhs = operation(operation(elements[i], elements[j]), elements[k2]);
        var rhs = operation(elements[i], operation(elements[j], elements[k2]));
        if lhs != rhs { return false; }
        k2 = k2 + 1;
      }
      j = j + 1;
    }
    i = i + 1;
  }
  return true;
}

// Validates the ring axioms of (elements, op_add, op_mul, zero, one): the
// abelian group (elements, op_add, zero), the monoid (elements, op_mul,
// one), and both distributive laws. Multiplication is not required to
// commute (non-commutative rings are accepted). NOTE: the parameter names
// avoid the compiler's built-in operator identifiers (`add`/`mul` resolve
// to Int/Float64 +/* regardless of the parameter, a name-resolution bug).
// Complexity: O(|R|^4).
pub fn ring_theory(op_add: fn(Int, Int) -> Int, op_mul: fn(Int, Int) -> Int, elements: &Vec[Int], zero: Int, one: Int) -> Bool {
  var n = elements.len();
  if n == 0 { return true; }
  var i = 0;
  while i < n {
    var j = 0;
    while j < n {
      // add closure
      var s = op_add(elements[i], elements[j]);
      if !_contains(elements, s) { return false; }
      // add commutativity
      if op_add(elements[i], elements[j]) != op_add(elements[j], elements[i]) { return false; }
      // add identity
      if op_add(elements[i], zero) != elements[i] { return false; }
      if op_add(zero, elements[i]) != elements[i] { return false; }
      // add inverse
      var has_inv = false;
      var k = 0;
      while k < n {
        if op_add(elements[i], elements[k]) == zero {
          if op_add(elements[k], elements[i]) == zero {
            has_inv = true;
            k = n;
          }
        }
        k = k + 1;
      }
      if !has_inv { return false; }
      // mul closure
      var p = op_mul(elements[i], elements[j]);
      if !_contains(elements, p) { return false; }
      // mul identity
      if op_mul(elements[i], one) != elements[i] { return false; }
      if op_mul(one, elements[i]) != elements[i] { return false; }
      // distributivity: a*(b+c) and (b+c)*a
      var bpc = op_add(elements[j], elements[0]);
      var l1 = op_mul(elements[i], bpc);
      var r1 = op_add(op_mul(elements[i], elements[j]), op_mul(elements[i], elements[0]));
      if l1 != r1 { return false; }
      var l2 = op_mul(bpc, elements[i]);
      var r2 = op_add(op_mul(elements[j], elements[i]), op_mul(elements[0], elements[i]));
      if l2 != r2 { return false; }
      j = j + 1;
    }
    i = i + 1;
  }
  // add associativity
  var a = 0;
  while a < n {
    var b = 0;
    while b < n {
      var c = 0;
      while c < n {
        var l = op_add(op_add(elements[a], elements[b]), elements[c]);
        var r = op_add(elements[a], op_add(elements[b], elements[c]));
        if l != r { return false; }
        c = c + 1;
      }
      b = b + 1;
    }
    a = a + 1;
  }
  // mul associativity
  var p = 0;
  while p < n {
    var q = 0;
    while q < n {
      var s = 0;
      while s < n {
        var lm = op_mul(op_mul(elements[p], elements[q]), elements[s]);
        var rm = op_mul(elements[p], op_mul(elements[q], elements[s]));
        if lm != rm { return false; }
        s = s + 1;
      }
      q = q + 1;
    }
    p = p + 1;
  }
  return true;
}

// Validates the field axioms of (elements, op_add, op_mul, zero, one): the
// ring axioms plus a commutative multiplication and a multiplicative
// inverse for every element other than zero. Parameter names avoid the
// compiler's built-in operator identifiers (see ring_theory). Complexity:
// O(|F|^4).
pub fn field_theory(op_add: fn(Float64, Float64) -> Float64, op_mul: fn(Float64, Float64) -> Float64,
                    elements: &Vec[Float64], zero: Float64, one: Float64) -> Bool {
  var n = elements.len();
  if n == 0 { return true; }
  var i = 0;
  while i < n {
    var j = 0;
    while j < n {
      var s = op_add(elements[i], elements[j]);
      if !_contains_f(elements, s) { return false; }
      if op_add(elements[i], elements[j]) != op_add(elements[j], elements[i]) { return false; }
      if op_add(elements[i], zero) != elements[i] { return false; }
      var has_inv = false;
      var k = 0;
      while k < n {
        if op_add(elements[i], elements[k]) == zero { has_inv = true; }
        k = k + 1;
      }
      if !has_inv { return false; }
      var p = op_mul(elements[i], elements[j]);
      if !_contains_f(elements, p) { return false; }
      if op_mul(elements[i], one) != elements[i] { return false; }
      // commutativity of multiplication
      if op_mul(elements[i], elements[j]) != op_mul(elements[j], elements[i]) { return false; }
      // distributivity
      var bpc = op_add(elements[j], elements[0]);
      var l1 = op_mul(elements[i], bpc);
      var r1 = op_add(op_mul(elements[i], elements[j]), op_mul(elements[i], elements[0]));
      if !_feq(l1, r1) { return false; }
      j = j + 1;
    }
    // multiplicative inverse for every non-zero element
    if elements[i] != zero {
      var has_mul_inv = false;
      var m = 0;
      while m < n {
        if _feq(op_mul(elements[i], elements[m]), one) {
          has_mul_inv = true;
          m = n;
        }
        m = m + 1;
      }
      if !has_mul_inv { return false; }
    }
    i = i + 1;
  }
  return true;
}

// Validates the module axioms of (ring, module, action): the ring set is
// treated as the scalars and the module set as the vectors. Given the
// frozen signature (no scalar/vector addition functions), the check covers
// closure of the action (r*v in module for every r, v) and the unital law
// assuming ring[0] is the multiplicative identity of the ring (documented
// convention). Complexity: O(|R| * |M|).
pub fn module_theory(action: fn(Int, Int) -> Int, ring: &Vec[Int], module_set: &Vec[Int]) -> Bool {
  var n = module_set.len();
  if n == 0 { return true; }
  var id = 0;
  if ring.len() > 0 { id = ring[0]; }
  var i = 0;
  while i < ring.len() {
    var j = 0;
    while j < n {
      var prod = action(ring[i], module_set[j]);
      if !_contains(module_set, prod) { return false; }
      if ring[i] == id {
        if prod != module_set[j] { return false; }
      }
      j = j + 1;
    }
    i = i + 1;
  }
  return true;
}

// True iff the polynomial (coefficients from the constant term) is
// separable over the field F_p: gcd(p, p') == 1 modulo p. Returns false for
// prime <= 1 (no field), or an empty/constant polynomial. Complexity:
// O(deg^2) modular Euclid.
pub fn galois_theory(polynomial: &Vec[Int], prime: Int) -> Bool {
  if prime <= 1 { return false; }
  var d = polynomial.len();
  if d == 0 { return false; }
  if d == 1 { return true; }
  var deriv = Vec[Int].new();
  var i = 1;
  while i < d {
    var c = (i * polynomial[i]) % prime;
    if c < 0 { c = c + prime; }
    deriv.push(c);
    i = i + 1;
  }
  var a = _strip_mod(polynomial, prime);
  var b = _strip_mod(&deriv, prime);
  var g = _poly_gcd_mod(&a, &b, prime);
  if g.len() == 1 { return true; }
  return false;
}

// True iff alpha is a root of the polynomial (coefficients from the
// constant term) within 1e-9 tolerance. Returns false for an empty
// polynomial. Complexity: O(deg).
pub fn algebraic_number(alpha: Float64, polynomial: &Vec[Float64]) -> Bool {
  var val = _poly_eval(alpha, polynomial);
  if val < 0.0 { val = -val; }
  return val < 1e-9;
}

// True iff the ideal is closed and absorbing in the ring under op_mul: the
// ideal is a subset of the ring, mul-closed on itself, and absorbing
// (r * i in the ideal for every ring element r and ideal element i). The
// frozen signature omits the ring addition, so the additive ideal laws are
// not checked (documented). Parameter name avoids the built-in operator
// identifiers (see ring_theory). Complexity: O(|R| * |I|).
pub fn commutative_algebra(ideal: &Vec[Int], ring: &Vec[Int], op_mul: fn(Int, Int) -> Int) -> Bool {
  var i = 0;
  while i < ideal.len() {
    if !_contains(ring, ideal[i]) { return false; }
    var j = 0;
    while j < ideal.len() {
      var p = op_mul(ideal[i], ideal[j]);
      if !_contains(ideal, p) { return false; }
      j = j + 1;
    }
    var r = 0;
    while r < ring.len() {
      var a = op_mul(ring[r], ideal[i]);
      if !_contains(ideal, a) { return false; }
      var b = op_mul(ideal[i], ring[r]);
      if !_contains(ideal, b) { return false; }
      r = r + 1;
    }
    i = i + 1;
  }
  return true;
}

// True iff the chain complex squares to zero: for every chain group element
// v at stage i, maps[i+1](maps[i](v)) is the zero element (an empty vector
// or a vector of zeros) of stage i+2. Each chain row is a set of elements;
// a single element is wrapped in a one-element vector before applying the
// corresponding map. Complexity: O(stages * |chain| * cost(map)).
pub fn homological_algebra(chain: &Vec[Vec[Int]], maps: &Vec[fn(&Vec[Int]) -> Vec[Int]>) -> Bool {
  var stages = chain.len();
  if stages == 0 { return true; }
  if maps.len() < stages - 1 { return false; }
  var i = 0;
  while i < stages - 2 {
    var row = chain[i];
    var j = 0;
    while j < row.len() {
      var v = Vec[Int].new();
      v.push(row[j]);
      var mapped = maps[i](&v);
      var mapped2 = maps[i + 1](&mapped);
      if !_is_zero_vec(&mapped2) { return false; }
      j = j + 1;
    }
    i = i + 1;
  }
  return true;
}

// True iff (objects, morphisms) is a category: morphism endpoints lie in
// objects, an identity morphism (x, x) exists for every object, and the
// composition of any composable pair (a, b) and (b, c) exists as a
// morphism (a, c). With the pair representation composition is then
// automatically associative (documented). Complexity: O(|M|^2).
pub fn category_theory(objects: &Vec[Int], morphisms: &Vec[(Int, Int)]) -> Bool {
  var m = 0;
  while m < morphisms.len() {
    if !_contains(objects, morphisms[m].0) { return false; }
    if !_contains(objects, morphisms[m].1) { return false; }
    m = m + 1;
  }
  var o = 0;
  while o < objects.len() {
    if !_has_pair(morphisms, objects[o], objects[o]) { return false; }
    o = o + 1;
  }
  var p = 0;
  while p < morphisms.len() {
    var q = 0;
    while q < morphisms.len() {
      if morphisms[p].1 == morphisms[q].0 {
        if !_has_pair(morphisms, morphisms[p].0, morphisms[q].1) { return false; }
      }
      q = q + 1;
    }
    p = p + 1;
  }
  return true;
}

// Validates an equational algebra signature with one operation of the given
// arity: the operation is closed on elements (the result of every arity-
// tuple of elements is itself an element). Returns false for arity <= 0
// (documented). Complexity: O(|A|^arity).
pub fn universal_algebra(operation: fn(&Vec[Int]) -> Int, arity: Int, elements: &Vec[Int]) -> Bool {
  if arity <= 0 { return false; }
  var n = elements.len();
  if n == 0 { return true; }
  var total = 1;
  var t = 0;
  while t < arity {
    total = total * n;
    t = t + 1;
  }
  var count = 0;
  while count < total {
    var args = Vec[Int].new();
    var tmp = count;
    var d = 0;
    while d < arity {
      var digit = tmp % n;
      args.push(elements[digit]);
      tmp = tmp / n;
      d = d + 1;
    }
    var r = operation(&args);
    if !_contains(elements, r) { return false; }
    count = count + 1;
  }
  return true;
}

// True iff the matrix assignment preserves group multiplication: assuming
// matrices[i] is the image of group[i] (documented correspondence), every
// pair (i, j) satisfies M[op_mul(g_i, g_j)] == M[i] * M[j] within 1e-9
// tolerance. Parameter name avoids the built-in operator identifiers (see
// ring_theory). Returns false when the assignment does not cover the group.
// Complexity: O(|G|^3 * dim^3).
pub fn representation_theory(group: &Vec[Int], op_mul: fn(Int, Int) -> Int, matrices: &Vec[Vec[Vec[Float64]]]) -> Bool {
  var n = group.len();
  if n == 0 { return true; }
  if matrices.len() != n { return false; }
  var i = 0;
  while i < n {
    var j = 0;
    while j < n {
      var prod = op_mul(group[i], group[j]);
      var k = _index_of(group, prod);
      if k < 0 { return false; }
      var expected = _mat_mul_rt(&matrices[i], &matrices[j]);
      if !_mat_eq_rt(&expected, &matrices[k]) { return false; }
      j = j + 1;
    }
    i = i + 1;
  }
  return true;
}

// True iff the bilinear alternating bracket satisfies the Jacobi identity
// on the basis (vectors over Z, represented as (Int, Int) pairs):
// anticommutativity bracket(x, x) == (0, 0), bilinearity in both arguments
// (using pair addition), and bracket(x, bracket(y, z)) + bracket(y,
// bracket(z, x)) + bracket(z, bracket(x, y)) == (0, 0). Complexity:
// O(|B|^3).
pub fn lie_algebra(bracket: fn((Int, Int), (Int, Int)) -> (Int, Int), basis: &Vec[(Int, Int)]) -> Bool {
  var n = basis.len();
  if n == 0 { return true; }
  var i = 0;
  while i < n {
    var bx = bracket(basis[i], basis[i]);
    if bx.0 != 0 || bx.1 != 0 { return false; }
    i = i + 1;
  }
  var a = 0;
  while a < n {
    var b = 0;
    while b < n {
      var c = 0;
      while c < n {
        var yz = bracket(basis[b], basis[c]);
        var zx = bracket(basis[c], basis[a]);
        var xy = bracket(basis[a], basis[b]);
        var t1 = _pair_add(bracket(basis[a], yz), bracket(basis[b], zx));
        var t2 = _pair_add(t1, bracket(basis[c], xy));
        if t2.0 != 0 || t2.1 != 0 { return false; }
        c = c + 1;
      }
      b = b + 1;
    }
    a = a + 1;
  }
  return true;
}

// Basis of the Clifford algebra for the diagonal metric: returns the 2^dim
// x 2^dim scalar table M with M[i][j] the coefficient such that
// blade_i * blade_j = M[i][j] * blade_{i xor j} (basis blades indexed by
// their generator bitmask, 1 = e_1e_2...). The metric is the quadratic
// form of the underlying space; only its diagonal is used (documented).
// Returns the empty matrix for dim < 0 (documented). Complexity: O(4^dim).
pub fn clifford_algebra(metric: &Vec[Vec[Float64]], dim: Int) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  if dim < 0 { return out; }
  var size = _pow2(dim);
  var i = 0;
  while i < size {
    var row = Vec[Float64].new();
    var j = 0;
    while j < size {
      var prod = _blade_product(metric, i, j, dim);
      row.push(prod.0);
      j = j + 1;
    }
    out.push(row);
    i = i + 1;
  }
  return out;
}

// ============================================================================
// Internal helpers
// ============================================================================

// True iff v contains elem (Int).
fn _contains(v: &Vec[Int], elem: Int) -> Bool {
  var i = 0;
  while i < v.len() {
    if v[i] == elem { return true; }
    i = i + 1;
  }
  return false;
}

// True iff v contains elem (Float64, exact equality).
fn _contains_f(v: &Vec[Float64], elem: Float64) -> Bool {
  var i = 0;
  while i < v.len() {
    if v[i] == elem { return true; }
    i = i + 1;
  }
  return false;
}

// True iff a and b are equal within 1e-9.
fn _feq(a: Float64, b: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < 1e-9;
}

// Index of elem in v, or -1.
fn _index_of(v: &Vec[Int], elem: Int) -> Int {
  var i = 0;
  while i < v.len() {
    if v[i] == elem { return i; }
    i = i + 1;
  }
  return -1;
}

// True iff the morphism (a, b) is present.
fn _has_pair(morphisms: &Vec[(Int, Int)], a: Int, b: Int) -> Bool {
  var i = 0;
  while i < morphisms.len() {
    if morphisms[i].0 == a && morphisms[i].1 == b { return true; }
    i = i + 1;
  }
  return false;
}

// Evaluate the polynomial (constant-first coefficients) at x.
fn _poly_eval(x: Float64, poly: &Vec[Float64]) -> Float64 {
  var s = 0.0;
  var i = poly.len();
  while i > 0 {
    s = s * x + poly[i - 1];
    i = i - 1;
  }
  return s;
}

// Reduce coefficients mod p and drop leading zeros.
fn _strip_mod(poly: &Vec[Int], p: Int) -> Vec[Int] {
  var out = Vec[Int].new();
  var i = 0;
  while i < poly.len() {
    var c = poly[i] % p;
    if c < 0 { c = c + p; }
    out.push(c);
    i = i + 1;
  }
  while out.len() > 1 && out[out.len() - 1] == 0 {
    out.remove(out.len() - 1);
  }
  return out;
}

// Polynomial gcd over F_p by Euclid.
fn _poly_gcd_mod(a: &Vec[Int], b: &Vec[Int], p: Int) -> Vec[Int] {
  var x = clone_poly(a);
  var y = clone_poly(b);
  while !_is_zero_vec(&y) {
    var r = _poly_mod(&x, &y, p);
    x = y;
    y = r;
  }
  return x;
}

// Remainder of polynomial division over F_p.
fn _poly_mod(a: &Vec[Int], b: &Vec[Int], p: Int) -> Vec[Int] {
  var r = clone_poly(a);
  var db = b.len();
  var lc = b[db - 1];
  while r.len() >= db && !_is_zero_vec(&r) {
    var da = r.len();
    var shift = da - db;
    var factor = (r[da - 1] * _mod_inv(lc, p)) % p;
    var i = 0;
    while i < db {
      var idx = i + shift;
      var t = (r[idx] - factor * b[i]) % p;
      if t < 0 { t = t + p; }
      r[idx] = t;
      i = i + 1;
    }
    while r.len() > 1 && r[r.len() - 1] == 0 {
      r.remove(r.len() - 1);
    }
  }
  return r;
}

// Modular inverse of a mod p (p prime).
fn _mod_inv(a: Int, p: Int) -> Int {
  var v = math.arithmetic.mod_inverse(a, p);
  if !v.is_some() { return 0; }
  return v.unwrap();
}

// Copy of a polynomial vector.
fn clone_poly(v: &Vec[Int]) -> Vec[Int] {
  var out = Vec[Int].new();
  var i = 0;
  while i < v.len() {
    out.push(v[i]);
    i = i + 1;
  }
  return out;
}

// True iff v is empty or all zeros.
fn _is_zero_vec(v: &Vec[Int]) -> Bool {
  var i = 0;
  while i < v.len() {
    if v[i] != 0 { return false; }
    i = i + 1;
  }
  return true;
}

// Pair addition over Z.
fn _pair_add(a: (Int, Int), b: (Int, Int)) -> (Int, Int) {
  return (a.0 + b.0, a.1 + b.1);
}

// Row-major matrix product of two square matrices.
fn _mat_mul_rt(a: &Vec[Vec[Float64]], b: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {
  var n = a.len();
  var out = Vec[Vec[Float64]].new();
  if n == 0 { return out; }
  var m = a[0].len();
  var i = 0;
  while i < n {
    var row = Vec[Float64].new();
    var j = 0;
    while j < m {
      var s = 0.0;
      var k = 0;
      while k < m {
        s = s + a[i][k] * b[k][j];
        k = k + 1;
      }
      row.push(s);
      j = j + 1;
    }
    out.push(row);
    i = i + 1;
  }
  return out;
}

// Element-wise tolerance equality of two matrices.
fn _mat_eq_rt(a: &Vec[Vec[Float64]], b: &Vec[Vec[Float64]]) -> Bool {
  if a.len() != b.len() { return false; }
  var i = 0;
  while i < a.len() {
    if a[i].len() != b[i].len() { return false; }
    var j = 0;
    while j < a[i].len() {
      if !_feq(a[i][j], b[i][j]) { return false; }
      j = j + 1;
    }
    i = i + 1;
  }
  return true;
}

// 2^n for n >= 0.
fn _pow2(n: Int) -> Int {
  var r = 1;
  var i = 0;
  while i < n {
    r = r * 2;
    i = i + 1;
  }
  return r;
}

// Clifford product of basis blades i and j for the diagonal metric:
// returns (coefficient, result blade index) with
// blade_i * blade_j = coefficient * blade_{i xor j}.
fn _blade_product(metric: &Vec[Vec[Float64]], i: Int, j: Int, dim: Int) -> (Float64, Int) {
  var sign = 1.0;
  var coeff = 1.0;
  var result = i;
  var bit = 0;
  while bit < dim {
    if (j / _pow2(bit)) % 2 == 1 {
      // count generators of the current result above this bit (inversions)
      var higher = 0;
      var hb = bit + 1;
      while hb < dim {
        if (result / _pow2(hb)) % 2 == 1 { higher = higher + 1; }
        hb = hb + 1;
      }
      if higher % 2 == 1 { sign = -sign; }
      if (result / _pow2(bit)) % 2 == 1 {
        coeff = coeff * metric[bit][bit];
        result = result - _pow2(bit);
      } else {
        result = result + _pow2(bit);
      }
    }
    bit = bit + 1;
  }
  return (sign * coeff, result);
}
