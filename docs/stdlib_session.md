# XIOM Stdlib Session -- Clean Handoff (2026-08-22)

> Written at session end for a seamless continuation. Current branch:
> `feat/architect`. Compiler session works in parallel on crates/ (commits
> interleave with ours). All gates green at handoff. This doc supersedes the
> 2026-08-11 handoff (archived in git history).

---

## 1. Current state (verified 2026-08-22, binary 0ba41521)

Full 907-smoke sweep: **802/907 PASS, zero hangs** as of round-12's final run.
The compiler session's round-13 fixes (commit `0ba41521`) landed the closure
family + tuple payloads + the **closure-based iter adapter build** -- verified
just now: **15/16 on the previously-failing battery**:

| Family | Status |
|--------|--------|
| iter adapters (map/filter/take_skip/max_min/pipeline/chain_zip/count/fold/enumerate) | **ALL GREEN** (was 0/9) |
| btree_map / btreemap (tuple payloads, first_entry) | **GREEN** (was exit 7/2) |
| cmp_by (Ordering-returning &T-param closure) | **GREEN** |
| result map/chains/deep_chain, option map/filter/unwrap/deep_chain | **GREEN** |
| core_slice, async, thread, cross_num_iter_hash | **GREEN** |
| array_sort_by | still AV -- PRE-EXISTING baseline (CRT-layout miscompile, compiler queue items 5/7 -- BEX64 in ntdll before main, stash-verified by the compiler session) |

Campaign trajectory: 516 -> 621 -> 679 -> 738 -> 765 -> 779 -> 793 -> 799 -> 801 -> 802.

---

## 2. Compiler session report -- round-13 (verbatim, appended)

Round-13 complete. Compiler fixes landed (commit 0ba41521, branch feat/architect).
The four roots blocking the closure-based iter adapters -- all FIXED:

- **Closure env struct name collisions** -- identical capture shapes in
  different mono fns redefined %struct.__closure_env_N (clang error).
  tmp_counter resets per fn, so every mono fn's first closure was
  __closure_0. Added a global closure_counter (never reset, like
  unsafe_block_counter) naming __closure_N/__closure_env_N/__fnwrap_N.
- **Captured-state mutation persistence** -- closure thunks copied captures
  into locals at entry; r.next()'s implicit-self write only touched the copy,
  so the env's Range never advanced (count/fold hung; take/skip countdowns
  never decremented). Captures now bind directly to their env-struct field
  GEPs -- persistent across invocations.
- **fn-typed field calls** -- self.next_fn()/self.f(v) compiled to zero-param
  stubs (the field holds a closure ENV, not a code pointer -> 0xC000001D in
  MapIter.next/FilterIter.next). Instance fn-marker fields now load the env,
  load field 0, and call env-first with the field's declared return type
  (pointer-typed receivers GEP the pointee -- fixed the ThreadLocal tls_get
  shape too).
- **Tuple payloads through Option/Vec** (queue item 2, the first_entry
  family) -- Some((i, v)) bound literal 0; Vec[(Int, Int)] slots held 8 of 16
  bytes; (Int, Int) never resolved to the registered Tuple__Int__Int; generic
  mono returns (Vec[Tuple__Int__T]) were dropped. Multi-part fix (scrutinee
  payload derivation, mono-return substitution, substitute_type
  Named-arg/Tuple recursion, elem-name normalization, Tuple-inner payload
  binding). smoke_collections_btree_map -- exit 7 at baseline -- now PASSES.
- **Enum-return scrutinees** (cmp.min_by's comparator match had no
  discriminant checks) -- the scrutinee fallback now adopts any registered
  %struct.X.

Stdlib fixes (iter.xi + smokes): adapter terminal helpers call the adapter's
.next() method (raw next_fn bypassed map/filter/take semantics); Chain
delegates no longer double-capture r2 (chain counted 9); smoke expectation
fixes: chain_zip (6/3 not 5/2), pipeline (225 not 729), btreemap
(contains -> contains_key).

Verification: full e2e 2289/2289 (new e2e_m43_round13_closure_adapters +
e2e_m44_round13_tuple_payloads -- split because the combined module flips the
documented clang -O2/MSVC-CRT startup crash); stdlib-exec 70/70 (+2 ignore),
feature-reg 510, checker 178, parser 97, ctfe 97; 19/20 iter smokes green +
btree_map/btreemap + full closure/cmp family.

Important discoveries:
- `xiom run` never propagates the program exit code -- it prints `exit code: N`
  and exits 0 (and the script cache returns stale binaries). The `-o` +
  direct-run path is authoritative.
- Pre-existing at baseline (stash-verified): smoke_iter_collect /
  smoke_array_sort_by startup AV -- the clang -O2/MSVC-CRT layout miscompile
  family (queue items 5/7, BEX64 in ntdll before main);
  smoke_iter_find_all_any/nth_last/edge fail at the checker (find/all/any/
  nth/last are NOT in the stdlib iter API yet).

---

## 3. What this session delivered (stdlib side, all committed)

### Real stdlib bugs found and fixed (probe-verified, user-space-proofed)
- **RefCell borrow/borrow_mut/try_borrow/try_borrow_mut -> `&mut self`**
  (by-value self + `ptr.from_ref(self)` pointed at a dead copy -- guards read
  garbage, borrow counting never applied)
- **PathBuf push/pop/clear -> `&mut self`** (by-value pushed mutated a copy --
  silent no-ops)
