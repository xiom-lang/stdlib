// XIOM -- Text Similarity Algorithms (xiom.text.similarity)
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.
//
// Pure string-similarity algorithms. All functions operate on raw byte
// sequences via string.byte_at and therefore assume ASCII input; multi-byte
// UTF-8 characters are treated as their individual bytes.

module xiom.text.similarity

use xiom.string;
use xiom.convert;
use xiom.math.sqrt;

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
  fn free(ptr: *UInt8);
}

/// Renders a single ASCII byte code (0..255) as a 1-character Str.
fn _byte_to_str(code: Int) -> Str
  requires: true
{
  unsafe {
    var buf = malloc(2);
    buf[0] = code as UInt8;
    buf[1] = 0;
    Str.from_cstring(buf)
  }
}

/// Returns the byte at `idx` as an Int, or -1 when `idx` is out of range.
fn _peek_byte(s: Str, idx: Int, len: Int) -> Int {
  if idx >= len {
    return -1;
  };
  string.byte_at(s, idx) as Int
}

/// True when `c` is an uppercase ASCII vowel (A, E, I, O, U).
fn _is_vowel_byte(c: UInt8) -> Bool {
  if c == 65 || c == 69 || c == 73 || c == 79 || c == 85 {
    return true;
  };
  false
}

/// djb2 hash of the `n` consecutive bytes of `s` starting at `start`.
/// Int wraparound is intentional: only equality of codes matters here.
fn _ngram_hash(s: Str, start: Int, n: Int) -> Int {
  var h: Int = 5381;
  var i = start;
  var end = start + n;
  while i < end {
    h = h * 33 + (string.byte_at(s, i) as Int);
    i = i + 1;
  }
  h
}

/// Distinct n-gram hash codes of `s` (duplicates within one string are skipped).
fn _ngrams(s: Str, len: Int, n: Int) -> Vec[Int] {
  var result = Vec[Int].new();
  var i: Int = 0;
  while i + n <= len {
    var code = _ngram_hash(s, i, n);
    var dup = false;
    var j: Int = 0;
    while j < result.len() {
      if result[j] == code {
        dup = true;
        break;
      };
      j = j + 1;
    }
    if !dup {
      result.push(code);
    };
    i = i + 1;
  }
  result
}

// -- Edit distances ----------------------------------------------------------

/// Levenshtein edit distance between `a` and `b` (insertions, deletions,
/// substitutions each cost 1). Classic two-row DP; ASCII byte comparison.
/// Complexity: O(|a| * |b|) time, O(|b|) space.
pub fn levenshtein(a: Str, b: Str) -> Int {
  let la = a.len();
  let lb = b.len();
  var prev = Vec[Int].new();
  var i: Int = 0;
  while i <= lb {
    prev.push(i);
    i = i + 1;
  }
  var j: Int = 1;
  while j <= la {
    var cur = Vec[Int].new();
    cur.push(j);
    var k: Int = 1;
    while k <= lb {
      var cost: Int = 0;
      if string.byte_at(a, j - 1) == string.byte_at(b, k - 1) {
        cost = 0;
      } else {
        cost = 1;
      };
      var m = prev[k] + 1;
      var ins = cur[k - 1] + 1;
      if ins < m {
        m = ins;
      };
      var sub = prev[k - 1] + cost;
      if sub < m {
        m = sub;
      };
      cur.push(m);
      k = k + 1;
    }
    prev = cur;
    j = j + 1;
  }
  prev[lb]
}

