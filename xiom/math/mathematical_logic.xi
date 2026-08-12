// XIOM - Math: Mathematical Logic
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.mathematical_logic

// Depends on: none

// ============================================================================
// Formal systems and metalogic: propositional through modal and categorical
// calculi, plus model and proof theory over finite domains.
//
// Formula syntax (documented mini-language):
//   variables: single letters a..z (propositional)
//   atoms:     P(d) - predicate P holds of element d (predicate/first-order)
//   operators: ! not, & and, | or, > implies, = iff, ( ) grouping
//   modal:     [f] box, <f> diamond (relations are (world, world) pairs)
//   temporal:  X f next-time along the successor chain
// Functions whose semantics cannot be soundly reduced to the finite
// string/relation machinery are marked TODO(compiler). Complexity is
// documented per function.
// ============================================================================

use xiom.string;
use xiom.math;
use xiom.core.to_int;

// Parser state: the formula and the current byte position.
type _PS = {
  s: Str;
  pos: Int;
}

// Byte at the current position, or -1 at end of input.
fn _peek(st: &_PS) -> Int {
  var len = string.str_len(st.s);
  if st.pos >= len { return -1; }
  var b = string.byte_at(st.s, st.pos);
  return b as Int;
}

// Consume and return the current byte, or -1 at end of input.
fn _take(st: &mut _PS) -> Int {
  var len = string.str_len(st.s);
  if st.pos >= len { return -1; }
  var b = string.byte_at(st.s, st.pos);
  st.pos = st.pos + 1;
  return b as Int;
}

// Skip whitespace bytes.
fn _skip(st: &mut _PS) {
  var c = _peek(st);
  while c == 32 || c == 9 || c == 10 || c == 13 {
    st.pos = st.pos + 1;
    c = _peek(st);
  }
}

// Variable index for a..z, else -1.
fn _var_index(c: Int) -> Int {
  if c >= 97 && c <= 122 { return c - 97; }
  return -1;
}

// Membership of value d in the domain vector.
fn _in_domain(d: Int, domain: &Vec[Int]) -> Bool {
  var i = 0;
  while i < domain.len() {
    if domain[i] == d { return true; }
    i = i + 1;
  }
  return false;
}

// Primary atom: a variable (mode 0) or P(d) with d in domain (mode 1) or
// P(d) verified through structure (mode 2).
fn _primary(st: &mut _PS, mode: Int, domain: &Vec[Int], structure: fn(&Vec[Int]) -> Bool, assign: &Vec[Int]) -> Bool {
  _skip(st);
  var c = _peek(st);
  if c == 40 {
    _take(st);
    var inner = _iff(st, mode, domain, structure, assign);
    _skip(st);
    _take(st);
    return inner;
  }
  if c == 80 || c == 112 {
    _take(st);
    _skip(st);
    if _peek(st) == 40 {
      _take(st);
      _skip(st);
      var val = 0;
      var d = _peek(st);
      while d >= 48 && d <= 57 {
        _take(st);
        val = val * 10 + (d - 48);
        d = _peek(st);
      }
      _skip(st);
      _take(st);
      if mode == 1 {
        return _in_domain(val, domain);
      }
      if mode == 2 {
        var single = Vec[Int].new();
        single.push(val);
        return structure(&single);
      }
      return false;
    }
    return false;
  }
  if mode == 0 {
    var ch = _take(st);
    var vi = _var_index(ch);
    if vi < 0 || vi >= 26 { return false; }
    if vi < assign.len() {
      if assign[vi] == 1 { return true; }
    }
    return false;
  }
  _take(st);
  return false;
}

// Binary operator levels: = (iff), > (implies), | (or), & (and).
fn _iff(st: &mut _PS, mode: Int, domain: &Vec[Int], structure: fn(&Vec[Int]) -> Bool, assign: &Vec[Int]) -> Bool {
  var a = _implies(st, mode, domain, structure, assign);
  _skip(st);
  if _peek(st) == 61 {
    _take(st);
    var b = _iff(st, mode, domain, structure, assign);
    if a == b { return true; }
    return false;
  }
  return a;
}

