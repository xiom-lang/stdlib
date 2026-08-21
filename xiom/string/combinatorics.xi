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

use xiom.string;
use xiom.rand;
use xiom.convert;

// -- Private helpers ---------------------------------------------------------

// Masked byte at `pos` (BUG 22 #10: `as Int` sign-extends UInt8).
// Complexity: O(1).
fn _byte(s: Str, i: Int) -> Int {
  let v = string.byte_at(s, i) as Int;
  v & 0xFF
}

// True when byte `b` is a UTF-8 continuation byte (0b10xxxxxx).
// Complexity: O(1).
fn _is_cont(b: Int) -> Bool {
  let masked = b & 0xC0;
  masked == 0x80
}

// True when `b` is an ASCII whitespace byte (space, tab, LF, CR).
// Complexity: O(1).
fn _is_ws_byte(b: Int) -> Bool {
  b == 32 || b == 9 || b == 10 || b == 13
}

// Splits `s` into its individual Unicode characters (one Str per code point).
// Malformed UTF-8 bytes are treated as single-byte characters.
// Complexity: O(|s|).
fn _split_chars(s: Str) -> Vec[Str] {
  var chars = Vec[Str].new();
  let len = string.str_len(s);
  var i: Int = 0;
  while i < len {
    var start = i;
    var adv: Int = 1;
    while start + adv < len && _is_cont(_byte(s, start + adv)) {
      adv = adv + 1;
    };
    chars.push(string.str_slice(s, start, start + adv));
    i = start + adv;
  };
  chars
}

// Concatenates the characters of `chars` into one string.
// Complexity: O(total bytes).
fn _join_chars(chars: &Vec[Str]) -> Str {
  var result = "";
  var i: Int = 0;
  while i < chars.len() {
    let c = chars[i];
    result = string.str_concat(result, c);
    i = i + 1;
  };
  result
}

// Independent copy of a Vec[Str] (defensive: enumeration helpers push copies
// so later mutation of the working vector cannot alias the pushed results).
// Complexity: O(|v|).
fn _copy_chars(v: &Vec[Str]) -> Vec[Str] {
  var c = Vec[Str].new();
  var i: Int = 0;
  while i < v.len() {
    let e = v[i];
    c.push(e);
    i = i + 1;
  };
  c
}

// Swaps elements `i` and `j` of `arr`.
// Complexity: O(1).
fn _swap(arr: &mut Vec[Str], i: Int, j: Int) {
  let t = arr[i];
  arr[i] = arr[j];
  arr[j] = t;
}

// Park-Miller LCG step (mod 2^31-1). The state stays in [1, 2^31-2] for any
// nonzero seed, so the intermediate product cannot overflow Int.
// Complexity: O(1).
fn _prng_next(state: Int) -> Int {
  let s = (state * 48271) % 2147483647;
  if s <= 0 {
    s + 2147483647
  } else {
    s
  }
}

// Normalized nonzero seed.
// Complexity: O(1).
fn _norm_seed(seed: Int) -> Int {
  var st = seed;
  if st < 0 {
    st = -st;
  };
  if st == 0 {
    st = 123456789;
  };
  if st >= 2147483647 {
    st = 123456789;
  };
  st
}

// Fisher-Yates shuffle of `chars`. When `use_rand` is true the index is drawn
// from the runtime PRNG; otherwise the deterministic Park-Miller sequence
// seeded with `seed` is used.
// Complexity: O(|chars|).
fn _shuffle(chars: &Vec[Str], use_rand: Bool, seed: Int) -> Vec[Str] {
  var arr = _copy_chars(chars);
  var st = _norm_seed(seed);
  var i: Int = arr.len();
  while i > 1 {
    i = i - 1;
    var j: Int = 0;
    if use_rand {
      let r = rand.random_int(0, i);
      j = r;
    } else {
      st = _prng_next(st);
      let m = st % (i + 1);
      j = m;
    };
    _swap(&mut arr, i, j);
  };
  arr
}

// Joins `words` with single spaces.
// Complexity: O(total bytes).
fn _join_words(words: &Vec[Str]) -> Str {
  var result = "";
  var i: Int = 0;
  while i < words.len() {
    let w = words[i];
    if i > 0 {
      result = string.str_concat(result, " ");
    };
    result = string.str_concat(result, w);
    i = i + 1;
  };
  result
}