/// Damerau-Levenshtein distance using the optimal string alignment (OSA)
/// variant: one transposition of adjacent characters counts as one edit.
/// Two-row DP plus the row two steps back for the transposition term.
/// Complexity: O(|a| * |b|) time, O(|b|) space.
pub fn damerau_levenshtein(a: Str, b: Str) -> Int {
  let la = a.len();
  let lb = b.len();
  if la == 0 {
    return lb;
  };
  if lb == 0 {
    return la;
  };
  var prev = Vec[Int].new();
  var i: Int = 0;
  while i <= lb {
    prev.push(i);
    i = i + 1;
  }
  var prevprev = Vec[Int].new();
  var j: Int = 1;
  while j <= la {
    var cur = Vec[Int].new();
    cur.push(j);
    var k: Int = 1;
    while k <= lb {
      var cost: Int = 1;
      if string.byte_at(a, j - 1) == string.byte_at(b, k - 1) {
        cost = 0;
      };
      var m = prev[k] + 1;
      var ins = cur[k - 1] + 1;
      if ins < m {
        m = ins;
      };
      var sub = prev[k - 1] + cost;
      if sub < m {
        m = sub;
      };
      if j > 1 && k > 1 {
        if string.byte_at(a, j - 1) == string.byte_at(b, k - 2) && string.byte_at(a, j - 2) == string.byte_at(b, k - 1) {
          var trans = prevprev[k - 2] + 1;
          if trans < m {
            m = trans;
          };
        };
      };
      cur.push(m);
      k = k + 1;
    }
    prevprev = prev;
    prev = cur;
    j = j + 1;
  }
  prev[lb]
}

// -- Jaro / Jaro-Winkler -----------------------------------------------------

/// Jaro similarity in [0, 1]. Match window is floor(max(|a|,|b|)/2) - 1
/// (clamped to 0); transpositions are mismatched match pairs divided by 2.
/// Returns 0.0 when there are no matches (including empty inputs).
pub fn jaro(a: Str, b: Str) -> Float64 {
  let la = a.len();
  let lb = b.len();
  if la == 0 || lb == 0 {
    return 0.0;
  };
  var window: Int = la;
  if lb > window {
    window = lb;
  };
  window = window / 2 - 1;
  if window < 0 {
    window = 0;
  };
  var a_matched = Vec[Bool].new();
  var b_matched = Vec[Bool].new();
  var i: Int = 0;
  while i < la {
    a_matched.push(false);
    i = i + 1;
  }
  i = 0;
  while i < lb {
    b_matched.push(false);
    i = i + 1;
  }
  var matches: Int = 0;
  i = 0;
  while i < la {
    var lo = i - window;
    if lo < 0 {
      lo = 0;
    };
    var hi = i + window;
    if hi > lb - 1 {
      hi = lb - 1;
    };
    var j = lo;
    while j <= hi {
      if !b_matched[j] {
        if string.byte_at(a, i) == string.byte_at(b, j) {
          b_matched[j] = true;
          a_matched[i] = true;
          matches = matches + 1;
          break;
        };
      };
      j = j + 1;
    }
    i = i + 1;
  }
  if matches == 0 {
    return 0.0;
  }
  var a_chars = Vec[Int].new();
  var b_chars = Vec[Int].new();
  i = 0;
  while i < la {
    if a_matched[i] {
      a_chars.push(string.byte_at(a, i) as Int);
    };
    i = i + 1;
  }
  var j = 0;
  while j < lb {
    if b_matched[j] {
      b_chars.push(string.byte_at(b, j) as Int);
    };
    j = j + 1;
  }
  var t: Int = 0;
  i = 0;
  while i < a_chars.len() {
    if a_chars[i] != b_chars[i] {
      t = t + 1;
    };
    i = i + 1;
  }
  t = t / 2;
  let mf = convert.int_to_float(matches);
  let la_f = convert.int_to_float(la);
  let lb_f = convert.int_to_float(lb);
  (mf / la_f + mf / lb_f + (mf - convert.int_to_float(t)) / mf) / 3.0
}

/// Jaro-Winkler similarity: Jaro plus a prefix bonus of
/// prefix_len * 0.1 * (1 - jaro), where prefix_len is capped at 4 and at the
/// length of the shorter string.
pub fn jaro_winkler(a: Str, b: Str) -> Float64 {
  let j = jaro(a, b);
  let la = a.len();
  let lb = b.len();
  var prefix: Int = 0;
  while prefix < 4 && prefix < la && prefix < lb && string.byte_at(a, prefix) == string.byte_at(b, prefix) {
    prefix = prefix + 1;
  }
  j + (convert.int_to_float(prefix) * 0.1 * (1.0 - j))
}

