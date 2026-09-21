// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
/* ============================================================================
 * fp128 (IEEE 754 quadruple / Float128) soft-float helpers
 * (BUG 13 fix -- 2026-08-11)
 *
 * clang emits libcalls (__divtf3, __multf3, __trunctfdf2, ...) for Float128
 * arithmetic on x86-64; the Windows compiler-rt builtins library ships only a
 * minimal subset. These helpers provide the full set a XIOM program can hit.
 *
 * Layout (IEEE 754 binary128, little-endian halves):
 *   hi (u64): sign:1 | exponent:15 | significand-hi:48
 *   lo (u64): significand-lo:64          (112-bit significand total)
 * Bias = 16383. Normal value = (-1)^s * 2^(e-16383) * 1.mantissa.
 *
 * The significand is manipulated as an unsigned __int128 (113 bits: implicit
 * bit at position 112). __int128 is natively supported by clang on x86-64.
 * ==========================================================================*/
#include <stdint.h>
#include <string.h>

typedef struct { uint64_t lo; uint64_t hi; } xiom_f128;

#define XIOM_F128_EXP_MASK 0x7FFFU
#define XIOM_F128_BIAS 16383
#define XIOM_F128_SIG_BITS 113
#define XIOM_F128_MAN_HI_MASK 0x0000FFFFFFFFFFFFULL

static int xiom_f128_isnan(xiom_f128 f) {
    uint32_t e = (uint32_t)((f.hi >> 48) & XIOM_F128_EXP_MASK);
    uint64_t mhi = f.hi & XIOM_F128_MAN_HI_MASK;
    return e == XIOM_F128_EXP_MASK && (mhi | f.lo) != 0;
}
static int xiom_f128_isinf(xiom_f128 f) {
    uint32_t e = (uint32_t)((f.hi >> 48) & XIOM_F128_EXP_MASK);
    uint64_t mhi = f.hi & XIOM_F128_MAN_HI_MASK;
    return e == XIOM_F128_EXP_MASK && (mhi | f.lo) == 0;
}
static int xiom_f128_iszero(xiom_f128 f) {
    return ((f.hi & 0x7FFFFFFFFFFFFFFFULL) | f.lo) == 0;
}

static xiom_f128 xiom_f128_pack(int sign, int exp, uint64_t mhi, uint64_t mlo) {
    xiom_f128 f;
    f.hi = ((uint64_t)(sign & 1) << 63)
         | ((uint64_t)(exp & XIOM_F128_EXP_MASK) << 48)
         | (mhi & XIOM_F128_MAN_HI_MASK);
    f.lo = mlo;
    return f;
}

/* Round a 128-bit significand (implicit bit at 112, plus `extra_bits` guard
 * bits BELOW it) down to 113 bits with round-to-nearest-even and pack. */
static xiom_f128 xiom_f128_round_pack(int sign, int exp, unsigned __int128 sig, int extra_bits) {
    if (extra_bits <= 0) {
        /* already exactly 113 bits (bit 112 set) -- no rounding needed */
        return xiom_f128_pack(sign, exp, (uint64_t)(sig >> 64), (uint64_t)sig);
    }
    int drop = extra_bits; /* bits below the 113-bit significand */
    unsigned __int128 mask = (((unsigned __int128)1) << drop) - 1;
    unsigned __int128 guard = (sig >> (drop - 1)) & 1;
    unsigned __int128 sticky = (sig & mask) & ~(((unsigned __int128)1) << (drop - 1));
    unsigned __int128 rounded = sig >> drop;
    if (guard) {
        unsigned __int128 lsb = rounded & 1;
        if (sticky || lsb) rounded += 1;
    }
    /* rounded now has 113 bits; renormalize if it grew to 114 */
    if (rounded >> 113) {
        rounded >>= 1;
        exp += 1;
    }
    if (rounded == 0) exp = 0;
    return xiom_f128_pack(sign, exp, (uint64_t)(rounded >> 64), (uint64_t)rounded);
}