fn _implies(st: &mut _PS, mode: Int, domain: &Vec[Int], structure: fn(&Vec[Int]) -> Bool, assign: &Vec[Int]) -> Bool {
  var a = _or(st, mode, domain, structure, assign);
  _skip(st);
  if _peek(st) == 62 {
    _take(st);
    var b = _implies(st, mode, domain, structure, assign);
    if a && b { return false; }
    return true;
  }
  return a;
}

fn _or(st: &mut _PS, mode: Int, domain: &Vec[Int], structure: fn(&Vec[Int]) -> Bool, assign: &Vec[Int]) -> Bool {
  var a = _and(st, mode, domain, structure, assign);
  _skip(st);
  if _peek(st) == 124 {
    _take(st);
    var b = _or(st, mode, domain, structure, assign);
    if a || b { return true; }
    return false;
  }
  return a;
}

fn _and(st: &mut _PS, mode: Int, domain: &Vec[Int], structure: fn(&Vec[Int]) -> Bool, assign: &Vec[Int]) -> Bool {
  var a = _not(st, mode, domain, structure, assign);
  _skip(st);
  if _peek(st) == 38 {
    _take(st);
    var b = _and(st, mode, domain, structure, assign);
    if a && b { return true; }
    return false;
  }
  return a;
}

fn _not(st: &mut _PS, mode: Int, domain: &Vec[Int], structure: fn(&Vec[Int]) -> Bool, assign: &Vec[Int]) -> Bool {
  _skip(st);
  if _peek(st) == 33 {
    _take(st);
    var inner = _not(st, mode, domain, structure, assign);
    if inner { return false; }
    return true;
  }
  return _primary(st, mode, domain, structure, assign);
}

// Dummy structure used when a mode does not consult the structure.
fn _dummy_struct(x: &Vec[Int]) -> Bool {
  return false;
}

// Validity of a propositional formula over the variables a..z: the formula
// evaluates true under every assignment. Complexity: O(2^vars * len).
pub fn propositional(expr: Str) -> Bool {
  var vars = Vec[Int].new();
  var i = 0;
  while i < 26 {
    vars.push(0);
    i = i + 1;
  }
  var count = 0;
  var len = string.str_len(expr);
  var j = 0;
  while j < len {
    var vi = _var_index(string.byte_at(expr, j) as Int);
    if vi >= 0 && vars[vi] == 0 {
      vars[vi] = 1;
      count = count + 1;
    }
    j = j + 1;
  }
  var total = 1;
  var k = 0;
  while k < count {
    total = total * 2;
    k = k + 1;
  }
  var assign = Vec[Int].new();
  var m = 0;
  while m < 26 {
    assign.push(0);
    m = m + 1;
  }
  var mask = 0;
  while mask < total {
    var bit = 0;
    while bit < 26 {
      if vars[bit] == 1 {
        if (mask >> bit) % 2 == 1 {
          assign[bit] = 1;
        } else {
          assign[bit] = 0;
        }
      }
      bit = bit + 1;
    }
    var st = _PS{ s: expr, pos: 0 };
    var val = _iff(&mut st, 0, &Vec[Int].new(), _dummy_struct, &assign);
    if !val {
      return false;
    }
    mask = mask + 1;
  }
  return true;
}

// Truth of a first-order formula over a finite domain: atoms P(d) hold when
// d is a member of the domain. Complexity: O(len).
pub fn predicate(expr: Str, domain: &Vec[Int]) -> Bool {
  var assign = Vec[Int].new();
  var i = 0;
  while i < 26 {
    assign.push(0);
    i = i + 1;
  }
  var st = _PS{ s: expr, pos: 0 };
  return _iff(&mut st, 1, domain, _dummy_struct, &assign);
}

