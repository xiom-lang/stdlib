// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
/* XIOM Async Runtime -- monotonic time source for the cooperative executor.
 *
 * Provides the clock used by stdlib/xiom/async.xi to drive real timers
 * (`delay`, `sleep_ms`) and the scheduler in general.
 *
 * All symbols are uniquely prefixed `xiom_async_` so they never collide with
 * xiom_runtime.c, which owns xiom_thread_*, xiom_socket_*, xiom_mutex_*, etc.
 * Nothing here is redefined from that file -- the executor calls the existing
 * xiom_thread_sleep_ms for the actual wait and only adds a clock here.
 *
 * This file is auto-linked (the compiler links every C file in stdlib runtime)
 * must compile standalone, including under:  clang -DXIOM_NO_ASM async_runtime.c
 * It contains no assembly, so XIOM_NO_ASM has no effect beyond being accepted.
 */

// Guarded against redefinition: the xiom compiler also passes
// -D_CRT_SECURE_NO_WARNINGS on the command line (a bare re-#define triggers
// clang's -Wmacro-redefined).
#ifndef _CRT_SECURE_NO_WARNINGS
#define _CRT_SECURE_NO_WARNINGS
#endif

#ifdef _WIN32
  #define WIN32_LEAN_AND_MEAN
  #include <windows.h>
#else
  #include <time.h>
#endif

/* Monotonic milliseconds since a fixed, unspecified epoch.
 * Guaranteed non-decreasing, which is exactly what scheduler deadlines need.
 * Returns a 64-bit value (`long long`) to match the XIOM `Int` (i64) ABI on
 * all platforms -- mirroring xiom_alloc's use of `long long` to avoid Win64
 * truncation of `long` (which is only 32-bit under MSVC/clang-cl). */
long long xiom_async_now_ms(void) {
#ifdef _WIN32
    static LARGE_INTEGER freq;
    static int have_freq = 0;
    LARGE_INTEGER now;
    if (!have_freq) {
        QueryPerformanceFrequency(&freq);
        have_freq = 1;
    }
    QueryPerformanceCounter(&now);
    if (freq.QuadPart == 0) {
        return 0;
    }
    return (long long)((now.QuadPart * 1000LL) / freq.QuadPart);
#elif defined(CLOCK_MONOTONIC)
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (long long)ts.tv_sec * 1000LL + (long long)ts.tv_nsec / 1000000LL;
#else
    /* Portable fallback when no monotonic clock is exposed. */
    return (long long)((clock() * 1000LL) / (long long)CLOCKS_PER_SEC);
#endif
}