// -- N-gram / vector similarity ----------------------------------------------

/// Jaccard similarity over the set of character n-grams (as djb2 hash codes)
/// of `a` and `b`. Returns 0.0 when either side has no n-grams. O(|a|*|b|).
pub fn ngram_similarity(a: Str, b: Str, n: Int) -> Float64 {
  if n <= 0 {
    return 0.0;
  };
  let la = a.len();
  let lb = b.len();
  if la < n || lb < n {
    return 0.0;
  };
  var ga = _ngrams(a, la, n);
  var gb = _ngrams(b, lb, n);
  if ga.len() == 0 || gb.len() == 0 {
    return 0.0;
  };
  var inter: Int = 0;
  var i: Int = 0;
  while i < ga.len() {
    var j: Int = 0;
    var found = false;
    while j < gb.len() {
      if ga[i] == gb[j] {
        found = true;
        break;
      };
      j = j + 1;
    }
    if found {
      inter = inter + 1;
    };
    i = i + 1;
  }
  let uni = ga.len() + gb.len() - inter;
  convert.int_to_float(inter) / convert.int_to_float(uni)
}

/// Cosine similarity over per-character frequency vectors.
/// Character-level (unigram) frequencies are used -- rather than bigram
/// frequencies -- so that words sharing letters but no bigrams (e.g. "hello"
/// and "world") still score a non-zero, sub-1 similarity.
/// Returns 0.0 when either vector has zero length.
pub fn cosine_similarity(a: Str, b: Str) -> Float64
  requires: true  // extern sqrt calls below (T002 confinement)
{
  let la = a.len();
  let lb = b.len();
  if la == 0 || lb == 0 {
    return 0.0;
  };
  var ua = Vec[Int].new();
  var i: Int = 0;
  while i < la {
    var code = string.byte_at(a, i) as Int;
    var dup = false;
    var j: Int = 0;
    while j < ua.len() {
      if ua[j] == code {
        dup = true;
        break;
      };
      j = j + 1;
    }
    if !dup {
      ua.push(code);
    };
    i = i + 1;
  }
  var ub = Vec[Int].new();
  i = 0;
  while i < lb {
    var code = string.byte_at(b, i) as Int;
    var dup = false;
    var j: Int = 0;
    while j < ub.len() {
      if ub[j] == code {
        dup = true;
        break;
      };
      j = j + 1;
    }
    if !dup {
      ub.push(code);
    };
    i = i + 1;
  }
  var dot: Int = 0;
  var na: Int = 0;
  var nb: Int = 0;
  i = 0;
  while i < ua.len() {
    var code = ua[i];
    var ca: Int = 0;
    var j: Int = 0;
    while j < la {
      if (string.byte_at(a, j) as Int) == code {
        ca = ca + 1;
      };
      j = j + 1;
    }
    var cb: Int = 0;
    j = 0;
    while j < lb {
      if (string.byte_at(b, j) as Int) == code {
        cb = cb + 1;
      };
      j = j + 1;
    }
    dot = dot + ca * cb;
    na = na + ca * ca;
    nb = nb + cb * cb;
    i = i + 1;
  }
  i = 0;
  while i < ub.len() {
    var code = ub[i];
    var in_a = false;
    var j: Int = 0;
    while j < ua.len() {
      if ua[j] == code {
        in_a = true;
        break;
      };
      j = j + 1;
    }
    if !in_a {
      var cb2: Int = 0;
      var k: Int = 0;
      while k < lb {
        if (string.byte_at(b, k) as Int) == code {
          cb2 = cb2 + 1;
        };
        k = k + 1;
      }
      nb = nb + cb2 * cb2;
    };
    i = i + 1;
  }
  if na == 0 || nb == 0 {
    return 0.0;
  };
  let denom = sqrt(convert.int_to_float(na)) * sqrt(convert.int_to_float(nb));
  if denom == 0.0 {
    return 0.0;
  };
  convert.int_to_float(dot) / denom
}