/* ============================ ADD / SUB =================================== */
/* Both operands unpacked; returns a+b or a-b with exact IEEE rounding. */
static xiom_f128 xiom_f128_addsub(xiom_f128 a, xiom_f128 b, int subtract) {
    if (xiom_f128_isnan(a)) return a;
    if (xiom_f128_isnan(b)) return b;
    if (xiom_f128_isinf(a)) {
        if (xiom_f128_isinf(b) && ((a.hi ^ b.hi) >> 63) == (uint64_t)subtract) {
            /* inf - inf or -inf + inf -> NaN */
            xiom_f128 nan = a; nan.hi = (nan.hi & 0x8000000000000000ULL) | 0x7FFF000000000000ULL; nan.lo = 1; return nan;
        }
        return a;
    }
    if (xiom_f128_isinf(b)) return b;

    int sa = (int)(a.hi >> 63), sb = (int)(b.hi >> 63);
    /* effective signs: for subtraction, flip b's sign */
    if (subtract) sb ^= 1;
    int ea = (int)((a.hi >> 48) & XIOM_F128_EXP_MASK);
    int eb = (int)((b.hi >> 48) & XIOM_F128_EXP_MASK);
    uint64_t ma_hi = a.hi & XIOM_F128_MAN_HI_MASK;
    uint64_t mb_hi = b.hi & XIOM_F128_MAN_HI_MASK;
    if (ea == 0 && ma_hi == 0 && a.lo == 0) { a.hi = (uint64_t)sa << 63; return b.hi == 0 ? (sa == sb ? a : xiom_f128_pack(0, 0, 0, 0)) : b; }
    if (eb == 0 && mb_hi == 0 && b.lo == 0) { b.hi = (uint64_t)sb << 63; return a.hi == 0 ? (sa == sb ? a : xiom_f128_pack(0, 0, 0, 0)) : a; }

    /* Build 113-bit significands (implicit bit at bit 112) */
    unsigned __int128 ma = ((unsigned __int128)1 << 112) | ((unsigned __int128)ma_hi << 64) | a.lo;
    unsigned __int128 mb = ((unsigned __int128)1 << 112) | ((unsigned __int128)mb_hi << 64) | b.lo;

    if (sa == sb) {
        /* same sign -> magnitude add */
        int e = ea > eb ? ea : eb;
        if (ea < eb) ma >>= (eb - ea); else if (eb < ea) mb >>= (ea - eb);
        unsigned __int128 sum = ma + mb;
        int n = 128;
        unsigned __int128 s = sum;
        while ((s >> 127) == 0) { s <<= 1; n--; }
        /* s has bit 127 set; shift to bit 112 */
        sum = s >> 15;
        e += n - 113;
        return xiom_f128_round_pack(sa, e, sum, 0);
    } else {
        /* opposite signs -> magnitude subtract */
        int ebig = ea, esmall = eb;
        unsigned __int128 big = ma, small = mb;
        if (ma < mb) { big = mb; small = ma; ebig = eb; esmall = ea; }
        int diff_exp = ebig - esmall;
        if (diff_exp >= 128) {
            return xiom_f128_pack(big ? (int)(big >> 127) & 1 : 0, 0, 0, 0);
        }
        unsigned __int128 diff = big - (small >> diff_exp);
        if (diff == 0) return xiom_f128_pack(0, 0, 0, 0);
        int sres = (ebig == ea) ? sa : sb;
        /* renormalize */
        int n = 128;
        unsigned __int128 s = diff;
        while ((s >> 127) == 0) { s <<= 1; n--; }
        int renorm = 127 - 112;
        diff = s >> renorm;
        int e2 = ebig - (n - 113);
        if (diff == 0) return xiom_f128_pack(0, 0, 0, 0);
        return xiom_f128_round_pack(sres, e2, diff, 0);
    }
}

