// XIOM - Math: Logic
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.logic

// Depends on: none

// ============================================================================
// Boolean and symbolic logic utilities: truth tables, normal forms, and
// quantifier reasoning over finite domains. TODO(compiler): implement.
// ============================================================================

// The boolean connectives and the named-operator evaluator are implemented.
// The string-parser family (truth_table, simplify, normal_forms,
// satisfiability, tautology_check, quantifiers) is NOT IMPLEMENTABLE in this
// compiler build: every implementation attempt crashes at runtime with
// 0xC0000005 (access violation) or fails to compile. Isolated probes proved
// the pattern `parse expr into (Int, Int) tuple states, evaluate recursively,
// then return a Bool / Str / conditionally-returned value` miscompiles: only
// a bare Int return of the recursive evaluator survives. Each function below
// therefore keeps its frozen signature with a TODO(compiler) note.

// ---------------------------------------------------------------------------
// Boolean operators and connectives
// ---------------------------------------------------------------------------

// Evaluate a named Boolean operator over the inputs a and b. Supported names
// (case-sensitive): "and", "or", "xor", "nand", "nor", "xnor", "implies",
// "iff". Any other name returns false (documented). Complexity: O(1).
pub fn boolean_expression(op: Str, a: Bool, b: Bool) -> Bool {
  if op == "and" { return a && b; }
  if op == "or" { return a || b; }
  if op == "xor" { return a != b; }
  if op == "nand" { return !(a && b); }
  if op == "nor" { return !(a || b); }
  if op == "xnor" { return a == b; }
  if op == "implies" {
    if a && !(b) { return false; }
    return true;
  }
  if op == "iff" { return a == b; }
  return false;
}

// Logical biconditional: true when a equals b. Complexity: O(1).
pub fn iff(a: Bool, b: Bool) -> Bool {
  return a == b;
}

// Logical implication: false only when a is true and b is false.
// Complexity: O(1).
pub fn implies(a: Bool, b: Bool) -> Bool {
  if a && !(b) { return false; }
  return true;
}

// Exclusive or: true when a differs from b. Complexity: O(1).
pub fn xor(a: Bool, b: Bool) -> Bool {
  return a != b;
}

// Not-and of a and b. Complexity: O(1).
pub fn nand(a: Bool, b: Bool) -> Bool {
  return !(a && b);
}

// Not-or of a and b. Complexity: O(1).
pub fn nor(a: Bool, b: Bool) -> Bool {
  return !(a || b);
}

// ---------------------------------------------------------------------------
// Truth tables and normal forms
// ---------------------------------------------------------------------------

// Enumerate all 2^vars Boolean assignments, evaluating expr on each, as a
// list of (assignment, outcome) pairs (bit i of the mask supplies the i-th
// input, least-significant bit first). Returns an empty list for vars < 0 and
// for vars > 20 (documented guard; 2^21 assignments is impractical).
// Complexity: O(2^vars * expr).
// TODO(compiler): NOT IMPLEMENTABLE in this compiler build - the return type
// Vec[(Vec[Bool], Bool)] requires a tuple containing a Vec, whose LLVM type is
// opaque ("Cannot allocate unsized type %struct.Tuple__Vec__Int"); tuples of
// Bool also mis-register as Tuple__Int__Int in catalog modules (BUG 1 family,
// see docs/COMPILER_BUGS.md). Keep the frozen signature; revisit when tuple
// elements other than i64/structs are supported.
// pub fn truth_table(expr: fn(Vec[Bool]) -> Bool, vars: Int) -> Vec[(Vec[Bool], Bool)]

// Algebraic simplification of a Boolean expression string: returns the
// canonical disjunctive normal form (sum of products) of expr, or "0"/"1"
// for the constant contradiction/tautology. Returns expr unchanged when it
// has more than 20 distinct variables (documented guard). Complexity:
// O(2^n * expr) with n the variable count.
// TODO(compiler): NOT IMPLEMENTABLE in this compiler build - a recursive
// evaluator over a tokenized expression returns garbage / crashes
// (0xC0000005) whenever the public wrapper returns Bool or Str or uses a
// conditional return; only a bare Int return of the recursive evaluator is
// codegen-correct (isolated probe dbg_sat15). Keep the frozen signature;
// revisit when the recursive-call return value is not miscompiled.
// pub fn simplify(expr: Str) -> Str

// The conjunctive and disjunctive normal forms of expr as a (cnf, dnf) pair,
// each a parenthesized chain over the falsifying / satisfying assignments.
// Returns ("", "") when expr has more than 20 distinct variables (documented
// guard). Complexity: O(2^n * expr).
// TODO(compiler): NOT IMPLEMENTABLE in this compiler build - same recursive
// evaluator crash as simplify (0xC0000005); a (Str, Str) return makes the
// codegen failure deterministic. Keep the frozen signature; revisit when the
// recursive evaluator's results can be consumed by non-Int returns.
// pub fn normal_forms(expr: Str) -> (Str, Str)

// ---------------------------------------------------------------------------
// Quantification and satisfiability
// ---------------------------------------------------------------------------

// Universal and existential quantification of pred over the finite domain:
// returns (forall, exists). The universal quantifier is vacuously true and
// the existential false over an empty domain. Complexity: O(|domain|).
// TODO(compiler): NOT IMPLEMENTABLE in this compiler build - the frozen
// signature `fn quantifiers(pred: fn(Int) -> Bool, domain: &Vec[Int]) ->
// (Bool, Bool)` requires a Bool tuple element, which the codegen lowers
// inconsistently ("ret %struct.Tuple__Bool__Bool %tmp8" where %tmp8 is
// Tuple__Int__Int - the tuple literal is keyed on the runtime Int lowering of
// Bool while the signature key is Bool). Every (Bool, ...) tuple return in
// the stdlib is an unimplemented stub for this reason (see docs/
// COMPILER_BUGS.md, BUG 1 family). Keep the frozen signature for the future
// compiler that lowers Bool tuple elements consistently.

// True iff some assignment of the variables makes expr true. Returns false
// for expressions with more than 20 distinct variables (documented guard).
// Complexity: O(2^n * expr).
// TODO(compiler): NOT IMPLEMENTABLE in this compiler build - same recursive
// evaluator crash as simplify: a Bool return around the tokenizer/recursive
// parser crashes with 0xC0000005 (probes dbg_sat16/17/19/20 all trap; the
// Int-returning dbg_sat15 is the only survivor). Keep the frozen signature;
// revisit when Bool-returning wrappers around the recursive parser work.
// pub fn satisfiability(expr: Str) -> Bool

// True iff every assignment of the variables makes expr true. Returns false
// for expressions with more than 20 distinct variables (documented guard).
// Complexity: O(2^n * expr).
// TODO(compiler): NOT IMPLEMENTABLE in this compiler build - same recursive
// evaluator crash as satisfiability (0xC0000005). Keep the frozen signature;
// revisit when Bool-returning wrappers around the recursive parser work.
// pub fn tautology_check(expr: Str) -> Bool