// -- Longest common subsequence / substring ----------------------------------

/// Length of the longest common subsequence of `a` and `b`.
/// Two-row DP. Complexity: O(|a| * |b|) time, O(|b|) space.
pub fn longest_common_subsequence(a: Str, b: Str) -> Int {
  let la = a.len();
  let lb = b.len();
  var prev = Vec[Int].new();
  var i: Int = 0;
  while i <= lb {
    prev.push(0);
    i = i + 1;
  }
  var j: Int = 1;
  while j <= la {
    var cur = Vec[Int].new();
    cur.push(0);
    var k: Int = 1;
    while k <= lb {
      var val: Int = 0;
      if string.byte_at(a, j - 1) == string.byte_at(b, k - 1) {
        val = prev[k - 1] + 1;
      } else {
        val = prev[k];
        if cur[k - 1] > val {
          val = cur[k - 1];
        };
      };
      cur.push(val);
      k = k + 1;
    }
    prev = cur;
    j = j + 1;
  }
  prev[lb]
}

/// Length of the longest common contiguous substring of `a` and `b`.
/// Two-row DP, resetting to 0 on mismatch. O(|a| * |b|) time, O(|b|) space.
pub fn longest_common_substring(a: Str, b: Str) -> Int {
  let la = a.len();
  let lb = b.len();
  var prev = Vec[Int].new();
  var i: Int = 0;
  while i <= lb {
    prev.push(0);
    i = i + 1;
  }
  var best: Int = 0;
  var j: Int = 1;
  while j <= la {
    var cur = Vec[Int].new();
    cur.push(0);
    var k: Int = 1;
    while k <= lb {
      var val: Int = 0;
      if string.byte_at(a, j - 1) == string.byte_at(b, k - 1) {
        val = prev[k - 1] + 1;
        if val > best {
          best = val;
        };
      };
      cur.push(val);
      k = k + 1;
    }
    prev = cur;
    j = j + 1;
  }
  best
}

// -- Phonetic algorithms -----------------------------------------------------

/// Hamming distance: number of differing byte positions. Returns None when the
/// byte lengths differ; Some(0) for empty == empty.
pub fn hamming(a: Str, b: Str) -> Option[Int] {
  let la = a.len();
  let lb = b.len();
  if la != lb {
    return None;
  };
  var count: Int = 0;
  var i: Int = 0;
  while i < la {
    if string.byte_at(a, i) != string.byte_at(b, i) {
      count = count + 1;
    };
    i = i + 1;
  }
  Some(count)
}