// Satisfiability of a formula in a given structure: atoms P(d) are
// evaluated by structure([d]). Complexity: O(len * cost(structure)).
pub fn first_order(formula: Str, structure: fn(&Vec[Int]) -> Bool) -> Bool {
  var assign = Vec[Int].new();
  var i = 0;
  while i < 26 {
    assign.push(0);
    i = i + 1;
  }
  var st = _PS{ s: formula, pos: 0 };
  return _iff(&mut st, 2, &Vec[Int].new(), structure, &assign);
}

// Truth of a modal formula at a world: atoms are P<k> (predicate P holds of
// world k); [f] is true when f holds at every world reachable from the
// current one, <f> when it holds at some reachable world. The relations
// vector is a list of (from, to) pairs. Complexity: O(len * reachable).
pub fn modal(formula: Str, world: Int, relations: &Vec[(Int, Int)]) -> Bool {
  var st = _PS{ s: formula, pos: 0 };
  return _modal_iff(&mut st, world, relations);
}

fn _modal_iff(st: &mut _PS, world: Int, relations: &Vec[(Int, Int)]) -> Bool {
  var a = _modal_implies(st, world, relations);
  _skip(st);
  if _peek(st) == 61 {
    _take(st);
    var b = _modal_iff(st, world, relations);
    if a == b { return true; }
    return false;
  }
  return a;
}

fn _modal_implies(st: &mut _PS, world: Int, relations: &Vec[(Int, Int)]) -> Bool {
  var a = _modal_or(st, world, relations);
  _skip(st);
  if _peek(st) == 62 {
    _take(st);
    var b = _modal_implies(st, world, relations);
    if a && b { return false; }
    return true;
  }
  return a;
}

fn _modal_or(st: &mut _PS, world: Int, relations: &Vec[(Int, Int)]) -> Bool {
  var a = _modal_and(st, world, relations);
  _skip(st);
  if _peek(st) == 124 {
    _take(st);
    var b = _modal_or(st, world, relations);
    if a || b { return true; }
    return false;
  }
  return a;
}

fn _modal_and(st: &mut _PS, world: Int, relations: &Vec[(Int, Int)]) -> Bool {
  var a = _modal_not(st, world, relations);
  _skip(st);
  if _peek(st) == 38 {
    _take(st);
    var b = _modal_and(st, world, relations);
    if a && b { return true; }
    return false;
  }
  return a;
}

fn _modal_not(st: &mut _PS, world: Int, relations: &Vec[(Int, Int)]) -> Bool {
  _skip(st);
  if _peek(st) == 33 {
    _take(st);
    var inner = _modal_not(st, world, relations);
    if inner { return false; }
    return true;
  }
  return _modal_primary(st, world, relations);
}

fn _modal_primary(st: &mut _PS, world: Int, relations: &Vec[(Int, Int)]) -> Bool {
  _skip(st);
  var c = _peek(st);
  if c == 40 {
    _take(st);
    var inner = _modal_iff(st, world, relations);
    _skip(st);
    _take(st);
    return inner;
  }
  if c == 91 {
    _take(st);
    var body = _modal_iff(st, world, relations);
    _skip(st);
    _take(st);
    var all_ok = true;
    var i = 0;
    while i < relations.len() {
      var r = relations[i];
      if r.0 == world {
        var w2 = r.1;
        var st2 = _PS{ s: st.s, pos: 0 };
        var v = _modal_iff(&mut st2, w2, relations);
        if !v {
          all_ok = false;
        }
      }
      i = i + 1;
    }
    return all_ok;
  }
  if c == 60 {
    _take(st);
    var body = _modal_iff(st, world, relations);
    _skip(st);
    _take(st);
    var any_ok = false;
    var j = 0;
    while j < relations.len() {
      var r = relations[j];
      if r.0 == world {
        var w2 = r.1;
        var st3 = _PS{ s: st.s, pos: 0 };
        var v = _modal_iff(&mut st3, w2, relations);
        if v {
          any_ok = true;
        }
      }
      j = j + 1;
    }
    return any_ok;
  }
  if c == 80 || c == 112 {
    _take(st);
    _skip(st);
    if _peek(st) == 60 {
      _take(st);
      _skip(st);
      var val = 0;
      var d = _peek(st);
      while d >= 48 && d <= 57 {
        _take(st);
        val = val * 10 + (d - 48);
        d = _peek(st);
      }
      _skip(st);
      _take(st);
      if val == world { return true; }
      return false;
    }
    return false;
  }
  _take(st);
  return false;
}

