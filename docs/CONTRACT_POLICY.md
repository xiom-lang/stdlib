<!--
Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
SPDX-License-Identifier: MIT OR Apache-2.0
-->
# Contract Policy (roadmap B1)

Status: **active** (2026-11-06). Owner: stdlib lane.
Related: `docs/STDLIB_ROADMAP.md` B1/B2/B3/B4, gate 8 in
`docs/PRODUCTION_READINESS_QUEUE.md`, `docs/MODULE_OWNERSHIP.md`,
`tools/contract_exemptions.json`, `tools/coverage_scan.ps1`,
`tools/check_contract_policy.ps1`.

## 1. Purpose

The public API is a contract, not a signature. A caller must be able to prove
that a call is legal and to rely on what the call guarantees without reading
the implementation. This policy makes that rule explicit, defines the only
allowed exceptions, and assigns a named sign-off for every module.

It does not re-audit the existing corpus. It formalizes the evidence already
recorded by readiness gate 8 (wave 208, refreshed 2026-10-31) and gives the
later B2 ratchet a stable vocabulary and a checked registry.

## 2. Scope and definitions

- **Public API**: every `pub fn`, `pub type`/`pub struct`/`pub enum`, and
  `pub const`/`pub static` reachable from `xiom/`.
- **Measured unit**: `pub fn`. The coverage metric counts a public function as
  covered when its header carries at least one `requires:` or `ensures:`
  clause. A public type `invariant:` is part of the contract and may be cited
  by function clauses, but it does not by itself mark a function covered.
- **Contract clause**: `requires:` (caller obligation) or `ensures:`
  (callee guarantee), plus public type `invariant:`.
- **Exemption**: a reviewed, recorded decision that a public function needs no
  additional clause under one of the categories in section 5.
- **Authorities**:
  - counts: `tools/coverage_scan.ps1`;
  - per-module sign-off: `docs/MODULE_OWNERSHIP.md`;
  - exemptions: `tools/contract_exemptions.json`;
  - agreement check: `tools/check_contract_policy.ps1` (CI static job).

## 3. The rule

Every public function MUST have at least one non-tautological clause, or a
recorded exemption. "No clause needed" is a decision, not a default.

A pull request that adds or changes a public function MUST do one of:

1. add or update its `requires:`/`ensures:`;
2. record a per-function exemption (category, rationale, owner, approval,
   expiry); or
3. remove the function from the public surface.

Deleting a clause to make a ratchet pass is a contract regression, not a
cleanup. If a clause is wrong, fix the clause or the implementation; do not
drop the obligation silently.

## 4. Contract quality bar

A clause counts only if it constrains observable behavior:

- **`requires:` states caller obligations**, not implementation steps. It may
  constrain inputs, aliasing, ownership, or initialization state.
- **`ensures:` states observable postconditions**: result value/range, state
  changes, aliasing and ownership of returned or borrowed memory, and error
  behavior. "Returned value is valid" is insufficient unless validity is
  defined.
- **Non-tautological**: `ensures: true`, `ensures: x == x`, or a clause that
  merely restates the declared type does not count. A clause must exclude at
  least one behavior the implementation could otherwise have.
- **Ownership and lifetime**: functions that return or borrow aggregates must
  state who owns the result and how long a borrowed view stays valid (for
  example `#[owns_return]`, borrowed view, or caller-owned buffer).
- **Failure**: if a function can fail, the clause must say when the failure is
  a precondition violation versus an in-domain error result.
- **Determinism**: nondeterministic functions must state the source or range
  of nondeterminism; deterministic functions should say so when callers rely
  on it.
- **Executable**: clauses must be side-effect free and checkable by the
  contract runtime. Do not reference private helpers, loop state, or
  allocation counts unless the count is a published performance/memory SLO.
- **No implementation leakage**: a clause may not exist only to restate the
  current algorithm. It must remain true for any conforming implementation.

## 5. Exemption categories

Only the categories below are valid. EX-1..EX-5 are per-function records.
EX-0 is the grandfathered, pre-policy tail and is closed to new entries.

| ID | Category | Allowed when | Required evidence |
|---|---|---|---|
| EX-0 | Legacy tail | A function is in the gate-8 no-clause tail recorded before this policy | Module-level count in `tools/contract_exemptions.json`; rationale and gate-8 reference; must shrink and be reclassified in B2 |
| EX-1 | Total function | The function is total over its declared domain and every meaningful postcondition is already a type-level fact; a clause would be `true` | Domain statement and why no partial behavior exists |
| EX-2 | ABI / platform shim | Correctness is defined by an external ABI/OS contract (FFI, syscall, handle, signal) | Link to the runtime/ABI documentation and the caller-side obligation |
| EX-3 | Accessor / iterator / trivial projection | A clause would restate the field, type, or iterator protocol | Citation of the enclosing type invariant or iterator protocol |
| EX-4 | Generated code | The contract lives in the generator and the output is checked in | Generator link plus provenance/hash of the generated output |
| EX-5 | Deprecated surface | The function is scheduled for removal and gets no further contract work | E1 deprecation entry and expiry version |

