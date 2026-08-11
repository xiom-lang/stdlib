// XIOM - Math: Mathematical Logic
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.mathematical_logic

// Depends on: none

// ============================================================================
// Formal systems and metalogic: propositional through modal and categorical
// calculi, plus model and proof theory over finite domains.
// TODO(compiler): implement.
// ============================================================================

// fn propositional(expr: Str) -> Bool - validity of a propositional formula.
// fn predicate(expr: Str, domain: &Vec[Int]) -> Bool - truth of a first-order formula over a finite domain.
// fn first_order(formula: Str, structure: fn(&Vec[Int]) -> Bool) -> Bool - satisfiability of a formula in a given structure.
// fn modal(formula: Str, world: Int, relations: &Vec[(Int, Int)]) -> Bool - truth of a modal formula at a world.
// fn temporal(formula: Str, state: Int, next: fn(Int) -> Int) -> Bool - temporal-logic truth evaluation along a run.
// fn fuzzy_logic(formula: Str, values: &Vec[Float64]) -> Float64 - truth value in [0, 1] under fuzzy semantics.
// fn intuitionistic(formula: Str) -> Bool - provability in intuitionistic propositional logic.
// fn linear_logic(formula: Str) -> Bool - provability in resource-sensitive linear logic.
// fn relevance(formula: Str) -> Bool - provability in relevance logic.
// fn provability(axioms: &Vec[Str], theorem: Str) -> Bool - theorem follows from axioms via the inference rules.
// fn model_theory(sentences: &Vec[Str], structure: fn(&Vec[Int]) -> Bool) -> Bool - structure is a model of every sentence.
// fn proof_theory(axioms: &Vec[Str], rules: fn(&Vec[Str]) -> Vec[Str]) -> Vec[Str] - all formulas derivable from axioms.
// fn set_theory_axioms(axiom: Str) -> Bool - validates an instance of the set-theoretic axiom schemas.
// fn type_theory(term: Str, context: fn(Str) -> Str) -> Option[Str] - type of a term in a typing context.
// fn category_theory(obj: Str, morphisms: &Vec[(Str, Str, Str)]) -> Bool - category axioms on objects and morphisms.
