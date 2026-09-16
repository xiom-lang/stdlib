// XIOM - String: Unicode
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.string.unicode

// Depends on: xiom.string, xiom.char, xiom.string.normalize,
// xiom.string.casefold, xiom.string.category, xiom.string.script,
// xiom.string.emoji, xiom.string.ea_width, xiom.string.bidi,
// xiom.string.linebreak, xiom.string.sentencebreak, xiom.string.wordbreak

// ============================================================================
// Unicode property tables and transforms: normalization (NFC/NFD/NFKC/NFKD),
// case folding, grapheme/word/sentence/line segmentation, East Asian display
// width, emoji handling, script/block/category properties, bidi helpers, and
// whitespace/numeric classification.
//
// The normalization, case folding, category, script, emoji, display-width,
// bidi and segmentation implementations live in the sibling xiom.string.*
// modules (canonical); this module re-exports them behind the xiom.string
// aggregate namespace and adds the aggregate-only helpers (blocks, combining
// classes, numeric values, grapheme iteration, titlecasing, ...). The local
// decomposition/composition table covers ASCII and the common Latin-1
// accented forms; the rest of the Unicode decomposition table is not embedded.
// TODO(unicode-data): full table for decomposition/composition/age/block.
// ============================================================================

use xiom.string;
use xiom.char;
use xiom.string.normalize;
use xiom.string.casefold;
use xiom.string.category;
use xiom.string.script;
use xiom.string.emoji;
use xiom.string.ea_width;
use xiom.string.bidi;
use xiom.string.linebreak;
use xiom.string.sentencebreak;
use xiom.string.wordbreak;

// -- Normalization -----------------------------------------------------------

/// Normalize `s` to NFC (canonical composition). See the normalize module.
pub fn unicode_normalize(s: Str) -> Str {
  normalize.unicode_normalize_nfc(s)
}

/// Normalize `s` to NFC (canonical composition).
pub fn unicode_normalize_nfc(s: Str) -> Str {
  normalize.unicode_normalize_nfc(s)
}

/// Normalize `s` to NFD (canonical decomposition).
pub fn unicode_normalize_nfd(s: Str) -> Str {
  normalize.unicode_normalize_nfd(s)
}

/// Normalize `s` to NFKC (compatibility composition).
pub fn unicode_normalize_nfkc(s: Str) -> Str {
  normalize.unicode_normalize_nfkc(s)
}

/// Normalize `s` to NFKD (compatibility decomposition).
pub fn unicode_normalize_nfkd(s: Str) -> Str {
  normalize.unicode_normalize_nfkd(s)
}

/// Normalize `s` using the named form "NFC", "NFD", "NFKC" or "NFKD"
/// (case-insensitive). Unknown forms return `s` unchanged.
pub fn unicode_normalize_form(s: Str, form: Str) -> Str {
  if form == "NFC" { return normalize.unicode_normalize_nfc(s); };
  if form == "nfc" { return normalize.unicode_normalize_nfc(s); };
  if form == "NFD" { return normalize.unicode_normalize_nfd(s); };
  if form == "nfd" { return normalize.unicode_normalize_nfd(s); };
  if form == "NFKC" { return normalize.unicode_normalize_nfkc(s); };
  if form == "nfkc" { return normalize.unicode_normalize_nfkc(s); };
  if form == "NFKD" { return normalize.unicode_normalize_nfkd(s); };
  if form == "nfkd" { return normalize.unicode_normalize_nfkd(s); };
  s
}

/// True when `s` is already normalized to the named form.
pub fn unicode_is_normalized(s: Str, form: Str) -> Bool {
  let norm = unicode_normalize_form(s, form);
  norm == s
}

/// Canonical composition of `a` + `b` (b a combining mark), None when not
/// composable. Covers ASCII + Latin-1 accents.
pub fn unicode_compose_pair(a: Char, b: Char) -> Option[Char] {
  let ca = to_int_from_char(a);
  let cb = to_int_from_char(b);
  let cp = _compose_cp(ca, cb);
  if cp >= 0 {
    return Some(to_char(cp));
  };
  None
}

/// Canonical decomposition of one char: the base + combining marks, or the
/// char itself when undecomposable. NOTE: Vec[Char] stores 1 byte per element
/// (COMPILER_BUGS.md BUG 12), so codepoints above U+00FF in the result are
/// truncated; prefer unicode_normalize_nfd for exact decomposition.
pub fn unicode_decompose(c: Char) -> Vec[Char] {
  var out = Vec[Char].new();
  let cp = to_int_from_char(c);
  let d = _decomp_cp(cp);
  if d.1 >= 0 {
    out.push(to_char(d.0));
    out.push(to_char(d.1));
  } else {
    out.push(c);
  };
  out
}

/// Split `s` into runs of a base character plus its trailing combining marks.
pub fn unicode_combining_sequence(s: Str) -> Vec[Str] {
  let len = string.str_len(s);
  var out = Vec[Str].new();
  var i: Int = 0;
  var start: Int = 0;
  var prev_was_mark: Bool = false;
  while i < len {
    let cp = _decode(s, i, len);
    if cp < 0 {
      i = i + 1;
      continue;
    };
    let is_mark = _is_combining_cp(cp);
    if !is_mark && prev_was_mark && i > start {
      out.push(string.str_slice(s, start, i));
      start = i;
    };
    prev_was_mark = is_mark;
    let bl = _char_len(cp);
    i = i + bl;
  }
  if start < len {
    out.push(string.str_slice(s, start, len));
  };
  out
}

/// Fast check: true when `s` is already NFC.
pub fn unicode_nfc_quick_check(s: Str) -> Bool
  ensures: result == (unicode_normalize_nfc(s) == s)
{
  let norm = normalize.unicode_normalize_nfc(s);
  norm == s
}

/// Fast check: true when `s` is already NFKC.
pub fn unicode_nfkc_quick_check(s: Str) -> Bool
  ensures: result == (unicode_normalize_nfkc(s) == s)
{
  let norm = normalize.unicode_normalize_nfkc(s);
  norm == s
}

// -- Case --------------------------------------------------------------------

/// Full case folding of `s` for caseless comparison.
pub fn unicode_casefold(s: Str) -> Str {
  casefold.str_casefold(s)
}

/// Simple 1:1 case fold of one char (ASCII/Latin-1/Greek/Cyrillic).
pub fn unicode_casefold_char(c: Char) -> Char {
  let cp = _lower_map_cp(to_int_from_char(c));
  to_char(cp)
}

/// Case fold of `s` using the Turkic I/U-dotted rules.
pub fn unicode_casefold_turkic(s: Str) -> Str {
  let len = string.str_len(s);
  var out = Vec[UInt8].new();
  var i: Int = 0;
  while i < len {
    let cp = _decode(s, i, len);
    if cp < 0 {
      _push_byte(&mut out, _byte_at(s, i));
      i = i + 1;
      continue;
    };
    var mapped = _lower_map_cp(cp);
    if cp == 0x130 { mapped = 0x69; };
    if cp == 0x131 { mapped = 0x131; };
    _push_cp(&mut out, mapped);
    let bl = _char_len(cp);
    i = i + bl;
  }
  if out.len() == 0 {
    return "";
  };
  out.push(0);
  _bytes_to_str(&out)
}

