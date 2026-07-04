// XIOM — Queryable Contract Runtime API
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.
//
// Exposes XIOM's contract system as a runtime-queryable API.
// No other language has this — contracts are first-class data in XIOM.

module xiom.contracts

// ============================================================================
// Contract Metadata Types
// ============================================================================

// A single contract clause (requires, ensures, or invariant)
pub type ContractClause = {
  kind: Int;           // 0=requires, 1=ensures, 2=invariant
  expression: Str;     // the contract text, e.g. "b != 0.0"
  location: Str;       // file:line
  function: Str;       // function name (for requires/ensures)
  type_name: Str;      // type name (for invariants)
} derive[Eq, Clone]

// All contracts for a function
pub type FunctionContracts = {
  name: Str;
  requires: Vec[ContractClause];
  ensures: Vec[ContractClause];
  return_type: Str;
  params: Vec[(Str, Str)]; // (name, type)
} derive[Clone]

// All contracts for a type
pub type TypeContracts = {
  name: Str;
  invariants: Vec[ContractClause];
  fields: Vec[(Str, Str)]; // (name, type)
} derive[Clone]

// Complete contract index for a package
pub type ContractIndex = {
  package: Str;
  version: Str;
  functions: Vec[FunctionContracts];
  types: Vec[TypeContracts];
  total_clauses: Int;
  requires_count: Int;
  ensures_count: Int;
  invariant_count: Int;
} derive[Clone]

// ============================================================================
// Runtime Contract Verification
// ============================================================================

// Result of a contract check
pub type ContractCheckResult = {
  passed: Bool;
  clause: ContractClause;
  actual_values: Map[Str, Str]; // variable -> value at violation
  message: Str;
} derive[Clone]

// Verify ALL invariants of a type against a value at runtime.
// Returns list of failures (empty = all passed).
pub fn verify_invariants[T](value: &T) -> Vec[ContractCheckResult]
  ensures: result.len() == 0 => value satisfies all invariants

// Verify ALL contracts of a function against its actual call.
// Called automatically by the compiler at runtime.
pub fn verify_function_contracts(func: Str, args: Map[Str, Str]) -> Vec[ContractCheckResult];

// Verify a single invariant expression against a value.
pub fn check_invariant[T](value: &T, invariant: Str) -> ContractCheckResult;

// ============================================================================
// Contract Index — Queryable Spec Database
// ============================================================================

// Build a complete contract index for the current package.
// This is what --dump-contracts does at compile time, but available at runtime.
pub fn build_contract_index() -> ContractIndex;

// Query contracts for a specific function.
pub fn get_function_contracts(name: Str) -> Option<Vec<FunctionContracts>>;

// Query contracts for a specific type.
pub fn get_type_contracts(name: Str) -> Option<Vec<TypeContracts>>;

// Find all functions whose contracts reference a given type.
pub fn find_functions_using_type(type_name: Str) -> Vec<Str>;

// Find all invariants that reference a given field.
pub fn find_invariants_using_field(type_name: Str, field_name: Str) -> Vec<ContractClause>;

// ============================================================================
// Contract Serialization (Spec Database Export)
// ============================================================================

// Export the contract index as JSON (same format as --dump-contracts).
pub fn export_contracts_json() -> Str;

// Export the contract index as structured documentation.
pub fn export_contracts_markdown() -> Str;

// Export contract index as OpenAPI/Swagger-like spec.
pub fn export_contracts_openapi() -> Str;

// ============================================================================
// Contract Coverage (Testing)
// ============================================================================

// Track which contracts have been exercised by tests.
pub fn reset_contract_coverage();
pub fn record_contract_hit(clause: ContractClause, input_values: Map[Str, Str]);
pub fn get_contract_coverage() -> Map[Str, Bool]; // clause -> was it exercised?
pub fn get_uncovered_contracts() -> Vec<ContractClause>;
pub fn coverage_percentage() -> Float64; // % of contracts covered

// ============================================================================
// Contract Composition (for AI Tooling)
// ============================================================================

// Given two functions f and g, can g's output satisfy f's requires?
// Returns the condition that must hold, or "impossible" if never.
pub fn can_compose(f_requires: Vec[ContractClause], g_ensures: Vec[ContractClause]) -> Str;

// Given a chain of function calls, verify contract propagation.
pub fn verify_chain(fns: Vec<Str>) -> Result[Unit, Vec[ContractCheckResult]>;

// ============================================================================
// Contract Statistics
// ============================================================================

pub fn total_contracts() -> Int;
pub fn total_requires() -> Int;
pub fn total_ensures() -> Int;
pub fn total_invariants() -> Int;
pub fn functions_with_contracts() -> Int;
pub fn types_with_invariants() -> Int;
pub fn contract_density() -> Float64; // contracts per function