/* ============================ MUL ========================================= */
static xiom_f128 xiom_f128_mul_impl(xiom_f128 a, xiom_f128 b) {
    if (xiom_f128_isnan(a)) return a;
    if (xiom_f128_isnan(b)) return b;
    int sa = (int)(a.hi >> 63), sb = (int)(b.hi >> 63);
    int sres = sa ^ sb;
    if (xiom_f128_isinf(a) || xiom_f128_isinf(b)) {
        if (xiom_f128_iszero(a) || xiom_f128_iszero(b)) {
            xiom_f128 nan = xiom_f128_pack(sres, 0x7FFF, 0, 1); return nan;
        }
        return xiom_f128_pack(sres, 0x7FFF, 0, 0);
    }
    if (xiom_f128_iszero(a) || xiom_f128_iszero(b)) return xiom_f128_pack(sres, 0, 0, 0);
    int ea = (int)((a.hi >> 48) & XIOM_F128_EXP_MASK);
    int eb = (int)((b.hi >> 48) & XIOM_F128_EXP_MASK);
    unsigned __int128 ma = ((unsigned __int128)1 << 112) | ((unsigned __int128)(a.hi & XIOM_F128_MAN_HI_MASK) << 64) | a.lo;
    unsigned __int128 mb = ((unsigned __int128)1 << 112) | ((unsigned __int128)(b.hi & XIOM_F128_MAN_HI_MASK) << 64) | b.lo;
    /* 113x113 -> 226-bit product: split into 64-bit halves */
    uint64_t a0 = (uint64_t)ma, a1 = (uint64_t)(ma >> 64);
    uint64_t b0 = (uint64_t)mb, b1 = (uint64_t)(mb >> 64);
    /* 64x64 -> 128 */
    unsigned __int128 p00 = (unsigned __int128)a0 * b0;
    unsigned __int128 p01 = (unsigned __int128)a0 * b1;
    unsigned __int128 p10 = (unsigned __int128)a1 * b0;
    unsigned __int128 p11 = (unsigned __int128)a1 * b1;
    /* assemble 256-bit product as (t3 t2 t1 t0) 64-bit words */
    uint64_t t0 = (uint64_t)p00;
    unsigned __int128 mid = (p00 >> 64) + (uint64_t)p01 + (uint64_t)p10;
    uint64_t t1 = (uint64_t)mid;
    unsigned __int128 hi2 = (mid >> 64) + (p01 >> 64) + (p10 >> 64) + p11;
    uint64_t t2 = (uint64_t)hi2;
    uint64_t t3 = (uint64_t)(hi2 >> 64);
    /* BUG 13 fix: extract the significand from the FULL product. P = ma*mb
     * in [2^224, 2^226); the 113-bit significand = P >> 112 (P < 2^225) or
     * P >> 113 (P >= 2^225). The old code built prod from t2:t1 only (bits
     * 64..191) -- dropping bits 192..225 -- so 1000*2.5 produced 0. Also the
     * exponent was missing a BIAS term.
     * value = 2^(ea+eb-2B) * P/2^224; with m = P/2^113 (P >= 2^225):
     * value = 2^(ea+eb-2B+1) * m/2^112 -> e = ea+eb-B+1 (biased). */
    int e = ea + eb - XIOM_F128_BIAS;
    unsigned __int128 prod;
    if (t3 >> 33) { /* P >= 2^225 */
        prod = ((unsigned __int128)t3 << 79) | ((unsigned __int128)t2 << 15) | (t1 >> 49);
        e += 1;
    } else {
        prod = ((unsigned __int128)t3 << 80) | ((unsigned __int128)t2 << 16) | (t1 >> 48);
    }
    return xiom_f128_round_pack(sres, e, prod, 0);
}

/* ============================ DIV ========================================= */
static unsigned __int128 xiom_f128_udiv_114(unsigned __int128 num, unsigned __int128 den) {
    /* num < den (both < 2^113); produce 114 quotient bits (113 + 1 guard).
     * BUG 13 fix: the remainder can exceed 2^128 (the shifted-out top bit
     * contributes 2^128) -- track it as an explicit high bit (`hi`) instead of
     * dropping it (the old `num -= den` on a carry corrupted the low digits:
     * 10/2 gave 13). */
    unsigned __int128 q = 0;
    int hi = 0; /* bit 128 of the remainder */
    int i;
    for (i = 0; i < 114; i++) {
        int top = (int)(num >> 127);
        num <<= 1;
        q <<= 1;
        if (top || num >= den) {
            num -= den;
            if (top) hi = 1; /* 2^128 + num - den keeps bit 128 set */
            q |= 1;
        }
        (void)hi;
    }
    return q;
}

