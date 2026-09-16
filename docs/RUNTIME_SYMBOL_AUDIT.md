# XIOM Runtime Symbol Audit (stdlib lane, 2026-09-16)

Scope: every `xiom_*` symbol DEFINED in `stdlib/runtime/**` (C, asm, headers)
versus every `xiom_*` extern DECLARED in `stdlib/xiom/**` (`fn xiom_...`).
Goal: classify the unbound remainder for the "runtime symbol bind-or-delete"
capability item (plan 9.3, ~194 unbound) and decide what, if anything, the
stdlib lane should bind.

## Method

1. Extract definitions: regex `xiom_[a-z0-9_]+` followed by `(` in
   `stdlib/runtime/*.c|*.h|*.asm` -> 322 unique symbols.
2. Extract stdlib declarations: `fn (xiom_[a-z0-9_]+)` in `stdlib/xiom/**`
   -> 138 unique names.
3. Unbound = definitions not declared by any stdlib module: **192**.
4. For each unbound symbol count: (a) literal references in `crates/**`,
   (b) literal references in `stdlib/xiom/**` + `examples/**`, (c) total
   textual occurrences across the runtime files (definition + uses).
5. Classify:
   - CODEGEN (crates literal refs > 0): compiler-emitted runtime ABI.
   - RUNTIME-INTERNAL (occurrences > 1, no crates/xi refs): used only by
     other runtime C/asm units (or within the defining unit).
   - DEFINITION-ONLY (occurrences == 1, no crates/xi refs): strongest
     delete candidates.

Results: **83 codegen-referenced, 83 runtime-internal, 20
definition-only candidates.**

## Disposition

- **Bind: nothing from the unbound set.** No user-facing capability gap was
  found: the 138 stdlib externs cover every runtime entry the stdlib uses
  (including CPU feature probing via `xiom_crypto_aesni_available` in
  `xiom.crypto`). The unbound families are the compiler's runtime ABI or
  dead code -- adding stdlib externs for them would freeze an internal ABI
  as public API.
- **Keep (83 codegen):** `xiom_ir_*` (IR emitter), `xiom_fn_*`,
  `xiom_fault_*`, `xiom_trap_*`, `xiom_ctx_*`, `xiom_guard_*`,
  `xiom_memset_dispatch`, `xiom_str_*` fast-path primitives, `xiom_none/all/
  contains/lookup/is_sorted/intern`, `xiom_*_to_string`, etc. These are
  referenced by compiler output or by the runtime's dispatch layer.
- **Keep (83 runtime-internal):** `xiom_asm_*` accelerated primitives
  (called from the dispatch layer), `__*tf3` companions, `xiom_f*` numeric
  helpers used by the compiler-rt entry points, trampoline/task/threadpool
  plumbing that other runtime units call.
- **Delete candidates (20, definition-only as of this audit):** listed
  below with defining file:line. CAVEAT before deleting: dynamic symbol
  lookup is invisible to this method -- `GetProcAddress`/`dlsym`, symbol
  names built from prefixes (`"xiom_hot_" + op`), and asm-level external
  references. The hot-reload family in particular is loaded by CLI tooling
  and should be confirmed by the compiler lane.

| symbol | defining file:line |
|---|---|
| xiom_asm_sha256_compress | xiom_runtime.c:60 |
| xiom_async_now_us | async_runtime.c:61 |
| xiom_channel_close | xiom_runtime.c:5379 |
| xiom_f128_norm_sig | fp128_helpers.c:76 |
| xiom_f256_is_one | xiom_runtime.c:5575 |
| xiom_guard_heap_depth | xiom_runtime.c:353 |
| xiom_guard_page_is_armed | xiom_runtime.c:459 |
| xiom_hot_enter | xiom_hot_reload.c:140 |
| xiom_hot_generation | xiom_hot_reload.c:94 |
| xiom_hot_get_version | xiom_hot_reload.c:177 |
| xiom_hot_init | xiom_hot_reload.c:83 |
| xiom_hot_is_stale | xiom_hot_reload.c:168 |
| xiom_hot_leave | xiom_hot_reload.c:148 |
| xiom_hot_register | xiom_hot_reload.c:100 |
| xiom_hot_restore_state_legacy | xiom_hot_reload.c:277 |
| xiom_hot_save_state_legacy | xiom_hot_reload.c:272 |
| xiom_hot_set_contract_checker | xiom_hot_reload.c:302 |
| xiom_hot_verify_contracts | xiom_hot_reload.c:309 |
| xiom_threadpool_shutdown | xiom_runtime.c:5501 |
| xiom_trampoline_clear_returned | xiom_runtime.c:752 |

Suggested actions (compiler lane owns `stdlib/runtime/**`):
1. Confirm none of the 20 is reached via dynamic names.
2. Either delete them or add a `/* AUDIT: intentionally-kept internal */`
   marker with the reason (e.g. kept as ABI-completeness or hot-reload
   tooling).
3. Optional: annotate the runtime build with `-Wunused-function` /
   `__attribute__((used))` discipline so this audit becomes mechanical.

Re-run the audit after runtime changes; the classifying script lives in the
session tooling (`stdlib_ws\runtime_syms.txt`, `runtime_audit.csv`,
`dead_strong.txt`) and is reproducible with the three greps above.
