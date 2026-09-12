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

---

## 6. Site audit (2026-08-25, phase T4)

Full enumeration over stdlib/xiom/**/*.xi: 74 files with extern "C"
blocks, ~45 distinct from_cstring call sites. Classification:

### [XFER-malloc] -- correct, malloc'd + NUL + handed over
core/core.xi (to_string, to_int_from_str helpers), string/string.xi
(concat/slice/trim/repeat/replace family), string/case.xi, string/casefold,
string/unescape, string/normalize, encoding/encoding.xi (hex/base64/base32
encoders), encoding/{percent,base64,base32,idna,punycode,ascii85},
convert/{percent,base16,base64,base64url,base32,ascii85,tostring,string?},
misc/{levenshtein,soundex,glob,misc}, text/{similarity,diff}, format/fmt,
format/textual, string/builder.xi (sb_to_str), os/args.xi copy_c_string.

### [XFER-vec] -- adopts a LOCAL Vec's buffer after push(0)
Pattern: `result.push(0); return Str.from_cstring(result.data);`
Used by several encoders' hex-output paths (e.g., crypto sha256_hex).
SAFE today because the Vec is local and last-touched at adoption, but this
is a fragile subclass: if Vec grows destructors or shares buffers, these
become use-after-free generators. RULE: never touch the Vec after
adoption; prefer copying into malloc'd storage when touching the file.
MIGRATION: convert to [XFER-malloc] opportunistically.

### [BORROW] -- aliases memory owned elsewhere (do not free)
os/os.xi cstr() (Str -> *UInt8 cast for FFI calls; callee must not retain),
convert/cstring.xi from_cstring(ptr) wrapping CALLER-provided C pointers
(documented API for interop), os/args.xi reads runtime argv then copies
([COPY] on exit).

### Allocator plumbing (N/A to Str convention)
alloc/alloc.xi (GlobalAlloc family), ffi/* (pass-through), simd/simd.xi
(aligned scratch alloc/free pairs), compress/* (no heap use post-fix).

### Violations found
NONE. Zero double-frees of adopted buffers; zero stack-buffer wraps; every
malloc'd handover site terminates with an explicit NUL. The one systemic
caveat is [XFER-vec] above plus the standing no-destructor leak posture
(section 5).

Counts: extern "C" blocks = 74 files; from_cstring sites = 45;
malloc call sites = 96; free call sites = 61 (allocator-plumbing-heavy
files account for the gap; no orphaned frees detected against XFER sites).
