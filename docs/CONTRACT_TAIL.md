<!--
Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
SPDX-License-Identifier: MIT OR Apache-2.0
-->
# Contract Tail Inventory (roadmap B2)

Generated: 2026-11-07 by `tools/contract_tail_inventory.ps1`.
Authoritative counts: `tools/coverage_scan.ps1`. Policy: `docs/CONTRACT_POLICY.md`.

**276 uncovered public functions across 7 modules: 0 EX-0 and 276 per-function exemptions.** Each row becomes a clause or an EX-1..EX-5 exemption in B2; EX-0 is closed to new entries.

| Module | Uncovered | EX-0 | Per-function |
|---|---:|---:|---:|
| ffi | 4 | 0 | 4 |
| format | 2 | 0 | 2 |
| iter | 54 | 0 | 54 |
| math | 94 | 0 | 94 |
| os | 111 | 0 | 111 |
| serialize | 6 | 0 | 6 |
| thread | 5 | 0 | 5 |

## Functions

| Module | File | Line | Function | Category | Signature |
|---|---|---:|---|---|---|
| ffi | ffi/dl.xi | 105 | `dl_open_global` | `EX-2` | `pub fn dl_open_global(path: Str) -> Result[Int, Str] {` |
| ffi | ffi/dl.xi | 111 | `dl_sym_address` | `EX-2` | `pub fn dl_sym_address(handle: Int, name: Str) -> Result[Int, Str] {` |
| ffi | ffi/errno.xi | 80 | `errno_perror` | `EX-1` | `pub fn errno_perror(msg: Str) {` |
| ffi | ffi/ffi.xi | 88 | `safe_ptr_free` | `EX-1` | `pub fn safe_ptr_free(ptr: SafePtr) {` |
| format | format/fmt.xi | 143 | `print` | `EX-1` | `pub fn print(s: Str) {` |
| format | format/fmt.xi | 148 | `println` | `EX-1` | `pub fn println(s: Str) {` |
| iter | iter/fold.xi | 269 | `iter_for_each` | `EX-3` | `pub fn iter_for_each(v: &Vec[Int], f: fn(&Int)) {` |
| iter | iter/iter.xi | 294 | `Range.map` | `EX-3` | `pub fn Range.map[U](self, f: fn(Int) -> U) -> MapIter[Int, U] {` |
| iter | iter/iter.xi | 300 | `Range.filter` | `EX-3` | `pub fn Range.filter(self, predicate: fn(&Int) -> Bool) -> FilterIter[Int] {` |
| iter | iter/iter.xi | 330 | `Range.chain` | `EX-3` | `pub fn Range.chain(self, other: Range) -> ChainIter[Int, Int] {` |
| iter | iter/iter.xi | 342 | `Range.zip` | `EX-3` | `pub fn Range.zip(self, other: Range) -> ZipIter[Int, Int] {` |
| iter | iter/iter.xi | 451 | `MapIter.next` | `EX-3` | `pub fn MapIter[T, U].next(self) -> Option[U] {` |
| iter | iter/iter.xi | 459 | `FilterIter.next` | `EX-3` | `pub fn FilterIter[T].next(self) -> Option[T] {` |
| iter | iter/iter.xi | 514 | `ChainIter.next` | `EX-3` | `pub fn ChainIter[T, U].next(self) -> Option[T] {` |
| iter | iter/iter.xi | 522 | `ZipIter.next` | `EX-3` | `pub fn ZipIter[T, U].next(self) -> Option[(T, U)] {` |
| iter | iter/iter.xi | 536 | `MapIter.map` | `EX-3` | `pub fn MapIter[T, U].map[V](self, f: fn(U) -> V) -> MapIter[U, V] {` |
| iter | iter/iter.xi | 542 | `MapIter.filter` | `EX-3` | `pub fn MapIter[T, U].filter(self, predicate: fn(&U) -> Bool) -> FilterIter[U] {` |
| iter | iter/iter.xi | 572 | `MapIter.chain` | `EX-3` | `pub fn MapIter[T, U].chain(self, other: Range) -> ChainIter[U, Int] {` |
| iter | iter/iter.xi | 580 | `MapIter.zip` | `EX-3` | `pub fn MapIter[T, U].zip(self, other: Range) -> ZipIter[U, Int] {` |
| iter | iter/iter.xi | 587 | `MapIter.collect` | `EX-3` | `pub fn MapIter[T, U].collect(self) -> Vec[U] {` |
| iter | iter/iter.xi | 593 | `MapIter.fold` | `EX-3` | `pub fn MapIter[T, U].fold[B](self, init: B, f: fn(B, U) -> B) -> B {` |
| iter | iter/iter.xi | 607 | `MapIter.sum` | `EX-3` | `pub fn MapIter[T, U].sum(self) -> U {` |
| iter | iter/iter.xi | 613 | `MapIter.product` | `EX-3` | `pub fn MapIter[T, U].product(self) -> U {` |
| iter | iter/iter.xi | 619 | `MapIter.max` | `EX-3` | `pub fn MapIter[T, U].max(self) -> Option[U] {` |
| iter | iter/iter.xi | 625 | `MapIter.min` | `EX-3` | `pub fn MapIter[T, U].min(self) -> Option[U] {` |
| iter | iter/iter.xi | 631 | `MapIter.find` | `EX-3` | `pub fn MapIter[T, U].find(self, predicate: fn(&U) -> Bool) -> Option[U] {` |
| iter | iter/iter.xi | 637 | `MapIter.all` | `EX-3` | `pub fn MapIter[T, U].all(self, predicate: fn(&U) -> Bool) -> Bool {` |
| iter | iter/iter.xi | 643 | `MapIter.any` | `EX-3` | `pub fn MapIter[T, U].any(self, predicate: fn(&U) -> Bool) -> Bool {` |
| iter | iter/iter.xi | 649 | `MapIter.nth` | `EX-3` | `pub fn MapIter[T, U].nth(self, n: Int) -> Option[U] {` |
| iter | iter/iter.xi | 655 | `MapIter.last` | `EX-3` | `pub fn MapIter[T, U].last(self) -> Option[U] {` |
| iter | iter/iter.xi | 661 | `FilterIter.map` | `EX-3` | `pub fn FilterIter[T].map[U](self, f: fn(T) -> U) -> MapIter[T, U] {` |
| iter | iter/iter.xi | 667 | `FilterIter.filter` | `EX-3` | `pub fn FilterIter[T].filter(self, predicate: fn(&T) -> Bool) -> FilterIter[T] {` |
| iter | iter/iter.xi | 697 | `FilterIter.chain` | `EX-3` | `pub fn FilterIter[T].chain(self, other: Range) -> ChainIter[T, Int] {` |
| iter | iter/iter.xi | 705 | `FilterIter.zip` | `EX-3` | `pub fn FilterIter[T].zip(self, other: Range) -> ZipIter[T, Int] {` |
| iter | iter/iter.xi | 712 | `FilterIter.collect` | `EX-3` | `pub fn FilterIter[T].collect(self) -> Vec[T] {` |
| iter | iter/iter.xi | 718 | `FilterIter.fold` | `EX-3` | `pub fn FilterIter[T].fold[B](self, init: B, f: fn(B, T) -> B) -> B {` |
| iter | iter/iter.xi | 732 | `FilterIter.sum` | `EX-3` | `pub fn FilterIter[T].sum(self) -> T {` |
| iter | iter/iter.xi | 738 | `FilterIter.product` | `EX-3` | `pub fn FilterIter[T].product(self) -> T {` |
| iter | iter/iter.xi | 744 | `FilterIter.max` | `EX-3` | `pub fn FilterIter[T].max(self) -> Option[T] {` |
| iter | iter/iter.xi | 750 | `FilterIter.min` | `EX-3` | `pub fn FilterIter[T].min(self) -> Option[T] {` |
| iter | iter/iter.xi | 756 | `FilterIter.find` | `EX-3` | `pub fn FilterIter[T].find(self, predicate: fn(&T) -> Bool) -> Option[T] {` |
| iter | iter/iter.xi | 762 | `FilterIter.all` | `EX-3` | `pub fn FilterIter[T].all(self, predicate: fn(&T) -> Bool) -> Bool {` |
| iter | iter/iter.xi | 768 | `FilterIter.any` | `EX-3` | `pub fn FilterIter[T].any(self, predicate: fn(&T) -> Bool) -> Bool {` |
| iter | iter/iter.xi | 774 | `FilterIter.nth` | `EX-3` | `pub fn FilterIter[T].nth(self, n: Int) -> Option[T] {` |
| iter | iter/iter.xi | 780 | `FilterIter.last` | `EX-3` | `pub fn FilterIter[T].last(self) -> Option[T] {` |
| iter | iter/iter.xi | 1066 | `ChainIter.collect` | `EX-3` | `pub fn ChainIter[T, U].collect(self) -> Vec[T] {` |
| iter | iter/iter.xi | 1092 | `ChainIter.map` | `EX-3` | `pub fn ChainIter[T, U].map[V](self, f: fn(T) -> V) -> MapIter[T, V] {` |
| iter | iter/iter.xi | 1106 | `ChainIter.find` | `EX-3` | `pub fn ChainIter[T, U].find(self, predicate: fn(&T) -> Bool) -> Option[T] {` |
| iter | iter/iter.xi | 1112 | `ChainIter.all` | `EX-3` | `pub fn ChainIter[T, U].all(self, predicate: fn(&T) -> Bool) -> Bool {` |
| iter | iter/iter.xi | 1118 | `ChainIter.any` | `EX-3` | `pub fn ChainIter[T, U].any(self, predicate: fn(&T) -> Bool) -> Bool {` |
| iter | iter/iter.xi | 1124 | `ChainIter.nth` | `EX-3` | `pub fn ChainIter[T, U].nth(self, n: Int) -> Option[T] {` |
| iter | iter/iter.xi | 1130 | `ChainIter.last` | `EX-3` | `pub fn ChainIter[T, U].last(self) -> Option[T] {` |
| iter | iter/iter.xi | 1136 | `ZipIter.collect` | `EX-3` | `pub fn ZipIter[T, U].collect(self) -> Vec[(T, U)] {` |
| iter | iter/iter.xi | 1162 | `ZipIter.find` | `EX-3` | `pub fn ZipIter[T, U].find(self, predicate: fn(&(T, U)) -> Bool) -> Option[(T, U)] {` |
| iter | iter/iter.xi | 1168 | `ZipIter.all` | `EX-3` | `pub fn ZipIter[T, U].all(self, predicate: fn(&(T, U)) -> Bool) -> Bool {` |
| iter | iter/iter.xi | 1174 | `ZipIter.any` | `EX-3` | `pub fn ZipIter[T, U].any(self, predicate: fn(&(T, U)) -> Bool) -> Bool {` |
| iter | iter/iter.xi | 1180 | `ZipIter.nth` | `EX-3` | `pub fn ZipIter[T, U].nth(self, n: Int) -> Option[(T, U)] {` |
| iter | iter/iter.xi | 1186 | `ZipIter.last` | `EX-3` | `pub fn ZipIter[T, U].last(self) -> Option[(T, U)] {` |
| iter | iter/iter.xi | 1298 | `Range.inspect` | `EX-3` | `pub fn Range.inspect(self, f: fn(&Int)) -> InspectIter[Int] {` |
| iter | iter/iter.xi | 1304 | `InspectIter.next` | `EX-3` | `pub fn InspectIter[T].next(self) -> Option[T] {` |
| math | math/algebra_extended.xi | 281 | `algebraic_number` | `EX-1` | `pub fn algebraic_number(alpha: Float64, polynomial: &Vec[Float64]) -> Bool {` |
| math | math/calculus.xi | 117 | `limit` | `EX-1` | `pub fn limit(f: fn(Float64) -> Float64, x: Float64) -> Float64 {` |
| math | math/calculus.xi | 125 | `limit_left` | `EX-1` | `pub fn limit_left(f: fn(Float64) -> Float64, x: Float64) -> Float64 {` |
| math | math/calculus.xi | 133 | `limit_right` | `EX-1` | `pub fn limit_right(f: fn(Float64) -> Float64, x: Float64) -> Float64 {` |
| math | math/calculus.xi | 142 | `is_continuous` | `EX-1` | `pub fn is_continuous(f: fn(Float64) -> Float64, x: Float64, tol: Float64) -> Bool {` |
| math | math/calculus.xi | 158 | `gradient` | `EX-1` | `pub fn gradient(f: fn(&Vec[Float64]) -> Float64, x: &Vec[Float64]) -> Vec[Float64] {` |
| math | math/calculus.xi | 167 | `partial_derivative` | `EX-1` | `pub fn partial_derivative(f: fn(&Vec[Float64]) -> Float64, x: &Vec[Float64], i: Int, h: Float64) -> Float64 {` |
| math | math/calculus.xi | 175 | `jacobian` | `EX-1` | `pub fn jacobian(fs: &Vec[fn(&Vec[Float64]) -> Float64], x: &Vec[Float64]) -> Vec[Vec[Float64]] {` |
| math | math/calculus.xi | 184 | `hessian` | `EX-1` | `pub fn hessian(f: fn(&Vec[Float64]) -> Float64, x: &Vec[Float64]) -> Vec[Vec[Float64]] {` |
| math | math/calculus.xi | 193 | `laplacian` | `EX-1` | `pub fn laplacian(f: fn(&Vec[Float64]) -> Float64, x: &Vec[Float64]) -> Float64 {` |
| math | math/calculus.xi | 202 | `curl` | `EX-1` | `pub fn curl(f: fn(&Vec[Float64]) -> Vec[Float64], x: &Vec[Float64]) -> Vec[Float64] {` |
| math | math/calculus.xi | 211 | `divergence` | `EX-1` | `pub fn divergence(f: fn(&Vec[Float64]) -> Vec[Float64], x: &Vec[Float64]) -> Float64 {` |
| math | math/control_theory.xi | 65 | `state_space` | `EX-1` | `pub fn state_space(a: &Vec[Vec[Float64]], b: &Vec[Vec[Float64]], c: &Vec[Vec[Float64]], d: &Vec[Vec[Float64]]) -> (Vec[Vec[Float64]], Vec[Vec[Float64]], Vec[Vec...` |
| math | math/control_theory.xi | 480 | `pole_placement` | `EX-1` | `pub fn pole_placement(a: &Vec[Vec[Float64]], b: &Vec[Vec[Float64]], poles: &Vec[Float64]) -> Vec[Vec[Float64]] {` |
| math | math/control_theory.xi | 488 | `lqr` | `EX-1` | `pub fn lqr(a: &Vec[Vec[Float64]], b: &Vec[Vec[Float64]], q: &Vec[Vec[Float64]], r: &Vec[Vec[Float64]]) -> (Vec[Vec[Float64]], Vec[Vec[Float64]]) {` |
| math | math/control_theory.xi | 497 | `lqg` | `EX-1` | `pub fn lqg(a: &Vec[Vec[Float64]], b: &Vec[Vec[Float64]], c: &Vec[Vec[Float64]], q: &Vec[Vec[Float64]], r: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {` |
| math | math/control_theory.xi | 522 | `h_infinity` | `EX-1` | `pub fn h_infinity(p: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {` |
| math | math/control_theory.xi | 530 | `robust_control` | `EX-1` | `pub fn robust_control(nominal: fn(Float64) -> Float64, uncertainty: Float64) -> Bool {` |
| math | math/differential.xi | 134 | `jacobian` | `EX-1` | `pub fn jacobian(fs: &Vec[fn(&Vec[Float64]) -> Float64], x: &Vec[Float64]) -> Vec[Vec[Float64]] {` |
| math | math/fuzzy.xi | 137 | `fuzzy_relation` | `EX-1` | `pub fn fuzzy_relation(r: &Vec[Vec[Float64]]) -> Bool {` |
| math | math/fuzzy.xi | 146 | `fuzzy_composition` | `EX-1` | `pub fn fuzzy_composition(r: &Vec[Vec[Float64]], s: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {` |
| math | math/game_theory.xi | 28 | `nash_equilibrium` | `EX-1` | `pub fn nash_equilibrium(payoffs: &Vec[Vec[Float64]]) -> Vec[(Float64, Float64)] {` |
| math | math/game_theory.xi | 36 | `minimax` | `EX-1` | `pub fn minimax(payoffs: &Vec[Vec[Float64]]) -> Float64 {` |
| math | math/game_theory.xi | 85 | `dominant_strategy` | `EX-1` | `pub fn dominant_strategy(payoffs: &Vec[Vec[Float64]]) -> Option[Int] {` |
| math | math/game_theory.xi | 92 | `pareto_optimal` | `EX-1` | `pub fn pareto_optimal(payoffs: &Vec[Vec[Float64]]) -> Vec[Int] {` |
| math | math/game_theory.xi | 291 | `evolutionary_game` | `EX-1` | `pub fn evolutionary_game(payoffs: &Vec[Vec[Float64]], population: &Vec[Float64]) -> Vec[Float64] {` |
| math | math/game_theory.xi | 299 | `replicator_dynamics` | `EX-1` | `pub fn replicator_dynamics(payoffs: &Vec[Vec[Float64]], population: &Vec[Float64], steps: Int) -> Vec[Vec[Float64]] {` |
| math | math/information_theory.xi | 56 | `joint_entropy` | `EX-1` | `pub fn joint_entropy(p_joint: &Vec[Vec[Float64]]) -> Float64 {` |
| math | math/information_theory.xi | 63 | `conditional_entropy` | `EX-1` | `pub fn conditional_entropy(p_joint: &Vec[Vec[Float64]]) -> Float64 {` |
| math | math/information_theory.xi | 70 | `mutual_information` | `EX-1` | `pub fn mutual_information(p_joint: &Vec[Vec[Float64]]) -> Float64 {` |
| math | math/information_theory.xi | 153 | `entropy_rate` | `EX-1` | `pub fn entropy_rate(p_transition: &Vec[Vec[Float64]], stationary: &Vec[Float64]) -> Float64 {` |
| math | math/information_theory.xi | 163 | `channel_capacity` | `EX-1` | `pub fn channel_capacity(p_transition: &Vec[Vec[Float64]]) -> Float64 {` |
| math | math/logic.xi | 31 | `boolean_expression` | `EX-1` | `pub fn boolean_expression(op: Str, a: Bool, b: Bool) -> Bool {` |
| math | math/machine_learning.xi | 387 | `normalization_batch` | `EX-1` | `pub fn normalization_batch(x: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {` |
| math | math/math.xi | 511 | `seed_rng` | `EX-1` | `pub fn seed_rng(seed: Int) {` |
| math | math/mathematical_biology.xi | 132 | `ecology` | `EX-1` | `pub fn ecology(species: &Vec[Float64], interaction: &Vec[Vec[Float64]], dt: Float64) -> Vec[Float64] {` |
| math | math/mathematical_economics.xi | 255 | `general_equilibrium` | `EX-1` | `pub fn general_equilibrium(endowments: &Vec[Vec[Float64]], utilities: &Vec[fn(&Vec[Float64]) -> Float64]) -> Vec[Float64] {` |
| math | math/mathematical_logic.xi | 195 | `propositional` | `EX-1` | `pub fn propositional(expr: Str) -> Bool {` |
| math | math/mathematical_logic.xi | 250 | `predicate` | `EX-1` | `pub fn predicate(expr: Str, domain: &Vec[Int]) -> Bool {` |
| math | math/mathematical_logic.xi | 263 | `first_order` | `EX-1` | `pub fn first_order(formula: Str, structure: fn(&Vec[Int]) -> Bool) -> Bool {` |
| math | math/mathematical_logic.xi | 278 | `modal` | `EX-1` | `pub fn modal(formula: Str, world: Int, relations: &Vec[(Int, Int)]) -> Bool {` |
| math | math/mathematical_logic.xi | 421 | `temporal` | `EX-1` | `pub fn temporal(formula: Str, state: Int, next: fn(Int) -> Int) -> Bool {` |
| math | math/mathematical_logic.xi | 527 | `fuzzy_logic` | `EX-1` | `pub fn fuzzy_logic(formula: Str, values: &Vec[Float64]) -> Float64 {` |
| math | math/mathematical_logic.xi | 725 | `set_theory_axioms` | `EX-1` | `pub fn set_theory_axioms(axiom: Str) -> Bool {` |
| math | math/mathematical_logic.xi | 744 | `type_theory` | `EX-1` | `pub fn type_theory(term: Str, context: fn(Str) -> Str) -> Option[Str] {` |
| math | math/mathematical_logic.xi | 791 | `intuitionistic` | `EX-1` | `pub fn intuitionistic(formula: Str) -> Bool {` |
| math | math/mathematical_logic.xi | 798 | `linear_logic` | `EX-1` | `pub fn linear_logic(formula: Str) -> Bool {` |
| math | math/mathematical_logic.xi | 805 | `relevance` | `EX-1` | `pub fn relevance(formula: Str) -> Bool {` |
| math | math/mathematical_physics.xi | 23 | `hamiltonian` | `EX-1` | `pub fn hamiltonian(q: &Vec[Float64], p: &Vec[Float64], h: fn(&Vec[Float64], &Vec[Float64]) -> Float64) -> Float64 {` |
| math | math/mathematical_physics.xi | 28 | `lagrangian` | `EX-1` | `pub fn lagrangian(q: &Vec[Float64], qdot: &Vec[Float64], l: fn(&Vec[Float64], &Vec[Float64]) -> Float64) -> Float64 {` |
| math | math/mathematical_physics.xi | 37 | `quantum_operators` | `EX-1` | `pub fn quantum_operators(observable: &Vec[Vec[Float64]], state: &Vec[Float64]) -> Vec[Float64] {` |
| math | math/mathematical_physics.xi | 129 | `tensor_calculus` | `EX-1` | `pub fn tensor_calculus(tensor: &Vec[Float64], metric: &Vec[Vec[Float64]]) -> Vec[Float64] {` |
| math | math/mathematical_physics.xi | 171 | `riemannian` | `EX-1` | `pub fn riemannian(g: &Vec[Vec[Float64]], point: &Vec[Float64]) -> Float64 {` |
| math | math/mathematical_physics.xi | 178 | `symplectic` | `EX-1` | `pub fn symplectic(w: &Vec[Vec[Float64]], x: &Vec[Float64], y: &Vec[Float64]) -> Float64 {` |
| math | math/mathematical_physics.xi | 185 | `lie_algebra` | `EX-1` | `pub fn lie_algebra(basis: &Vec[Vec[Vec[Float64]]], a: Int, b: Int) -> Vec[Vec[Float64]] {` |
| math | math/mathematical_physics.xi | 193 | `lie_group` | `EX-1` | `pub fn lie_group(algebra: &Vec[Vec[Vec[Float64]]], params: &Vec[Float64]) -> Vec[Vec[Float64]] {` |
| math | math/mathematical_physics.xi | 201 | `representation` | `EX-1` | `pub fn representation(group: &Vec[Vec[Float64]], algebra: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {` |
| math | math/mathematical_physics.xi | 287 | `path_integral` | `EX-1` | `pub fn path_integral(action: fn(&Vec[Float64]) -> Float64, paths: &Vec[Vec[Float64]]) -> Vec[Float64] {` |
| math | math/matrices.xi | 203 | `mat4_mul` | `EX-1` | `pub fn mat4_mul(a: Mat4, b: Mat4) -> Mat4 {` |
| math | math/matrices.xi | 226 | `mat4_det` | `EX-1` | `pub fn mat4_det(m: Mat4) -> Float64 {` |
| math | math/numerical.xi | 33 | `bisection` | `EX-1` | `pub fn bisection(f: fn(Float64) -> Float64, a: Float64, b: Float64, tol: Float64) -> Float64 {` |
| math | math/numerical.xi | 78 | `newton` | `EX-1` | `pub fn newton(f: fn(Float64) -> Float64, fprime: fn(Float64) -> Float64, x0: Float64, tol: Float64) -> Float64 {` |
| math | math/numerical.xi | 97 | `secant` | `EX-1` | `pub fn secant(f: fn(Float64) -> Float64, x0: Float64, x1: Float64, tol: Float64) -> Float64 {` |
| math | math/numerical.xi | 233 | `fixed_point` | `EX-1` | `pub fn fixed_point(g: fn(Float64) -> Float64, x0: Float64, tol: Float64) -> Float64 {` |
| math | math/numerical.xi | 250 | `steffensen` | `EX-1` | `pub fn steffensen(f: fn(Float64) -> Float64, x0: Float64, tol: Float64) -> Float64 {` |
| math | math/numerical.xi | 1425 | `bisection_root` | `EX-1` | `pub fn bisection_root(f: fn(Float64) -> Float64, a: Float64, b: Float64, tol: Float64) -> Float64 {` |
| math | math/numerical.xi | 1431 | `newton_root` | `EX-1` | `pub fn newton_root(f: fn(Float64) -> Float64, fprime: fn(Float64) -> Float64, x0: Float64, tol: Float64) -> Float64 {` |
| math | math/operations_research.xi | 169 | `routing` | `EX-1` | `pub fn routing(distances: &Vec[Vec[Float64]], vehicles: Int) -> Vec[Vec[Int]] {` |
| math | math/operations_research.xi | 177 | `assignment` | `EX-1` | `pub fn assignment(cost: &Vec[Vec[Float64]]) -> Vec[Int] {` |
| math | math/operations_research.xi | 185 | `transportation` | `EX-1` | `pub fn transportation(supply: &Vec[Float64], demand: &Vec[Float64], cost: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {` |
| math | math/operations_research.xi | 193 | `transshipment` | `EX-1` | `pub fn transshipment(supply: &Vec[Float64], demand: &Vec[Float64], transship: &Vec[Float64], cost: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {` |
| math | math/operations_research.xi | 395 | `supply_chain` | `EX-1` | `pub fn supply_chain(demands: &Vec[Vec[Float64]], costs: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {` |
| math | math/optimization.xi | 200 | `integer_programming` | `EX-1` | `pub fn integer_programming(c: &Vec[Float64], a: &Vec[Vec[Float64]], b: &Vec[Float64]) -> Vec[Int] {` |
| math | math/optimization.xi | 208 | `mixed_integer_programming` | `EX-1` | `pub fn mixed_integer_programming(c: &Vec[Float64], a: &Vec[Vec[Float64]], b: &Vec[Float64], int_vars: &Vec[Bool]) -> Vec[Float64] {` |
| math | math/optimization.xi | 216 | `quadratic_programming` | `EX-1` | `pub fn quadratic_programming(q: &Vec[Vec[Float64]], c: &Vec[Float64], a: &Vec[Vec[Float64]], b: &Vec[Float64]) -> Vec[Float64] {` |
| math | math/optimization.xi | 224 | `nonlinear_programming` | `EX-1` | `pub fn nonlinear_programming(f: fn(&Vec[Float64]) -> Float64, cons: &Vec[fn(&Vec[Float64]) -> Float64], x0: &Vec[Float64]) -> Vec[Float64] {` |
| math | math/optimization.xi | 402 | `lp_interior_point` | `EX-1` | `pub fn lp_interior_point(c: &Vec[Float64], a: &Vec[Vec[Float64]], b: &Vec[Float64]) -> Vec[Float64] {` |
| math | math/optimization.xi | 410 | `branch_and_bound` | `EX-1` | `pub fn branch_and_bound(c: &Vec[Float64], a: &Vec[Vec[Float64]], b: &Vec[Float64]) -> Vec[Float64] {` |
| math | math/optimization.xi | 418 | `cutting_plane` | `EX-1` | `pub fn cutting_plane(c: &Vec[Float64], a: &Vec[Vec[Float64]], b: &Vec[Float64]) -> Vec[Float64] {` |
| math | math/optimization.xi | 426 | `sequential_quadratic` | `EX-1` | `pub fn sequential_quadratic(f: fn(&Vec[Float64]) -> Float64, cons: &Vec[fn(&Vec[Float64]) -> Float64], x0: &Vec[Float64]) -> Vec[Float64] {` |
| math | math/optimization.xi | 434 | `penalty_method` | `EX-1` | `pub fn penalty_method(f: fn(&Vec[Float64]) -> Float64, cons: &Vec[fn(&Vec[Float64]) -> Float64], x0: &Vec[Float64]) -> Vec[Float64] {` |
| math | math/optimization.xi | 442 | `barrier_method` | `EX-1` | `pub fn barrier_method(f: fn(&Vec[Float64]) -> Float64, cons: &Vec[fn(&Vec[Float64]) -> Float64], x0: &Vec[Float64]) -> Vec[Float64] {` |
| math | math/optimization.xi | 450 | `augmented_lagrangian` | `EX-1` | `pub fn augmented_lagrangian(f: fn(&Vec[Float64]) -> Float64, cons: &Vec[fn(&Vec[Float64]) -> Float64], x0: &Vec[Float64]) -> Vec[Float64] {` |
| math | math/optimization.xi | 458 | `genetic_algorithm` | `EX-1` | `pub fn genetic_algorithm(f: fn(&Vec[Float64]) -> Float64, bounds: &Vec[Vec[Float64]], pop_size: Int, generations: Int) -> Vec[Float64] {` |
| math | math/optimization.xi | 530 | `particle_swarm` | `EX-1` | `pub fn particle_swarm(f: fn(&Vec[Float64]) -> Float64, bounds: &Vec[Vec[Float64]], particles: Int, iters: Int) -> Vec[Float64] {` |
| math | math/optimization.xi | 615 | `differential_evolution` | `EX-1` | `pub fn differential_evolution(f: fn(&Vec[Float64]) -> Float64, bounds: &Vec[Vec[Float64]], pop_size: Int, iters: Int) -> Vec[Float64] {` |
| math | math/optimization.xi | 623 | `bayesian_optimization` | `EX-1` | `pub fn bayesian_optimization(f: fn(&Vec[Float64]) -> Float64, bounds: &Vec[Vec[Float64]], iters: Int) -> Vec[Float64] {` |
| math | math/optimization.xi | 631 | `grid_search` | `EX-1` | `pub fn grid_search(f: fn(&Vec[Float64]) -> Float64, bounds: &Vec[Vec[Float64]], n: Int) -> Vec[Float64] {` |
| math | math/optimization.xi | 639 | `random_search` | `EX-1` | `pub fn random_search(f: fn(&Vec[Float64]) -> Float64, bounds: &Vec[Vec[Float64]], iters: Int) -> Vec[Float64] {` |
| math | math/precision.xi | 123 | `max_value` | `EX-1` | `pub fn max_value[T: PrecisionLimits]() -> T {` |
| math | math/precision.xi | 128 | `epsilon` | `EX-1` | `pub fn epsilon[T: PrecisionLimits]() -> T {` |
| math | math/precision.xi | 168 | `is_signed` | `EX-1` | `pub fn is_signed[T: PrecisionLimits]() -> Bool {` |
| math | math/series.xi | 124 | `maclaurin_series` | `EX-1` | `pub fn maclaurin_series(f: fn(Float64) -> Float64, order: Int, x: Float64) -> Float64 {` |
| math | math/topology.xi | 43 | `closed_set` | `EX-1` | `pub fn closed_set(tau: &Vec[Vec[Int]], s: &Vec[Int], universe: &Vec[Int]) -> Bool {` |
| os | os/err.xi | 23 | `errno` | `EX-2` | `pub fn errno() -> Int {` |
| os | os/err.xi | 157 | `perror` | `EX-2` | `pub fn perror(msg: Str) -> Unit {` |
| os | os/err.xi | 173 | `errno_set` | `EX-2` | `pub fn errno_set(code: Int) -> Unit {` |
| os | os/err.xi | 181 | `backtrace` | `EX-2` | `pub fn backtrace() -> Vec[Str] {` |
| os | os/err.xi | 190 | `backtrace_symbols` | `EX-2` | `pub fn backtrace_symbols(frames: &Vec[Int]) -> Vec[Str] {` |
| os | os/err.xi | 208 | `last_error` | `EX-2` | `pub fn last_error() -> Str {` |
| os | os/event.xi | 46 | `epoll_create` | `EX-2` | `pub fn epoll_create() -> Result[Int, Str] {` |
| os | os/event.xi | 53 | `epoll_add` | `EX-2` | `pub fn epoll_add(ep: Int, fd: Int, events: Int) -> Result[Unit, Str] {` |
| os | os/event.xi | 63 | `epoll_mod` | `EX-2` | `pub fn epoll_mod(ep: Int, fd: Int, events: Int) -> Result[Unit, Str] {` |
| os | os/event.xi | 73 | `epoll_del` | `EX-2` | `pub fn epoll_del(ep: Int, fd: Int) -> Result[Unit, Str] {` |
| os | os/event.xi | 82 | `epoll_wait` | `EX-2` | `pub fn epoll_wait(ep: Int, max_events: Int, timeout_ms: Int) -> Result[Vec[EpollEvent], Str] {` |
| os | os/event.xi | 91 | `epoll_close` | `EX-2` | `pub fn epoll_close(ep: Int) -> Unit {` |
| os | os/event.xi | 99 | `kqueue_create` | `EX-2` | `pub fn kqueue_create() -> Result[Int, Str] {` |
| os | os/event.xi | 105 | `kqueue_add_read` | `EX-2` | `pub fn kqueue_add_read(kq: Int, fd: Int) -> Unit {` |
| os | os/event.xi | 112 | `kqueue_add_write` | `EX-2` | `pub fn kqueue_add_write(kq: Int, fd: Int) -> Unit {` |
| os | os/event.xi | 120 | `kqueue_wait` | `EX-2` | `pub fn kqueue_wait(kq: Int, timeout_ms: Int) -> Result[Vec[KEvent], Str] {` |
| os | os/event.xi | 128 | `kqueue_close` | `EX-2` | `pub fn kqueue_close(kq: Int) -> Unit {` |
| os | os/event.xi | 136 | `eventfd_new` | `EX-2` | `pub fn eventfd_new(init: Int) -> Result[Int, Str] {` |
| os | os/event.xi | 144 | `eventfd_read` | `EX-2` | `pub fn eventfd_read(fd: Int) -> Result[Int, Str] {` |
| os | os/event.xi | 152 | `eventfd_write` | `EX-2` | `pub fn eventfd_write(fd: Int, value: Int) -> Result[Unit, Str] {` |
| os | os/event.xi | 162 | `timerfd_new` | `EX-2` | `pub fn timerfd_new() -> Result[Int, Str] {` |
| os | os/event.xi | 169 | `timerfd_set` | `EX-2` | `pub fn timerfd_set(fd: Int, ms: Int) -> Result[Unit, Str] {` |
| os | os/event.xi | 179 | `signalfd_new` | `EX-2` | `pub fn signalfd_new(signals: &Vec[Int]) -> Result[Int, Str] {` |
| os | os/event.xi | 188 | `poll` | `EX-2` | `pub fn poll(fds: &Vec[PollFd], timeout_ms: Int) -> Result[Int, Str] {` |
| os | os/event.xi | 198 | `ppoll` | `EX-2` | `pub fn ppoll(fds: &Vec[PollFd], timeout_ms: Int) -> Result[Int, Str] {` |
| os | os/event.xi | 208 | `select` | `EX-2` | `pub fn select(read_fds: &Vec[Int], write_fds: &Vec[Int], timeout_ms: Int) -> Result[Int, Str] {` |
| os | os/event.xi | 219 | `pselect` | `EX-2` | `pub fn pselect(read_fds: &Vec[Int], write_fds: &Vec[Int], timeout_ms: Int) -> Result[Int, Str] {` |
| os | os/fs_ffi.xi | 37 | `symlink` | `EX-2` | `pub fn symlink(target: Str, link: Str) -> Result[Unit, Str] {` |
| os | os/fs_ffi.xi | 46 | `readlink` | `EX-2` | `pub fn readlink(path: Str) -> Result[Str, Str] {` |
| os | os/fs_ffi.xi | 53 | `is_symlink` | `EX-2` | `pub fn is_symlink(path: Str) -> Bool {` |
| os | os/fs_ffi.xi | 61 | `hard_link` | `EX-2` | `pub fn hard_link(old: Str, new: Str) -> Result[Unit, Str] {` |
| os | os/fs_ffi.xi | 70 | `chown` | `EX-2` | `pub fn chown(path: Str, uid: Int, gid: Int) -> Result[Unit, Str] {` |
| os | os/fs_ffi.xi | 181 | `dup` | `EX-2` | `pub fn dup(fd: Int) -> Result[Int, Str] {` |
| os | os/fs_ffi.xi | 189 | `dup2` | `EX-2` | `pub fn dup2(old: Int, new: Int) -> Result[Int, Str] {` |
| os | os/fs_ffi.xi | 198 | `truncate` | `EX-2` | `pub fn truncate(path: Str, length: Int) -> Result[Unit, Str] {` |
| os | os/fs_ffi.xi | 207 | `ftruncate` | `EX-2` | `pub fn ftruncate(fd: Int, length: Int) -> Result[Unit, Str] {` |
| os | os/fs_ffi.xi | 216 | `fallocate` | `EX-2` | `pub fn fallocate(fd: Int, offset: Int, length: Int) -> Result[Unit, Str] {` |
| os | os/fs_ffi.xi | 226 | `pread` | `EX-2` | `pub fn pread(fd: Int, offset: Int, length: Int) -> Result[Vec[UInt8], Str] {` |
| os | os/fs_ffi.xi | 236 | `pwrite` | `EX-2` | `pub fn pwrite(fd: Int, offset: Int, data: &Vec[UInt8]) -> Result[Int, Str] {` |
| os | os/fs_ffi.xi | 246 | `readv` | `EX-2` | `pub fn readv(fd: Int, buffers: &Vec[Vec[UInt8]]) -> Result[Int, Str] {` |
| os | os/fs_ffi.xi | 353 | `splice` | `EX-2` | `pub fn splice(in_fd: Int, out_fd: Int, count: Int) -> Result[Int, Str] {` |
| os | os/fs_ffi.xi | 407 | `mkfifo` | `EX-2` | `pub fn mkfifo(path: Str, mode: Int) -> Result[Unit, Str] {` |
| os | os/fs_ffi.xi | 416 | `fifo_open` | `EX-2` | `pub fn fifo_open(path: Str) -> Result[Int, Str] {` |
| os | os/ioctl.xi | 18 | `ioctl` | `EX-2` | `pub fn ioctl(fd: Int, request: Int, arg: Int) -> Result[Int, Str] {` |
| os | os/ioctl.xi | 28 | `ioctl_get_winsize` | `EX-2` | `pub fn ioctl_get_winsize(fd: Int) -> Result[(Int, Int), Str] {` |
| os | os/ioctl.xi | 36 | `ioctl_set_nonblock` | `EX-2` | `pub fn ioctl_set_nonblock(fd: Int, on: Bool) -> Result[Unit, Str] {` |
| os | os/ioctl.xi | 45 | `ioctl_fionread` | `EX-2` | `pub fn ioctl_fionread(fd: Int) -> Result[Int, Str] {` |
| os | os/lock.xi | 167 | `file_lock_release` | `EX-2` | `pub fn file_lock_release(l: FileLock) {` |
| os | os/mmap.xi | 296 | `mmap_resize` | `EX-2` | `pub fn mmap_resize(ptr: Int, old_len: Int, new_len: Int) -> Result[Int, Str] {` |
| os | os/os.xi | 503 | `FileWatcher.close` | `EX-2` | `pub fn FileWatcher.close(self) {` |
| os | os/os.xi | 741 | `sleep_millis` | `EX-2` | `pub fn sleep_millis(ms: Int) {` |
| os | os/proc_ffi.xi | 388 | `fork` | `EX-2` | `pub fn fork() -> Result[Int, Str] {` |
| os | os/proc_ffi.xi | 396 | `waitpid` | `EX-2` | `pub fn waitpid(pid: Int, options: Int) -> Result[Int, Str] {` |
| os | os/proc_ffi.xi | 405 | `wait` | `EX-2` | `pub fn wait() -> Result[Int, Str] {` |
| os | os/proc_ffi.xi | 414 | `execv` | `EX-2` | `pub fn execv(path: Str, args: &Vec[Str]) -> Result[Int, Str] {` |
| os | os/proc_ffi.xi | 423 | `execvp` | `EX-2` | `pub fn execvp(file: Str, args: &Vec[Str]) -> Result[Int, Str] {` |
| os | os/proc_ffi.xi | 441 | `getppid` | `EX-2` | `pub fn getppid() -> Int {` |
| os | os/proc_ffi.xi | 447 | `getsid` | `EX-2` | `pub fn getsid(pid: Int) -> Int {` |
| os | os/proc_ffi.xi | 456 | `raise` | `EX-2` | `pub fn raise(sig: Int) -> Result[Unit, Str] {` |
| os | os/proc_ffi.xi | 484 | `process_status` | `EX-2` | `pub fn process_status(pid: Int) -> Option[Int] {` |
| os | os/sync_io.xi | 103 | `read_until_eof` | `EX-2` | `pub fn read_until_eof(fd: Int) -> Result[Vec[UInt8], Str] {` |
| os | os/sync_io.xi | 111 | `read_line_buffered` | `EX-2` | `pub fn read_line_buffered(fd: Int) -> Result[Str, Str] {` |
| os | os/sync_io.xi | 119 | `copy_fd` | `EX-2` | `pub fn copy_fd(src: Int, dst: Int) -> Result[Int, Str] {` |
| os | os/sync_io.xi | 128 | `copy_fd_n` | `EX-2` | `pub fn copy_fd_n(src: Int, dst: Int, n: Int) -> Result[Int, Str] {` |
| os | os/sync_io.xi | 138 | `flush_fd` | `EX-2` | `pub fn flush_fd(fd: Int) -> Result[Unit, Str] {` |
| os | os/sync_io.xi | 263 | `file_advise` | `EX-2` | `pub fn file_advise(fd: Int, offset: Int, length: Int, advice: Int) -> Result[Unit, Str] {` |
| os | os/sync_io.xi | 274 | `file_allocate` | `EX-2` | `pub fn file_allocate(fd: Int, offset: Int, length: Int) -> Result[Unit, Str] {` |
| os | os/term.xi | 24 | `term_is_tty` | `EX-2` | `pub fn term_is_tty(fd: Int) -> Bool {` |
| os | os/term.xi | 97 | `term_width` | `EX-2` | `pub fn term_width() -> Int {` |
| os | os/terminal.xi | 31 | `isatty` | `EX-2` | `pub fn isatty(fd: Int) -> Bool {` |
| os | os/terminal.xi | 39 | `tty_name` | `EX-2` | `pub fn tty_name(fd: Int) -> Result[Str, Str] {` |
| os | os/terminal.xi | 47 | `pty_open` | `EX-2` | `pub fn pty_open() -> Result[(Int, Int), Str] {` |
| os | os/terminal.xi | 53 | `pty_close` | `EX-2` | `pub fn pty_close(master: Int, slave: Int) -> Unit {` |
| os | os/terminal.xi | 61 | `termios_get` | `EX-2` | `pub fn termios_get(fd: Int) -> Result[Termios, Str] {` |
| os | os/terminal.xi | 69 | `termios_set` | `EX-2` | `pub fn termios_set(fd: Int, t: Termios) -> Result[Unit, Str] {` |
| os | os/terminal.xi | 78 | `raw_mode` | `EX-2` | `pub fn raw_mode(fd: Int) -> Result[Termios, Str] {` |
| os | os/terminal.xi | 86 | `restore_mode` | `EX-2` | `pub fn restore_mode(fd: Int, t: Termios) -> Result[Unit, Str] {` |
| os | os/terminal.xi | 95 | `cbreak_mode` | `EX-2` | `pub fn cbreak_mode(fd: Int) -> Result[Termios, Str] {` |
| os | os/terminal.xi | 103 | `canonical_mode` | `EX-2` | `pub fn canonical_mode(fd: Int) -> Result[Termios, Str] {` |
| os | os/terminal.xi | 111 | `nonblock` | `EX-2` | `pub fn nonblock(fd: Int) -> Result[Unit, Str] {` |
| os | os/terminal.xi | 119 | `blocking` | `EX-2` | `pub fn blocking(fd: Int) -> Result[Unit, Str] {` |
| os | os/terminal.xi | 127 | `winsize` | `EX-2` | `pub fn winsize(fd: Int) -> Result[(Int, Int), Str] {` |
| os | os/terminal.xi | 135 | `set_winsize` | `EX-2` | `pub fn set_winsize(fd: Int, rows: Int, cols: Int) -> Result[Unit, Str] {` |
| os | os/terminal.xi | 144 | `terminal_width` | `EX-2` | `pub fn terminal_width() -> Int {` |
| os | os/terminal.xi | 150 | `terminal_height` | `EX-2` | `pub fn terminal_height() -> Int {` |
| os | os/unix.xi | 21 | `unix_umask` | `EX-2` | `pub fn unix_umask(mask: Int) -> Int {` |
| os | os/unix.xi | 28 | `unix_uid` | `EX-2` | `pub fn unix_uid() -> Int {` |
| os | os/unix.xi | 34 | `unix_gid` | `EX-2` | `pub fn unix_gid() -> Int {` |
| os | os/unix.xi | 41 | `unix_username` | `EX-2` | `pub fn unix_username(uid: Int) -> Result[Str, Str] {` |
| os | os/unix.xi | 49 | `unix_groupname` | `EX-2` | `pub fn unix_groupname(gid: Int) -> Result[Str, Str] {` |
| os | os/unix.xi | 69 | `unix_hostname` | `EX-2` | `pub fn unix_hostname() -> Str {` |
| os | os/unix.xi | 75 | `unix_domainname` | `EX-2` | `pub fn unix_domainname() -> Str {` |
| os | os/unix.xi | 81 | `unix_uptime` | `EX-2` | `pub fn unix_uptime() -> Int {` |
| os | os/unix.xi | 87 | `unix_loadavg` | `EX-2` | `pub fn unix_loadavg() -> (Float64, Float64, Float64) {` |
| os | os/unix.xi | 93 | `unix_sysconf` | `EX-2` | `pub fn unix_sysconf(name: Int) -> Int {` |
| os | os/unix.xi | 100 | `unix_pathconf` | `EX-2` | `pub fn unix_pathconf(path: Str, name: Int) -> Int {` |
| os | os/unix.xi | 108 | `unix_getrlimit` | `EX-2` | `pub fn unix_getrlimit(resource: Int) -> (Int, Int) {` |
| os | os/unix.xi | 116 | `unix_setrlimit` | `EX-2` | `pub fn unix_setrlimit(resource: Int, soft: Int, hard: Int) -> Result[Unit, Str] {` |
| os | os/unix.xi | 126 | `unix_utime` | `EX-2` | `pub fn unix_utime(path: Str, atime: Int, mtime: Int) -> Result[Unit, Str] {` |
| os | os/unix.xi | 136 | `unix_chroot` | `EX-2` | `pub fn unix_chroot(path: Str) -> Result[Unit, Str] {` |
| os | os/unix.xi | 144 | `unix_nice` | `EX-2` | `pub fn unix_nice(inc: Int) -> Result[Int, Str] {` |
| os | os/watch.xi | 154 | `watch_close` | `EX-2` | `pub fn watch_close(handle: Int) {` |
| os | os/win.xi | 22 | `win_registry_read` | `EX-2` | `pub fn win_registry_read(hive: Int, path: Str, name: Str) -> Result[Str, Str] {` |
| os | os/win.xi | 32 | `win_registry_write` | `EX-2` | `pub fn win_registry_write(hive: Int, path: Str, name: Str, value: Str) -> Result[Unit, Str] {` |
| os | os/win.xi | 43 | `win_registry_delete` | `EX-2` | `pub fn win_registry_delete(hive: Int, path: Str, name: Str) -> Result[Unit, Str] {` |
| os | os/win.xi | 66 | `win_set_environment_var` | `EX-2` | `pub fn win_set_environment_var(name: Str, value: Str) -> Result[Unit, Str] {` |
| os | os/win.xi | 74 | `win_service_status` | `EX-2` | `pub fn win_service_status(name: Str) -> Str {` |
| os | os/win.xi | 82 | `win_service_start` | `EX-2` | `pub fn win_service_start(name: Str) -> Result[Unit, Str] {` |
| os | os/win.xi | 90 | `win_service_stop` | `EX-2` | `pub fn win_service_stop(name: Str) -> Result[Unit, Str] {` |
| os | os/win.xi | 98 | `win_shell_execute` | `EX-2` | `pub fn win_shell_execute(verb: Str, file: Str, args: Str) -> Result[Int, Str] {` |
| os | os/win.xi | 117 | `win_is_admin` | `EX-2` | `pub fn win_is_admin() -> Bool {` |
| serialize | serialize/json.xi | 924 | `json_get` | `EX-3` | `pub fn json_get(v: JsonValue, key: Str) -> Option[JsonValue] {` |
| serialize | serialize/serialize.xi | 196 | `to_json` | `EX-1` | `pub fn to_json[T: Serialize](value: T) -> Result[Str, SerializeError] {` |
| serialize | serialize/serialize.xi | 201 | `from_json` | `EX-1` | `pub fn from_json[T: Deserialize](s: Str) -> Result[T, SerializeError] {` |
| serialize | serialize/serialize.xi | 563 | `JsonValue.get` | `EX-3` | `pub fn JsonValue.get(self, key: Str) -> Option[JsonValue] {` |
| serialize | serialize/yaml_lite.xi | 233 | `yaml_stringify` | `EX-1` | `pub fn yaml_stringify(v: YamlValue) -> Str {` |
| serialize | serialize/yaml_lite.xi | 389 | `yaml_get` | `EX-3` | `pub fn yaml_get(v: YamlValue, key: Str) -> Option[YamlValue] {` |
| thread | thread/spawn.xi | 142 | `sleep_ms` | `EX-1` | `pub fn sleep_ms(ms: Int) {` |
| thread | thread/spawn.xi | 183 | `is_main_thread` | `EX-1` | `pub fn is_main_thread() -> Bool {` |
| thread | thread/thread.xi | 165 | `scope` | `EX-2` | `pub fn scope[T](f: fn(&Scope) -> T) -> T {` |
| thread | thread/thread.xi | 226 | `thread_yield` | `EX-1` | `pub fn thread_yield() {` |
| thread | thread/thread.xi | 236 | `thread_parallel_for` | `EX-1` | `pub fn thread_parallel_for(start: Int, end: Int, f: fn(Int)) {` |

