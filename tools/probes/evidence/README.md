# Probe evidence archive (excluded from the probe runner)

Files here are kept for reference only. They are **not** part of the probe
gate: `run_smokes.ps1 -Corpus tools/probes` does not recurse, so this
subdirectory is invisible to it. Each file below fails on an older compiler,
is understood and superseded by a green probe, or is deliberate
(warning-only) evidence -- none is an open compiler defect. Open findings
live in `tools/known_failures/`.

| File | Why it is archived |
|---|---|
| `p_alg_ext_b.xi` | Duplicate of the green `p_alg_ext_a.xi`; the only defect is the omitted `use xiom.io;` (T001 undefined variable 'io'). |
| `p_char_count.xi` | Expects `Option[Char]` from the byte-domain `.char_at` Char form; the working idiom is locked by the green `p_charat_probe.xi`. |
| `p_glob_min.xi` | Uses an invalid `Bool as Str` cast; the modern form (`convert.bool_to_string`) is locked by the green `p_glob_parity.xi`. |
| `p_mime_lock.xi` | Calls `multipart_*` through `xiom.net.mime`; the symbols live in `xiom.net.multipart` and the green `p_mime_lock2.xi` locks them. |
| `p_optmatch.xi` | Uses leaf-qualified type spelling (`regex.Match`), which the resolver never supported; the supported `use <module>.<Type>;` idiom is locked by the green `p_optstruct.xi`. |
| `p_parttype.xi` | Same leaf-qualified-type issue plus a missing `use xiom.io;`; the parse side is covered by `smoke_net_http2`. |
| `p_regex_dbg.xi` | Written against the pre-`Result` `Regex.new` shape; superseded by the green `p_regex_dbg4.xi` / `p_regex_dbg5.xi`. |
| `p_regex_dbg2.xi` | Same pre-`Result` shape; superseded by `p_regex_dbg4/5`. |
| `p_regex_dbg3.xi` | Same pre-`Result` shape; superseded by `p_regex_dbg4/5`. |
| `p_puny_parity.xi` | Deliberate parity evidence: prints 10/16 shared vectors that differ by convention (ACE-label vs raw-payload), documented as NOT a bug; the convert-side convention is pinned by `smoke_convert_punycode`. |
| `p_regex_val.xi` | Asserts group captures. Group support is a documented honest stub (whole-match only); whole-match captures are locked by the green `p_regex_dbg5.xi`. |
| `p_sweep_single_param_raw.xi` | Raw single-parameter generated call set. Made codegen fail through R52 (R49-4); R54 `7837b194` fixed the codegen, but the generated arguments are unsafe to execute (null FFI pointers, `async_read_line` at EOF), so it is kept as crash evidence only. The runnable lock is `tools/probes/p_sweep_single_param.xi`. |
| `p_sweep_single_param.clang-crash.txt` | clang 22.1.8 crash header for the resolved R49-4 ISel failure (`0xC0000005` on `@__unsafe_block_77`). |
| `p_hash_probe.xi` | **RULED 2026-09-22** (R61, e2e_m117): interface-typed parameters erase to i64; an aggregate argument is now rejected loudly (`error[C001]: unsupported: interface-typed parameter ...`) instead of silently returning a wrong value. Archived until the interface ABI lands, then re-add as a green probe. |
| `p_e001_borrow_conservatism.xi` | **WARNING-ONLY EVIDENCE 2026-09-24**: minimal pattern for the relayed E001 conservatism (a `&local` call followed by a `&mut local` call warns even though the immutable borrow is complete). Compiles + runs green on v0.61.3; the deterministic reproduction is the 7 E001 lines in `smoke_collect_sparse`'s compile log (plus smoke_collect2a:63 and smoke_collect_threadpool:28) via `run_smokes.ps1 -Filter smoke_collect_sparse`. Compiler-lane intake pattern. |
| `p_r70_pending_shapes.xi` | **PENDING PIN 2026-09-24**: green on a local compiler-main R66-R72 build (compile 0, run 0) for the R67/R68/R69/R70/R72 shapes (for-in over Vec, `0..b`/`0..=b` with `use xiom.iter;`, ctor leaves with a user `*Result*` struct, nested extern, generic `T.to_str()`, fixed-array fn-literal indexed call); on the v0.61.3 pin the `for`-over-Vec lowering is broken, so it must NOT enter the gate. Promote to `tools/probes/` in the commit that bumps the pin to R66-R72. Still open on R72: `let` Vec[fn] literals and `Vec[fn].new()`+push (0xC0000005). |
| `p_fnref.xi` | **RULED 2026-09-22**: function-value identity is unspecified; the observed behaviour (distinct module-qualified fn values comparing equal) needs a language-spec decision, not a compiler fix. |
