// XIOM - String: Unicode
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.string.unicode

// Depends on: xiom.string, xiom.char

// ============================================================================
// Unicode property tables and transforms: normalization (NFC/NFD/NFKC/NFKD),
// case folding, grapheme/word/sentence/line segmentation, East Asian display
// width, emoji handling, script/block/category properties, bidi helpers, and
// whitespace/numeric classification. Pure data tables, zero dependencies.
// ============================================================================

// --- Normalization (NFC / NFD / NFKC / NFKD) ---

// fn unicode_normalize(s: Str) -> Str - normalize s to NFC (canonical composition). TODO(compiler): implement.
// fn unicode_normalize_nfc(s: Str) -> Str - normalize s to NFC (canonical composition). TODO(compiler): implement.
// fn unicode_normalize_nfd(s: Str) -> Str - normalize s to NFD (canonical decomposition). TODO(compiler): implement.
// fn unicode_normalize_nfkc(s: Str) -> Str - normalize s to NFKC (compatibility composition). TODO(compiler): implement.
// fn unicode_normalize_nfkd(s: Str) -> Str - normalize s to NFKD (compatibility decomposition). TODO(compiler): implement.
// fn unicode_normalize_form(s: Str, form: Str) -> Str - normalize s using the named form "NFC", "NFD", "NFKC" or "NFKD". TODO(compiler): implement.
// fn unicode_is_normalized(s: Str, form: Str) -> Bool - true when s is already normalized to the named form. TODO(compiler): implement.
// fn unicode_compose_pair(a: Char, b: Char) -> Option[Char] - canonical composition of two chars, None when not composable. TODO(compiler): implement.
// fn unicode_decompose(c: Char) -> Vec[Char] - canonical decomposition of one char, single char when uncomposable. TODO(compiler): implement.
// fn unicode_combining_sequence(s: Str) -> Vec[Str] - split s into runs of base char plus trailing combining marks. TODO(compiler): implement.
// fn unicode_nfc_quick_check(s: Str) -> Bool - fast check: true when s is already NFC. TODO(compiler): implement.
// fn unicode_nfkc_quick_check(s: Str) -> Bool - fast check: true when s is already NFKC. TODO(compiler): implement.

// --- Case (case folding, title case, full and simple mappings) ---

// fn unicode_casefold(s: Str) -> Str - full case folding of s, for caseless comparison. TODO(compiler): implement.
// fn unicode_casefold_char(c: Char) -> Char - simple case fold of one char. TODO(compiler): implement.
// fn unicode_casefold_turkic(s: Str) -> Str - case fold of s using the Turkic I/U-dotted rules. TODO(compiler): implement.
// fn unicode_titlecase(s: Str) -> Str - titlecase transform: first cased letter of each word uppercased. TODO(compiler): implement.
// fn unicode_titlecase_word(s: Str) -> Str - titlecase only the first word of s, leave the rest unchanged. TODO(compiler): implement.
// fn unicode_lowercase_map(c: Char) -> Char - simple 1:1 lowercase mapping of c, c itself when none exists. TODO(compiler): implement.
// fn unicode_uppercase_map(c: Char) -> Char - simple 1:1 uppercase mapping of c, c itself when none exists. TODO(compiler): implement.
// fn unicode_tolower_full(s: Str) -> Str - full lowercase of s, handling multi-char expansions. TODO(compiler): implement.
// fn unicode_toupper_full(s: Str) -> Str - full uppercase of s, handling multi-char expansions. TODO(compiler): implement.
// fn unicode_titlecase_map(c: Char) -> Char - simple 1:1 titlecase mapping of c (capital form). TODO(compiler): implement.
// fn unicode_istitlecase(c: Char) -> Bool - true when c is a titlecase letter (Lt). TODO(compiler): implement.

// --- Segmentation (UAX #29 grapheme / word / sentence, UAX #14 line breaks) ---

// fn unicode_grapheme_clusters(s: Str) -> Vec[Str] - split s into extended grapheme clusters. TODO(compiler): implement.
// fn unicode_grapheme_count(s: Str) -> Int - number of extended grapheme clusters in s. TODO(compiler): implement.
// fn unicode_word_boundaries(s: Str) -> Vec[Int] - byte offsets of word boundaries in s. TODO(compiler): implement.
// fn unicode_word_count(s: Str) -> Int - number of words in s. TODO(compiler): implement.
// fn unicode_sentence_boundaries(s: Str) -> Vec[Int] - byte offsets of sentence boundaries in s. TODO(compiler): implement.
// fn unicode_sentence_count(s: Str) -> Int - number of sentences in s. TODO(compiler): implement.
// fn unicode_line_break_points(s: Str) -> Vec[Int] - byte offsets of allowed line break points in s. TODO(compiler): implement.
// fn unicode_line_breaks(s: Str) -> Vec[Str] - split s into lines at the allowed break points. TODO(compiler): implement.
// fn unicode_next_grapheme(s: Str, offset: Int) -> Int - byte offset just past the grapheme starting at offset. TODO(compiler): implement.
// fn unicode_prev_grapheme(s: Str, offset: Int) -> Int - byte offset of the grapheme start ending before offset. TODO(compiler): implement.

// --- Display width (East Asian Width) ---

// fn unicode_ea_width(c: Char) -> Int - East Asian Width of c: 0, 1 or 2 (narrow/ambiguous count 1). TODO(compiler): implement.
// fn unicode_display_width(s: Str) -> Int - total display width of s, wide chars count 2. TODO(compiler): implement.
// fn unicode_truncate_display(s: Str, max_width: Int) -> Str - truncate s to fit max_width display cells, grapheme-safe. TODO(compiler): implement.
// fn unicode_pad_display(s: Str, width: Int, side: Str) -> Str - pad s to a display width; side "left", "right" or "center". TODO(compiler): implement.
// fn unicode_display_slice(s: Str, start: Int, end: Int) -> Str - substring of s bounded by display-cell offsets. TODO(compiler): implement.
// fn unicode_is_wide(c: Char) -> Bool - true when c has East Asian Width W or F. TODO(compiler): implement.