static xiom_f128 xiom_f128_div_impl(xiom_f128 a, xiom_f128 b) {
    if (xiom_f128_isnan(a)) return a;
    if (xiom_f128_isnan(b)) return b;
    int sa = (int)(a.hi >> 63), sb = (int)(b.hi >> 63);
    int sres = sa ^ sb;
    if (xiom_f128_isinf(a)) {
        if (xiom_f128_isinf(b)) { xiom_f128 nan = xiom_f128_pack(sres, 0x7FFF, 0, 1); return nan; }
        return xiom_f128_pack(sres, 0x7FFF, 0, 0);
    }
    if (xiom_f128_iszero(b)) {
        if (xiom_f128_iszero(a)) { xiom_f128 nan = xiom_f128_pack(sres, 0x7FFF, 0, 1); return nan; }
        return xiom_f128_pack(sres, 0x7FFF, 0, 0);
    }
    if (xiom_f128_iszero(a)) return xiom_f128_pack(sres, 0, 0, 0);
    if (xiom_f128_isinf(b)) return xiom_f128_pack(sres, 0, 0, 0);
    int ea = (int)((a.hi >> 48) & XIOM_F128_EXP_MASK);
    int eb = (int)((b.hi >> 48) & XIOM_F128_EXP_MASK);
    unsigned __int128 ma = ((unsigned __int128)1 << 112) | ((unsigned __int128)(a.hi & XIOM_F128_MAN_HI_MASK) << 64) | a.lo;
    unsigned __int128 mb = ((unsigned __int128)1 << 112) | ((unsigned __int128)(b.hi & XIOM_F128_MAN_HI_MASK) << 64) | b.lo;
    /* ma/mb in [2^112, 2^113). Ensure ma < mb by shifting ma right once.
     * value = 2^(ea-eb) * ma/mb; with sig = (ma/mb)*2^113 in [2^112, 2^113):
     * value = 2^(ea-eb-113) * sig -> e = ea-eb+BIAS-1 (+1 when shifted). */
    int e = ea - eb + XIOM_F128_BIAS - 1;
    if (ma >= mb) {
        ma >>= 1;
        e += 1;
    }
    unsigned __int128 q = xiom_f128_udiv_114(ma, mb); /* 114 bits: 113 + guard */
    /* pass q with extra_bits=1 -- round_pack drops the guard bit itself */
    return xiom_f128_round_pack(sres, e, q, 1);
}

/* ========================== CONVERSIONS =================================== */
static xiom_f128 xiom_f128_from_i64_impl(int64_t i) {
    int sign = i < 0;
    uint64_t mag = sign ? (uint64_t)(-(i + 1)) + 1 : (uint64_t)i;
    if (mag == 0) return xiom_f128_pack(sign, 0, 0, 0);
    int n = 0;
    uint64_t t = mag;
    while (t) { t >>= 1; n++; }
    int exp = XIOM_F128_BIAS + n - 1;
    unsigned __int128 sig = ((unsigned __int128)mag) << (112 - (n - 1));
    return xiom_f128_pack(sign, exp, (uint64_t)(sig >> 64), (uint64_t)sig);
}
static xiom_f128 xiom_f128_from_u64_impl(uint64_t u) {
    if (u == 0) return xiom_f128_pack(0, 0, 0, 0);
    int n = 0;
    uint64_t t = u;
    while (t) { t >>= 1; n++; }
    int exp = XIOM_F128_BIAS + n - 1;
    unsigned __int128 sig = ((unsigned __int128)u) << (112 - (n - 1));
    return xiom_f128_pack(0, exp, (uint64_t)(sig >> 64), (uint64_t)sig);
}

static xiom_f128 xiom_f128_from_f64_impl(double d) {
    uint64_t bits;
    memcpy(&bits, &d, 8);
    int sign = (int)(bits >> 63);
    int e = (int)((bits >> 52) & 0x7FF);
    uint64_t m = bits & 0xFFFFFFFFFFFFFULL;
    if (e == 0x7FF) return xiom_f128_pack(sign, 0x7FFF, m ? 1 : 0, m);
    if (e == 0 && m == 0) return xiom_f128_pack(sign, 0, 0, 0);
    /* shift the 53-bit significand up to bit 112 */
    unsigned __int128 sig = ((unsigned __int128)1 << 112) | ((unsigned __int128)m << (112 - 52));
    return xiom_f128_pack(sign, e - 1023 + XIOM_F128_BIAS, (uint64_t)(sig >> 64), (uint64_t)sig);
}

/* ============================================================================
 * ABI note (BUG 37/36 root cause, fixed 2026-08-17):
 *
 * The IR clang generates for fp128 arithmetic calls the soft-float helpers
 * with LLVM's Win64 convention for f128:
 *   - f128 args: POINTERS to 16-byte slots (e.g. __addtf3: rcx=&a, rdx=&b)
 *   - f128 result: XMM0 (NOT sret)
 * but the MSVC C ABI for a 16-byte STRUCT (xiom_f128) is:
 *   - args: pointers (same), result: hidden sret pointer in rcx
 * So any helper RETURNING xiom_f128 was compiled with an extra sret param in
 * rcx, shifted the args by one register (rdx/r8), and never wrote XMM0 --
 * the caller read XMM0 = garbage and the callee dereferenced r8 = garbage
 * (0xC0000005 in every runtime fp128 shape; constant-folded loops masked it).
 *
 * The fix: each f128-returning helper symbol is now a naked asm shim that
 * implements the IR convention (rcx/rdx/r8 args as the IR passes them,
 * result in XMM0) and forwards to a plain sret-ABI wrapper that reuses the
 * pure by-value implementations above. Shims use SSE2-only instructions so
 * they work in every build (the JIT runtime DLL is built without -mavx).
 * ==========================================================================*/

