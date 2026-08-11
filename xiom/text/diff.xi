// XIOM - Text: Diff
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.text.diff

// Depends on: xiom.string

// ============================================================================
// Line, word and byte-level diffing with Myers/LCS, unified and patch
// rendering plus similarity metrics. NOTE: current implementation lives in
// string.xi - move the functions here during the implementation phase.
// TODO(compiler): implement.
// ============================================================================

// type DiffOp - a diff operation: equal (kept), insert (added), or delete (removed).
// fn diff_myers(a: &Vec[Str], b: &Vec[Str]) -> Vec[DiffOp] - compute an optimal line diff with Myers' algorithm. TODO(compiler): implement.
// fn diff_myers_lines(a: Str, b: Str) -> Vec[DiffOp] - split a and b into lines and diff them. TODO(compiler): implement.
// fn diff_lcs(a: &Vec[Str], b: &Vec[Str]) -> Vec[DiffOp] - compute a diff via longest common subsequence. TODO(compiler): implement.
// fn diff_unified(a: Str, b: Str, context: Int) -> Str - render a unified diff with context lines. TODO(compiler): implement.
// fn diff_patch(a: Str, b: Str) -> Str - render a compact patch text from a to b. TODO(compiler): implement.
// fn diff_apply(a: Str, patch: Str) -> Result[Str, Str] - apply a patch to a and return the result. TODO(compiler): implement.
// fn diff_similarity(a: Str, b: Str) -> Float64 - normalized similarity in [0,1]. TODO(compiler): implement.
// fn diff_ratio(a: Str, b: Str) -> Float64 - 2*matches / (len_a + len_b). TODO(compiler): implement.
// fn diff_word_level(a: Str, b: Str) -> Vec[DiffOp] - diff a and b tokenized into words. TODO(compiler): implement.
// fn diff_byte_level(a: &Vec[UInt8], b: &Vec[UInt8]) -> Vec[DiffOp] - diff two byte sequences. TODO(compiler): implement.