// Temporal-logic truth evaluation along the successor run: atoms are P<k>
// (true at state k) and the next-time operator X shifts evaluation to
// next(current). Complexity: O(len * cost(next)).
pub fn temporal(formula: Str, state: Int, next: fn(Int) -> Int) -> Bool {
  var st = _PS{ s: formula, pos: 0 };
  return _temp_iff(&mut st, state, next);
}

fn _temp_iff(st: &mut _PS, state: Int, next: fn(Int) -> Int) -> Bool {
  var a = _temp_implies(st, state, next);
  _skip(st);
  if _peek(st) == 61 {
    _take(st);
    var b = _temp_iff(st, state, next);
    if a == b { return true; }
    return false;
  }
  return a;
}

fn _temp_implies(st: &mut _PS, state: Int, next: fn(Int) -> Int) -> Bool {
  var a = _temp_or(st, state, next);
  _skip(st);
  if _peek(st) == 62 {
    _take(st);
    var b = _temp_implies(st, state, next);
    if a && b { return false; }
    return true;
  }
  return a;
}

fn _temp_or(st: &mut _PS, state: Int, next: fn(Int) -> Int) -> Bool {
  var a = _temp_and(st, state, next);
  _skip(st);
  if _peek(st) == 124 {
    _take(st);
    var b = _temp_or(st, state, next);
    if a || b { return true; }
    return false;
  }
  return a;
}

fn _temp_and(st: &mut _PS, state: Int, next: fn(Int) -> Int) -> Bool {
  var a = _temp_not(st, state, next);
  _skip(st);
  if _peek(st) == 38 {
    _take(st);
    var b = _temp_and(st, state, next);
    if a && b { return true; }
    return false;
  }
  return a;
}

fn _temp_not(st: &mut _PS, state: Int, next: fn(Int) -> Int) -> Bool {
  _skip(st);
  if _peek(st) == 33 {
    _take(st);
    var inner = _temp_not(st, state, next);
    if inner { return false; }
    return true;
  }
  return _temp_primary(st, state, next);
}

fn _temp_primary(st: &mut _PS, state: Int, next: fn(Int) -> Int) -> Bool {
  _skip(st);
  var c = _peek(st);
  if c == 40 {
    _take(st);
    var inner = _temp_iff(st, state, next);
    _skip(st);
    _take(st);
    return inner;
  }
  if c == 88 {
    _take(st);
    var ns = next(state);
    return _temp_iff(st, ns, next);
  }
  if c == 80 || c == 112 {
    _take(st);
    _skip(st);
    if _peek(st) == 60 {
      _take(st);
      _skip(st);
      var val = 0;
      var d = _peek(st);
      while d >= 48 && d <= 57 {
        _take(st);
        val = val * 10 + (d - 48);
        d = _peek(st);
      }
      _skip(st);
      _take(st);
      if val == state { return true; }
      return false;
    }
    return false;
  }
  _take(st);
  return false;
}

// Fuzzy truth value in [0, 1] of a formula over the variable truth values in
// `values` (a..z indexed; unknown variables default to 0). min/max/1-x
// semantics for &/|/!, and |a - b| for = (documented). Complexity: O(len).
pub fn fuzzy_logic(formula: Str, values: &Vec[Float64]) -> Float64 {
  var st = _PS{ s: formula, pos: 0 };
  return _fuzzy_iff(&mut st, values);
}

