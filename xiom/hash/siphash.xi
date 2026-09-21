// XIOM - Hash: SipHash
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.hash.siphash

// Faithful port of the canonical SipHash (Aumasson & Bernstein). Key is two
// 64-bit halves (k0, k1); c = compression rounds, d = finalization rounds:
// SipHash-2-4 is the standard, SipHash-1-3 the faster variant. Verified
// against a clang-built reference (2026-08-11): key 00..0f, SipHash-2-4 ""
// -> 0x726fdb47dd0e0e31, "a" -> 0x2ba3e8e9a71148ca; SipHash-1-3 "" ->
// 0xabac0158050fc4dc, "a" -> 0x1c2697ab786a6237. The flat hash.sip_hash
// name was taken by a DJB2 wrapper -- this is the real SipHash.
//
// 2026-09-12: core converted to a pointer+len signature so both Vec[UInt8]
// and Str inputs hash with ZERO copies (siphash24_str), and a per-process
// OS-entropy seeded key pair was added (siphash24_str_seeded) for the
// keyed-container default -- hash-DoS hardening. The reference vectors are
// re-asserted by the kat/vector probe and smoke.

// SipState is a named struct (not a UInt64 tuple): mixed Int/UInt64 tuples
// of the same arity collide in catalog codegen type resolution
// (COMPILER_BUGS.md quirk family).
type SipState = { v0: UInt64; v1: UInt64; v2: UInt64; v3: UInt64; }

// Logical (unsigned) right shift of a UInt64 by k bits.
// NOTE: two-var body -- a single-var `var mask = ...; return ... & mask;`
// body is mis-inlined by the compiler (the mask statement is dropped,
// COMPILER_BUGS.md BUG 15). Keep the two-var form.
fn _u64_shr(x: UInt64, k: Int) -> UInt64 {
  var shift = 64 - k;
  var mask: UInt64 = ((1 as UInt64) << shift) - 1;
  return (x >> k) & mask;
}

fn _rotl(x: UInt64, b: Int) -> UInt64 {
  return (x << b) | _u64_shr(x, 64 - b);
}

fn _read_u64_le(p: *UInt8, pos: Int) -> UInt64
  requires: true
{
  unsafe {
    var r: UInt64 = p[pos] as UInt64;
    r = r | ((p[pos + 1] as UInt64) << 8);
    r = r | ((p[pos + 2] as UInt64) << 16);
    r = r | ((p[pos + 3] as UInt64) << 24);
    r = r | ((p[pos + 4] as UInt64) << 32);
    r = r | ((p[pos + 5] as UInt64) << 40);
    r = r | ((p[pos + 6] as UInt64) << 48);
    r = r | ((p[pos + 7] as UInt64) << 56);
    return r;
  }
}

// One SipRound on the 4 state words (canonical ordering: the returned
// SipState holds (v0, v1, v2, v3) after the round).
fn _sipround(v0: UInt64, v1: UInt64, v2: UInt64, v3: UInt64) -> SipState {
  var a = v0 + v1;
  var b = _rotl(v1, 13) ^ a;
  var c = _rotl(a, 32);
  var d = v2 + v3;
  var e = _rotl(v3, 16) ^ d;
  var g = c + e;
  var h = _rotl(e, 21) ^ g;
  var j = b + d;
  var k = _rotl(b, 17) ^ j;
  var l = _rotl(j, 32);
  return SipState{ v0: g; v1: k; v2: l; v3: h; };
}

// Core: c compression rounds, d finalization rounds, key (k0, k1).
// Reads `len` bytes through `p` -- callers pass a Vec buffer pointer or a
// Str's byte pointer (Str is NUL-terminated but len is explicit, so the
// terminator is never hashed).
fn _siphash_core(p: *UInt8, len: Int, k0: UInt64, k1: UInt64, c: Int, d: Int) -> UInt64
  requires: len >= 0
{
  var v0: UInt64 = 0x736f6d6570736575 ^ k0;
  var v1: UInt64 = 0x646f72616e646f6d ^ k1;
  var v2: UInt64 = 0x6c7967656e657261 ^ k0;
  var v3: UInt64 = 0x7465646279746573 ^ k1;
  var b: UInt64 = ((len as UInt64) & 0xFF) << 56;
  var pos: Int = 0;
  while pos + 8 <= len {
    var m = _read_u64_le(p, pos);
    v3 = v3 ^ m;
    var r: Int = 0;
    while r < c {
      var sr = _sipround(v0, v1, v2, v3);
      v0 = sr.v0;
      v1 = sr.v1;
      v2 = sr.v2;
      v3 = sr.v3;
      r = r + 1;
    }
    v0 = v0 ^ m;
    pos = pos + 8;
  }
  var left = len - pos;
  unsafe {
    if left >= 7 {
      b = b | ((p[pos + 6] as UInt64) << 48);
      b = b | ((p[pos + 5] as UInt64) << 40);
      b = b | ((p[pos + 4] as UInt64) << 32);
      b = b | ((p[pos + 3] as UInt64) << 24);
      b = b | ((p[pos + 2] as UInt64) << 16);
      b = b | ((p[pos + 1] as UInt64) << 8);
      b = b | (p[pos] as UInt64);
    } elif left == 6 {
      b = b | ((p[pos + 5] as UInt64) << 40);
      b = b | ((p[pos + 4] as UInt64) << 32);
      b = b | ((p[pos + 3] as UInt64) << 24);
      b = b | ((p[pos + 2] as UInt64) << 16);
      b = b | ((p[pos + 1] as UInt64) << 8);
      b = b | (p[pos] as UInt64);
    } elif left == 5 {
      b = b | ((p[pos + 4] as UInt64) << 32);
      b = b | ((p[pos + 3] as UInt64) << 24);
      b = b | ((p[pos + 2] as UInt64) << 16);
      b = b | ((p[pos + 1] as UInt64) << 8);
      b = b | (p[pos] as UInt64);
    } elif left == 4 {
      b = b | ((p[pos + 3] as UInt64) << 24);
      b = b | ((p[pos + 2] as UInt64) << 16);
      b = b | ((p[pos + 1] as UInt64) << 8);
      b = b | (p[pos] as UInt64);
    } elif left == 3 {
      b = b | ((p[pos + 2] as UInt64) << 16);
      b = b | ((p[pos + 1] as UInt64) << 8);
      b = b | (p[pos] as UInt64);
    } elif left == 2 {
      b = b | ((p[pos + 1] as UInt64) << 8);
      b = b | (p[pos] as UInt64);
    } elif left == 1 {
      b = b | (p[pos] as UInt64);
    }
  }
  v3 = v3 ^ b;
  var r2: Int = 0;
  while r2 < c {
    var sr2 = _sipround(v0, v1, v2, v3);
    v0 = sr2.v0;
    v1 = sr2.v1;
    v2 = sr2.v2;
    v3 = sr2.v3;
    r2 = r2 + 1;
  }
  v0 = v0 ^ b;
  v2 = v2 ^ 0xff;
  var r3: Int = 0;
  while r3 < d {
    var sr3 = _sipround(v0, v1, v2, v3);
    v0 = sr3.v0;
    v1 = sr3.v1;
    v2 = sr3.v2;
    v3 = sr3.v3;
    r3 = r3 + 1;
  }
  return v0 ^ v1 ^ v2 ^ v3;
}