/* ==================== sret-ABI wrappers (MSVC convention) ================= */
void xiom_f128_add_sret(xiom_f128* out, const xiom_f128* a, const xiom_f128* b) { *out = xiom_f128_addsub(*a, *b, 0); }
void xiom_f128_sub_sret(xiom_f128* out, const xiom_f128* a, const xiom_f128* b) { *out = xiom_f128_addsub(*a, *b, 1); }
void xiom_f128_mul_sret(xiom_f128* out, const xiom_f128* a, const xiom_f128* b) { *out = xiom_f128_mul_impl(*a, *b); }
void xiom_f128_div_sret(xiom_f128* out, const xiom_f128* a, const xiom_f128* b) { *out = xiom_f128_div_impl(*a, *b); }
void xiom_f128_neg_sret(xiom_f128* out, const xiom_f128* a) {
    xiom_f128 r = *a;
    r.hi ^= 0x8000000000000000ULL;
    *out = r;
}
void xiom_f128_ext_d_sret(xiom_f128* out, double d) { *out = xiom_f128_from_f64_impl(d); }
void xiom_f128_ext_s_sret(xiom_f128* out, float f) { *out = xiom_f128_from_f64_impl((double)f); }
void xiom_f128_from_i32_sret(xiom_f128* out, int32_t v) { *out = xiom_f128_from_i64_impl(v); }
void xiom_f128_from_u32_sret(xiom_f128* out, uint32_t v) { *out = xiom_f128_from_u64_impl(v); }
void xiom_f128_from_i64_sret(xiom_f128* out, int64_t v) { *out = xiom_f128_from_i64_impl(v); }
void xiom_f128_from_u64_sret(xiom_f128* out, uint64_t v) { *out = xiom_f128_from_u64_impl(v); }

/* v is a POINTER to the 16-byte value (MSVC passes __int128 2nd args by ref);
 * neg = sign flag for the signed conversion (two's-complement magnitude). */
void xiom_f128_from_i128_sret(xiom_f128* out, const unsigned __int128* v, int neg) {
    unsigned __int128 u = *v;
    if (neg) u = (unsigned __int128)0 - u;
    if (u == 0) { *out = xiom_f128_pack(neg, 0, 0, 0); return; }
    int n = 128;
    unsigned __int128 t = u;
    while ((t >> 127) == 0) { t <<= 1; n--; }
    int exp = XIOM_F128_BIAS + n - 1;
    unsigned __int128 sig = t >> 15; /* bit 127 -> bit 112 */
    *out = xiom_f128_pack(neg, exp, (uint64_t)(sig >> 64), (uint64_t)sig);
}

/* ============== naked asm shims (IR convention -> sret wrappers) ============ */
/* Layout at each shim entry (rsp == 8 mod 16):
 *   subq N -> rsp == 0 at the `callq` (N == 8 mod 16, N >= 48)
 *   shadow space for the wrapper: [rsp .. rsp+31]
 *   sret result slot: [rsp+32 .. rsp+47]  (outside the wrapper's shadow)
 *   extra locals (i128 copy): [rsp+48 .. rsp+63]
 * Result is reloaded from the sret slot into XMM0 after the call. */

