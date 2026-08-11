// XIOM - Misc: Natural Sort
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.misc.natural

// Depends on: xiom.string

// ============================================================================
// Natural (human) ordering that compares embedded digit runs numerically,
// with sorting helpers and key extraction. NOTE: current implementation
// lives in misc.xi - move the functions here during the implementation phase.
// TODO(compiler): implement.
// ============================================================================

// fn natural_compare(a: Str, b: Str) -> Int - compare a and b in natural order: -1, 0, or 1. TODO(compiler): implement.
// fn natural_compare_ignore_case(a, b) -> Int - natural comparison ignoring case. TODO(compiler): implement.
// fn natural_sort(strings: &Vec[Str]) -> Vec[Str] - a copy of strings sorted naturally. TODO(compiler): implement.
// fn natural_sort_by[T](items: &Vec[T], key: fn(&T) -> Str) -> Vec[T] - sort items by an extracted natural key. TODO(compiler): implement.
// fn natural_key(s: Str) -> Vec[(Int, Str)] - the comparison segments; each tuple is (digit_value, chunk). TODO(compiler): implement.
// fn natural_chunk(s) -> Vec[Str] - split s into alternating digit and text chunks. TODO(compiler): implement.
// fn natural_is_digit_run(s, i) -> Bool - whether s contains a digit run starting at index i. TODO(compiler): implement.
// fn natural_compare_numeric(a, b) -> Int - compare two pure numeric strings by value. TODO(compiler): implement.
// fn natural_sort_desc(strings) -> Vec[Str] - a copy of strings sorted naturally in descending order. TODO(compiler): implement.
