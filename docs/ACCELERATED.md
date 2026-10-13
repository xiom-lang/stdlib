# Accelerated-path transparency (per-symbol markers)

Relay: REL-20261010-1550-website (accelerated-path transparency). This file
is the machine-greppable per-symbol marker inventory for the stdlib: which
surfaces route through NASM/SIMD-backed runtime code, what the portable
fallback is, and where the evidence lives. The registry/website API pages
can consume this file directly; the stdlib emits no separate generated-API
metadata for it yet.

## Marker legend

- `ACCEL` -- a hardware-accelerated path exists (NASM asm or CPU
  intrinsics) selected by CPUID at runtime.
- `FALLBACK` -- the portable implementation used when the feature is
  absent (same symbol, runtime branch) or when the compiler builds with
  `-DXIOM_NO_ASM` (fallback symbols with external linkage).
- `VERIFIED-BY` -- the in-repo evidence (KATs, smokes, probes).

## Runtime dispatch surfaces (runtime/xiom_runtime.c)

| Symbol | Marker | Backed by | Fallback | VERIFIED-BY |
|---|---|---|---|---|
| `xiom_memcpy_dispatch` | ACCEL | `xiom_asm_memcpy` (SSE2, n >= 16) | byte-by-byte loop in the dispatch body | corpus smokes over string/mem paths; `tools/probes/p_wave132_shapes.xi` |
| `xiom_memset_dispatch` | ACCEL | `xiom_asm_memset` (SSE2, n >= 16) | byte loop in the dispatch body | same as memcpy |
| `xiom_ct_compare_dispatch` | ACCEL | `xiom_asm_constant_time_compare` | no-NASM build: `xiom_runtime.c` FIPS-safe XOR accumulator (website-10) | `kat_crypto_*` smokes; probe 132 differential row |
| `xiom_sha256_compress_dispatch` | ACCEL | `xiom_shani_sha256_compress` (SHA-NI intrinsics, simd_runtime.c) | pure-XIOM SHA-256 compression in `xiom.crypto` (crypto.xi) | FIPS vectors in `kat_crypto_sha_*`; probe 132 KAT row |
| `xiom_aes128_encrypt_dispatch` | ACCEL | `xiom_asm_aes128_key_expand` + `xiom_asm_aes128_encrypt_block` (AES-NI) | returns 0; caller uses the portable AES | `kat_crypto_*`; probe 132 roundtrip row |
| `xiom_aes128_decrypt_dispatch` | ACCEL | `xiom_asm_aes128_decrypt_block` (AES-NI) | returns 0; portable AES | same as encrypt |
| `xiom_asm_available` / `xiom_asm_has_aesni` / `xiom_asm_has_sha_ni` | query | CPUID detection in the runtime | n/a | probe 132 query rows |

Asm symbol sets (runtime/mem_x86_64.asm, crypto_x86_64.asm,
context_switch.asm):

- mem: `xiom_asm_memcpy`, `xiom_asm_memset`, `xiom_asm_memcmp`,
  `xiom_asm_memmove`, `xiom_asm_bzero`, `xiom_asm_memcmp_ct`.
- crypto: `xiom_asm_aes128_encrypt_block`, `xiom_asm_aes128_decrypt_block`,
  `xiom_asm_aes128_key_expand`, `xiom_asm_constant_time_compare`.
- context: `xiom_asm_ctx_save`, `xiom_asm_ctx_load`, `xiom_asm_ctx_swap`,
  `xiom_asm_stack_init`.

SIMD surface (runtime/simd_runtime.c): `xiom_shani_sha256_compress` plus
the scalar fallback backend in the same file (used when SHA-NI is absent
or the build is `-DXIOM_NO_ASM`).

## Stdlib surface pairing

- `xiom.crypto.sha256(data)` -- runtime `xiom_sha256_hash` -> compress
  dispatch (SHA-NI when present, pure-XIOM otherwise).
- `xiom.crypto.sha256_accelerated(data)` -- documented pair; both
  branches currently call `sha256` (the runtime does the dispatch), so
  the two are equality-locked by probe 132 until the wrapper gains a
  distinct software path.
- `xiom.crypto.constant_time_compare(a, b)` -- ct-compare dispatch.
- `xiom.string.str_concat` and the byte builders -- `xiom_memcpy_dispatch`
  for bulk copies.

## Differential evidence

- Same-build differential: `tools/probes/p_wave132_shapes.xi` compares
  `sha256` vs `sha256_accelerated`, checks the FIPS `"abc"` vector
  through `sha256_hex`, runs the ct-compare dispatch against a naive
  comparison, and roundtrips AES through `crypto.aes_encrypt` /
  `aes_decrypt`. The memcpy/memset dispatch is exercised through the
  string/mem corpus smokes.
- Build-variant differential (asm vs `-DXIOM_NO_ASM`) is owned by the
  compiler lane's nasm/no-nasm builds (see the website-10 triage note in
  `docs/stdlib_session.md` block 103); the stdlib side keeps both
  variants correct by construction (same dispatch symbols).

## IO stream surfaces (playground-4 callout)

Not accelerated, but documented here because the relay asked for one
callout: `io.stdin()` returns the numeric fd 0 and never blocks --
console input uses `io.read_line` / `io.read_int` / `io.read_float`;
FILE*-based APIs use `io.stdin_file()`.