// Advances the index vector to the next k-combination of indices in [0, n).
// Returns false when the current combination was the last one.
// Complexity: O(k).
fn _next_combination(idx: &mut Vec[Int], n: Int, k: Int) -> Bool {
  var i: Int = k - 1;
  while i >= 0 {
    if idx[i] < n - k + i {
      idx[i] = idx[i] + 1;
      var j: Int = i + 1;
      while j < k {
        idx[j] = idx[j - 1] + 1;
        j = j + 1;
      };
      return true;
    };
    i = i - 1;
  };
  false
}

// Advances the index vector to the next permutation in lexicographic order.
// Returns false when the current permutation was the last one.
// Complexity: O(|idx|).
fn _next_perm(idx: &mut Vec[Int]) -> Bool {
  let n = idx.len();
  if n < 2 {
    return false;
  };
  var i: Int = n - 2;
  loop {
    if i < 0 {
      break;
    };
    if idx[i] < idx[i + 1] {
      break;
    };
    i = i - 1;
  };
  if i < 0 {
    return false;
  };
  var j: Int = n - 1;
  while idx[j] < idx[i] {
    j = j - 1;
  };
  let t = idx[i];
  idx[i] = idx[j];
  idx[j] = t;
  var lo = i + 1;
  var hi = n - 1;
  while lo < hi {
    let t2 = idx[lo];
    idx[lo] = idx[hi];
    idx[hi] = t2;
    lo = lo + 1;
    hi = hi - 1;
  };
  true
}

// Independent copy of a Vec[Int].
// Complexity: O(|v|).
fn _copy_idx(v: &Vec[Int]) -> Vec[Int] {
  var c = Vec[Int].new();
  var i: Int = 0;
  while i < v.len() {
    let e = v[i];
    c.push(e);
    i = i + 1;
  };
  c
}

// Builds a string from `s` by concatenating the single-byte characters at the
// byte offsets given by `idx`, in order. Byte-based (ASCII-exact); multi-byte
// characters are treated as byte sequences, matching the sibling enumeration
// modules.
// Complexity: O(|idx|).
fn _piece_from_idx(s: Str, idx: &Vec[Int]) -> Str {
  var piece = "";
  var j: Int = 0;
  while j < idx.len() {
    let pos = idx[j];
    let one = string.str_slice(s, pos, pos + 1);
    piece = string.str_concat(piece, one);
    j = j + 1;
  };
  piece
}

// -- Shuffle (Fisher-Yates) --------------------------------------------------

/// Random permutation of the characters of `s` via Fisher-Yates, drawing swap
/// indices from the runtime PRNG. The result is a rearrangement of the
/// characters of `s` (same byte length); the order is not specified.
/// Params: s the string to shuffle.
/// Returns: a random permutation of the characters of `s`.
/// Error case: none; the empty string maps to itself.
/// Complexity: O(|s|).
pub fn str_shuffle(s: Str) -> Str {
  let chars = _split_chars(s);
  let shuffled = _shuffle(&chars, true, 0);
  let r = _join_chars(&shuffled);
  r
}

/// Deterministic shuffle of `s` using the given `seed`: the same seed always
/// produces the same permutation via the Park-Miller sequence. The empty
/// string maps to itself.
/// Params: s the string to shuffle; seed the PRNG seed.
/// Returns: the seeded permutation of `s`.
/// Error case: none.
/// Complexity: O(|s|).
pub fn str_shuffle_seeded(s: Str, seed: Int) -> Str {
  let chars = _split_chars(s);
  let shuffled = _shuffle(&chars, false, seed);
  let r = _join_chars(&shuffled);
  r
}

/// Random permutation of the whitespace-separated words of `s`. The result
/// rejoins the shuffled words with single spaces; the original spacing runs
/// are not preserved (see `str_reverse_words` for spacing preservation).
/// Params: s the string whose words to shuffle.
/// Returns: the shuffled words joined by single spaces.
/// Error case: none; a string with no words yields "".
/// Complexity: O(|s|).
pub fn str_shuffle_words(s: Str) -> Str {
  let words = string.words(s);
  let shuffled = _shuffle(&words, true, 0);
  let r = _join_words(&shuffled);
  r
}