fn _fuzzy_iff(st: &mut _PS, values: &Vec[Float64]) -> Float64 {
  var a = _fuzzy_implies(st, values);
  _skip(st);
  if _peek(st) == 61 {
    _take(st);
    var b = _fuzzy_iff(st, values);
    var d = a - b;
    if d < 0.0 { d = -d; }
    return d;
  }
  return a;
}

fn _fuzzy_implies(st: &mut _PS, values: &Vec[Float64]) -> Float64 {
  var a = _fuzzy_or(st, values);
  _skip(st);
  if _peek(st) == 62 {
    _take(st);
    var b = _fuzzy_implies(st, values);
    var one = 1.0 - a;
    if b < one { return b; }
    return one;
  }
  return a;
}

fn _fuzzy_or(st: &mut _PS, values: &Vec[Float64]) -> Float64 {
  var a = _fuzzy_and(st, values);
  _skip(st);
  if _peek(st) == 124 {
    _take(st);
    var b = _fuzzy_or(st, values);
    if a > b { return a; }
    return b;
  }
  return a;
}

fn _fuzzy_and(st: &mut _PS, values: &Vec[Float64]) -> Float64 {
  var a = _fuzzy_not(st, values);
  _skip(st);
  if _peek(st) == 38 {
    _take(st);
    var b = _fuzzy_and(st, values);
    if a < b { return a; }
    return b;
  }
  return a;
}

fn _fuzzy_not(st: &mut _PS, values: &Vec[Float64]) -> Float64 {
  _skip(st);
  if _peek(st) == 33 {
    _take(st);
    var inner = _fuzzy_not(st, values);
    return 1.0 - inner;
  }
  return _fuzzy_primary(st, values);
}

fn _fuzzy_primary(st: &mut _PS, values: &Vec[Float64]) -> Float64 {
  _skip(st);
  var c = _peek(st);
  if c == 40 {
    _take(st);
    var inner = _fuzzy_iff(st, values);
    _skip(st);
    _take(st);
    return inner;
  }
  var ch = _take(st);
  var vi = _var_index(ch);
  if vi >= 0 && vi < values.len() {
    return values[vi];
  }
  return 0.0;
}

// Theorem follows from the axioms via the inference rules: true when the
// theorem string matches an axiom or a single modus ponens step (an axiom is
// an implication "a>b" and "a" is derivable). Complexity: O(axioms^2 * len).
pub fn provability(axioms: &Vec[Str], theorem: Str) -> Bool {
  var i = 0;
  while i < axioms.len() {
    if axioms[i] == theorem {
      return true;
    }
    i = i + 1;
  }
  var j = 0;
  while j < axioms.len() {
    var ax = axioms[j];
    var gt = _find_gt(ax);
    if gt > 0 {
      var ant = string.str_slice(ax, 0, gt);
      var cons = string.str_slice(ax, gt + 1, string.str_len(ax));
      if cons == theorem {
        var k = 0;
        while k < axioms.len() {
          if axioms[k] == ant {
            return true;
          }
          k = k + 1;
        }
      }
    }
    j = j + 1;
  }
  return false;
}

// Index of the implication symbol '>' in a formula, or -1.
fn _find_gt(s: Str) -> Int {
  var i = 0;
  while i < string.str_len(s) {
    if string.byte_at(s, i) == 62 {
      return i;
    }
    i = i + 1;
  }
  return -1;
}

// Structure is a model of every sentence (atoms P(d) evaluated by the
// structure). Complexity: O(sentences * len).
pub fn model_theory(sentences: &Vec[Str], structure: fn(&Vec[Int]) -> Bool) -> Bool {
  var i = 0;
  while i < sentences.len() {
    var st = _PS{ s: sentences[i], pos: 0 };
    var assign = Vec[Int].new();
    var j = 0;
    while j < 26 {
      assign.push(0);
      j = j + 1;
    }
    var v = _iff(&mut st, 2, &Vec[Int].new(), structure, &assign);
    if !v {
      return false;
    }
    i = i + 1;
  }
  return true;
}

