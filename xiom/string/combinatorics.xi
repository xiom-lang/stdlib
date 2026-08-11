// XIOM - String: Combinatorics
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.string.combinatorics

// Depends on: xiom.string, xiom.rand

// ============================================================================
// String transformations and combinatorics: shuffling, rotation, permutations,
// combinations, interleaving, chunking, sliding windows, and character-level
// statistics. All functions are pure; shuffle uses an internal PRNG seeded
// from the runtime or an explicit seed value.
// ============================================================================

// --- Shuffle (Fisher-Yates) ---

// fn str_shuffle(s: Str) -> Str - random permutation of the chars of s. TODO(compiler): implement.
// fn str_shuffle_seeded(s: Str, seed: Int) -> Str - deterministic shuffle of s using the given seed. TODO(compiler): implement.
// fn str_shuffle_words(s: Str) -> Str - random permutation of the whitespace-separated words of s. TODO(compiler): implement.
// fn str_shuffle_words_seeded(s: Str, seed: Int) -> Str - deterministic word shuffle of s using the given seed. TODO(compiler): implement.

// --- Rotation ---

// fn str_rotate(s: Str, n: Int) -> Str - rotate s by n positions, positive moves chars right. TODO(compiler): implement.
// fn str_rotate_left(s: Str, n: Int) -> Str - rotate s left by n positions. TODO(compiler): implement.
// fn str_rotate_right(s: Str, n: Int) -> Str - rotate s right by n positions. TODO(compiler): implement.
// fn str_rotate_word(s: Str, n: Int) -> Str - rotate the words of s by n positions. TODO(compiler): implement.

// --- Permutations and combinations ---

// fn str_permutations(s: Str) -> Vec[Str] - all permutations of the chars of s (distinct chars). TODO(compiler): implement.
// fn str_permutations_n(s: Str, n: Int) -> Vec[Str] - all n-length arrangements of chars of s. TODO(compiler): implement.
// fn str_combinations(s: Str, n: Int) -> Vec[Str] - all n-length combinations of chars of s, each kept in source order. TODO(compiler): implement.
// fn str_cartesian(a: Str, b: Str) -> Vec[Str] - every char of a paired with every char of b. TODO(compiler): implement.

// --- Interleave, chunking and windows ---

// fn str_interleave(a: Str, b: Str) -> Str - merge a and b alternating chars, remainder appended. TODO(compiler): implement.
// fn str_chunk(s: Str, n: Int) -> Vec[Str] - split s into consecutive chunks of n chars, last may be shorter. TODO(compiler): implement.
// fn str_chunks_reverse(s: Str, n: Int) -> Vec[Str] - chunk s from the end, remainder forms the first chunk. TODO(compiler): implement.
// fn str_windows(s: Str, n: Int) -> Vec[Str] - all length-n overlapping substrings of s. TODO(compiler): implement.
// fn str_chunk_bytes(s: Str, n: Int) -> Vec[Str] - split s into chunks of n bytes, char-boundary safe. TODO(compiler): implement.

// --- Word order ---

// fn str_reverse_words(s: Str) -> Str - reverse the order of whitespace-separated words, preserving spacing. TODO(compiler): implement.

// --- Character statistics ---

// fn str_unique_chars(s: Str) -> Str - chars of s without duplicates, in first-seen order. TODO(compiler): implement.
// fn str_frequencies(s: Str) -> Vec[(Char, Int)] - each distinct char and its occurrence count. (Char, Int): the char and how many times it appears in s. TODO(compiler): implement.
// fn str_most_frequent(s: Str) -> Option[Char] - char that appears most often in s, None when s is empty. TODO(compiler): implement.
// fn str_char_set(s: Str) -> Vec[Char] - distinct chars of s in first-seen order. TODO(compiler): implement.