__attribute__((used, naked)) void __addtf3(xiom_f128 a, xiom_f128 b) {
    __asm__(
        "subq $0x48, %rsp\n\t"
        "movq %rdx, %r8\n\t"
        "movq %rcx, %rdx\n\t"
        "leaq 32(%rsp), %rcx\n\t"
        "callq xiom_f128_add_sret\n\t"
        "movdqu 32(%rsp), %xmm0\n\t"
        "addq $0x48, %rsp\n\t"
        "retq\n\t");
}
__attribute__((used, naked)) void __subtf3(xiom_f128 a, xiom_f128 b) {
    __asm__(
        "subq $0x48, %rsp\n\t"
        "movq %rdx, %r8\n\t"
        "movq %rcx, %rdx\n\t"
        "leaq 32(%rsp), %rcx\n\t"
        "callq xiom_f128_sub_sret\n\t"
        "movdqu 32(%rsp), %xmm0\n\t"
        "addq $0x48, %rsp\n\t"
        "retq\n\t");
}
__attribute__((used, naked)) void __multf3(xiom_f128 a, xiom_f128 b) {
    __asm__(
        "subq $0x48, %rsp\n\t"
        "movq %rdx, %r8\n\t"
        "movq %rcx, %rdx\n\t"
        "leaq 32(%rsp), %rcx\n\t"
        "callq xiom_f128_mul_sret\n\t"
        "movdqu 32(%rsp), %xmm0\n\t"
        "addq $0x48, %rsp\n\t"
        "retq\n\t");
}
__attribute__((used, naked)) void __divtf3(xiom_f128 a, xiom_f128 b) {
    __asm__(
        "subq $0x48, %rsp\n\t"
        "movq %rdx, %r8\n\t"
        "movq %rcx, %rdx\n\t"
        "leaq 32(%rsp), %rcx\n\t"
        "callq xiom_f128_div_sret\n\t"
        "movdqu 32(%rsp), %xmm0\n\t"
        "addq $0x48, %rsp\n\t"
        "retq\n\t");
}
__attribute__((used, naked)) void __negtf2(xiom_f128 a) {
    __asm__(
        "subq $0x48, %rsp\n\t"
        "movq %rcx, %rdx\n\t"
        "leaq 32(%rsp), %rcx\n\t"
        "callq xiom_f128_neg_sret\n\t"
        "movdqu 32(%rsp), %xmm0\n\t"
        "addq $0x48, %rsp\n\t"
        "retq\n\t");
}
__attribute__((used, naked)) void __extenddftf2(double d) {
    __asm__(
        "subq $0x48, %rsp\n\t"
        "leaq 32(%rsp), %rcx\n\t"
        "movaps %xmm0, %xmm1\n\t"
        "callq xiom_f128_ext_d_sret\n\t"
        "movdqu 32(%rsp), %xmm0\n\t"
        "addq $0x48, %rsp\n\t"
        "retq\n\t");
}
__attribute__((used, naked)) void __extendsftf2(float f) {
    __asm__(
        "subq $0x48, %rsp\n\t"
        "leaq 32(%rsp), %rcx\n\t"
        "movaps %xmm0, %xmm1\n\t"
        "callq xiom_f128_ext_s_sret\n\t"
        "movdqu 32(%rsp), %xmm0\n\t"
        "addq $0x48, %rsp\n\t"
        "retq\n\t");
}
__attribute__((used, naked)) void __floatsitf(int32_t i) {
    __asm__(
        "subq $0x48, %rsp\n\t"
        "movl %ecx, %edx\n\t"
        "leaq 32(%rsp), %rcx\n\t"
        "callq xiom_f128_from_i32_sret\n\t"
        "movdqu 32(%rsp), %xmm0\n\t"
        "addq $0x48, %rsp\n\t"
        "retq\n\t");
}
__attribute__((used, naked)) void __floatunsitf(uint32_t u) {
    __asm__(
        "subq $0x48, %rsp\n\t"
        "movl %ecx, %edx\n\t"
        "leaq 32(%rsp), %rcx\n\t"
        "callq xiom_f128_from_u32_sret\n\t"
        "movdqu 32(%rsp), %xmm0\n\t"
        "addq $0x48, %rsp\n\t"
        "retq\n\t");
}
__attribute__((used, naked)) void __floatditf(int64_t i) {
    __asm__(
        "subq $0x48, %rsp\n\t"
        "movq %rcx, %rdx\n\t"
        "leaq 32(%rsp), %rcx\n\t"
        "callq xiom_f128_from_i64_sret\n\t"
        "movdqu 32(%rsp), %xmm0\n\t"
        "addq $0x48, %rsp\n\t"
        "retq\n\t");
}
__attribute__((used, naked)) void __floatunditf(uint64_t u) {
    __asm__(
        "subq $0x48, %rsp\n\t"
        "movq %rcx, %rdx\n\t"
        "leaq 32(%rsp), %rcx\n\t"
        "callq xiom_f128_from_u64_sret\n\t"
        "movdqu 32(%rsp), %xmm0\n\t"
        "addq $0x48, %rsp\n\t"
        "retq\n\t");
}
/* i128 args arrive BY REFERENCE in rcx (memory class on Win64). */
__attribute__((used, naked)) void __floattitf(__int128 i) {
    __asm__(
        "subq $0x58, %rsp\n\t"
        "movq %rcx, %rdx\n\t"
        "leaq 32(%rsp), %rcx\n\t"
        "movq 8(%rdx), %rax\n\t"
        "shrq $63, %rax\n\t"
        "movq %rax, %r8\n\t"
        "callq xiom_f128_from_i128_sret\n\t"
        "movdqu 32(%rsp), %xmm0\n\t"
        "addq $0x58, %rsp\n\t"
        "retq\n\t");
}
__attribute__((used, naked)) void __floatuntitf(unsigned __int128 u) {
    __asm__(
        "subq $0x58, %rsp\n\t"
        "movq %rcx, %rdx\n\t"
        "leaq 32(%rsp), %rcx\n\t"
        "xorl %r8d, %r8d\n\t"
        "callq xiom_f128_from_i128_sret\n\t"
        "movdqu 32(%rsp), %xmm0\n\t"
        "addq $0x58, %rsp\n\t"
        "retq\n\t");
}