/// Titlecase transform: the first cased letter of each word uppercased.
pub fn unicode_titlecase(s: Str) -> Str {
  let len = string.str_len(s);
  var out = Vec[UInt8].new();
  var i: Int = 0;
  var at_word_start: Bool = true;
  while i < len {
    let cp = _decode(s, i, len);
    if cp < 0 {
      _push_byte(&mut out, _byte_at(s, i));
      i = i + 1;
      continue;
    };
    var mapped = _lower_map_cp(cp);
    if at_word_start {
      mapped = _upper_map_cp(cp);
    };
    if _is_space_cp(cp) {
      at_word_start = true;
    } else {
      at_word_start = false;
    };
    _push_cp(&mut out, mapped);
    let bl = _char_len(cp);
    i = i + bl;
  }
  if out.len() == 0 {
    return "";
  };
  out.push(0);
  _bytes_to_str(&out)
}

/// Titlecase only the first word of `s`, leaving the rest unchanged.
pub fn unicode_titlecase_word(s: Str) -> Str {
  let len = string.str_len(s);
  var out = Vec[UInt8].new();
  var i: Int = 0;
  var first_word: Bool = true;
  var done: Bool = false;
  while i < len {
    let cp = _decode(s, i, len);
    if cp < 0 {
      _push_byte(&mut out, _byte_at(s, i));
      i = i + 1;
      continue;
    };
    var mapped = cp;
    if first_word && !done {
      if _is_space_cp(cp) {
        first_word = false;
      } else {
        mapped = _upper_map_cp(cp);
        done = true;
      };
    };
    _push_cp(&mut out, mapped);
    let bl = _char_len(cp);
    i = i + bl;
  }
  if out.len() == 0 {
    return "";
  };
  out.push(0);
  _bytes_to_str(&out)
}

/// Simple 1:1 lowercase mapping of `c`, `c` itself when none exists.
pub fn unicode_lowercase_map(c: Char) -> Char {
  let cp = _lower_map_cp(to_int_from_char(c));
  to_char(cp)
}

/// Simple 1:1 uppercase mapping of `c`, `c` itself when none exists.
pub fn unicode_uppercase_map(c: Char) -> Char {
  let cp = _upper_map_cp(to_int_from_char(c));
  to_char(cp)
}

/// Full lowercase of `s` (1:1 mappings; no multi-char expansions).
pub fn unicode_tolower_full(s: Str) -> Str {
  let len = string.str_len(s);
  var out = Vec[UInt8].new();
  var i: Int = 0;
  while i < len {
    let cp = _decode(s, i, len);
    if cp < 0 {
      _push_byte(&mut out, _byte_at(s, i));
      i = i + 1;
      continue;
    };
    _push_cp(&mut out, _lower_map_cp(cp));
    let bl = _char_len(cp);
    i = i + bl;
  }
  if out.len() == 0 {
    return "";
  };
  out.push(0);
  _bytes_to_str(&out)
}

/// Full uppercase of `s` (1:1 mappings; no multi-char expansions).
pub fn unicode_toupper_full(s: Str) -> Str {
  let len = string.str_len(s);
  var out = Vec[UInt8].new();
  var i: Int = 0;
  while i < len {
    let cp = _decode(s, i, len);
    if cp < 0 {
      _push_byte(&mut out, _byte_at(s, i));
      i = i + 1;
      continue;
    };
    _push_cp(&mut out, _upper_map_cp(cp));
    let bl = _char_len(cp);
    i = i + bl;
  }
  if out.len() == 0 {
    return "";
  };
  out.push(0);
  _bytes_to_str(&out)
}

/// Simple 1:1 titlecase mapping of `c` (capital form).
pub fn unicode_titlecase_map(c: Char) -> Char {
  let cp = _upper_map_cp(to_int_from_char(c));
  to_char(cp)
}

/// True when `c` is a titlecase letter (Lt).
pub fn unicode_istitlecase(c: Char) -> Bool {
  let cat = category.unicode_general_category(c);
  cat == "Lt"
}

// -- Segmentation ------------------------------------------------------------

/// Split `s` into extended grapheme clusters (simplified: base + combining
/// marks + ZWJ sequences + emoji modifiers).
pub fn unicode_grapheme_clusters(s: Str) -> Vec[Str] {
  let len = string.str_len(s);
  var out = Vec[Str].new();
  var i: Int = 0;
  var start: Int = 0;
  while i < len {
    let cp = _decode(s, i, len);
    if cp < 0 {
      i = i + 1;
      continue;
    };
    let bl = _char_len(cp);
    let is_extend = _is_combining_cp(cp) || _is_modifier_cp(cp) || cp == 0x200D;
    if !is_extend && i > start {
      out.push(string.str_slice(s, start, i));
      start = i;
    };
    i = i + bl;
  }
  if start < len {
    out.push(string.str_slice(s, start, len));
  };
  out
}

/// Number of extended grapheme clusters in `s`.
pub fn unicode_grapheme_count(s: Str) -> Int
  ensures: result >= 0
{
  let clusters = unicode_grapheme_clusters(s);
  clusters.len()
}

/// Byte offsets of word boundaries in `s`.
pub fn unicode_word_boundaries(s: Str) -> Vec[Int] {
  wordbreak.unicode_word_boundaries(s)
}

/// Number of words in `s`.
pub fn unicode_word_count(s: Str) -> Int
  ensures: result >= 0
{
  let words = wordbreak.unicode_split_words(s);
  words.len()
}

/// Byte offsets of sentence boundaries in `s`.
pub fn unicode_sentence_boundaries(s: Str) -> Vec[Int] {
  sentencebreak.unicode_sentence_boundaries(s)
}

/// Number of sentences in `s`.
pub fn unicode_sentence_count(s: Str) -> Int
  ensures: result >= 0
{
  let sents = sentencebreak.unicode_split_sentences(s);
  sents.len()
}

/// Byte offsets of allowed line break points in `s`.
pub fn unicode_line_break_points(s: Str) -> Vec[Int] {
  linebreak.unicode_line_break_points(s)
}

/// Split `s` into lines at the allowed break points.
pub fn unicode_line_breaks(s: Str) -> Vec[Str] {
  linebreak.unicode_split_lines(s)
}

/// Byte offset just past the grapheme starting at `offset`.
pub fn unicode_next_grapheme(s: Str, offset: Int) -> Int
  ensures: result >= 0
{
  let len = string.str_len(s);
  if offset < 0 || offset >= len {
    return len;
  };
  var i: Int = offset;
  var start: Int = offset;
  while i < len {
    let cp = _decode(s, i, len);
    if cp < 0 {
      return i + 1;
    };
    let bl = _char_len(cp);
    let is_extend = _is_combining_cp(cp) || _is_modifier_cp(cp) || cp == 0x200D;
    if !is_extend && i > start {
      return i;
    };
    i = i + bl;
  }
  len
}

