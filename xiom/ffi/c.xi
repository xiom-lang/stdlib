// XIOM - FFI: C Library
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.ffi.c

// Depends on: xiom.ffi

// ============================================================================
// Thin bindings to common C standard library functions. NOTE: current
// implementation lives in ffi.xi - move the functions here during the
// implementation phase. TODO(compiler): implement.
// ============================================================================

// fn c_strlen(ptr: Int) -> Int - length of a null-terminated string. TODO(compiler): implement.
// fn c_strcmp(a: Int, b: Int) -> Int - lexicographic string comparison. TODO(compiler): implement.
// fn c_strcpy(dst: Int, src: Int) -> Int - copy a string, returning dst. TODO(compiler): implement.
// fn c_memcpy(dst: Int, src: Int, n: Int) -> Int - copy n bytes, returning dst. TODO(compiler): implement.
// fn c_memset(ptr: Int, value: Int, n: Int) -> Int - fill n bytes with a value, returning ptr. TODO(compiler): implement.
// fn c_memcmp(a: Int, b: Int, n: Int) -> Int - compare n bytes. TODO(compiler): implement.
// fn c_atoi(ptr: Int) -> Int - parse a decimal string to Int. TODO(compiler): implement.
// fn c_atof(ptr: Int) -> Float64 - parse a string to Float64. TODO(compiler): implement.
// fn c_abs(n: Int) -> Int - absolute value. TODO(compiler): implement.
// fn c_rand() -> Int - pseudo-random integer. TODO(compiler): implement.
// fn c_srand(seed: Int) - seed the C random generator. TODO(compiler): implement.
// fn c_clock() -> Int - processor time consumed. TODO(compiler): implement.
// fn c_qsort(base: Int, n: Int, size: Int, cmp: Int) - sort an array using a comparator callback. TODO(compiler): implement.
// fn c_bsearch(key: Int, base: Int, n: Int, size: Int, cmp: Int) -> Int - binary search in a sorted array. TODO(compiler): implement.
