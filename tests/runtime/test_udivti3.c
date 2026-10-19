/* test_udivti3.c -- regression test for the runtime __udivti3 helper.
 * Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
 * SPDX-License-Identifier: MIT OR Apache-2.0
 *
 * REL-20261016-2331 residual: the old helper used native `a / b` for a
 * single-limb divisor, which clang lowered back to __udivti3 (the symbol
 * defined in the same TU) and self-recursed; the high-limb path also lost
 * the 129th remainder bit and returned wrong quotients.
 *
 * This test lives outside runtime/ on purpose: the compiler links every
 * .c file in runtime/ into each program, and a test main() would collide
 * with the program entry point.
 *
 * Build (Windows; run from tests/runtime/):
 *   clang -c -O0 -maes -ffunction-sections -fdata-sections -DXIOM_NO_ASM ^
 *         ..\..\runtime\xiom_runtime.c -o xiom_runtime_test.obj
 *   clang -O2 test_udivti3.c xiom_runtime_test.obj -o test_udivti3.exe
 *   test_udivti3.exe
 * Expected: prints "ok" and exits 0.
 *
 * Linux/macOS: same, adding -lpthread -ldl -lm to the link line.
 */

#include <stdio.h>

extern unsigned __int128 __udivti3(unsigned __int128 a, unsigned __int128 b);

static int check(unsigned __int128 a, unsigned __int128 b,
                 unsigned __int128 want, int id) {
    unsigned __int128 got = __udivti3(a, b);
    if (got != want) {
        printf("FAIL %d got_hi=%016llx got_lo=%016llx\n", id,
               (unsigned long long)(got >> 64), (unsigned long long)got);
        return 1;
    }
    return 0;
}

int main(void) {
    int bad = 0;
    /* High-limb divisors: the old Knuth path returned 0 for both. */
    bad += check(((unsigned __int128)0x97A391CE01F3892EULL << 64) | 0x2EF6453C5B4FE5BCULL,
                 ((unsigned __int128)0x3C0F74A626599577ULL << 64) | 0xDD251AB0F9E49B9DULL,
                 2, 1);
    bad += check(((unsigned __int128)0xE9CA7BF6B0C347BBULL << 64) | 0x2E93CFBD9A6C4FF4ULL,
                 ((unsigned __int128)0x3FD953622763EA6BULL << 64) | 0xEEDCF094E864D77FULL,
                 3, 2);
    /* Single-limb divisors: the old path self-recursed. */
    bad += check((unsigned __int128)1 << 100, 3,
                 ((unsigned __int128)0x555555555ULL << 64) | 0x5555555555555555ULL, 3);
    bad += check(~(unsigned __int128)0, 3,
                 ((unsigned __int128)0x5555555555555555ULL << 64) | 0x5555555555555555ULL, 4);
    bad += check(0xFFFFFFFFFFFFFFFFULL, 3, 0x5555555555555555ULL, 5);
    /* Small/edge cases. */
    bad += check(5, 7, 0, 6);
    bad += check(0, 7, 0, 7);
    bad += check((unsigned __int128)1 << 100, 1, (unsigned __int128)1 << 100, 8);
    bad += check(~(unsigned __int128)0, ~(unsigned __int128)0, 1, 9);
    if (bad == 0) { printf("ok\n"); }
    return bad ? 1 : 0;
}