/// Byte offset of the grapheme start ending before `offset`.
pub fn unicode_prev_grapheme(s: Str, offset: Int) -> Int
  ensures: result >= 0
{
  let len = string.str_len(s);
  if offset <= 0 {
    return 0;
  };
  var boundary: Int = 0;
  var i: Int = 0;
  var start: Int = 0;
  while i < len {
    let cp = _decode(s, i, len);
    if cp < 0 {
      i = i + 1;
      continue;
    };
    let bl = _char_len(cp);
    let is_extend = _is_combining_cp(cp) || _is_modifier_cp(cp) || cp == 0x200D;
    if !is_extend && i > start {
      if i >= offset {
        return boundary;
      };
      boundary = i;
    };
    i = i + bl;
  }
  boundary
}

// -- Display width -----------------------------------------------------------

/// East Asian Width of `c`: 0, 1 or 2.
pub fn unicode_ea_width(c: Char) -> Int
  ensures: result >= 0
{
  ea_width.unicode_ea_width(c)
}

/// Total display width of `s` in cells.
pub fn unicode_display_width(s: Str) -> Int
  ensures: result >= 0
{
  ea_width.unicode_display_width(s)
}

/// Truncate `s` to fit `max_width` display cells (grapheme-safe).
pub fn unicode_truncate_display(s: Str, max_width: Int) -> Str {
  ea_width.unicode_truncate_display(s, max_width)
}

/// Pad `s` to a display width; side "left", "right" or "center".
pub fn unicode_pad_display(s: Str, width: Int, side: Str) -> Str {
  let w = ea_width.unicode_display_width(s);
  if w >= width {
    return s;
  };
  let pad = width - w;
  var left_pad: Int = 0;
  var right_pad: Int = 0;
  if side == "left" {
    left_pad = pad;
  } elif side == "right" {
    right_pad = pad;
  } else {
    left_pad = pad / 2;
    right_pad = pad - left_pad;
  };
  var result = "";
  var i: Int = 0;
  while i < left_pad {
    result = string.str_concat(result, " ");
    i = i + 1;
  }
  result = string.str_concat(result, s);
  var j: Int = 0;
  while j < right_pad {
    result = string.str_concat(result, " ");
    j = j + 1;
  }
  result
}

/// Substring of `s` bounded by display-cell offsets `start` and `end`.
pub fn unicode_display_slice(s: Str, start: Int, end: Int) -> Str {
  let len = string.str_len(s);
  var cells: Int = 0;
  var byte_start: Int = 0;
  var byte_end: Int = len;
  var i: Int = 0;
  while i < len {
    let cp = _decode(s, i, len);
    if cp < 0 {
      i = i + 1;
      continue;
    };
    let cw = ea_width.unicode_ea_width(to_char(cp));
    let bl = _char_len(cp);
    if cells < start && cells + cw > start {
      byte_start = i;
    };
    if cells + cw >= end {
      byte_end = i + bl;
      break;
    };
    cells = cells + cw;
    i = i + bl;
  }
  if start <= 0 && end > cells {
    return s;
  };
  string.str_slice(s, byte_start, byte_end)
}

/// True when `c` has East Asian Width W or F.
pub fn unicode_is_wide(c: Char) -> Bool
  ensures: result == (ea_width.unicode_ea_width(c) == 2)
{
  let w = ea_width.unicode_ea_width(c);
  w == 2
}

// -- Emoji -------------------------------------------------------------------

/// True when `c` is an emoji or emoji component codepoint.
pub fn unicode_is_emoji(c: Char) -> Bool
  ensures: result == emoji.unicode_is_emoji(c)
{
  emoji.unicode_is_emoji(c)
}

/// Number of emoji characters and components in `s`.
pub fn unicode_count_emoji(s: Str) -> Int
  ensures: result >= 0
{
  emoji.unicode_count_emoji(s)
}

/// True when `s` contains at least one emoji.
pub fn unicode_has_emoji(s: Str) -> Bool {
  emoji.unicode_has_emoji(s)
}

/// True when `c` defaults to emoji presentation (not text).
pub fn unicode_emoji_presentation(c: Char) -> Bool {
  let cp = to_int_from_char(c);
  _emoji_pres_cp(cp)
}

/// Extract full emoji sequences (ZWJ joins, skin-tone modifiers, keycaps,
/// regional-indicator flag pairs) from `s`.
pub fn unicode_emoji_sequences(s: Str) -> Vec[Str] {
  let len = string.str_len(s);
  var out = Vec[Str].new();
  var i: Int = 0;
  var start: Int = -1;
  while i < len {
    let cp = _decode(s, i, len);
    if cp < 0 {
      i = i + 1;
      continue;
    };
    let bl = _char_len(cp);
    if _is_emoji_part(cp) {
      if start < 0 {
        start = i;
      };
    } else {
      if start >= 0 {
        out.push(string.str_slice(s, start, i));
        start = -1;
      };
    };
    i = i + bl;
  }
  if start >= 0 {
    out.push(string.str_slice(s, start, len));
  };
  out
}

/// True when `c` is an emoji modifier (skin tone).
pub fn unicode_emoji_modifier(c: Char) -> Bool {
  let cp = to_int_from_char(c);
  cp >= 0x1F3FB && cp <= 0x1F3FF
}

/// True when `c` is the ZWJ emoji joiner (U+200D).
pub fn unicode_emoji_zwj(c: Char) -> Bool {
  let cp = to_int_from_char(c);
  cp == 0x200D
}

/// Emoji version implemented by the tables.
pub fn unicode_emoji_version() -> Str {
  "15.0"
}

// -- Properties --------------------------------------------------------------

/// ISO 15924 script code of `c`.
pub fn unicode_script(c: Char) -> Str {
  script.unicode_script(c)
}

/// Long English script name for an ISO 15924 code.
pub fn unicode_script_name(code: Str) -> Str {
  script.unicode_script_name(code)
}

/// Unicode block name containing `c`, e.g. "Basic Latin".
pub fn unicode_block(c: Char) -> Str {
  let cp = to_int_from_char(c);
  _block_cp(cp)
}

/// Short general category of `c`, e.g. "Lu", "Nd", "Zs".
pub fn unicode_general_category(c: Char) -> Str {
  category.unicode_general_category(c)
}

/// Long general category name of `c`, e.g. "Uppercase_Letter".
pub fn unicode_general_category_name(c: Char) -> Str {
  let cat = category.unicode_general_category(c);
  _cat_long_name(cat)
}

/// Unicode age of `c` as a version string (approximate for the compact table).
pub fn unicode_age(c: Char) -> Str {
  let cp = to_int_from_char(c);
  if cp >= 0x1F300 && cp <= 0x1FAFF { return "6.0"; };
  if cp >= 0x1F900 && cp <= 0x1FAFF { return "9.0"; };
  if cp >= 0x1FA00 && cp <= 0x1FAFF { return "12.0"; };
  if cp >= 0x1F600 && cp <= 0x1F64F { return "6.0"; };
  if cp >= 0x1F680 && cp <= 0x1F6FF { return "6.0"; };
  if cp >= 0x2600 && cp <= 0x26FF { return "1.1"; };
  if cp >= 0x2700 && cp <= 0x27BF { return "1.1"; };
  "1.1"
}