EX-0 is a budget, not a suppression: the count is visible, ratcheted, and
cannot grow. B2 reclassifies each EX-0 function to a contract or to EX-1..EX-5.

## 6. Exemption records

`tools/contract_exemptions.json` is versioned JSON. An EX-1..EX-5 entry names
the function:

```json
{
  "module": "io",
  "function": "read_file_bytes",
  "path": "xiom/io/io.xi",
  "category": "EX-2",
  "rationale": "why the external contract is the whole contract",
  "owner": "stdlib lane",
  "approved": "2026-11-06",
  "expires": "never"
}
```

An EX-0 entry carries `count` instead of `function`/`path`:

```json
{ "module": "os", "count": 111, "category": "EX-0",
  "rationale": "gate-8 no-clause tail; reclassify per function in B2",
  "owner": "stdlib lane", "approved": "2026-11-06" }
```

A homogeneous family may replace `function` with a `functions: ["Type.method",
...]` list and one shared rationale. The checker still validates every name
against the named path individually.

Rules:

- The sum of EX-0 counts MUST equal the number of uncovered public functions
  reported by `tools/coverage_scan.ps1`; otherwise the checker fails.
- An EX-0 count may only shrink. Raising it requires a policy amendment and a
  review-log row, and is not allowed for convenience.
- A new public function cannot be added as EX-0. It needs a clause or an
  EX-1..EX-5 record in the same commit.
- An exemption is a review artifact, not a runtime suppression. It must not
  silence a failing contract check.

## 7. Per-module sign-off

`docs/MODULE_OWNERSHIP.md` has one row per top-level module directory under
`xiom/`. The row records the owner, the scanner counts, the exemption count,
the status, and the sign-off date.

Signing a module asserts all of the following:

1. the public-function, covered, and exemption counts match
   `tools/coverage_scan.ps1`;
2. every uncovered public function is in `tools/contract_exemptions.json`;
3. the covered functions' clauses meet the section 4 quality bar on review;
4. public type invariants were reviewed as part of the module's contract; and
5. there is no unreviewed public surface in the module.

Status values:

- `signed-off`: every public function is covered (exempt count 0).
- `tail-approved`: every uncovered function is a recorded EX-0 tail entry.
- `pending`: the module is not signed off; CI fails until it is.

Ownership and re-sign-off:

- The owner is accountable for the module's public surface, contracts, probes,
  and memory budget. In the current single-lane layout the owner is the stdlib
  lane; G2 may split this into named maintainers without changing the rule.
- The owner re-signs in the same commit as any public API or contract change
  in the module.
- A new module needs an owner, a sign-off, a probe set, and a memory/perf
  budget before merge (roadmap admission test, section 3.3).
- If coverage falls or an uncovered function is not exempt, the status becomes
  `pending` until the owner restores or exempts it.

## 8. Measurement, gates, and CI

Authoritative command:

```powershell
pwsh tools/coverage_scan.ps1
```

Gate 8 ("contract coverage 100% outside the documented no-clause tail") is
defined as: every public function outside the recorded EX-0 tail has at least
one clause. The tail is visible, counted, and ratcheted; it is not silently
excluded.

No-regression rule:

- The per-module floors in `tools/coverage_floors197.json` must stay green.
- `tools/check_contract_policy.ps1` runs in the static CI job and fails when
  the scanner totals, the ownership map, and the exemption registry disagree.
- The checker is count-based. Counts certify the budget, not function
  identity; function-level reclassification is B2, and reviewers must still
  reject clause deletion or exemption broadening in the diff.

## 9. Roadmap hand-off

- **B2** reclassifies every EX-0 function into a clause or EX-1..EX-5, retires
  EX-0, and ratchets `pub-with-clause` to 100% (exemptions counted). It also
  moves the checker from count-level to function-level where useful.
- **B3** generates reference documentation from the contracts and runs doc
  examples as tests.
- **B4** decides contract-check runtime semantics (debug/release) and the cost
  budget, and documents both.
- **E4** dedups same-leaf public types/functions before 1.0; dedup must
  preserve the surviving contract.

## 10. Current baseline (2026-11-06)

Measured by `tools/coverage_scan.ps1` on `main`:

- 44 modules, 9,449 functions, 6,992 public functions.
- 9,247 clauses; 6,716 public functions covered (96.1%).
- 276 uncovered public functions in 7 modules: 94 EX-0 (math) and 182
  per-function exemptions (os 111, iter 54, serialize 6, thread 5, ffi 4,
  format 2). The nine format ANSI helpers now carry constant clauses.
- Signature: `GLOBAL: fns=9449  pubFns=6992  clauses=9247  pubCovered=6716`;
  `pub-with-clause = 96.1%`.

This baseline is the B1 sign-off point and the current B2 line.