/// Metaphone-LITE: a deliberately simplified Metaphone variant (it is NOT
/// guaranteed to match the real Metaphone algorithm). Uppercases the input,
/// keeps the first letter (with a few start-of-word rules), drops vowels,
/// maps the remaining consonants, then removes consecutive duplicate codes
/// and any H/W that are not the leading letter.
pub fn metaphone(word: Str) -> Str {
  let upper = string.str_upper(word);
  let len = upper.len();
  if len == 0 {
    return "";
  };
  var result = "";
  var last_code: Int = -1;
  let first = string.byte_at(upper, 0);
  if first == 88 {
    result = result + "S";
    last_code = 83;
  } elif first == 75 && len >= 2 && string.byte_at(upper, 1) == 78 {
    last_code = -1;
  } elif first == 87 && len >= 2 && string.byte_at(upper, 1) == 82 {
    last_code = -1;
  } else {
    result = result + _byte_to_str(first as Int);
    last_code = first as Int;
  }
  var i: Int = 1;
  while i < len {
    let c = string.byte_at(upper, i);
    var c1: Int = -1;
    var c2: Int = -1;
    if c == 65 || c == 69 || c == 73 || c == 79 || c == 85 {
      c1 = -1;
    } elif c == 66 {
      if i == len - 1 && string.byte_at(upper, i - 1) == 77 {
        c1 = -1;
      } else {
        c1 = 66;
      };
    } elif c == 67 {
      let nx = _peek_byte(upper, i + 1, len);
      if nx == 69 || nx == 73 || nx == 89 {
        c1 = 83;
      } else {
        c1 = 75;
      };
    } elif c == 68 {
      c1 = 84;
    } elif c == 70 {
      c1 = 70;
    } elif c == 71 {
      let nx = _peek_byte(upper, i + 1, len);
      if nx == 72 {
        c1 = -1;
      } elif nx == 69 || nx == 73 || nx == 89 {
        c1 = 74;
      } else {
        c1 = 75;
      };
    } elif c == 72 {
      c1 = -1;
    } elif c == 74 {
      c1 = 74;
    } elif c == 75 {
      c1 = 75;
    } elif c == 76 {
      c1 = 76;
    } elif c == 77 {
      c1 = 77;
    } elif c == 78 {
      c1 = 78;
    } elif c == 80 {
      c1 = 80;
    } elif c == 81 {
      c1 = 75;
    } elif c == 82 {
      c1 = 82;
    } elif c == 83 {
      let nx = _peek_byte(upper, i + 1, len);
      if nx == 72 {
        c1 = 88;
      } else {
        c1 = 83;
      };
    } elif c == 84 {
      let nx = _peek_byte(upper, i + 1, len);
      if nx == 72 {
        c1 = -1;
        i = i + 1;
      } else {
        c1 = 84;
      };
    } elif c == 86 {
      c1 = 70;
    } elif c == 87 {
      c1 = -1;
    } elif c == 88 {
      c1 = 75;
      c2 = 83;
    } elif c == 89 {
      c1 = 89;
    } elif c == 90 {
      c1 = 83;
    } else {
      c1 = -1;
    };
    if c1 != -1 && c1 != last_code {
      result = result + _byte_to_str(c1);
      last_code = c1;
    };
    if c2 != -1 && c2 != last_code {
      result = result + _byte_to_str(c2);
      last_code = c2;
    };
    i = i + 1;
  }
  result
}

/// Classic American Soundex code: keeps the first letter (uppercased), maps
/// the remaining letters to digit codes, drops adjacent duplicates (same code
/// as the previously emitted code) unless separated by a vowel, then pads
/// with '0' to exactly 4 characters.
pub fn soundex(word: Str) -> Str {
  let upper = string.str_upper(word);
  let len = upper.len();
  if len == 0 {
    return "";
  };
  var result = _byte_to_str(string.byte_at(upper, 0) as Int);
  var last_code: Int = 0;
  let fc = string.byte_at(upper, 0);
  if fc == 66 || fc == 70 || fc == 80 || fc == 86 {
    last_code = 1;
  } elif fc == 67 || fc == 71 || fc == 74 || fc == 75 || fc == 81 || fc == 83 || fc == 88 || fc == 90 {
    last_code = 2;
  } elif fc == 68 || fc == 84 {
    last_code = 3;
  } elif fc == 76 {
    last_code = 4;
  } elif fc == 77 || fc == 78 {
    last_code = 5;
  } elif fc == 82 {
    last_code = 6;
  } else {
    last_code = 0;
  }
  var i: Int = 1;
  while i < len {
    let c = string.byte_at(upper, i);
    var code: Int = 0;
    if c == 66 || c == 70 || c == 80 || c == 86 {
      code = 1;
    } elif c == 67 || c == 71 || c == 74 || c == 75 || c == 81 || c == 83 || c == 88 || c == 90 {
      code = 2;
    } elif c == 68 || c == 84 {
      code = 3;
    } elif c == 76 {
      code = 4;
    } elif c == 77 || c == 78 {
      code = 5;
    } elif c == 82 {
      code = 6;
    } else {
      code = 0;
    };
    if code != 0 {
      if code == last_code {
        if _is_vowel_byte(string.byte_at(upper, i - 1)) {
          result = result + _byte_to_str(48 + code);
        };
      } else {
        result = result + _byte_to_str(48 + code);
        last_code = code;
      };
    };
    i = i + 1;
  }
  if result.len() > 4 {
    result = string.str_slice(result, 0, 4);
  } else {
    while result.len() < 4 {
      result = result + "0";
    };
  };
  result
}