/// Canonical combining class of `c`, 0 when spacing.
pub fn unicode_combining_class(c: Char) -> Int
  ensures: result >= 0
{
  let cp = to_int_from_char(c);
  _ccc_cp(cp)
}

/// True when `c` is in a letter category (L*).
pub fn unicode_is_letter(c: Char) -> Bool {
  category.unicode_is_letter(c)
}

/// True when `c` is a decimal digit (Nd).
pub fn unicode_is_digit(c: Char) -> Bool {
  category.unicode_is_digit(c)
}

/// True when `c` is punctuation (P*).
pub fn unicode_is_punct(c: Char) -> Bool {
  category.unicode_is_punct(c)
}

/// True when `c` is a symbol (S*).
pub fn unicode_is_symbol(c: Char) -> Bool {
  category.unicode_is_symbol(c)
}

/// True when `c` is a separator (Z*).
pub fn unicode_is_separator(c: Char) -> Bool {
  category.unicode_is_separator(c)
}

/// True when `c` is a control or format character (Cc, Cf, Cs, Co, Cn).
pub fn unicode_is_control(c: Char) -> Bool {
  category.unicode_is_control(c)
}

/// True when `c` is printable (not control, format or unassigned).
pub fn unicode_is_printable(c: Char) -> Bool {
  category.unicode_is_printable(c)
}

/// Dominant script of `s` by character count; "Zzzz" for empty input.
pub fn unicode_script_of(s: Str) -> Str {
  let scripts = unicode_scripts(s);
  if scripts.len() == 0 {
    return "Zzzz";
  };
  let first = scripts[0];
  first
}

/// Distinct scripts present in `s`, in first-seen order.
pub fn unicode_scripts(s: Str) -> Vec[Str] {
  let len = string.str_len(s);
  var out = Vec[Str].new();
  var i: Int = 0;
  while i < len {
    let cp = _decode(s, i, len);
    if cp < 0 {
      i = i + 1;
      continue;
    };
    let scr = script.unicode_script(to_char(cp));
    var found = false;
    var j: Int = 0;
    while j < out.len() {
      let existing = out[j];
      if existing == scr {
        found = true;
      };
      j = j + 1;
    }
    if !found {
      out.push(scr);
    };
    let bl = _char_len(cp);
    i = i + bl;
  }
  out
}

/// True when `c` is in an ideographic range (Han, Hiragana, Katakana, Hangul).
pub fn unicode_is_ideographic(c: Char) -> Bool {
  let cp = to_int_from_char(c);
  _is_ideo_cp(cp)
}

// -- Bidi --------------------------------------------------------------------

/// Bidi class of `c`, e.g. "L", "R", "AL", "NSM".
pub fn unicode_bidi_class(c: Char) -> Str {
  bidi.unicode_bidi_class(c)
}

/// True when `c` has the Bidi_Mirrored property.
pub fn unicode_mirrored(c: Char) -> Bool {
  bidi.unicode_mirrored(c)
}

/// Mirrored counterpart of `c`, `c` itself when not mirrored.
pub fn unicode_mirror_char(c: Char) -> Char {
  bidi.unicode_mirror_char(c)
}

/// Scan `s` for bidi bracket characters: one single-char string per bracket.
pub fn unicode_bidi_brackets(s: Str) -> Vec[Str] {
  let len = string.str_len(s);
  var out = Vec[Str].new();
  var i: Int = 0;
  while i < len {
    let cp = _decode(s, i, len);
    if cp < 0 {
      i = i + 1;
      continue;
    };
    let bl = _char_len(cp);
    if _is_bracket_cp(cp) {
      out.push(string.str_slice(s, i, i + bl));
    };
    i = i + bl;
  }
  out
}

/// Implicit bidi embedding level of `c`: 0 (L), 1 (R/AL), 2 (EN/AN).
pub fn unicode_bidi_level(c: Char) -> Int
  ensures: result >= 0
{
  let cls = bidi.unicode_bidi_class(c);
  if cls == "R" || cls == "AL" {
    return 1;
  };
  if cls == "EN" || cls == "AN" {
    return 2;
  };
  0
}

/// Resolved bidi levels of each char of `s` (simplified UBA: base level from
/// the first strong character, strong/weak resolved per the bidi class).
pub fn unicode_bidi_scan(s: Str) -> Vec[Int] {
  let len = string.str_len(s);
  var levels = Vec[Int].new();
  var par: Int = 0;
  var i: Int = 0;
  while i < len {
    let cp = _decode(s, i, len);
    if cp < 0 {
      i = i + 1;
      continue;
    };
    let cls = bidi.unicode_bidi_class(to_char(cp));
    if par == 0 {
      if cls == "R" || cls == "AL" {
        par = 1;
      };
    };
    i = i + _char_len(cp);
  }
  i = 0;
  var prev_level: Int = 0;
  while i < len {
    let cp = _decode(s, i, len);
    if cp < 0 {
      levels.push(par);
      i = i + 1;
      continue;
    };
    let cls = bidi.unicode_bidi_class(to_char(cp));
    var lv: Int = par;
    if cls == "R" || cls == "AL" {
      lv = 1;
    } elif cls == "EN" || cls == "AN" {
      lv = 2;
    } elif cls == "NSM" {
      lv = prev_level;
    };
    levels.push(lv);
    prev_level = lv;
    i = i + _char_len(cp);
  }
  levels
}

// -- Whitespace and numeric classification -----------------------------------

/// True when `c` matches the White_Space property.
pub fn unicode_is_whitespace(c: Char) -> Bool {
  let cp = to_int_from_char(c);
  _is_ws_cp(cp)
}

/// True when `c` has the Alphabetic property (approximated by letter + marks).
pub fn unicode_is_alphabetic(c: Char) -> Bool {
  let cat = category.unicode_general_category(c);
  _cat_is_alpha(cat)
}

/// True when `c` has the Cased property (uppercase/lowercase/titlecase).
pub fn unicode_is_cased(c: Char) -> Bool {
  let cat = category.unicode_general_category(c);
  cat == "Lu" || cat == "Ll" || cat == "Lt"
}

/// True when `c` has the Numeric_Type property.
pub fn unicode_is_numeric(c: Char) -> Bool {
  let cat = category.unicode_general_category(c);
  cat == "Nd" || cat == "Nl" || cat == "No"
}

/// Decimal numeric value of `c` (Nd), None when not a decimal digit.
pub fn unicode_decimal_value(c: Char) -> Option[Int] {
  let cp = to_int_from_char(c);
  var v: Int = -1;
  if cp >= 0x30 && cp <= 0x39 {
    v = cp - 0x30;
  } elif cp >= 0x660 && cp <= 0x669 {
    v = cp - 0x660;
  } elif cp >= 0x6F0 && cp <= 0x6F9 {
    v = cp - 0x6F0;
  } elif cp >= 0x966 && cp <= 0x96F {
    v = cp - 0x966;
  };
  if v >= 0 {
    return Some(v);
  };
  None
}