/// Deterministic word shuffle of `s` using the given `seed`.
/// Params: s the string whose words to shuffle; seed the PRNG seed.
/// Returns: the seeded permutation of the words of `s`.
/// Error case: none; a string with no words yields "".
/// Complexity: O(|s|).
pub fn str_shuffle_words_seeded(s: Str, seed: Int) -> Str {
  let words = string.words(s);
  let shuffled = _shuffle(&words, false, seed);
  let r = _join_words(&shuffled);
  r
}

// -- Rotation ----------------------------------------------------------------

/// Rotate `s` right by `n` byte positions: a positive `n` moves characters
/// toward the end of the string ("abcde" rotated right by 2 is "deabc"). A
/// negative `n` rotates left. Rotating by a multiple of |s| returns `s`.
/// Params: s the string to rotate; n the rotation amount in bytes.
/// Returns: the rotated string.
/// Error case: none; the empty string is returned unchanged.
/// Complexity: O(|s|).
pub fn str_rotate(s: Str, n: Int) -> Str {
  let len = string.str_len(s);
  if len == 0 {
    return s;
  };
  var k = n % len;
  if k < 0 {
    k = k + len;
  };
  if k == 0 {
    return s;
  };
  let cut = len - k;
  let head = string.str_slice(s, 0, cut);
  let tail = string.str_slice(s, cut, len);
  let r = string.str_concat(tail, head);
  r
}

/// Rotate `s` left by `n` byte positions ("abcde" rotated left by 2 is
/// "cdeab"). A negative `n` rotates right.
/// Params: s the string to rotate; n the rotation amount in bytes.
/// Returns: the rotated string.
/// Error case: none; the empty string is returned unchanged.
/// Complexity: O(|s|).
pub fn str_rotate_left(s: Str, n: Int) -> Str {
  let len = string.str_len(s);
  if len == 0 {
    return s;
  };
  var k = n % len;
  if k < 0 {
    k = k + len;
  };
  if k == 0 {
    return s;
  };
  let head = string.str_slice(s, k, len);
  let tail = string.str_slice(s, 0, k);
  let r = string.str_concat(head, tail);
  r
}

/// Rotate `s` right by `n` byte positions; identical to `str_rotate` and kept
/// as the explicit right-rotation entry point.
/// Params: s the string to rotate; n the rotation amount in bytes.
/// Returns: the rotated string.
/// Error case: none; the empty string is returned unchanged.
/// Complexity: O(|s|).
pub fn str_rotate_right(s: Str, n: Int) -> Str {
  let r = str_rotate(s, n);
  r
}

/// Rotate the whitespace-separated words of `s` by `n` positions: a positive
/// `n` moves words toward the end. The result rejoins the rotated words with
/// single spaces.
/// Params: s the string whose words to rotate; n the rotation amount in words.
/// Returns: the word-rotated string.
/// Error case: none; a string with no words yields "".
/// Complexity: O(|s|).
pub fn str_rotate_word(s: Str, n: Int) -> Str {
  let words = string.words(s);
  let wc = words.len();
  if wc == 0 {
    return "";
  };
  var k = n % wc;
  if k < 0 {
    k = k + wc;
  };
  var result = "";
  var i: Int = 0;
  while i < wc {
    let src = (i + wc - k) % wc;
    let w = words[src];
    if i > 0 {
      result = string.str_concat(result, " ");
    };
    result = string.str_concat(result, w);
    i = i + 1;
  };
  result
}

// -- Permutations and combinations -------------------------------------------

/// All permutations of the characters of `s`, treating the characters as
/// distinct (n! results for |s| = n; duplicate characters yield duplicate
/// permutations). An empty string yields a vector containing "". The
/// permutations are emitted in lexicographic byte order.
/// Params: s the source string.
/// Returns: a Vec[Str] with n! permutations.
/// Error case: inputs longer than 8 characters return an empty vector
///             (documented guard against an impractical 8!+ result set).
/// Complexity: O(n! * n).
pub fn str_permutations(s: Str) -> Vec[Str] {
  var out = Vec[Str].new();
  let len = string.str_len(s);
  if len == 0 {
    out.push("");
    return out;
  };
  if len > 8 {
    return out;
  };
  var idx = Vec[Int].new();
  var i: Int = 0;
  while i < len {
    idx.push(i);
    i = i + 1;
  };
  loop {
    let piece = _piece_from_idx(s, &idx);
    out.push(piece);
    if !_next_perm(&mut idx) {
      break;
    };
  };
  out
}

