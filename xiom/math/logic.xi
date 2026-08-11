// XIOM - Math: Logic
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.logic

// Depends on: none

// ============================================================================
// Boolean and symbolic logic utilities: truth tables, normal forms, and
// quantifier reasoning over finite domains. TODO(compiler): implement.
// ============================================================================

// fn truth_table(expr: fn(Vec[Bool]) -> Bool, vars: Int) -> Vec[(Vec[Bool], Bool)] - enumeration of all assignments with their outcome.
// fn boolean_expression(op: Str, a: Bool, b: Bool) -> Bool - evaluate a named Boolean operator (and, or, xor, nand, nor, ...).
// fn simplify(expr: Str) -> Str - algebraic simplification of a Boolean expression string.
// fn normal_forms(expr: Str) -> (Str, Str) - conjunctive and disjunctive normal forms of expr.
// fn iff(a: Bool, b: Bool) -> Bool - logical biconditional, true when a equals b.
// fn implies(a: Bool, b: Bool) -> Bool - logical implication, false only when a is true and b is false.
// fn xor(a: Bool, b: Bool) -> Bool - exclusive or, true when a differs from b.
// fn nand(a: Bool, b: Bool) -> Bool - not and of a and b.
// fn nor(a: Bool, b: Bool) -> Bool - not or of a and b.
// fn quantifiers(pred: fn(Int) -> Bool, domain: &Vec[Int]) -> (Bool, Bool) - universal and existential quantification over domain.
// fn satisfiability(expr: Str) -> Bool - true iff some assignment makes expr true.
// fn tautology_check(expr: Str) -> Bool - true iff every assignment makes expr true.
