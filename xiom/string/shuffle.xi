// XIOM - String: Shuffle
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.string.shuffle

// Depends on: xiom.rand

// ============================================================================
// Random and seeded shuffling of characters and words. NOTE: current
// implementation lives in TODO - move the functions here during the
// implementation phase. TODO(compiler): implement.
// ============================================================================

use xiom.string;
use xiom.rand;

// -- Private helpers ---------------------------------------------------------

// Masked byte at `pos` (BUG 22 #10: `as Int` sign-extends UInt8).
// Complexity: O(1).
fn _sh_byte(s: Str, i: Int) -> Int {
  let v = string.byte_at(s, i) as Int;
  v & 0xFF
}

// True when byte `b` is a UTF-8 continuation byte (0b10xxxxxx).
// Complexity: O(1).
fn _sh_is_cont(b: Int) -> Bool {
  let masked = b & 0xC0;
  masked == 0x80
}

// Splits `s` into its individual Unicode characters.
// Complexity: O(|s|).
fn _sh_split(s: Str) -> Vec[Str] {
  var chars = Vec[Str].new();
  let len = string.str_len(s);
  var i: Int = 0;
  while i < len {
    var start = i;
    var adv: Int = 1;
    while start + adv < len && _sh_is_cont(_sh_byte(s, start + adv)) {
      adv = adv + 1;
    };
    chars.push(string.str_slice(s, start, start + adv));
    i = start + adv;
  };
  chars
}

// Concatenates `chars`.
// Complexity: O(total bytes).
fn _sh_join(chars: &Vec[Str]) -> Str {
  var result = "";
  var i: Int = 0;
  while i < chars.len() {
    let c = chars[i];
    result = string.str_concat(result, c);
    i = i + 1;
  };
  result
}

// Joins `words` with single spaces.
// Complexity: O(total bytes).
fn _sh_join_words(words: &Vec[Str]) -> Str {
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

// Independent copy of a Vec[Str].
// Complexity: O(|v|).
fn _sh_copy(v: &Vec[Str]) -> Vec[Str] {
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
fn _sh_swap(arr: &mut Vec[Str], i: Int, j: Int) {
  let t = arr[i];
  arr[i] = arr[j];
  arr[j] = t;
}

// Park-Miller LCG step (mod 2^31-1); the state stays in [1, 2^31-2] for any
// nonzero seed, so the intermediate product cannot overflow Int.
// Complexity: O(1).
fn _sh_prng_next(state: Int) -> Int {
  let s = (state * 48271) % 2147483647;
  if s <= 0 {
    s + 2147483647
  } else {
    s
  }
}

// Normalized nonzero seed.
// Complexity: O(1).
fn _sh_norm_seed(seed: Int) -> Int {
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

// Fisher-Yates shuffle of `chars`. When `use_rand` is true the swap index is
// drawn from the runtime PRNG; otherwise the deterministic Park-Miller
// sequence seeded with `seed` is used.
// Complexity: O(|chars|).
fn _sh_shuffle(chars: &Vec[Str], use_rand: Bool, seed: Int) -> Vec[Str] {
  var arr = _sh_copy(chars);
  var st = _sh_norm_seed(seed);
  var i: Int = arr.len();
  while i > 1 {
    i = i - 1;
    var j: Int = 0;
    if use_rand {
      let r = rand.random_int(0, i);
      j = r;
    } else {
      st = _sh_prng_next(st);
      let m = st % (i + 1);
      j = m;
    };
    _sh_swap(&mut arr, i, j);
  };
  arr
}

// -- Public API --------------------------------------------------------------

/// Random permutation of the characters of `s` via Fisher-Yates, drawing swap
/// indices from the runtime PRNG. The result is a rearrangement of the
/// characters of `s`; the order is not specified.
/// Params: s the string to shuffle.
/// Returns: a random permutation of the characters of `s`.
/// Error case: none; the empty string maps to itself.
/// Complexity: O(|s|).
pub fn str_shuffle(s: Str) -> Str {
  let chars = _sh_split(s);
  let shuffled = _sh_shuffle(&chars, true, 0);
  let r = _sh_join(&shuffled);
  r
}

/// Deterministic shuffle of `s` using the given `seed`: the same seed always
/// produces the same permutation via the Park-Miller sequence.
/// Params: s the string to shuffle; seed the PRNG seed.
/// Returns: the seeded permutation of `s`.
/// Error case: none; the empty string maps to itself.
/// Complexity: O(|s|).
pub fn str_shuffle_seeded(s: Str, seed: Int) -> Str {
  let chars = _sh_split(s);
  let shuffled = _sh_shuffle(&chars, false, seed);
  let r = _sh_join(&shuffled);
  r
}

/// Random permutation of the whitespace-separated words of `s`, rejoined with
/// single spaces (spacing runs are not preserved).
/// Params: s the string whose words to shuffle.
/// Returns: the shuffled words joined by single spaces.
/// Error case: none; a string with no words yields "".
/// Complexity: O(|s|).
pub fn str_shuffle_words(s: Str) -> Str {
  let words = string.words(s);
  let shuffled = _sh_shuffle(&words, true, 0);
  let r = _sh_join_words(&shuffled);
  r
}