// --- Emoji ---

// fn unicode_is_emoji(c: Char) -> Bool - true when c is an emoji or emoji component codepoint. TODO(compiler): implement.
// fn unicode_count_emoji(s: Str) -> Int - number of emoji characters (bases plus modifiers) in s. TODO(compiler): implement.
// fn unicode_has_emoji(s: Str) -> Bool - true when s contains at least one emoji. TODO(compiler): implement.
// fn unicode_emoji_presentation(c: Char) -> Bool - true when c defaults to emoji presentation, not text. TODO(compiler): implement.
// fn unicode_emoji_sequences(s: Str) -> Vec[Str] - extract full emoji sequences (ZWJ, keycap, flag, TAG) from s. TODO(compiler): implement.
// fn unicode_emoji_modifier(c: Char) -> Bool - true when c is an emoji modifier (skin tone). TODO(compiler): implement.
// fn unicode_emoji_zwj(c: Char) -> Bool - true when c is the ZWJ (U+200D) emoji joiner. TODO(compiler): implement.
// fn unicode_emoji_version() -> Str - emoji version implemented by the tables. TODO(compiler): implement.

// --- Properties (script, block, general category, combining class) ---

// fn unicode_script(c: Char) -> Str - ISO 15924 script code of c, e.g. "Latn", "Hani", "Zyyy". TODO(compiler): implement.
// fn unicode_script_name(code: Str) -> Str - long English script name for an ISO 15924 code. TODO(compiler): implement.
// fn unicode_block(c: Char) -> Str - Unicode block name containing c, e.g. "Basic Latin". TODO(compiler): implement.
// fn unicode_general_category(c: Char) -> Str - short general category of c, e.g. "Lu", "Nd", "Zs". TODO(compiler): implement.
// fn unicode_general_category_name(c: Char) -> Str - long general category name of c, e.g. "Uppercase_Letter". TODO(compiler): implement.
// fn unicode_age(c: Char) -> Str - Unicode age of c as a version string, e.g. "1.1". TODO(compiler): implement.
// fn unicode_combining_class(c: Char) -> Int - canonical combining class of c, 0 when spacing. TODO(compiler): implement.
// fn unicode_is_letter(c: Char) -> Bool - true when c is in a letter category (L*). TODO(compiler): implement.
// fn unicode_is_digit(c: Char) -> Bool - true when c is a decimal digit (Nd). TODO(compiler): implement.
// fn unicode_is_punct(c: Char) -> Bool - true when c is punctuation (P*). TODO(compiler): implement.
// fn unicode_is_symbol(c: Char) -> Bool - true when c is a symbol (S*). TODO(compiler): implement.
// fn unicode_is_separator(c: Char) -> Bool - true when c is a separator (Z*). TODO(compiler): implement.
// fn unicode_is_control(c: Char) -> Bool - true when c is a control or format character (Cc, Cf, Cs, Co, Cn). TODO(compiler): implement.
// fn unicode_is_printable(c: Char) -> Bool - true when c is not control, format or unassigned. TODO(compiler): implement.
// fn unicode_script_of(s: Str) -> Str - dominant script of s by character count. TODO(compiler): implement.
// fn unicode_scripts(s: Str) -> Vec[Str] - distinct scripts present in s, in first-seen order. TODO(compiler): implement.
// fn unicode_is_ideographic(c: Char) -> Bool - true when c is in an ideographic range (Han, Kana, Hangul). TODO(compiler): implement.

// --- Bidi (basic bidirectional support) ---

// fn unicode_bidi_class(c: Char) -> Str - bidi class of c, e.g. "L", "R", "AL", "NSM", "PDF". TODO(compiler): implement.
// fn unicode_mirrored(c: Char) -> Bool - true when c has the Bidi_Mirrored property. TODO(compiler): implement.
// fn unicode_mirror_char(c: Char) -> Char - mirrored counterpart of c, c itself when not mirrored. TODO(compiler): implement.
// fn unicode_bidi_brackets(s: Str) -> Vec[Str] - scan s for paired bidi bracket sets, e.g. "(" with ")". TODO(compiler): implement.
// fn unicode_bidi_level(c: Char) -> Int - implicit bidi embedding level of c (0..61). TODO(compiler): implement.
// fn unicode_bidi_scan(s: Str) -> Vec[Int] - resolved bidi levels of each char of s per the UBA rules. TODO(compiler): implement.

// --- Whitespace and numeric classification ---

// fn unicode_is_whitespace(c: Char) -> Bool - true when c matches the White_Space property. TODO(compiler): implement.
// fn unicode_is_alphabetic(c: Char) -> Bool - true when c has the Alphabetic property. TODO(compiler): implement.
// fn unicode_is_cased(c: Char) -> Bool - true when c has the Cased property. TODO(compiler): implement.
// fn unicode_is_numeric(c: Char) -> Bool - true when c has the Numeric_Type property. TODO(compiler): implement.
// fn unicode_decimal_value(c: Char) -> Option[Int] - decimal numeric value of c (Nd), None when not a decimal digit. TODO(compiler): implement.
// fn unicode_digit_value(c: Char) -> Option[Int] - digit numeric value of c (Nd and Nl/No digit forms), None otherwise. TODO(compiler): implement.
// fn unicode_numeric_value(c: Char) -> Option[Float] - full numeric value of c including fractions, None when none. TODO(compiler): implement.
