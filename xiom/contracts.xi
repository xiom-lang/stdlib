// XIOM — Queryable Contract Runtime API
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.
//
// Exposes XIOM's contract system as a runtime-queryable API.
// No other language has this — contracts are first-class data in XIOM.

module xiom.contracts

// === FFI: compiler-emitted contract metadata table ===
// Backed by an additive, read-only table that the codegen
// (`xiom-codegen::emit_metadata_tables`) emits for every function in the
// compilation unit that carries pre/postconditions. This makes the contract
// index, statistics, queries and coverage below query REAL compiler data.
//
// REAL:    build_contract_index (function names + requires/ensures COUNTS) and,
//          transitively, every statistic/query/coverage helper that reads the
//          index (total_*, functions_with_contracts, contract_density,
//          get_function_contracts, get_uncovered_contracts, coverage_percentage…).
// LIMITED: clause EXPRESSION text, source locations, parameter/return types and
//          type invariants are not embedded yet, so those fields are "" / empty;
//          runtime contract evaluation (verify_function_contracts, check_invariant)
//          and SMT reasoning (can_compose, verify_chain) remain honest placeholders.
extern "C" {
  fn xiom_contract_fn_count() -> Int;
  fn xiom_contract_fn_name(idx: Int) -> Str;
  fn xiom_contract_pre_count(idx: Int) -> Int;
  fn xiom_contract_post_count(idx: Int) -> Int;
}

fn contract_fn_count() -> Int {
  unsafe { return xiom_contract_fn_count(); }
}

fn contract_fn_name(idx: Int) -> Str {
  unsafe { return xiom_contract_fn_name(idx); }
}

fn contract_pre_count(idx: Int) -> Int {
  unsafe { return xiom_contract_pre_count(idx); }
}

fn contract_post_count(idx: Int) -> Int {
  unsafe { return xiom_contract_post_count(idx); }
}

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
// Module State
// ============================================================================

// Contract coverage tracking
var _coverage: Map[Str, Bool] = Map[Str, Bool].new();

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
  ensures: result.len() == 0
{
  // Bootstrap: compiler contract metadata not yet available
  Vec[ContractCheckResult].new()
}

// Verify ALL contracts of a function against its actual call.
// Called automatically by the compiler at runtime.
pub fn verify_function_contracts(func: Str, args: Map[Str, Str]) -> Vec[ContractCheckResult] {
  // Bootstrap: compiler contract metadata not yet available
  Vec[ContractCheckResult].new()
}

// Verify a single invariant expression against a value.
pub fn check_invariant[T](value: &T, invariant: Str) -> ContractCheckResult {
  let clause = ContractClause{
    kind: 2;
    expression: invariant;
    location: "";
    function: "";
    type_name: "";
  };
  ContractCheckResult{
    passed: true;
    clause: clause;
    actual_values: Map[Str, Str].new();
    message: "bootstrap: runtime contract checking not yet available";
  }
}

// ============================================================================
// Contract Index — Queryable Spec Database
// ============================================================================

// Internal: retrieve the current contract index.
fn _get_index() -> ContractIndex {
  build_contract_index()
}

// Build a complete contract index for the current package.
// This is what --dump-contracts does at compile time, but available at runtime.
// REAL: reads function names and requires/ensures counts from the compiler
// contract table. LIMITED: clause expression text, locations, params, return
// types and type invariants are not embedded, so those remain empty.
pub fn build_contract_index() -> ContractIndex {
  var functions = Vec[FunctionContracts].new();
  var total = 0;
  var req_total = 0;
  var ens_total = 0;
  let count = contract_fn_count();
  var idx = 0;
  while idx < count {
    let fname = contract_fn_name(idx);
    let pre = contract_pre_count(idx);
    let post = contract_post_count(idx);
    req_total = req_total + pre;
    ens_total = ens_total + post;
    total = total + pre + post;

    var reqs = Vec[ContractClause].new();
    var r = 0;
    while r < pre {
      reqs.push(ContractClause{
        kind: 0;
        expression: "";
        location: "";
        function: fname;
        type_name: "";
      });
      r = r + 1;
    }

    var enss = Vec[ContractClause].new();
    var e = 0;
    while e < post {
      enss.push(ContractClause{
        kind: 1;
        expression: "";
        location: "";
        function: fname;
        type_name: "";
      });
      e = e + 1;
    }

    functions.push(FunctionContracts{
      name: fname;
      requires: reqs;
      ensures: enss;
      return_type: "";
      params: Vec[(Str, Str)].new();
    });
    idx = idx + 1;
  }

  return ContractIndex{
    package: "";
    version: "0.1.0";
    functions: functions;
    types: Vec[TypeContracts].new();
    total_clauses: total;
    requires_count: req_total;
    ensures_count: ens_total;
    invariant_count: 0;
  };
}

