<!--
Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
SPDX-License-Identifier: MIT OR Apache-2.0
-->
# Module Ownership and Contract Sign-off (roadmap B1)

Status: **active** (2026-11-06). Policy: `docs/CONTRACT_POLICY.md`.
Exemptions: `tools/contract_exemptions.json`.

This is the per-module sign-off map for the contract policy. One row per
top-level module directory under `xiom/`. Counts are generated from
`tools/coverage_scan.ps1`; do not hand-edit them.

Regenerate the counts:

```powershell
pwsh tools/coverage_scan.ps1
pwsh tools/check_contract_policy.ps1
```

The checker fails if this table, the scanner, and the exemption registry
disagree, or if any module is `pending`.

## Sign-off summary

- 44 modules; 6,992 public functions; 6,716 covered (96.1%); 276 exemptions
  in 7 modules (259 EX-0 + 17 per-function EX-1/EX-2/EX-3).
- 37 modules `signed-off` at 100%; 7 modules `tail-approved` with a recorded
  budget (3 with EX-0: iter/os/math; ffi/thread/serialize/format with
  per-function exemptions). No module is `pending`.
- The sign-off formalizes the readiness gate-8 evidence (wave 208, refreshed
  2026-10-31) and the 2026-11-06 scanner run. It is not a fresh clause-quality
  audit of every function; B2 performs the function-level reclassification.

| Module | Owner | Pub fns | Covered | Exempt | Coverage | Status | Signed off |
|---|---|---|---|---|---|---|---|
| alloc | stdlib lane | 14 | 14 | 0 | 100% | signed-off | 2026-11-06 |
| array | stdlib lane | 45 | 45 | 0 | 100% | signed-off | 2026-11-06 |
| async | stdlib lane | 67 | 67 | 0 | 100% | signed-off | 2026-11-06 |
| bench | stdlib lane | 16 | 16 | 0 | 100% | signed-off | 2026-11-06 |
| bits | stdlib lane | 101 | 101 | 0 | 100% | signed-off | 2026-11-06 |
| cell | stdlib lane | 16 | 16 | 0 | 100% | signed-off | 2026-11-06 |
| collect | stdlib lane | 603 | 603 | 0 | 100% | signed-off | 2026-11-06 |
| collections | stdlib lane | 57 | 57 | 0 | 100% | signed-off | 2026-11-06 |
| compress | stdlib lane | 108 | 108 | 0 | 100% | signed-off | 2026-11-06 |
| convert | stdlib lane | 320 | 320 | 0 | 100% | signed-off | 2026-11-06 |
| core | stdlib lane | 131 | 131 | 0 | 100% | signed-off | 2026-11-06 |
| crypto | stdlib lane | 203 | 203 | 0 | 100% | signed-off | 2026-11-06 |
| debug | stdlib lane | 41 | 41 | 0 | 100% | signed-off | 2026-11-06 |
| encoding | stdlib lane | 95 | 95 | 0 | 100% | signed-off | 2026-11-06 |
| error | stdlib lane | 42 | 42 | 0 | 100% | signed-off | 2026-11-06 |
| ffi | stdlib lane | 73 | 69 | 4 | 94.5% | tail-approved | 2026-11-06 |
| format | stdlib lane | 231 | 229 | 2 | 99.1% | tail-approved | 2026-11-06 |
| geom | stdlib lane | 414 | 414 | 0 | 100% | signed-off | 2026-11-06 |
| hash | stdlib lane | 93 | 93 | 0 | 100% | signed-off | 2026-11-06 |
| io | stdlib lane | 122 | 122 | 0 | 100% | signed-off | 2026-11-06 |
| iter | stdlib lane | 183 | 129 | 54 | 70.5% | tail-approved | 2026-11-06 |
| log | stdlib lane | 68 | 68 | 0 | 100% | signed-off | 2026-11-06 |
| math | stdlib lane | 1013 | 919 | 94 | 90.7% | tail-approved | 2026-11-06 |
| mem | stdlib lane | 14 | 14 | 0 | 100% | signed-off | 2026-11-06 |
| misc | stdlib lane | 82 | 82 | 0 | 100% | signed-off | 2026-11-06 |
| net | stdlib lane | 436 | 436 | 0 | 100% | signed-off | 2026-11-06 |
| num | stdlib lane | 491 | 491 | 0 | 100% | signed-off | 2026-11-06 |
| os | stdlib lane | 390 | 279 | 111 | 71.5% | tail-approved | 2026-11-06 |
| ptr | stdlib lane | 19 | 19 | 0 | 100% | signed-off | 2026-11-06 |
| rand | stdlib lane | 52 | 52 | 0 | 100% | signed-off | 2026-11-06 |
| rc | stdlib lane | 15 | 15 | 0 | 100% | signed-off | 2026-11-06 |
| reflect | stdlib lane | 44 | 44 | 0 | 100% | signed-off | 2026-11-06 |
| regex | stdlib lane | 49 | 49 | 0 | 100% | signed-off | 2026-11-06 |
| search | stdlib lane | 37 | 37 | 0 | 100% | signed-off | 2026-11-06 |
| serialize | stdlib lane | 117 | 111 | 6 | 94.9% | tail-approved | 2026-11-06 |
| simd | stdlib lane | 90 | 90 | 0 | 100% | signed-off | 2026-11-06 |
| sort | stdlib lane | 47 | 47 | 0 | 100% | signed-off | 2026-11-06 |
| stats | stdlib lane | 144 | 144 | 0 | 100% | signed-off | 2026-11-06 |
| string | stdlib lane | 458 | 458 | 0 | 100% | signed-off | 2026-11-06 |
| sync | stdlib lane | 125 | 125 | 0 | 100% | signed-off | 2026-11-06 |
| test | stdlib lane | 88 | 88 | 0 | 100% | signed-off | 2026-11-06 |
| text | stdlib lane | 41 | 41 | 0 | 100% | signed-off | 2026-11-06 |
| thread | stdlib lane | 59 | 54 | 5 | 91.5% | tail-approved | 2026-11-06 |
| time | stdlib lane | 138 | 138 | 0 | 100% | signed-off | 2026-11-06 |
| **Total** | | **6992** | **6716** | **276** | **96.1%** | 37 / 7 / 0 | |