/* ============ scalar-return helpers (ABI already matches; unchanged) ====== */

double __trunctfdf2(xiom_f128 f) {
    if (xiom_f128_isnan(f)) { uint64_t nan = 0x7FF8000000000000ULL; double d; memcpy(&d, &nan, 8); return d; }
    int sign = (int)(f.hi >> 63);
    int e = (int)((f.hi >> 48) & XIOM_F128_EXP_MASK);
    uint64_t mhi = f.hi & XIOM_F128_MAN_HI_MASK;
    if (e == 0x7FFF) {
        uint64_t bits = ((uint64_t)sign << 63) | 0x7FF0000000000000ULL | (mhi ? (mhi >> 60) : 0);
        double d; memcpy(&d, &bits, 8); return d;
    }
    if (e == 0 && mhi == 0 && f.lo == 0) { double z = 0.0; if (sign) z = -z; return z; }
    int e64 = e - XIOM_F128_BIAS + 1023;
    /* significand: implicit bit + 112 mantissa bits; keep 53 + guard/sticky */
    unsigned __int128 sig = ((unsigned __int128)1 << 112) | ((unsigned __int128)mhi << 64) | f.lo;
    if (e64 >= 0x7FF) { /* overflow -> inf */
        uint64_t bits = ((uint64_t)sign << 63) | 0x7FF0000000000000ULL;
        double d; memcpy(&d, &bits, 8); return d;
    }
    if (e64 <= 0) {
        /* denormal/underflow path: shift right by (1 - e64) more */
        int shift = 113 - 53 + (1 - e64);
        unsigned __int128 shifted = shift >= 128 ? 0 : (sig >> shift);
        uint64_t mant = (uint64_t)(shifted >> 60);
        uint64_t bits = ((uint64_t)sign << 63) | mant;
        double d; memcpy(&d, &bits, 8); return d;
    }
    int shift = 113 - 53;
    unsigned __int128 shifted = sig >> shift;
    uint64_t guard = (uint64_t)((sig >> (shift - 1)) & 1);
    uint64_t sticky = (uint64_t)(sig & ((((unsigned __int128)1) << (shift - 1)) - 1));
    uint64_t mant = (uint64_t)shifted; /* 53 bits */
    if (guard && (sticky || (mant & 1))) mant += 1;
    if (mant >> 53) { mant >>= 1; e64 += 1; }
    uint64_t bits = ((uint64_t)sign << 63) | ((uint64_t)e64 << 52) | (mant & 0xFFFFFFFFFFFFFULL);
    double d; memcpy(&d, &bits, 8); return d;
}

float __trunctfsf2(xiom_f128 f) {
    double d = __trunctfdf2(f);
    return (float)d;
}

int64_t __fixtfdi(xiom_f128 f) {
    if (xiom_f128_isnan(f) || xiom_f128_isinf(f)) return 0;
    int sign = (int)(f.hi >> 63);
    int e = (int)((f.hi >> 48) & XIOM_F128_EXP_MASK);
    uint64_t mhi = f.hi & XIOM_F128_MAN_HI_MASK;
    if (e == 0 && mhi == 0 && f.lo == 0) return 0;
    unsigned __int128 sig = ((unsigned __int128)1 << 112) | ((unsigned __int128)mhi << 64) | f.lo;
    int shift = 112 - (e - XIOM_F128_BIAS);
    if (shift < 0) return 0; /* overflow */
    if (shift >= 128) return 0;
    unsigned __int128 mag = sig >> shift;
    if (mag > (unsigned __int128)INT64_MAX + (sign ? 1 : 0)) return 0;
    int64_t v = (int64_t)mag;
    return sign ? -v : v;
}
uint64_t __fixunstfdi(xiom_f128 f) {
    if (xiom_f128_isnan(f) || xiom_f128_isinf(f) || (int)(f.hi >> 63)) return 0;
    int e = (int)((f.hi >> 48) & XIOM_F128_EXP_MASK);
    uint64_t mhi = f.hi & XIOM_F128_MAN_HI_MASK;
    if (e == 0 && mhi == 0 && f.lo == 0) return 0;
    unsigned __int128 sig = ((unsigned __int128)1 << 112) | ((unsigned __int128)mhi << 64) | f.lo;
    int shift = 112 - (e - XIOM_F128_BIAS);
    if (shift < 0 || shift >= 128) return 0;
    return (uint64_t)(sig >> shift);
}
int32_t __fixtfsi(xiom_f128 f) { return (int32_t)__fixtfdi(f); }
uint32_t __fixunstfsi(xiom_f128 f) { return (uint32_t)__fixunstfdi(f); }