// ============================================================================
// 2026-08-11 additions: Jaccard, LCP/LCSuffix, n-gram extraction
// ============================================================================

// All contiguous n-grams of `s` (n = 1 -> single chars). Empty input or
// n < 1 -> empty Vec. O(len) with O(len) output.
pub fn ngram_extract(s: Str, n: Int) -> Vec[Str] {
  var out = Vec[Str].new();
  var len = xiom.string.str_len(s);
  if n < 1 || len < n {
    return out;
  }
  var i: Int = 0;
  while i + n <= len {
    out.push(xiom.string.str_slice(s, i, i + n));
    i = i + 1;
  }
  return out;
}

// Content-based string equality. The compiler's `==` between two runtime
// Vec[Str] ELEMENTS lowers to pointer comparison (COMPILER_BUGS.md BUG 17),
// so all element-to-element string tests go through byte-wise comparison.
fn _str_eq(a: Str, b: Str) -> Bool {
  var la = xiom.string.str_len(a);
  var lb = xiom.string.str_len(b);
  if la != lb {
    return false;
  }
  var i: Int = 0;
  while i < la {
    if xiom.string.byte_at(a, i) != xiom.string.byte_at(b, i) {
      return false;
    }
    i = i + 1;
  }
  return true;
}

// Jaccard similarity over n-grams: |A & B| / |A | B| in Float64 (0 when
// both inputs have no n-grams, 1 when identical). O(|a|-|b|) naive set
// comparison -- the compiler's Set is not usable for Str elements here.
pub fn jaccard_similarity(a: Str, b: Str, n: Int) -> Float64 {
  var ga = ngram_extract(a, n);
  var gb = ngram_extract(b, n);
  if ga.len() == 0 && gb.len() == 0 {
    return 0.0;
  }
  var inter: Int = 0;
  var i: Int = 0;
  while i < ga.len() {
    var j: Int = 0;
    var found = false;
    while j < gb.len() && !found {
      if _str_eq(ga[i], gb[j]) {
        found = true;
      }
      j = j + 1;
    }
    if found {
      inter = inter + 1;
    }
    i = i + 1;
  }
  var union = ga.len() + gb.len() - inter;
  if union <= 0 {
    return 0.0;
  }
  return xiom.convert.int_to_float(inter) / xiom.convert.int_to_float(union);
}

// Length of the longest common prefix of a and b. O(min(|a|,|b|)).
pub fn longest_common_prefix(a: Str, b: Str) -> Int {
  var la = xiom.string.str_len(a);
  var lb = xiom.string.str_len(b);
  var lim = la;
  if lb < lim { lim = lb; }
  var i: Int = 0;
  while i < lim {
    if xiom.string.byte_at(a, i) != xiom.string.byte_at(b, i) {
      break;
    }
    i = i + 1;
  }
  return i;
}

// Length of the longest common suffix of a and b. O(min(|a|,|b|)).
pub fn longest_common_suffix(a: Str, b: Str) -> Int {
  var la = xiom.string.str_len(a);
  var lb = xiom.string.str_len(b);
  var lim = la;
  if lb < lim { lim = lb; }
  var i: Int = 0;
  while i < lim {
    if xiom.string.byte_at(a, la - 1 - i) != xiom.string.byte_at(b, lb - 1 - i) {
      break;
    }
    i = i + 1;
  }
  return i;
}