Status meanings: `signed-off` = every public function covered; `tail-approved`
= every uncovered function is a recorded exemption (EX-0 or per-function
EX-1..EX-5); `pending` = not signed off (CI fails).

B2 blocks 342/343/345: ffi 4, thread 5, serialize 6 and format 2 exemptions
are per-function -- ffi: `dl_open_global`/`dl_sym_address` EX-2,
`errno_perror`/`safe_ptr_free` EX-1; thread: `scope` EX-2,
`sleep_ms`/`is_main_thread`/`thread_yield`/`thread_parallel_for` EX-1;
serialize: `json_get`/`JsonValue.get`/`yaml_get` EX-3,
`to_json`/`from_json`/`yaml_stringify` EX-1; format: `print`/`println` EX-1.
The nine format ANSI helpers moved to constant clauses. The other 259
(iter/os/math) are EX-0.

## Sign-off record

| Date | Reviewer | Scope | Basis |
|---|---|---|---|
| 2026-11-06 | stdlib lane | all 44 modules | readiness gate-8 evidence (wave 208, refreshed 2026-10-31) + `tools/coverage_scan.ps1` run on `main` at snapshot 120; 276 tail entries recorded in `tools/contract_exemptions.json` (259 EX-0 + 17 per-function ffi/thread/serialize/format EX-1/EX-2/EX-3); the nine format ANSI helpers carry constant clauses |

## Change protocol

- The module owner re-signs in the same commit as any public API or contract
  change in that module.
- New public functions need a clause or an EX-1..EX-5 record; EX-0 is closed.
- New modules need an owner, a sign-off, a probe set, and a memory/perf budget
  before merge.
- If coverage falls or an uncovered function is not exempt, the row becomes
  `pending` until the owner restores or exempts it.