/// All n-length arrangements of the characters of `s` (P(|s|, n) results,
/// ordered, without repetition). n == 0 yields [""]; n < 0 or n > |s| yields
/// an empty vector.
/// Params: s the source string; n the arrangement length.
/// Returns: a Vec[Str] of n-length permutations.
/// Error case: n < 0 or n > |s| => empty vector; large inputs are guarded as
///             in str_permutations.
/// Complexity: O(P(n, k) * k).
pub fn str_permutations_n(s: Str, n: Int) -> Vec[Str] {
  var out = Vec[Str].new();
  let len = string.str_len(s);
  if n < 0 || n > len {
    return out;
  };
  if n == 0 {
    out.push("");
    return out;
  };
  if len > 8 {
    return out;
  };
  var sel = Vec[Int].new();
  var i: Int = 0;
  while i < n {
    sel.push(i);
    i = i + 1;
  };
  loop {
    var order = _copy_idx(&sel);
    loop {
      let piece = _piece_from_idx(s, &order);
      out.push(piece);
      if !_next_perm(&mut order) {
        break;
      };
    };
    if !_next_combination(&mut sel, len, n) {
      break;
    };
  };
  out
}

/// All n-length combinations of the characters of `s`, each kept in source
/// order (C(|s|, n) results). n < 1 or n > |s| yields an empty vector,
/// matching `xiom.string.combine.str_combinations`.
/// Params: s the source string; n the combination length.
/// Returns: a Vec[Str] of n-length combinations.
/// Error case: n < 1 or n > |s| => empty vector.
/// Complexity: O(C(n, k) * k).
pub fn str_combinations(s: Str, n: Int) -> Vec[Str] {
  var result = Vec[Str].new();
  let len = string.str_len(s);
  if n < 1 || n > len {
    return result;
  };
  var idx = Vec[Int].new();
  var i: Int = 0;
  while i < n {
    idx.push(i);
    i = i + 1;
  };
  loop {
    let piece = _piece_from_idx(s, &idx);
    result.push(piece);
    if !_next_combination(&mut idx, len, n) {
      break;
    };
  };
  result
}

/// Every character of `a` paired with every character of `b`, in order
/// ("ab" x "12" yields "a1", "a2", "b1", "b2").
/// Params: a, b the source strings.
/// Returns: a Vec[Str] of two-character pairs.
/// Error case: none; an empty operand yields an empty vector.
/// Complexity: O(|a| * |b|).
pub fn str_cartesian(a: Str, b: Str) -> Vec[Str] {
  var out = Vec[Str].new();
  let ac = _split_chars(a);
  let bc = _split_chars(b);
  var i: Int = 0;
  while i < ac.len() {
    var j: Int = 0;
    while j < bc.len() {
      let p = string.str_concat(ac[i], bc[j]);
      out.push(p);
      j = j + 1;
    };
    i = i + 1;
  };
  out
}

// -- Interleave, chunking and windows ----------------------------------------

/// Merge `a` and `b` alternating characters, appending the remainder of the
/// longer string ("abc" + "12" yields "a1b2c").
/// Params: a, b the strings to interleave.
/// Returns: the interleaved string.
/// Error case: none.
/// Complexity: O(|a| + |b|).
pub fn str_interleave(a: Str, b: Str) -> Str {
  let ac = _split_chars(a);
  let bc = _split_chars(b);
  var result = "";
  var i: Int = 0;
  while i < ac.len() && i < bc.len() {
    result = string.str_concat(result, ac[i]);
    result = string.str_concat(result, bc[i]);
    i = i + 1;
  };
  while i < ac.len() {
    result = string.str_concat(result, ac[i]);
    i = i + 1;
  };
  while i < bc.len() {
    result = string.str_concat(result, bc[i]);
    i = i + 1;
  };
  result
}

