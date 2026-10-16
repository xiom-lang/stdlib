# Crypto + Clock Audit (station-consumable surfaces)

Status line for `REL-20261016-1128-orbitdb` asks 4-5 ("a minimal audit line
for any crypto we consume"). Every row is locked by tests/probes in-tree on
the official v0.64.5 pin.

| surface | entry point | known-answer lock | trust notes |
|---|---|---|---|
| CSPRNG | `crypto.secure_random_bytes(n)`, `rand.random_bytes_crypto(n)` | `p_wave156_shapes` (len / nonzero / distinct), `smoke_stress_crypto_secure_random` | OS entropy (getrandom / BCryptGenRandom class) |
| HKDF-SHA-256 | `crypto.hkdf_sha256` (+ `kdf.hkdf_extract/expand`) | `kat_crypto_kdf_rfc5869` TC1-3 verbatim; `p_wave156` TC1 | RFC 5869; empty-salt / empty-info paths covered |
| PBKDF2-HMAC-SHA-256 | `crypto.pbkdf2`, `kdf.pbkdf2` | `p_wave156` KAT (`"password"` / `"salt"` / c=1) | RFC 7914 section 11 family |
| Argon2id | `crypto.argon2`, `kdf.argon2id` | `smoke_stress_crypto_argon2_basic`; `p_wave156` determinism | memory-hard; station-auth default candidate |
| SHA-2 family / HMAC | `crypto.sha256/sha512`, `crypto.hmac_sha256` | `kat_crypto_sha_multiblock`, `kat_crypto_hmac_rfc4231`, SHA KATs; 64-bit rotate helpers re-locked by `p_wave161` | the KDFs above are built on these |
| BLAKE2b-512 | `crypto.hash.crypto_hash_blake2b` | `p_wave161` RFC 7693 KAT (`"abc"`); wave 161 fixed a big-endian tail-block load (previously every tail-carrying digest was wrong, no KAT existed) | unkeyed; not a KDF |
| MD5 (legacy) | `crypto.md5` | wave-140 RFC-correctness fix (`REL-20261015-1942`) | do NOT use for auth; interop only |
| Monotonic clock | `time.monotonic_ms`, `time.Instant` | `p_wave156` (non-decreasing; `elapsed() >= 0`), `smoke_time_instant` | QueryPerformanceCounter / CLOCK_MONOTONIC; immune to wall-clock jumps |

Consumption rule (station): auth = argon2id or pbkdf2 (>= 600k iterations)
through the KDFs above; salts/nonces = CSPRNG; timeouts and replication-lag
metrics = the monotonic clock, never wall time. A crypto surface that is not
in this table is not audited -- file a bus item before consuming it.
