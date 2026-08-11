// XIOM - Misc: Levenshtein
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.misc.levenshtein

// Depends on: xiom.string

// ============================================================================
// Edit-distance metrics and algorithms: Levenshtein, Damerau-Levenshtein,
// OSA and Wagner-Fischer with alignment and matrix helpers. NOTE: current
// implementation lives in misc.xi - move the functions here during the
// implementation phase. TODO(compiler): implement.
// ============================================================================

// fn levenshtein_distance(a: Str, b: Str) -> Int - the minimum edit distance between a and b. TODO(compiler): implement.
// fn levenshtein_distance_limited(a, b, max: Int) -> Int - edit distance capped at max, for early exit. TODO(compiler): implement.
// fn levenshtein_similarity(a, b) -> Float64 - normalized similarity in [0,1]. TODO(compiler): implement.
// fn levenshtein_align(a, b) -> (Str, Str) - optimal alignment; the tuple is (aligned_a, aligned_b). TODO(compiler): implement.
// fn levenshtein_matrix(a, b) -> Vec[Vec[Int]] - the full dynamic-programming matrix. TODO(compiler): implement.
// fn levenshtein_edit_script(a, b) -> Vec[Str] - the sequence of edit operations. TODO(compiler): implement.
// fn damerau_levenshtein(a, b) -> Int - distance with transposition of adjacent characters. TODO(compiler): implement.
// fn osa_distance(a, b) -> Int - optimal string alignment (restricted transposition) distance. TODO(compiler): implement.
// fn wagner_fischer(a, b) -> Int - classic Wagner-Fischer edit distance. TODO(compiler): implement.