/// Split `s` into consecutive chunks of `n` bytes; the final chunk may be
/// shorter. A chunk size below 1 or an empty input yields an empty vector.
/// Params: s the source string; n the chunk size in bytes.
/// Returns: a Vec[Str] of chunks covering `s` exactly once.
/// Error case: n < 1 or s.len() == 0 => empty vector.
/// Complexity: O(|s|).
pub fn str_chunk(s: Str, n: Int) -> Vec[Str] {
  var result = Vec[Str].new();
  let len = string.str_len(s);
  if n < 1 || len == 0 {
    return result;
  };
  var i: Int = 0;
  while i < len {
    var end = i + n;
    if end > len {
      end = len;
    };
    let piece = string.str_slice(s, i, end);
    result.push(piece);
    i = end;
  };
  result
}

/// Split `s` into chunks of `n` bytes starting from the end; the remainder
/// (if any) forms the first chunk. A chunk size below 1 or an empty input
/// yields an empty vector.
/// Params: s the source string; n the chunk size in bytes.
/// Returns: a Vec[Str] of chunks in source order (first may be shorter).
/// Error case: n < 1 or s.len() == 0 => empty vector.
/// Complexity: O(|s|).
pub fn str_chunks_reverse(s: Str, n: Int) -> Vec[Str] {
  var result = Vec[Str].new();
  let len = string.str_len(s);
  if n < 1 || len == 0 {
    return result;
  };
  var first = len % n;
  if first == 0 {
    first = n;
  };
  var cur = first;
  var i: Int = 0;
  while i < len {
    var end = i + cur;
    if end > len {
      end = len;
    };
    let piece = string.str_slice(s, i, end);
    result.push(piece);
    i = end;
    cur = n;
  };
  result
}

/// All length-`n` overlapping substrings (windows) of `s`. A window size
/// below 1 or larger than the input yields an empty vector.
/// Params: s the source string; n the window size in bytes.
/// Returns: a Vec[Str] with one element per start position 0..len-n.
/// Error case: n < 1 or len < n => empty vector.
/// Complexity: O(|s|).
pub fn str_windows(s: Str, n: Int) -> Vec[Str] {
  var result = Vec[Str].new();
  let len = string.str_len(s);
  if n < 1 || len < n {
    return result;
  };
  var i: Int = 0;
  while i <= len - n {
    let piece = string.str_slice(s, i, i + n);
    result.push(piece);
    i = i + 1;
  };
  result
}

/// Split `s` into chunks of `n` bytes that never split a multi-byte UTF-8
/// character: a chunk is extended to the end of a character that would cross
/// the `n`-byte boundary.
/// Params: s the source string; n the target chunk size in bytes.
/// Returns: a Vec[Str] of chunks covering `s` exactly once.
/// Error case: n < 1 or s.len() == 0 => empty vector.
/// Complexity: O(|s|).
pub fn str_chunk_bytes(s: Str, n: Int) -> Vec[Str] {
  var result = Vec[Str].new();
  let chars = _split_chars(s);
  if n < 1 || chars.len() == 0 {
    return result;
  };
  var cur = "";
  var cur_bytes: Int = 0;
  var i: Int = 0;
  while i < chars.len() {
    let c = chars[i];
    let bl = string.str_len(c);
    if cur_bytes > 0 && cur_bytes + bl > n {
      result.push(cur);
      cur = c;
      cur_bytes = bl;
    } else {
      cur = string.str_concat(cur, c);
      cur_bytes = cur_bytes + bl;
    };
    i = i + 1;
  };
  if cur_bytes > 0 {
    result.push(cur);
  };
  result
}

// -- Word order --------------------------------------------------------------

/// Reverse the order of the whitespace-separated words of `s`, preserving the
/// whitespace runs: only the token order changes ("a  b" -> "b  a"). Returns
/// `s` unchanged when `s` has no words.
/// Params: s the string whose words to reverse.
/// Returns: the word-reversed string.
/// Error case: none.
/// Complexity: O(|s|).
pub fn str_reverse_words(s: Str) -> Str {
  var runs = Vec[Str].new();
  let len = string.str_len(s);
  var i: Int = 0;
  while i < len {
    let first_ws = _is_ws_byte(_byte(s, i));
    var run_start = i;
    while i < len && _is_ws_byte(_byte(s, i)) == first_ws {
      i = i + 1;
    };
    runs.push(string.str_slice(s, run_start, i));
  };
  if runs.len() == 0 {
    return "";
  };
  var result = "";
  var j: Int = runs.len() - 1;
  while j >= 0 {
    let r = runs[j];
    result = string.str_concat(result, r);
    j = j - 1;
  };
  result
}