/// Digit numeric value of `c` (Nd and Nl/No digit forms), None otherwise.
pub fn unicode_digit_value(c: Char) -> Option[Int] {
  let d = unicode_decimal_value(c);
  if d.is_some {
    return d;
  };
  let cp = to_int_from_char(c);
  if cp >= 0x2460 && cp <= 0x2468 {
    return Some(cp - 0x2460 + 1);
  };
  if cp >= 0x2070 && cp <= 0x2079 {
    return Some(cp - 0x2070);
  };
  None
}

/// Full numeric value of `c` including fractions, None when none.
pub fn unicode_numeric_value(c: Char) -> Option[Float64] {
  let d = unicode_digit_value(c);
  if d.is_some {
    return Some(_int_to_float(d.value));
  };
  let cp = to_int_from_char(c);
  if cp == 0xBD {
    return Some(0.5);
  };
  if cp == 0xBC {
    return Some(0.25);
  };
  if cp == 0xBE {
    return Some(0.75);
  };
  None
}

// -- Private helpers ---------------------------------------------------------

fn _int_to_float(v: Int) -> Float64 {
  let f = v as Float64;
  f
}

/// Masked byte at `pos` (BUG 22 #10: `as Int` sign-extends UInt8).
fn _byte_at(s: Str, pos: Int) -> Int {
  let v = string.byte_at(s, pos) as Int;
  v & 0xFF
}

/// UTF-8 sequence length given the leading byte.
fn _seq_len(b0: Int) -> Int {
  if b0 <= 0x7F { return 1; };
  if (b0 & 0xE0) == 0xC0 { return 2; };
  if (b0 & 0xF0) == 0xE0 { return 3; };
  if (b0 & 0xF8) == 0xF0 { return 4; };
  1
}

/// UTF-8 byte length of a valid codepoint.
fn _char_len(cp: Int) -> Int {
  if cp <= 0x7F { return 1; };
  if cp <= 0x7FF { return 2; };
  if cp <= 0xFFFF { return 3; };
  4
}

