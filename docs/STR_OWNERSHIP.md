# STR / Malloc Buffer Ownership Convention

**Status:** normative for `stdlib/**` code review - **Created:** 2026-08-24
**Evidence base:** codegen `crates/xiom-codegen/src/call.rs` (Str.from_cstring
emitted inline), audit finding S4.1/BUG-table #6.

## 1. The rule

`Str.from_cstring(ptr)` is an **identity on the pointer** at the ABI: a XIOM
`Str` IS `i8*`, so the returned string wraps the exact buffer passed in.
There is NO copy and NO reference count.

Therefore:

1. **Ownership transfers at the call.** After `Str.from_cstring(buf)` returns,
   the caller must treat `buf` as consumed: never read it, never free it.
2. **Buffers handed to `from_cstring` must come from the module's allocator
   family (`malloc`/`xiom_alloc`)** -- not stack arrays, not `&buf[i]` of a
   local `[N]UInt8`, not pointers into Vec payloads (those are only legal via
   `from_utf8`/`from_bytes`, which COPY through `xiom_str_from_vec`).
3. **Buffer must be NUL-terminated** within its allocation; embedded NULs
   truncate silently (known representability limit, see section 5).

## 2. The canonical pattern (as used in core.xi `to_string`)

```text
unsafe {
  var buf = malloc(len + 1);
  // fill buf[0..len]; buf[len] = 0;
  return Str.from_cstring(buf);   // ownership moves into the Str
}
// no free(buf) here -- ever
```

## 3. Violations classes to check in review

| Class | Symptom | Check |
|---|---|---|
| use-after-handover | caller keeps using `buf` after wrapping | any read/write after the call |
| double-free | explicit `free(buf)` after wrapping | grep `free(` near `from_cstring` |
| stack buffer wrap | `&local_array[0]` passed | dangling Str once frame exits |
| non-malloc heap | buffer from realloc-family mismatched later | allocator pairing |
| unterminated | missing `buf[len] = 0` | strlen runs past allocation |

## 4. Audit scope (Phase 0 item 3)

All ~93 `extern "C"` sites plus every `Str.from_cstring` call site (~25+
modules: encoding/*, convert/*, os/env, os/os, ffi/errno, rand, ...). Each
site gets one of three annotations:

- `[XFER]` -- malloc'd, NUL-terminated, ownership moved (correct)
- `[COPY]` -- goes through `from_bytes/from_utf8` or an explicit byte-copy
  loop instead (correct; slight overhead)
- `[FIX]` -- violates section 3; file a defect row in the sweep triage log

ASAN verification of the whole corpus is deferred until the compiler stage-5
sanitizer infrastructure exists; until then this checklist is the gate.

## 5. Known limits (documented, not bugs)

- Embedded NUL bytes are unrepresentable through `from_cstring` paths;
  binary-ish text must stay in `Vec[UInt8]`.
- There is currently no deallocator wired into Str drop (the language has no
  destructors yet). Buffers adopted by Str are leaked by design today; when
  the compiler grows drop glue this convention becomes the contract that makes
  single-ownership freeing safe.