/// Canonical SipHash-2-4 over a byte buffer.
pub fn siphash24(data: &Vec[UInt8], k0: UInt64, k1: UInt64) -> UInt64
  requires: true  // whole-body unsafe core call (T007)
{
  unsafe {
    return _siphash_core(data.as_ptr(), data.len(), k0, k1, 2, 4);
  }
}

/// SipHash-1-3 (faster variant, same security level for MAC use cases).
pub fn siphash13(data: &Vec[UInt8], k0: UInt64, k1: UInt64) -> UInt64
  requires: true  // whole-body unsafe core call (T007)
{
  unsafe {
    return _siphash_core(data.as_ptr(), data.len(), k0, k1, 1, 3);
  }
}

/// SipHash-2-4 with a zero key (convenience; NOT secure -- use real keys).
pub fn siphash24_zerokey(data: &Vec[UInt8]) -> UInt64
  requires: true  // whole-body unsafe core call (T007)
{
  unsafe {
    return _siphash_core(data.as_ptr(), data.len(), 0, 0, 2, 4);
  }
}

/// SipHash-2-4 over a Str's bytes with an explicit key, zero copies.
pub fn siphash24_str(s: Str, k0: UInt64, k1: UInt64) -> UInt64
  requires: true  // whole-body unsafe core call (T007)
{
  unsafe {
    return _siphash_core(s as *UInt8, s.len(), k0, k1, 2, 4);
  }
}

// ============================================================================
// Per-process seeded hashing (hash-DoS hardening for keyed containers)
// ============================================================================

extern "C" {
  fn xiom_os_entropy(buf: *UInt8, len: Int) -> Int;
  fn time(t: *Int) -> Int;
}

var _sip_keys_ready: Bool = false;
var _sip_k0: UInt64 = 0;
var _sip_k1: UInt64 = 0;

fn _u64_from_bytes(buf: &Vec[UInt8], off: Int) -> UInt64 {
  var r: UInt64 = buf[off] as UInt64;
  var i = 1;
  while i < 8 {
    r = r | ((buf[off + i] as UInt64) << (i * 8));
    i = i + 1;
  }
  return r;
}

// Lazily seed the process-wide SipHash keys from OS entropy (ProcessPrng/
// RtlGenRandom or /dev/urandom via the runtime). Degraded fallback when no
// OS source answers: a time-derived key -- still per-process variable, but
// predictable; documented in STDLIB_CONTAINER_TUNING.md.
fn _sip_ensure_keys() {
  if _sip_keys_ready { return; };
  _sip_keys_ready = true;
  var kb = Vec[UInt8].new();
  var i = 0;
  while i < 16 {
    kb.push(0u8);
    i = i + 1;
  }
  var got: Int = 0;
  unsafe {
    got = xiom_os_entropy(kb.as_mut_ptr(), 16);
  }
  if got == 16 {
    _sip_k0 = _u64_from_bytes(kb, 0);
    _sip_k1 = _u64_from_bytes(kb, 8);
  } else {
    var secs: Int = 0;
    unsafe {
      secs = time(0);
    }
    let s64 = secs as UInt64;
    _sip_k0 = s64 * 0x5851F42D4C957F2D;
    _sip_k1 = (s64 ^ 0x2545F4914F6CDD1D) * 0x5851F42D4C957F2D;
  };
}

/// SipHash-2-4 over a Str using the process-wide OS-seeded key pair.
/// This is the default hasher for Str-keyed containers (StringMap).
pub fn siphash24_str_seeded(s: Str) -> UInt64 {
  _sip_ensure_keys();
  return siphash24_str(s, _sip_k0, _sip_k1);
}