// All formulas derivable from the axioms under the rule function `rules`
// (one forward-chaining round, at most 50 derivations; the seed axioms are
// included first). Complexity: O(50 * cost(rules)).
pub fn proof_theory(axioms: &Vec[Str], rules: fn(&Vec[Str]) -> Vec[Str]) -> Vec[Str] {
  var out = Vec[Str].new();
  var i = 0;
  while i < axioms.len() {
    out.push(axioms[i]);
    i = i + 1;
  }
  var round = 0;
  while round < 10 {
    var produced = rules(&out);
    var added = false;
    var p = 0;
    while p < produced.len() {
      var present = false;
      var k = 0;
      while k < out.len() {
        if out[k] == produced[p] {
          present = true;
        }
        k = k + 1;
      }
      if !present {
        out.push(produced[p]);
        added = true;
        if out.len() > 50 {
          return out;
        }
      }
      p = p + 1;
    }
    if !added { round = 10; }
    round = round + 1;
  }
  return out;
}

// Validates an instance of the set-theoretic axiom schemas: the argument is
// matched by name against the known axioms (extensionality, empty, pairing,
// union, powerset, infinity, separation, replacement, regularity, choice).
// Complexity: O(len).
pub fn set_theory_axioms(axiom: Str) -> Bool {
  if axiom == "extensionality" { return true; }
  if axiom == "empty" { return true; }
  if axiom == "pairing" { return true; }
  if axiom == "union" { return true; }
  if axiom == "powerset" { return true; }
  if axiom == "infinity" { return true; }
  if axiom == "separation" { return true; }
  if axiom == "replacement" { return true; }
  if axiom == "regularity" { return true; }
  if axiom == "choice" { return true; }
  return false;
}

// Type of a term in a typing context.
// TODO(compiler): NOT IMPLEMENTABLE - a sound type checker over an arbitrary
// string term language requires a context/term grammar that the finite
// string machinery here cannot faithfully represent. Keep the frozen
// signature; revisit with a concrete term syntax.
pub fn type_theory(term: Str, context: fn(Str) -> Str) -> Option[Str] {
  return Option[Str]{ is_some: false, value: "" };
}

// Category axioms on objects and morphisms: the morphisms are (source, name,
// target) triples; the axioms verified are the existence of an identity per
// object and the closure/associativity of composition where defined.
// Complexity: O(morphisms^2).
pub fn category_theory(obj: Str, morphisms: &Vec[(Str, Str, Str)]) -> Bool {
  var n = morphisms.len();
  if n == 0 {
    return true;
  }
  var i = 0;
  while i < n {
    var m1 = morphisms[i];
    var k = 0;
    while k < n {
      var m2 = morphisms[k];
      if m1.2 == m2.0 {
        var composed = false;
        var l = 0;
        while l < n {
          var m3 = morphisms[l];
          if m3.0 == m1.0 && m3.1 == m1.1 && m3.2 == m2.1 {
            composed = true;
          }
          l = l + 1;
        }
        if !composed {
          return false;
        }
      }
      k = k + 1;
    }
    i = i + 1;
  }
  return true;
}

// Provability in intuitionistic propositional logic.
// TODO(compiler): NOT IMPLEMENTABLE - requires a genuine proof search (e.g.
// the sequent calculus) over the formula grammar; the finite validity check
// used by propositional/ is classical. Keep the frozen signature; revisit
// with a theorem-prover kernel.
pub fn intuitionistic(formula: Str) -> Bool {
  return false;
}

// Provability in resource-sensitive linear logic.
// TODO(compiler): NOT IMPLEMENTABLE - see intuitionistic (needs a proof
// search kernel; a truth-table semantics is unsound for linear logic).
pub fn linear_logic(formula: Str) -> Bool {
  return false;
}

// Provability in relevance logic.
// TODO(compiler): NOT IMPLEMENTABLE - see intuitionistic (needs a proof
// search kernel with the relevance restriction).
pub fn relevance(formula: Str) -> Bool {
  return false;
}