/* 128-bit integer results return in rax:rdx on Win64 -- matches the IR's
 * i128 convention, so these need no shim. */
__int128 __fixtfti(xiom_f128 f) {
    if (xiom_f128_isnan(f) || xiom_f128_isinf(f)) return 0;
    int sign = (int)(f.hi >> 63);
    int e = (int)((f.hi >> 48) & XIOM_F128_EXP_MASK);
    uint64_t mhi = f.hi & XIOM_F128_MAN_HI_MASK;
    if (e == 0 && mhi == 0 && f.lo == 0) return 0;
    unsigned __int128 sig = ((unsigned __int128)1 << 112) | ((unsigned __int128)mhi << 64) | f.lo;
    int shift = 112 - (e - XIOM_F128_BIAS);
    if (shift < 0 || shift >= 128) return 0; /* overflow */
    unsigned __int128 mag = sig >> shift;
    if (sign) {
        if (mag > (((unsigned __int128)1) << 127)) return 0; /* < INT128_MIN */
        return (__int128)(0 - mag);
    }
    if (mag >= (((unsigned __int128)1) << 127)) return 0; /* >= INT128_MAX */
    return (__int128)mag;
}
unsigned __int128 __fixunstfti(xiom_f128 f) {
    if (xiom_f128_isnan(f) || xiom_f128_isinf(f) || (int)(f.hi >> 63)) return 0;
    int e = (int)((f.hi >> 48) & XIOM_F128_EXP_MASK);
    uint64_t mhi = f.hi & XIOM_F128_MAN_HI_MASK;
    if (e == 0 && mhi == 0 && f.lo == 0) return 0;
    unsigned __int128 sig = ((unsigned __int128)1 << 112) | ((unsigned __int128)mhi << 64) | f.lo;
    int shift = 112 - (e - XIOM_F128_BIAS);
    if (shift < 0 || shift >= 128) return 0;
    return sig >> shift;
}

/* ========================== COMPARISONS =================================== */
int __unordtf2(xiom_f128 a, xiom_f128 b) { return xiom_f128_isnan(a) || xiom_f128_isnan(b); }
int __eqtf2(xiom_f128 a, xiom_f128 b) {
    if (xiom_f128_isnan(a) || xiom_f128_isnan(b)) return 1;
    return (a.hi == b.hi && a.lo == b.lo) ? 0 : 1;
}
int __netf2(xiom_f128 a, xiom_f128 b) { return __eqtf2(a, b); }
int __cmptf2(xiom_f128 a, xiom_f128 b) {
    if (xiom_f128_isnan(a) || xiom_f128_isnan(b)) return 1;
    if (__eqtf2(a, b) == 0) return 0;
    int sa = (int)(a.hi >> 63), sb = (int)(b.hi >> 63);
    if (sa != sb) return sa ? -1 : 1;
    int e = sa ? -1 : 1;
    /* compare magnitudes */
    uint64_t ah = a.hi & 0x7FFFFFFFFFFFFFFFULL, bh = b.hi & 0x7FFFFFFFFFFFFFFFULL;
    if (ah != bh) return (ah < bh) ? -e : e;
    if (a.lo != b.lo) return (a.lo < b.lo) ? -e : e;
    return 0;
}
int __getf2(xiom_f128 a, xiom_f128 b) {
    int c = __cmptf2(a, b);
    return c == 1 ? 0 : c; /* unord -> 0 */
}
int __gttf2(xiom_f128 a, xiom_f128 b) {
    int c = __cmptf2(a, b);
    return c > 0 ? 1 : 0;
}
int __letf2(xiom_f128 a, xiom_f128 b) {
    int c = __cmptf2(a, b);
    return c == 1 ? 1 : (c == 0 ? 0 : -1); /* unord -> 1 */
}
int __lttf2(xiom_f128 a, xiom_f128 b) {
    int c = __cmptf2(a, b);
    return c < 0 ? -1 : 0;
}