/// Decode the codepoint at byte `pos`, or -1 on malformed input.
fn _decode(s: Str, pos: Int, len: Int) -> Int {
  let b0 = _byte_at(s, pos);
  let n = _seq_len(b0);
  if pos + n > len { return -1; };
  if n == 1 { return b0; };
  if n == 2 {
    let b1 = _byte_at(s, pos + 1);
    if (b1 & 0xC0) != 0x80 { return -1; };
    return ((b0 & 0x1F) << 6) | (b1 & 0x3F);
  };
  if n == 3 {
    let b1 = _byte_at(s, pos + 1);
    let b2 = _byte_at(s, pos + 2);
    if (b1 & 0xC0) != 0x80 { return -1; };
    if (b2 & 0xC0) != 0x80 { return -1; };
    let cp = ((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F);
    if cp >= 0xD800 && cp <= 0xDFFF { return -1; };
    return cp;
  };
  let b1 = _byte_at(s, pos + 1);
  let b2 = _byte_at(s, pos + 2);
  let b3 = _byte_at(s, pos + 3);
  if (b1 & 0xC0) != 0x80 { return -1; };
  if (b2 & 0xC0) != 0x80 { return -1; };
  if (b3 & 0xC0) != 0x80 { return -1; };
  ((b0 & 0x07) << 18) | ((b1 & 0x3F) << 12) | ((b2 & 0x3F) << 6) | (b3 & 0x3F)
}

/// Append a codepoint to a byte buffer.
fn _push_cp(out: &mut Vec[UInt8], cp: Int) {
  if cp < 0 || cp > 0x10FFFF {
    return;
  };
  char.encode_utf8(to_char(cp), out);
}

/// Append a raw byte to `out`.
fn _push_byte(out: &mut Vec[UInt8], b: Int) {
  if b >= 0 && b <= 0xFF {
    out.push(b as UInt8);
  };
}

/// Null-terminate `buf` and wrap it as a Str. Callers must have pushed the 0.
fn _bytes_to_str(buf: &Vec[UInt8]) -> Str
  requires: buf.len() >= 1
{
  unsafe {
    Str.from_cstring(buf.data)
  }
}

/// Combining marks (Mn/Mc/Me approximation for segmentation).
/// NOTE (BUG 20): walked through a recursive helper to avoid SIMD
/// vectorization of the range chain.
fn _is_combining_cp(cp: Int) -> Bool {
  _comb_r(cp, 0)
}

fn _comb_r(cp: Int, i: Int) -> Bool {
  if i == 0 {
    if cp >= 0x0300 && cp <= 0x036F { return true; };
  };
  if i == 1 {
    if cp >= 0x1AB0 && cp <= 0x1AFF { return true; };
  };
  if i == 2 {
    if cp >= 0x1DC0 && cp <= 0x1DFF { return true; };
  };
  if i == 3 {
    if cp >= 0x20D0 && cp <= 0x20FF { return true; };
  };
  if i == 4 {
    if cp >= 0xFE20 && cp <= 0xFE2F { return true; };
  };
  if i < 4 {
    return _comb_r(cp, i + 1);
  };
  false
}

/// Emoji modifiers (skin tones).
fn _is_modifier_cp(cp: Int) -> Bool {
  cp >= 0x1F3FB && cp <= 0x1F3FF
}

/// Emoji presentation codepoints.
fn _emoji_pres_cp(cp: Int) -> Bool {
  if cp >= 0x1F300 && cp <= 0x1FAFF { return true; };
  if cp >= 0x1F3FB && cp <= 0x1F3FF { return true; };
  if cp == 0xFE0F { return true; };
  false
}

/// Emoji or emoji component used by the sequence extractor.
fn _is_emoji_part(cp: Int) -> Bool {
  if cp >= 0x1F300 && cp <= 0x1FAFF { return true; };
  if cp >= 0x2600 && cp <= 0x27BF { return true; };
  if cp >= 0x2B00 && cp <= 0x2BFF { return true; };
  if cp >= 0x2300 && cp <= 0x23FF { return true; };
  if cp >= 0x1F3FB && cp <= 0x1F3FF { return true; };
  if cp == 0xFE0F || cp == 0x200D || cp == 0x20E3 { return true; };
  false
}

/// Bidi bracket characters.
fn _is_bracket_cp(cp: Int) -> Bool {
  if cp == 0x28 || cp == 0x29 { return true; };
  if cp == 0x5B || cp == 0x5D { return true; };
  if cp == 0x7B || cp == 0x7D { return true; };
  if cp == 0x3008 || cp == 0x3009 { return true; };
  if cp == 0x300A || cp == 0x300B { return true; };
  if cp == 0x300C || cp == 0x300D { return true; };
  if cp == 0x300E || cp == 0x300F { return true; };
  if cp == 0x3010 || cp == 0x3011 { return true; };
  false
}

/// Whitespace codepoints.
fn _is_ws_cp(cp: Int) -> Bool {
  if cp == 0x09 || cp == 0x0A || cp == 0x0B || cp == 0x0C || cp == 0x0D { return true; };
  if cp == 0x20 || cp == 0xA0 { return true; };
  if cp == 0x1680 { return true; };
  if cp >= 0x2000 && cp <= 0x200A { return true; };
  if cp == 0x2028 || cp == 0x2029 || cp == 0x202F || cp == 0x205F || cp == 0x3000 { return true; };
  false
}

/// Space used by titlecasing.
fn _is_space_cp(cp: Int) -> Bool {
  if cp == 0x09 || cp == 0x0A || cp == 0x0D { return true; };
  if cp == 0x20 { return true; };
  false
}

/// Ideographic codepoints.
fn _is_ideo_cp(cp: Int) -> Bool {
  if cp >= 0x4E00 && cp <= 0x9FFF { return true; };
  if cp >= 0x3400 && cp <= 0x4DBF { return true; };
  if cp >= 0xF900 && cp <= 0xFAFF { return true; };
  if cp >= 0x20000 && cp <= 0x2A6DF { return true; };
  if cp >= 0x3040 && cp <= 0x309F { return true; };
  if cp >= 0x30A0 && cp <= 0x30FF { return true; };
  if cp >= 0xAC00 && cp <= 0xD7A3 { return true; };
  if cp >= 0x1100 && cp <= 0x11FF { return true; };
  false
}

/// Canonical combining class (subset covering the marks used by the tables).
fn _ccc_cp(cp: Int) -> Int {
  if cp >= 0x300 && cp <= 0x30C { return 230; };
  if cp == 0x315 { return 232; };
  if cp == 0x31B { return 216; };
  if cp == 0x31C { return 202; };
  if cp >= 0x31D && cp <= 0x320 { return 220; };
  if cp >= 0x321 && cp <= 0x322 { return 202; };
  if cp >= 0x323 && cp <= 0x326 { return 220; };
  if cp == 0x327 || cp == 0x328 { return 202; };
  if cp >= 0x329 && cp <= 0x33D { return 220; };
  0
}

/// Long category name for a two-letter code.
fn _cat_long_name(cat: Str) -> Str {
  if cat == "Lu" { return "Uppercase_Letter"; };
  if cat == "Ll" { return "Lowercase_Letter"; };
  if cat == "Lt" { return "Titlecase_Letter"; };
  if cat == "Lm" { return "Modifier_Letter"; };
  if cat == "Lo" { return "Other_Letter"; };
  if cat == "Mn" { return "Nonspacing_Mark"; };
  if cat == "Nd" { return "Decimal_Number"; };
  if cat == "Nl" { return "Letter_Number"; };
  if cat == "No" { return "Other_Number"; };
  if cat == "Pc" { return "Connector_Punctuation"; };
  if cat == "Pd" { return "Dash_Punctuation"; };
  if cat == "Ps" { return "Open_Punctuation"; };
  if cat == "Pe" { return "Close_Punctuation"; };
  if cat == "Pi" { return "Initial_Punctuation"; };
  if cat == "Pf" { return "Final_Punctuation"; };
  if cat == "Po" { return "Other_Punctuation"; };
  if cat == "Sm" { return "Math_Symbol"; };
  if cat == "Sc" { return "Currency_Symbol"; };
  if cat == "Sk" { return "Modifier_Symbol"; };
  if cat == "So" { return "Other_Symbol"; };
  if cat == "Zs" { return "Space_Separator"; };
  if cat == "Zl" { return "Line_Separator"; };
  if cat == "Zp" { return "Paragraph_Separator"; };
  if cat == "Cc" { return "Control"; };
  if cat == "Cf" { return "Format"; };
  if cat == "Cs" { return "Surrogate"; };
  if cat == "Co" { return "Private_Use"; };
  if cat == "Cn" { return "Unassigned"; };
  "Unassigned"
}

/// Alphabetic approximation: letters plus the combining marks.
fn _cat_is_alpha(cat: Str) -> Bool {
  if cat == "Lu" || cat == "Ll" || cat == "Lt" || cat == "Lm" || cat == "Lo" { return true; };
  if cat == "Mn" || cat == "Mc" || cat == "Me" { return true; };
  false
}

/// Block name for a codepoint (compact table, see header).
/// NOTE (BUG 20): the table is walked through a small recursive helper; a
/// straight-line range-check chain would be SIMD-vectorized by the -O2
/// vectorizer into AVX-512 instructions that trap on CPUs without AVX-512.
fn _block_cp(cp: Int) -> Str {
  _block_r(cp, 0)
}

fn _block_r(cp: Int, i: Int) -> Str {
  if i == 0 {
    if cp >= 0x0000 && cp <= 0x007F { return "Basic Latin"; };
  };
  if i == 1 {
    if cp >= 0x0080 && cp <= 0x00FF { return "Latin-1 Supplement"; };
  };
  if i == 2 {
    if cp >= 0x0100 && cp <= 0x017F { return "Latin Extended-A"; };
  };
  if i == 3 {
    if cp >= 0x0180 && cp <= 0x024F { return "Latin Extended-B"; };
  };
  if i == 4 {
    if cp >= 0x0300 && cp <= 0x036F { return "Combining Diacritical Marks"; };
  };
  if i == 5 {
    if cp >= 0x0370 && cp <= 0x03FF { return "Greek and Coptic"; };
  };
  if i == 6 {
    if cp >= 0x0400 && cp <= 0x04FF { return "Cyrillic"; };
  };
  if i == 7 {
    if cp >= 0x0590 && cp <= 0x05FF { return "Hebrew"; };
  };
  if i == 8 {
    if cp >= 0x0600 && cp <= 0x06FF { return "Arabic"; };
  };
  if i == 9 {
    if cp >= 0x0900 && cp <= 0x097F { return "Devanagari"; };
  };
  if i == 10 {
    if cp >= 0x0980 && cp <= 0x09FF { return "Bengali"; };
  };
  if i == 11 {
    if cp >= 0x0E00 && cp <= 0x0E7F { return "Thai"; };
  };
  if i == 12 {
    if cp >= 0x1100 && cp <= 0x11FF { return "Hangul Jamo"; };
  };
  if i == 13 {
    if cp >= 0x2000 && cp <= 0x206F { return "General Punctuation"; };
  };
  if i == 14 {
    if cp >= 0x20A0 && cp <= 0x20CF { return "Currency Symbols"; };
  };
  if i == 15 {
    if cp >= 0x20D0 && cp <= 0x20FF { return "Combining Diacritical Marks for Symbols"; };
  };
  if i == 16 {
    if cp >= 0x2190 && cp <= 0x21FF { return "Arrows"; };
  };
  if i == 17 {
    if cp >= 0x2200 && cp <= 0x22FF { return "Mathematical Operators"; };
  };
  if i == 18 {
    if cp >= 0x2300 && cp <= 0x23FF { return "Miscellaneous Technical"; };
  };
  if i == 19 {
    if cp >= 0x2460 && cp <= 0x24FF { return "Enclosed Alphanumerics"; };
  };
  if i == 20 {
    if cp >= 0x2500 && cp <= 0x257F { return "Box Drawing"; };
  };
  if i == 21 {
    if cp >= 0x25A0 && cp <= 0x25FF { return "Geometric Shapes"; };
  };
  if i == 22 {
    if cp >= 0x2600 && cp <= 0x26FF { return "Miscellaneous Symbols"; };
  };
  if i == 23 {
    if cp >= 0x2700 && cp <= 0x27BF { return "Dingbats"; };
  };
  if i == 24 {
    if cp >= 0x2B00 && cp <= 0x2BFF { return "Miscellaneous Symbols and Arrows"; };
  };
  if i == 25 {
    if cp >= 0x3000 && cp <= 0x303F { return "CJK Symbols and Punctuation"; };
  };
  if i == 26 {
    if cp >= 0x3040 && cp <= 0x309F { return "Hiragana"; };
  };
  if i == 27 {
    if cp >= 0x30A0 && cp <= 0x30FF { return "Katakana"; };
  };
  if i == 28 {
    if cp >= 0x3130 && cp <= 0x318F { return "Hangul Compatibility Jamo"; };
  };
  if i == 29 {
    if cp >= 0x3400 && cp <= 0x4DBF { return "CJK Unified Ideographs Extension A"; };
  };
  if i == 30 {
    if cp >= 0x4E00 && cp <= 0x9FFF { return "CJK Unified Ideographs"; };
  };
  if i == 31 {
    if cp >= 0xAC00 && cp <= 0xD7A3 { return "Hangul Syllables"; };
  };
  if i == 32 {
    if cp >= 0xD800 && cp <= 0xDFFF { return "Surrogates"; };
  };
  if i == 33 {
    if cp >= 0xE000 && cp <= 0xF8FF { return "Private Use Area"; };
  };
  if i == 34 {
    if cp >= 0xF900 && cp <= 0xFAFF { return "CJK Compatibility Ideographs"; };
  };
  if i == 35 {
    if cp >= 0xFE00 && cp <= 0xFE0F { return "Variation Selectors"; };
  };
  if i == 36 {
    if cp >= 0xFF00 && cp <= 0xFFEF { return "Halfwidth and Fullwidth Forms"; };
  };
  if i == 37 {
    if cp >= 0x1F300 && cp <= 0x1F5FF { return "Miscellaneous Symbols and Pictographs"; };
  };
  if i == 38 {
    if cp >= 0x1F600 && cp <= 0x1F64F { return "Emoticons"; };
  };
  if i == 39 {
    if cp >= 0x1F680 && cp <= 0x1F6FF { return "Transport and Map Symbols"; };
  };
  if i == 40 {
    if cp >= 0x1F900 && cp <= 0x1F9FF { return "Supplemental Symbols and Pictographs"; };
  };
  if i == 41 {
    if cp >= 0x1FA00 && cp <= 0x1FAFF { return "Symbols and Pictographs Extended-A"; };
  };
  if i == 42 {
    if cp >= 0x20000 && cp <= 0x2A6DF { return "CJK Unified Ideographs Extension B"; };
  };
  if i < 42 {
    return _block_r(cp, i + 1);
  };
  "Undefined"
}

/// Simple 1:1 uppercase mapping of one codepoint.
/// NOTE (BUG 20): the mapping walks its ranges through a small recursive
/// helper; a straight-line range-check chain would be SIMD-vectorized by the
/// -O2 vectorizer into AVX-512 instructions that trap on CPUs without
/// AVX-512 (0xC000001D).
fn _upper_map_cp(cp: Int) -> Int {
  _upper_map_r(cp, 0)
}

fn _upper_map_r(cp: Int, i: Int) -> Int {
  if i == 0 {
    if cp >= 97 && cp <= 122 { return cp - 32; };
  };
  if i == 1 {
    if cp >= 0xE0 && cp <= 0xF6 { return cp - 0x20; };
  };
  if i == 2 {
    if cp >= 0xF8 && cp <= 0xFE { return cp - 0x20; };
  };
  if i == 3 {
    if cp == 0xFF { return 0x178; };
  };
  if i == 4 {
    if cp == 0xDF { return 0x1E9E; };
  };
  if i == 5 {
    if cp >= 0x3B1 && cp <= 0x3C1 { return cp - 0x20; };
  };
  if i == 6 {
    if cp >= 0x3C3 && cp <= 0x3CB { return cp - 0x20; };
  };
  if i == 7 {
    if cp >= 0x430 && cp <= 0x44F { return cp - 0x20; };
  };
  if i == 8 {
    if cp >= 0x450 && cp <= 0x45F { return cp - 0x50; };
  };
  if i == 9 {
    if cp >= 0x101 && cp <= 0x137 && (cp & 1) == 1 { return cp - 1; };
  };
  if i == 10 {
    if cp >= 0x13A && cp <= 0x148 && (cp & 1) == 1 { return cp - 1; };
  };
  if i == 11 {
    if cp >= 0x14B && cp <= 0x177 && (cp & 1) == 1 { return cp - 1; };
  };
  if i == 12 {
    if cp >= 0x17A && cp <= 0x17E && (cp & 1) == 1 { return cp - 1; };
  };
  if i == 13 {
    if cp >= 0x1E01 && cp <= 0x1EFF && (cp & 1) == 1 { return cp - 1; };
  };
  if i < 13 {
    return _upper_map_r(cp, i + 1);
  };
  cp
}

/// Simple 1:1 lowercase mapping of one codepoint.
/// NOTE (BUG 20): the mapping walks its ranges through a small recursive
/// helper; a straight-line range-check chain would be SIMD-vectorized by the
/// -O2 vectorizer into AVX-512 instructions that trap on CPUs without
/// AVX-512 (0xC000001D).
fn _lower_map_cp(cp: Int) -> Int {
  _lower_map_r(cp, 0)
}

fn _lower_map_r(cp: Int, i: Int) -> Int {
  if i == 0 {
    if cp >= 65 && cp <= 90 { return cp + 32; };
  };
  if i == 1 {
    if cp >= 0xC0 && cp <= 0xD6 { return cp + 0x20; };
  };
  if i == 2 {
    if cp >= 0xD8 && cp <= 0xDE { return cp + 0x20; };
  };
  if i == 3 {
    if cp >= 0x391 && cp <= 0x3A1 { return cp + 0x20; };
  };
  if i == 4 {
    if cp >= 0x3A3 && cp <= 0x3AB { return cp + 0x20; };
  };
  if i == 5 {
    if cp >= 0x400 && cp <= 0x40F { return cp + 0x50; };
  };
  if i == 6 {
    if cp >= 0x410 && cp <= 0x42F { return cp + 0x20; };
  };
  if i == 7 {
    if cp >= 0x100 && cp <= 0x137 && (cp & 1) == 0 { return cp + 1; };
  };
  if i == 8 {
    if cp >= 0x139 && cp <= 0x148 && (cp & 1) == 0 { return cp + 1; };
  };
  if i == 9 {
    if cp >= 0x14A && cp <= 0x177 && (cp & 1) == 0 { return cp + 1; };
  };
  if i == 10 {
    if cp >= 0x179 && cp <= 0x17D && (cp & 1) == 0 { return cp + 1; };
  };
  if i == 11 {
    if cp == 0x1E9E { return 0xDF; };
  };
  if i == 12 {
    if cp >= 0x1E00 && cp <= 0x1EFF && (cp & 1) == 0 { return cp + 1; };
  };
  if i == 13 {
    if cp == 0x178 { return 0xFF; };
  };
  if i < 13 {
    return _lower_map_r(cp, i + 1);
  };
  cp
}

/// Single-level canonical decomposition of `cp` as (base, mark); (cp, -1) when
/// undecomposable. Covers the Latin-1 accented forms (see header note).
fn _decomp_cp(cp: Int) -> (Int, Int) {
  if cp == 0xC0 { return (0x41, 0x300); };
  if cp == 0xC1 { return (0x41, 0x301); };
  if cp == 0xC2 { return (0x41, 0x302); };
  if cp == 0xC3 { return (0x41, 0x303); };
  if cp == 0xC4 { return (0x41, 0x308); };
  if cp == 0xC5 { return (0x41, 0x30A); };
  if cp == 0xC7 { return (0x43, 0x327); };
  if cp == 0xC8 { return (0x45, 0x300); };
  if cp == 0xC9 { return (0x45, 0x301); };
  if cp == 0xCA { return (0x45, 0x302); };
  if cp == 0xCB { return (0x45, 0x308); };
  if cp == 0xCC { return (0x49, 0x300); };
  if cp == 0xCD { return (0x49, 0x301); };
  if cp == 0xCE { return (0x49, 0x302); };
  if cp == 0xCF { return (0x49, 0x308); };
  if cp == 0xD1 { return (0x4E, 0x303); };
  if cp == 0xD2 { return (0x4F, 0x300); };
  if cp == 0xD3 { return (0x4F, 0x301); };
  if cp == 0xD4 { return (0x4F, 0x302); };
  if cp == 0xD5 { return (0x4F, 0x303); };
  if cp == 0xD6 { return (0x4F, 0x308); };
  if cp == 0xD9 { return (0x55, 0x300); };
  if cp == 0xDA { return (0x55, 0x301); };
  if cp == 0xDB { return (0x55, 0x302); };
  if cp == 0xDC { return (0x55, 0x308); };
  if cp == 0xDD { return (0x59, 0x301); };
  if cp == 0xE0 { return (0x61, 0x300); };
  if cp == 0xE1 { return (0x61, 0x301); };
  if cp == 0xE2 { return (0x61, 0x302); };
  if cp == 0xE3 { return (0x61, 0x303); };
  if cp == 0xE4 { return (0x61, 0x308); };
  if cp == 0xE5 { return (0x61, 0x30A); };
  if cp == 0xE7 { return (0x63, 0x327); };
  if cp == 0xE8 { return (0x65, 0x300); };
  if cp == 0xE9 { return (0x65, 0x301); };
  if cp == 0xEA { return (0x65, 0x302); };
  if cp == 0xEB { return (0x65, 0x308); };
  if cp == 0xEC { return (0x69, 0x300); };
  if cp == 0xED { return (0x69, 0x301); };
  if cp == 0xEE { return (0x69, 0x302); };
  if cp == 0xEF { return (0x69, 0x308); };
  if cp == 0xF1 { return (0x6E, 0x303); };
  if cp == 0xF2 { return (0x6F, 0x300); };
  if cp == 0xF3 { return (0x6F, 0x301); };
  if cp == 0xF4 { return (0x6F, 0x302); };
  if cp == 0xF5 { return (0x6F, 0x303); };
  if cp == 0xF6 { return (0x6F, 0x308); };
  if cp == 0xF9 { return (0x75, 0x300); };
  if cp == 0xFA { return (0x75, 0x301); };
  if cp == 0xFB { return (0x75, 0x302); };
  if cp == 0xFC { return (0x75, 0x308); };
  if cp == 0xFD { return (0x79, 0x301); };
  if cp == 0xFF { return (0x79, 0x308); };
  (cp, -1)
}

/// Canonical composition of `a` + `b` (b a combining mark), -1 when not
/// composable. Covers the Latin-1 accented forms.
fn _compose_cp(a: Int, b: Int) -> Int {
  if b == 0x300 {
    if a == 0x41 { return 0xC0; };
    if a == 0x61 { return 0xE0; };
    if a == 0x45 { return 0xC8; };
    if a == 0x65 { return 0xE8; };
    if a == 0x49 { return 0xCC; };
    if a == 0x69 { return 0xEC; };
    if a == 0x4F { return 0xD2; };
    if a == 0x6F { return 0xF2; };
    if a == 0x55 { return 0xD9; };
    if a == 0x75 { return 0xF9; };
    return -1;
  };
  if b == 0x301 {
    if a == 0x41 { return 0xC1; };
    if a == 0x61 { return 0xE1; };
    if a == 0x45 { return 0xC9; };
    if a == 0x65 { return 0xE9; };
    if a == 0x49 { return 0xCD; };
    if a == 0x69 { return 0xED; };
    if a == 0x4F { return 0xD3; };
    if a == 0x6F { return 0xF3; };
    if a == 0x55 { return 0xDA; };
    if a == 0x75 { return 0xFA; };
    if a == 0x59 { return 0xDD; };
    if a == 0x79 { return 0xFD; };
    return -1;
  };
  if b == 0x302 {
    if a == 0x41 { return 0xC2; };
    if a == 0x61 { return 0xE2; };
    if a == 0x45 { return 0xCA; };
    if a == 0x65 { return 0xEA; };
    if a == 0x49 { return 0xCE; };
    if a == 0x69 { return 0xEE; };
    if a == 0x4F { return 0xD4; };
    if a == 0x6F { return 0xF4; };
    if a == 0x55 { return 0xDB; };
    if a == 0x75 { return 0xFB; };
    return -1;
  };
  if b == 0x303 {
    if a == 0x41 { return 0xC3; };
    if a == 0x61 { return 0xE3; };
    if a == 0x4E { return 0xD1; };
    if a == 0x6E { return 0xF1; };
    if a == 0x4F { return 0xD5; };
    if a == 0x6F { return 0xF5; };
    return -1;
  };
  if b == 0x308 {
    if a == 0x41 { return 0xC4; };
    if a == 0x61 { return 0xE4; };
    if a == 0x45 { return 0xCB; };
    if a == 0x65 { return 0xEB; };
    if a == 0x49 { return 0xCF; };
    if a == 0x69 { return 0xEF; };
    if a == 0x4F { return 0xD6; };
    if a == 0x6F { return 0xF6; };
    if a == 0x55 { return 0xDC; };
    if a == 0x75 { return 0xFC; };
    if a == 0x79 { return 0xFF; };
    return -1;
  };
  if b == 0x30A {
    if a == 0x41 { return 0xC5; };
    if a == 0x61 { return 0xE5; };
    return -1;
  };
  if b == 0x327 {
    if a == 0x43 { return 0xC7; };
    if a == 0x63 { return 0xE7; };
    return -1;
  };
  -1
}