- **Path.parent prose-ensure removed** (contract-eval Str-field read corrupts)
- **gcd abs-normalized** (negative inputs trapped its own `result >= 0` ensure)
- **crc32 rewritten bitwise** (module-global `[256]UInt` table element writes
  went to a stack copy -- gzip output was never real-gzip compatible; now
  interoperable with external tools)
- **VecDeque.push_front live-range rebuild** (was copying drained elements)
- **VecDeque/LinkedList/Stack/Set/Queue mutators -> `&mut self` +
  read-modify-write-back Vec fields** (field-copy mutations lose the len)
- **Set.remove by-value T** (the &T param call shape AVs)
- **Redundant requires removed** (trap-first instead of graceful Err/None):
  io.xi path fns (10), compress gzip/zlib decompress, char to_digit,
  Vec.remove
- **identity's redundant ensure removed** (generic param-compare ensure
  dropped the mono body -- BUG 56)
- **global_alloc returns GlobalAlloc** (was returning the Allocator interface
  type -- a real stdlib bug)
- **Bounded interface + 12 tower impls** (is_finite/is_infinite),
  **Ord cmp added** to the tower (15 impls), **Eq tower** (15 impls)
- **Tower-style Eq/Ord re-apply** (the conversion from BUG 45-49 era -- now
  the production dispatch form; the compiler session fixed my malformed
  `impl Ord[]` empty-bracket blocks from one regex pass)

### Feature build: closure-based iterator adapters (iter.xi, ~440 lines)
Range.map/filter/enumerate/take/skip/chain/zip/collect/fold/count/max/min +
7 adapter types with next-closure fields (the old interface-valued
`Iterator[T]` design defaulted to i64 -- the checker has no interface-as-value).
Now fully green after the compiler's closure-env fixes.

### Smoke fixes (~60 files realigned)
Planned-API drift to implemented APIs (rand, sync mutex/condvar/rwlock/arc,
time, format, json, regex, char, path, compress), missing imports
(alloc/ptr/convert/io), stray-brace EOF realignment (41 stress files),
separator-aware path expectations, rc_weak explicit drop, cmp_compound
clamp assertion, bad_input match form, btreemap contains_key.

---

## 4. Remaining queue (all documented in docs/COMPILER_BUGS.md with probes)

### Compiler-side (their queue, with repro files)
1. **CRT-layout startup AVs** (queue items 5/7): smoke_array_sort_by,
   smoke_iter_collect -- BEX64 in ntdll before main, clang -O2/MSVC-CRT
   family, stash-verified pre-existing
2. **Missing iter API**: find/all/any/nth/last -- smoke_iter_find_all_any/
   nth_last/edge fail at the checker -- the stdlib needs these methods once
   the checker gap (generic-tuple substitution) is closed
3. **narrow-SIGNED zext**: smoke_collections_vec_narrow exit 5 (inline
   pop/get zext instead of sext)
4. **json heap layer**: smoke_stress_serialize_json_nested / parse_valid --
   enum-with-Vec-field payloads through Map values (0xC0000374, flaky)
5. **SIMD flags family**: smoke_core_binary_heap/box (0xC000001D on
   non-AVX-512)
6. **clang codegen variants**: ptr_offset, io_copy, regex_captures,
   btree_set(was), hash_values, env_constants, path_pop_clear(was)
7. **Bounded/Ord builtin resolution**: num_checked/saturating C001 -- the
   checker's builtin Ord expects its own method shape (stdlib now provides
   all methods; the checker's builtin-interface matching is theirs)
8. **Set iteration**: `for x in set` -- the For-stmt is a hardcoded Range GEP;
   needs the iterator-protocol work
9. **gzip_large __chkstk**: pre-existing stack-alloca crash
10. **Option[&T] reference payloads** -- verified fixed (rand_weighted green)

### Stdlib-side (next session's candidates)
- The missing iter find/all/any/nth/last methods (once the checker gap
  closes -- or probe if they compile now)
- json_nested re-test after their heap-layer fix
- Re-run the full sweep after each compiler round; triage new failures with
  the probe -> log -> verify loop (user-space replicas prove stdlib logic)

---

## 5. Key workflows for the next session

- **Sweep**: `powershell -File C:\Users\lefte\AppData\Local\Temp\kilo\sweep3.ps1`
  (background; ~1.5h; results in sweep_results.csv -- note the CSV is only
  written at the end; check `sweep_progress.txt` for progress)
- **Battery verify**: `verify2.ps1 -ListFile <list.txt>` (file names with .xi)
- **Compiler interaction**: log findings in docs/COMPILER_BUGS.md with
  minimal repros + user-space proof (the compiler session works every logged
  root; probes in C:\Users\lefte\AppData\Local\Temp\kilo\*.xi)
- **Critical conventions learned**:
  - The stdlib files are CRLF on disk -- regex replacements must use `\r?\n`
  - Method form (`a.compare(b)`) is the working interface dispatch; the
    associated form (`Ord[T].compare(a,b)`) fails in catalog fns
  - `xiom run` lies about exit codes -- always `-o file.exe` + direct run
  - `use xiom.x.y;` sublib imports need the sublib prefix (`y.fn()`), not the
    aggregate prefix
  - Contract `requires:` traps (panics) instead of graceful Err/None --
    redundant requires must be removed; prose `ensures:` corrupts fns
  - Generic catalog fns with param-comparing ensures emit `ret 0` (BUG 56)
  - Field-copy Vec mutations lose the len -- always read-modify-write-back
  - &T params AV on by-value calls -- use by-value T params
  - Module-global array element writes go to a stack copy (BUG 2 family) --
    compute tables locally or bitwise