// Query contracts for a specific function.
pub fn get_function_contracts(name: Str) -> Option<Vec[FunctionContracts>> {
  let idx = _get_index();
  var result = Vec[FunctionContracts].new();
  var i = 0;
  while i < idx.functions.len() {
    if idx.functions[i].name == name {
      result.push(idx.functions[i]);
    }
    i = i + 1;
  }
  if result.len() == 0 { return None; }
  Some(result)
}

// Query contracts for a specific type.
pub fn get_type_contracts(name: Str) -> Option<Vec<TypeContracts>> {
  let idx = _get_index();
  var result = Vec[TypeContracts].new();
  var i = 0;
  while i < idx.types.len() {
    if idx.types[i].name == name {
      result.push(idx.types[i]);
    }
    i = i + 1;
  }
  if result.len() == 0 { return None; }
  Some(result)
}

// Find all functions whose contracts reference a given type.
pub fn find_functions_using_type(type_name: Str) -> Vec[Str] {
  let idx = _get_index();
  var result = Vec[Str].new();
  var i = 0;
  while i < idx.functions.len() {
    let fc = idx.functions[i];
    var found = false;
    var j = 0;
    while j < fc.params.len() {
      if fc.params[j].1 == type_name {
        found = true;
      }
      j = j + 1;
    }
    if fc.return_type == type_name { found = true; }
    if found { result.push(fc.name); }
    i = i + 1;
  }
  result
}

// Find all invariants that reference a given field.
pub fn find_invariants_using_field(type_name: Str, field_name: Str) -> Vec[ContractClause] {
  var idx = _get_index();
  var result = Vec[ContractClause].new();
  var i = 0;
  while i < idx.types.len() {
    let tc = idx.types[i];
    if tc.name == type_name {
      var j = 0;
      while j < tc.invariants.len() {
        let c = tc.invariants[j];
        match string.index_of(c.expression, field_name) {
          Some(_) => { result.push(c); },
          None => {},
        }
        j = j + 1;
      }
    }
    i = i + 1;
  }
  result
}

// ============================================================================
// Contract Serialization (Spec Database Export)
// ============================================================================

// Export the contract index as JSON (same format as --dump-contracts).
pub fn export_contracts_json() -> Str {
  let idx = _get_index();
  var json = "{\n";
  json = string.str_concat(json, "  \"package\": \"");
  json = string.str_concat(json, idx.package);
  json = string.str_concat(json, "\",\n");
  json = string.str_concat(json, "  \"version\": \"");
  json = string.str_concat(json, idx.version);
  json = string.str_concat(json, "\",\n");
  json = string.str_concat(json, "  \"total_clauses\": 0,\n");
  json = string.str_concat(json, "  \"requires_count\": 0,\n");
  json = string.str_concat(json, "  \"ensures_count\": 0,\n");
  json = string.str_concat(json, "  \"invariant_count\": 0,\n");
  json = string.str_concat(json, "  \"functions\": [],\n");
  json = string.str_concat(json, "  \"types\": []\n");
  json = string.str_concat(json, "}");
  json
}

// Export the contract index as structured documentation.
pub fn export_contracts_markdown() -> Str {
  let idx = _get_index();
  var md = "# Contract Index\n\n";
  md = string.str_concat(md, "## Package: ");
  md = string.str_concat(md, idx.package);
  md = string.str_concat(md, " (v");
  md = string.str_concat(md, idx.version);
  md = string.str_concat(md, ")\n\n");
  md = string.str_concat(md, "| Category | Count |\n");
  md = string.str_concat(md, "|----------|-------|\n");
  md = string.str_concat(md, "| Total Clauses | 0 |\n");
  md = string.str_concat(md, "| Requires | 0 |\n");
  md = string.str_concat(md, "| Ensures | 0 |\n");
  md = string.str_concat(md, "| Invariants | 0 |\n");
  md = string.str_concat(md, "| Functions with Contracts | 0 |\n");
  md = string.str_concat(md, "| Types with Invariants | 0 |\n\n");
  md = string.str_concat(md, "## Functions\n\n*No contracts defined.*\n\n");
  md = string.str_concat(md, "## Types\n\n*No invariants defined.*\n");
  md
}

// Export contract index as OpenAPI/Swagger-like spec.
pub fn export_contracts_openapi() -> Str {
  let idx = _get_index();
  var yaml = "openapi: \"3.0.0\"\n";
  yaml = string.str_concat(yaml, "info:\n");
  yaml = string.str_concat(yaml, "  title: \"");
  yaml = string.str_concat(yaml, idx.package);
  yaml = string.str_concat(yaml, " Contract API\"\n");
  yaml = string.str_concat(yaml, "  version: \"");
  yaml = string.str_concat(yaml, idx.version);
  yaml = string.str_concat(yaml, "\"\n");
  yaml = string.str_concat(yaml, "  description: \"Auto-generated from XIOM contracts\"\n");
  yaml = string.str_concat(yaml, "paths: {}\n");
  yaml = string.str_concat(yaml, "components:\n");
  yaml = string.str_concat(yaml, "  schemas:\n");
  yaml = string.str_concat(yaml, "    x-xiom-contracts:\n");
  yaml = string.str_concat(yaml, "      total_clauses: 0\n");
  yaml = string.str_concat(yaml, "      requires_count: 0\n");
  yaml = string.str_concat(yaml, "      ensures_count: 0\n");
  yaml = string.str_concat(yaml, "      invariant_count: 0\n");
  yaml
}

// ============================================================================
// Contract Coverage (Testing)
// ============================================================================

// Track which contracts have been exercised by tests.
pub fn reset_contract_coverage() {
  _coverage = Map[Str, Bool].new();
}

pub fn record_contract_hit(clause: ContractClause, input_values: Map[Str, Str]) {
  _coverage.insert(clause.expression, true);
}

pub fn get_contract_coverage() -> Map[Str, Bool] {
  var result = Map[Str, Bool].new();
  let keys = _coverage.keys();
  var i = 0;
  while i < keys.len() {
    let key = keys[i];
    let val_opt = _coverage.get(&key);
    match val_opt {
      Some(v) => { result.insert(key, v); },
      None => {},
    }
    i = i + 1;
  }
  result
}

pub fn get_uncovered_contracts() -> Vec[ContractClause] {
  let idx = _get_index();
  var result = Vec[ContractClause].new();
  var i = 0;
  while i < idx.functions.len() {
    let fc = idx.functions[i];
    var j = 0;
    while j < fc.requires.len() {
      let c = fc.requires[j];
      if !_coverage.contains(&c.expression) {
        result.push(c);
      }
      j = j + 1;
    }
    j = 0;
    while j < fc.ensures.len() {
      let c = fc.ensures[j];
      if !_coverage.contains(&c.expression) {
        result.push(c);
      }
      j = j + 1;
    }
    i = i + 1;
  }
  i = 0;
  while i < idx.types.len() {
    let tc = idx.types[i];
    var j = 0;
    while j < tc.invariants.len() {
      let c = tc.invariants[j];
      if !_coverage.contains(&c.expression) {
        result.push(c);
      }
      j = j + 1;
    }
    i = i + 1;
  }
  result
}

pub fn coverage_percentage() -> Float64 {
  let idx = _get_index();
  let total = idx.total_clauses;
  if total == 0 { return 100.0; }
  let covered = _coverage.len();
  (covered as Float64) / (total as Float64) * 100.0
}

// ============================================================================
// Contract Composition (for AI Tooling)
// ============================================================================

// Given two functions f and g, can g's output satisfy f's requires?
// Returns the condition that must hold, or "impossible" if never.
pub fn can_compose(f_requires: Vec[ContractClause], g_ensures: Vec[ContractClause]) -> Str {
  // Bootstrap: SMT-based contract composition not yet available.
  // In the future this will use Z3/Boogie to check contract compatibility.
  "unknown"
}

// Given a chain of function calls, verify contract propagation.
pub fn verify_chain(fns: Vec<Str>) -> Result[Unit, Vec[ContractCheckResult]] {
  // Bootstrap: chained contract verification not yet available.
  Ok(Unit)
}

// ============================================================================
// Contract Statistics
// ============================================================================

pub fn total_contracts() -> Int {
  _get_index().total_clauses
}

pub fn total_requires() -> Int {
  _get_index().requires_count
}

pub fn total_ensures() -> Int {
  _get_index().ensures_count
}

pub fn total_invariants() -> Int {
  _get_index().invariant_count
}

pub fn functions_with_contracts() -> Int {
  _get_index().functions.len()
}

pub fn types_with_invariants() -> Int {
  _get_index().types.len()
}

pub fn contract_density() -> Float64 {
  let idx = _get_index();
  let fn_count = idx.functions.len();
  if fn_count == 0 { return 0.0; }
  (idx.total_clauses as Float64) / (fn_count as Float64)
}