// -- Character statistics ----------------------------------------------------

/// The characters of `s` without duplicates, in first-seen order. Dedup is
/// byte-based, so two different multi-byte code points sharing a leading byte
/// are treated as duplicates (documented; ASCII is exact).
/// Params: s the source string.
/// Returns: a string of distinct characters.
/// Error case: none.
/// Complexity: O(|s|^2).
pub fn str_unique_chars(s: Str) -> Str {
  var result = "";
  var seen = Vec[Int].new();
  let chars = _split_chars(s);
  var i: Int = 0;
  while i < chars.len() {
    let c = chars[i];
    let b = _byte(c, 0);
    var found = false;
    var k: Int = 0;
    while k < seen.len() {
      if seen[k] == b {
        found = true;
      };
      k = k + 1;
    };
    if !found {
      seen.push(b);
      result = string.str_concat(result, c);
    };
    i = i + 1;
  };
  result
}

/// Each distinct character of `s` and its occurrence count, in first-seen
/// order. Characters are derived from their bytes (ASCII-exact; multi-byte
/// code points are counted per byte, documented).
/// Params: s the source string.
/// Returns: a Vec[(Char, Int)] of (character, count) pairs.
/// Error case: none.
/// Complexity: O(|s|^2).
pub fn str_frequencies(s: Str) -> Vec[(Char, Int)] {
  var chars = Vec[Char].new();
  var counts = Vec[Int].new();
  let len = string.str_len(s);
  var i: Int = 0;
  while i < len {
    let b = _byte(s, i);
    let c_opt = convert.int_to_char(b);
    match c_opt {
      Some(c) => {
        var found = false;
        var k: Int = 0;
        while k < chars.len() {
          if chars[k] == c {
            counts[k] = counts[k] + 1;
            found = true;
            break;
          };
          k = k + 1;
        };
        if !found {
          chars.push(c);
          counts.push(1);
        };
      };
      None => {};
    };
    i = i + 1;
  };
  var out = Vec[(Char, Int)].new();
  var j: Int = 0;
  while j < chars.len() {
    let t = (chars[j], counts[j]);
    out.push(t);
    j = j + 1;
  };
  out
}

/// The character that appears most often in `s`, or None when `s` is empty.
/// When several characters tie, the first-seen one wins.
/// Params: s the source string.
/// Returns: Some with the most frequent character, None when empty.
/// Error case: none.
/// Complexity: O(|s|^2).
pub fn str_most_frequent(s: Str) -> Option[Char] {
  var chars = Vec[Char].new();
  var counts = Vec[Int].new();
  let len = string.str_len(s);
  var i: Int = 0;
  while i < len {
    let b = _byte(s, i);
    let c_opt = convert.int_to_char(b);
    match c_opt {
      Some(c) => {
        var found = false;
        var k: Int = 0;
        while k < chars.len() {
          if chars[k] == c {
            counts[k] = counts[k] + 1;
            found = true;
            break;
          };
          k = k + 1;
        };
        if !found {
          chars.push(c);
          counts.push(1);
        };
      };
      None => {};
    };
    i = i + 1;
  };
  if chars.len() == 0 {
    return None;
  };
  var best_idx: Int = 0;
  var j: Int = 1;
  while j < chars.len() {
    if counts[j] > counts[best_idx] {
      best_idx = j;
    };
    j = j + 1;
  };
  Some(chars[best_idx])
}

/// The distinct characters of `s` in first-seen order, as Char values.
/// Params: s the source string.
/// Returns: a Vec[Char] of distinct characters.
/// Error case: none.
/// Complexity: O(|s|^2).
pub fn str_char_set(s: Str) -> Vec[Char] {
  var out = Vec[Char].new();
  let len = string.str_len(s);
  var i: Int = 0;
  while i < len {
    let b = _byte(s, i);
    let c_opt = convert.int_to_char(b);
    match c_opt {
      Some(c) => {
        var found = false;
        var k: Int = 0;
        while k < out.len() {
          if out[k] == c {
            found = true;
          };
          k = k + 1;
        };
        if !found {
          out.push(c);
        };
      };
      None => {};
    };
    i = i + 1;
  };
  out
}


