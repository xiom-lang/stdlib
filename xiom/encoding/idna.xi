// XIOM - Encoding: IDNA
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.encoding.idna

// Depends on: xiom.string

// ============================================================================
// Internationalized Domain Names: UTS-46 processing and nameprep checks.
// NOTE: current implementation lives in encoding.xi - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

// fn idna_to_ascii(s: Str) -> Result[Str, Str] - convert a Unicode domain to A-label ASCII. TODO(compiler): implement.
// fn idna_to_unicode(s: Str) -> Result[Str, Str] - convert an A-label domain to Unicode. TODO(compiler): implement.
// fn idna_is_valid(s: Str) -> Bool - true if s is a valid IDNA domain. TODO(compiler): implement.
// fn idna_uts46_normalize(s: Str) -> Result[Str, Str] - apply the UTS-46 mapping and normalization. TODO(compiler): implement.
// fn idna_nameprep(s: Str) -> Result[Str, Str] - apply the older nameprep profile. TODO(compiler): implement.
// fn idna_split_labels(domain: Str) -> Vec[Str] - split a domain at the dot separators. TODO(compiler): implement.
// fn idna_join_labels(labels: &Vec[Str]) -> Str - join labels back into a domain. TODO(compiler): implement.
// fn idna_is_bidi_valid(s: Str) -> Bool - true if s satisfies the IDNA bidi rule. TODO(compiler): implement.
