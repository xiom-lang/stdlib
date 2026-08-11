// XIOM — Miscellaneous Pure Algorithm Utilities
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.
//
// Collection of pure functions: version comparison, string distance,
// glob matching, natural sort, slugify, soundex, etc.
// NOTE: UUID generation lives in xiom.rand (rand.uuid_v4 / rand.uuid_v7).

module xiom.misc

use xiom.misc.glob;
use xiom.misc.levenshtein;
use xiom.misc.semver;
use xiom.misc.soundex;
use xiom.misc.natural;

use xiom.string;
use xiom.core;
use xiom.char;
use xiom.convert;

extern "C" {
    fn malloc(size: UInt) -> *UInt8;
    fn xiom_char_at(s: Str, pos: Int) -> Char;
}

// ── Semver comparison ────────────────────────────────────────────────────────

/// Compare two semantic version strings (major.minor.patch).
/// Returns -1 if a < b, 0 if equal, 1 if a > b.
pub fn semver_compare(a: Str, b: Str) -> Int
    requires: a.len() > 0
    requires: b.len() > 0
{
    let parts_a = xiom.string.str_split(a, ".");
    let parts_b = xiom.string.str_split(b, ".");
    var i: Int = 0;
    var max_i: Int = parts_a.len();
    if parts_b.len() > max_i {
        max_i = parts_b.len();
    };
    while i < max_i {
        var num_a: Int = 0;
        var num_b: Int = 0;
        if i < parts_a.len() {
            let parsed = xiom.string.str_to_int(parts_a[i]);
            match parsed {
                Ok(v) => { num_a = v; };
                Err(_) => { num_a = 0; };
            };
        };
        if i < parts_b.len() {
            let parsed = xiom.string.str_to_int(parts_b[i]);
            match parsed {
                Ok(v) => { num_b = v; };
                Err(_) => { num_b = 0; };
            };
        };
        if num_a < num_b { return -1; };
        if num_a > num_b { return 1; };
        i = i + 1;
    };
    0
}

// ── Levenshtein distance ─────────────────────────────────────────────────────

/// Compute the Levenshtein (edit) distance between two strings.
/// Uses dynamic programming with O(m*n) time and O(min(m,n)) space.
pub fn levenshtein_distance(a: Str, b: Str) -> Int
    ensures: result >= 0
{
    let m = a.len();
    let n = b.len();
    if m == 0 { return n; };
    if n == 0 { return m; };

    // Ensure a is the shorter string (space optimization)
    var shorter = a;
    var longer = b;
    var shorter_len = m;
    var longer_len = n;
    if m > n {
        shorter = b;
        longer = a;
        shorter_len = n;
        longer_len = m;
    };

    // Single-row DP: prev row
    var prev = Vec[Int].new();
    var j: Int = 0;
    while j <= shorter_len {
        prev.push(j);
        j = j + 1;
    };

    var i: Int = 1;
    while i <= longer_len {
        var curr = Vec[Int].new();
        curr.push(i);
        j = 1;
        while j <= shorter_len {
            var cost: Int = 1;
            if longer.char_at(i - 1) == shorter.char_at(j - 1) {
                cost = 0;
            };
            let del = prev[j] + 1;
            let ins = curr[j - 1] + 1;
            let sub = prev[j - 1] + cost;
            var min_val = del;
            if ins < min_val { min_val = ins; };
            if sub < min_val { min_val = sub; };
            curr.push(min_val);
            j = j + 1;
        };
        prev = curr;
        i = i + 1;
    };

    prev[shorter_len]
}

// ── Glob matching ────────────────────────────────────────────────────────────

/// Match a string against a glob pattern supporting:
///   '?' matches any single character
///   '*' matches zero or more characters
pub fn glob_match(pattern: Str, text: Str) -> Bool {
    let plen = pattern.len();
    let tlen = text.len();
    var pi: Int = 0;
    var ti: Int = 0;
    var star_idx: Int = -1;
    var match_idx: Int = 0;

    while ti < tlen {
        if pi < plen && pattern.char_at(pi) == '*' {
            star_idx = pi;
            match_idx = ti;
            pi = pi + 1;
        } elif pi < plen && (pattern.char_at(pi) == '?' || pattern.char_at(pi) == text.char_at(ti)) {
            pi = pi + 1;
            ti = ti + 1;
        } elif star_idx >= 0 {
            pi = star_idx + 1;
            match_idx = match_idx + 1;
            ti = match_idx;
        } else {
            return false;
        };
    };

    while pi < plen && pattern.char_at(pi) == '*' {
        pi = pi + 1;
    };

    pi == plen
}

// ── Natural compare ──────────────────────────────────────────────────────────

/// Compare two strings using natural sort order (e.g., "file2" < "file10").
/// Returns -1 if a < b, 0 if equal, 1 if a > b.
pub fn natural_compare(a: Str, b: Str) -> Int {
    let alen = a.len();
    let blen = b.len();
    var ai: Int = 0;
    var bi: Int = 0;

    while ai < alen && bi < blen {
        let ac = a.char_at(ai);
        let bc = b.char_at(bi);

        if xiom.char.is_digit(ac) && xiom.char.is_digit(bc) {
            var a_num: Int = 0;
            var b_num: Int = 0;
            while ai < alen && xiom.char.is_digit(a.char_at(ai)) {
                a_num = a_num * 10 + ((a.char_at(ai) as Int) - 48);
                ai = ai + 1;
            };
            while bi < blen && xiom.char.is_digit(b.char_at(bi)) {
                b_num = b_num * 10 + ((b.char_at(bi) as Int) - 48);
                bi = bi + 1;
            };
            if a_num < b_num { return -1; };
            if a_num > b_num { return 1; };
        } else {
            if (ac as Int) < (bc as Int) { return -1; };
            if (ac as Int) > (bc as Int) { return 1; };
            ai = ai + 1;
            bi = bi + 1;
        };
    };

    if ai == alen && bi == blen {
        return 0;
    };
    if ai < alen { return 1; };
    -1
}

// ── Slugify ──────────────────────────────────────────────────────────────────

/// Convert a string to a URL-friendly slug (lowercased, non-alnum → '-').
pub fn slugify(s: Str) -> Str
    ensures: result.len() <= s.len()
{
    let len = s.len();
    if len == 0 {
        return "";
    };
    unsafe {
        var buf = malloc(len as UInt + 1);
        var out: Int = 0;
        var last_was_dash: Bool = false;
        var i: Int = 0;
        while i < len {
            let c = s.char_at(i);
            if xiom.char.is_alphanumeric(c) {
                let lc = xiom.char.to_lowercase(c);
                buf[out] = lc as UInt8;
                out = out + 1;
                last_was_dash = false;
            } elif !last_was_dash && out > 0 {
                buf[out] = 45; // '-'
                out = out + 1;
                last_was_dash = true;
            };
            i = i + 1;
        };
        if last_was_dash && out > 0 {
            out = out - 1;
        };
        buf[out] = 0;
        return Str.from_cstring(buf);
    }
}

// ── Soundex helper ────────────────────────────────────────────────────────────

/// Map a character to its Soundex digit (1-6), or 0 if ignored.
fn soundex_map(c: Char) -> Int {
    let uc = xiom.char.to_uppercase(c);
    let v = uc as Int;
    if v == 'B' as Int || v == 'F' as Int || v == 'P' as Int || v == 'V' as Int { return 1; };
    if v == 'C' as Int || v == 'G' as Int || v == 'J' as Int || v == 'K' as Int ||
       v == 'Q' as Int || v == 'S' as Int || v == 'X' as Int || v == 'Z' as Int { return 2; };
    if v == 'D' as Int || v == 'T' as Int { return 3; };
    if v == 'L' as Int { return 4; };
    if v == 'M' as Int || v == 'N' as Int { return 5; };
    if v == 'R' as Int { return 6; };
    0
}

// ── Soundex ──────────────────────────────────────────────────────────────────

/// Compute the classic American Soundex code for a string (4 chars).
pub fn soundex(code: Str) -> Str {
    let len = code.len();
    if len == 0 {
        return "0000";
    };

    var first: Int = 0;
    var i: Int = 0;
    var found_letter: Bool = false;
    while i < len && !found_letter {
        let c = xiom_char_at(code, i);
        if xiom.char.is_alphabetic(c) {
            first = xiom.char.to_uppercase(c) as Int;
            i = i + 1;
            found_letter = true;
        } else {
            i = i + 1;
        };
    };
    if first == 0 {
        return "0000";
    };

    var prev_code: Int = soundex_map(xiom_char_at(code, i - 1));
    var count: Int = 0;
    unsafe {
        var buf = malloc(5 as UInt);
        buf[0] = first as UInt8;
        count = 1;

        while i < len && count < 4 {
            let c = xiom_char_at(code, i);
            let d = soundex_map(c);
            if d > 0 && d != prev_code {
                buf[count] = (48 + d) as UInt8;
                count = count + 1;
                prev_code = d;
            } elif d == 0 {
                let v = xiom.char.to_uppercase(c) as Int;
                if v != 'H' as Int && v != 'W' as Int {
                    prev_code = 0;
                };
            };
            i = i + 1;
        };

        while count < 4 {
            buf[count] = 48; // '0'
            count = count + 1;
        };
        buf[4] = 0;
        return Str.from_cstring(buf);
    }
}

// ── Palindrome ───────────────────────────────────────────────────────────────

/// Check if a string reads the same forward and backward.
pub fn is_palindrome(s: Str) -> Bool {
    let len = s.len();
    var left: Int = 0;
    var right: Int = len - 1;
    while left < right {
        if s.char_at(left) != s.char_at(right) {
            return false;
        };
        left = left + 1;
        right = right - 1;
    };
    true
}

// ── Reverse string ───────────────────────────────────────────────────────────

/// Return the reversed copy of a string.
pub fn reverse_str(s: Str) -> Str
    ensures: result.len() == s.len()
{
    let len = s.len();
    if len == 0 {
        return "";
    };
    unsafe {
        var buf = malloc(len as UInt + 1);
        var i: Int = 0;
        while i < len {
            buf[len - 1 - i] = s.char_at(i) as UInt8;
            i = i + 1;
        };
        buf[len] = 0;
        return Str.from_cstring(buf);
    }
}

// ── Count occurrences ────────────────────────────────────────────────────────

/// Count non-overlapping occurrences of needle in haystack.
pub fn count_occurrences(haystack: Str, needle: Str) -> Int
    requires: needle.len() > 0
    ensures:  result >= 0
{
    let nlen = needle.len();
    let hlen = haystack.len();
    if nlen == 0 || nlen > hlen {
        return 0;
    };
    var count: Int = 0;
    var pos: Int = 0;
    while pos <= hlen - nlen {
        var match_found: Bool = true;
        var j: Int = 0;
        while j < nlen && match_found {
            if haystack.char_at(pos + j) != needle.char_at(j) {
                match_found = false;
            } else {
                j = j + 1;
            };
        };
        if match_found {
            count = count + 1;
            pos = pos + nlen;
        } else {
            pos = pos + 1;
        };
    };
    count
}

// ── Truncate ─────────────────────────────────────────────────────────────────

/// Truncate a string to at most max_len bytes.
pub fn truncate(s: Str, max_len: Int) -> Str
    requires: max_len >= 0
    ensures:  result.len() <= s.len()
{
    let len = s.len();
    if len <= max_len || max_len < 0 {
        return s;
    };
    if max_len == 0 {
        return "";
    };
    xiom.string.str_slice(s, 0, max_len)
}

// ============================================================================
// Extended utilities (2026-08-11): string metrics, case conversion, roman
// numerals, ordinal/pluralize, units. ASCII-oriented where noted.
// ============================================================================

// Damerau-Levenshtein distance (insert/delete/substitute/transpose), O(n*m).
pub fn damerau_levenshtein_distance(a: Str, b: Str) -> Int {
  var la = a.len();
  var lb = b.len();
  var cols = lb + 1;
  var dp = Vec[Int].new();
  var i = 0;
  while i < (la + 1) * cols { dp.push(0); i = i + 1; }
  i = 0;
  while i <= la { dp[i * cols] = i; i = i + 1; }
  i = 0;
  while i <= lb { dp[i] = i; i = i + 1; }
  var ai = 1;
  while ai <= la {
    var bj = 1;
    while bj <= lb {
      var cost = 1;
      if xiom.string.str_slice(a, ai - 1, ai) == xiom.string.str_slice(b, bj - 1, bj) { cost = 0; }
      var del = dp[(ai - 1) * cols + bj] + 1;
      var ins = dp[ai * cols + (bj - 1)] + 1;
      var sub = dp[(ai - 1) * cols + (bj - 1)] + cost;
      var best = del;
      if ins < best { best = ins; }
      if sub < best { best = sub; }
      // transposition: a[ai-1] == b[bj-2] && a[ai-2] == b[bj-1]
      if ai > 1 && bj > 1 {
        if xiom.string.str_slice(a, ai - 1, ai) == xiom.string.str_slice(b, bj - 2, bj - 1) &&
           xiom.string.str_slice(a, ai - 2, ai - 1) == xiom.string.str_slice(b, bj - 1, bj) {
          var trans = dp[(ai - 2) * cols + (bj - 2)] + 1;
          if trans < best { best = trans; }
        }
      }
      dp[ai * cols + bj] = best;
      bj = bj + 1;
    }
    ai = ai + 1;
  }
  return dp[la * cols + lb];
}

// Jaro similarity in [0, 1] (ASCII-aware matching window).
pub fn jaro_similarity(a: Str, b: Str) -> Float64 {
  var la = a.len();
  var lb = b.len();
  if la == 0 && lb == 0 { return 1.0; }
  if la == 0 || lb == 0 { return 0.0; }
  var window = la;
  if lb > window { window = lb; }
  window = window / 2;
  if window > 0 { window = window - 1; }
  if window < 0 { window = 0; }
  var a_m = Vec[Int].new();
  var b_m = Vec[Int].new();
  var i = 0;
  while i < la { a_m.push(0); i = i + 1; }
  i = 0;
  while i < lb { b_m.push(0); i = i + 1; }
  var matches = 0;
  i = 0;
  while i < la {
    var lo = i - window;
    if lo < 0 { lo = 0; }
    var hi = i + window + 1;
    if hi > lb { hi = lb; }
    var j = lo;
    while j < hi {
      if b_m[j] == 0 {
        if xiom.string.str_slice(a, i, i + 1) == xiom.string.str_slice(b, j, j + 1) {
          a_m[i] = 1;
          b_m[j] = 1;
          matches = matches + 1;
          break;
        }
      }
      j = j + 1;
    }
    i = i + 1;
  }
  if matches == 0 { return 0.0; }
  // count transpositions
  var trans = 0;
  var k = 0;
  i = 0;
  while i < la {
    if a_m[i] == 1 {
      while k < lb && b_m[k] == 0 { k = k + 1; }
      if k < lb {
        if xiom.string.str_slice(a, i, i + 1) != xiom.string.str_slice(b, k, k + 1) { trans = trans + 1; }
        k = k + 1;
      }
    }
    i = i + 1;
  }
  var mf = matches as Float64;
  var tf = (trans / 2) as Float64;
  var laf = la as Float64;
  var lbf = lb as Float64;
  var jaro = (mf / laf + mf / lbf + (mf - tf) / mf) / 3.0;
  return jaro;
}

// Jaro-Winkler similarity (prefix bonus up to 4 chars, scale 0.1).
pub fn jaro_winkler_similarity(a: Str, b: Str) -> Float64 {
  var j = jaro_similarity(a, b);
  var prefix = 0;
  var limit = a.len();
  if b.len() < limit { limit = b.len(); }
  if limit > 4 { limit = 4; }
  var i = 0;
  while i < limit {
    if xiom.string.str_slice(a, i, i + 1) == xiom.string.str_slice(b, i, i + 1) { prefix = prefix + 1; }
    else { break; }
    i = i + 1;
  }
  var pf = prefix as Float64;
  return j + pf * 0.1 * (1.0 - j);
}

// Hamming distance; -1 if lengths differ.
pub fn hamming_distance(a: Str, b: Str) -> Int {
  if a.len() != b.len() { return -1; }
  var d = 0;
  var i = 0;
  while i < a.len() {
    if xiom.string.str_slice(a, i, i + 1) != xiom.string.str_slice(b, i, i + 1) { d = d + 1; }
    i = i + 1;
  }
  return d;
}

// Longest common subsequence (not substring), O(n*m).
pub fn longest_common_subsequence(a: Str, b: Str) -> Str {
  var la = a.len();
  var lb = b.len();
  var cols = lb + 1;
  var dp = Vec[Int].new();
  var i = 0;
  while i < (la + 1) * cols { dp.push(0); i = i + 1; }
  var ai = 1;
  while ai <= la {
    var bj = 1;
    while bj <= lb {
      if xiom.string.str_slice(a, ai - 1, ai) == xiom.string.str_slice(b, bj - 1, bj) {
        dp[ai * cols + bj] = dp[(ai - 1) * cols + (bj - 1)] + 1;
      } else {
        var up = dp[(ai - 1) * cols + bj];
        var left = dp[ai * cols + (bj - 1)];
        if up >= left { dp[ai * cols + bj] = up; }
        else { dp[ai * cols + bj] = left; }
      }
      bj = bj + 1;
    }
    ai = ai + 1;
  }
  // backtrack
  var result = "";
  var x = la;
  var y = lb;
  while x > 0 && y > 0 {
    if xiom.string.str_slice(a, x - 1, x) == xiom.string.str_slice(b, y - 1, y) {
      result = xiom.string.str_concat(xiom.string.str_slice(a, x - 1, x), result);
      x = x - 1;
      y = y - 1;
    } elif dp[(x - 1) * cols + y] >= dp[x * cols + (y - 1)] {
      x = x - 1;
    } else {
      y = y - 1;
    }
  }
  return result;
}

// Roman numerals for 1..3999; "" outside the range.
pub fn to_roman(n: Int) -> Str
  requires: n >= 1
  requires: n <= 3999
{
  if n < 1 || n > 3999 { return ""; }
  var values = Vec[Int].new();
  values.push(1000); values.push(900); values.push(500); values.push(400);
  values.push(100); values.push(90); values.push(50); values.push(40);
  values.push(10); values.push(9); values.push(5); values.push(4); values.push(1);
  var symbols = Vec[Str].new();
  symbols.push("M"); symbols.push("CM"); symbols.push("D"); symbols.push("CD");
  symbols.push("C"); symbols.push("XC"); symbols.push("L"); symbols.push("XL");
  symbols.push("X"); symbols.push("IX"); symbols.push("V"); symbols.push("IV"); symbols.push("I");
  var result = "";
  var v = n;
  var i = 0;
  while i < values.len() {
    while v >= values[i] {
      result = xiom.string.str_concat(result, symbols[i]);
      v = v - values[i];
    }
    i = i + 1;
  }
  return result;
}

// Parse a Roman numeral; 0 if invalid.
pub fn from_roman(s: Str) -> Int {
  var total = 0;
  var prev = 0;
  var i = s.len() - 1;
  while i >= 0 {
    var ch = xiom.string.str_slice(s, i, i + 1);
    var val = 0;
    if ch == "I" { val = 1; }
    elif ch == "V" { val = 5; }
    elif ch == "X" { val = 10; }
    elif ch == "L" { val = 50; }
    elif ch == "C" { val = 100; }
    elif ch == "D" { val = 500; }
    elif ch == "M" { val = 1000; }
    else { return 0; }
    if val < prev { total = total - val; }
    else { total = total + val; }
    prev = val;
    i = i - 1;
  }
  return total;
}

// ASCII case helpers shared by the converters.
fn _misc_split_words(s: Str) -> Vec[Str] {
  var words = Vec[Str].new();
  var current = "";
  var i = 0;
  var prev_lower = false;
  while i < s.len() {
    var ch = xiom.string.str_slice(s, i, i + 1);
    var code = xiom.string.byte_at(s, i);
    var is_alpha = false;
    var is_upper = false;
    if code >= 65 && code <= 90 { is_alpha = true; is_upper = true; }
    if code >= 97 && code <= 122 { is_alpha = true; }
    if code >= 48 && code <= 57 { is_alpha = true; }
    if is_alpha {
      // camelCase boundary: uppercase following a lowercase starts a word.
      if is_upper && prev_lower && current.len() > 0 {
        words.push(current);
        current = "";
      }
      current = xiom.string.str_concat(current, ch);
      prev_lower = !is_upper;
    } else {
      if current.len() > 0 { words.push(current); current = ""; }
      prev_lower = false;
    }
    i = i + 1;
  }
  if current.len() > 0 { words.push(current); }
  return words;
}

fn _misc_lower(s: Str) -> Str {
  var lower = "abcdefghijklmnopqrstuvwxyz";
  var upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  var result = "";
  var i = 0;
  while i < s.len() {
    var ch = xiom.string.str_slice(s, i, i + 1);
    var idx_opt = xiom.string.str_index_of(upper, ch);
    var idx = -1;
    match idx_opt {
      Some(v) => { idx = v; },
      None => {},
    }
    if idx >= 0 { ch = xiom.string.str_slice(lower, idx, idx + 1); }
    result = xiom.string.str_concat(result, ch);
    i = i + 1;
  }
  return result;
}

fn _misc_capitalize(s: Str) -> Str {
  var lower = "abcdefghijklmnopqrstuvwxyz";
  var upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  if s.len() == 0 { return s; }
  var first = xiom.string.str_slice(s, 0, 1);
  var idx_opt = xiom.string.str_index_of(lower, first);
  var idx = -1;
  match idx_opt {
    Some(v) => { idx = v; },
    None => {},
  }
  if idx >= 0 { first = xiom.string.str_slice(upper, idx, idx + 1); }
  var rest = _misc_lower(xiom.string.str_slice(s, 1, s.len()));
  return xiom.string.str_concat(first, rest);
}

pub fn to_camel_case(s: Str) -> Str {
  var words = _misc_split_words(s);
  var result = "";
  var i = 0;
  while i < words.len() {
    var w = words[i];
    if i == 0 { result = _misc_lower(w); }
    else { result = xiom.string.str_concat(result, _misc_capitalize(w)); }
    i = i + 1;
  }
  return result;
}

pub fn to_pascal_case(s: Str) -> Str {
  var words = _misc_split_words(s);
  var result = "";
  var i = 0;
  while i < words.len() {
    result = xiom.string.str_concat(result, _misc_capitalize(words[i]));
    i = i + 1;
  }
  return result;
}

pub fn to_snake_case(s: Str) -> Str {
  var words = _misc_split_words(s);
  var result = "";
  var i = 0;
  while i < words.len() {
    if i > 0 { result = xiom.string.str_concat(result, "_"); }
    result = xiom.string.str_concat(result, _misc_lower(words[i]));
    i = i + 1;
  }
  return result;
}

pub fn to_kebab_case(s: Str) -> Str {
  var words = _misc_split_words(s);
  var result = "";
  var i = 0;
  while i < words.len() {
    if i > 0 { result = xiom.string.str_concat(result, "-"); }
    result = xiom.string.str_concat(result, _misc_lower(words[i]));
    i = i + 1;
  }
  return result;
}

// Ordinal suffix: 1st, 2nd, 3rd, 11th, 21st, ...
pub fn ordinal(n: Int) -> Str {
  var suffix = "th";
  var mod100 = n % 100;
  if mod100 < 11 || mod100 > 13 {
    var mod10 = n % 10;
    if mod10 == 1 { suffix = "st"; }
    elif mod10 == 2 { suffix = "nd"; }
    elif mod10 == 3 { suffix = "rd"; }
  }
  return xiom.string.str_concat(xiom.core.to_string(n), suffix);
}

// Naive pluralize: count == 1 keeps the singular; otherwise +s / +es / +ies.
pub fn pluralize(s: Str, count: Int) -> Str {
  if count == 1 { return s; }
  if s.len() == 0 { return s; }
  var last = xiom.string.str_slice(s, s.len() - 1, s.len());
  if last == "y" {
    var second = "";
    if s.len() >= 2 { second = xiom.string.str_slice(s, s.len() - 2, s.len() - 1); }
    var vowels = "aeiou";
    var v_opt = xiom.string.str_index_of(vowels, second);
    var v_idx = -1;
    match v_opt {
      Some(v) => { v_idx = v; },
      None => {},
    }
    if v_idx >= 0 {
      return xiom.string.str_concat(s, "s");
    }
    var stem = xiom.string.str_slice(s, 0, s.len() - 1);
    return xiom.string.str_concat(stem, "ies");
  }
  if last == "s" || last == "x" || last == "z" {
    return xiom.string.str_concat(s, "es");
  }
  if s.len() >= 2 {
    var tail = xiom.string.str_slice(s, s.len() - 2, s.len());
    if tail == "ch" || tail == "sh" {
      return xiom.string.str_concat(s, "es");
    }
  }
  return xiom.string.str_concat(s, "s");
}

// Anagrams (ASCII case-insensitive letter counts).
pub fn is_anagram(a: Str, b: Str) -> Bool {
  var counts = Vec[Int].new();
  var i = 0;
  while i < 26 { counts.push(0); i = i + 1; }
  i = 0;
  while i < a.len() {
    var code = xiom.string.byte_at(a, i);
    if code >= 65 && code <= 90 { code = code + 32; }
    if code >= 97 && code <= 122 { counts[code - 97] = counts[code - 97] + 1; }
    i = i + 1;
  }
  i = 0;
  while i < b.len() {
    var code = xiom.string.byte_at(b, i);
    if code >= 65 && code <= 90 { code = code + 32; }
    if code >= 97 && code <= 122 { counts[code - 97] = counts[code - 97] - 1; }
    i = i + 1;
  }
  i = 0;
  while i < 26 {
    if counts[i] != 0 { return false; }
    i = i + 1;
  }
  return true;
}

// ---- Units ----

pub fn celsius_to_fahrenheit(c: Float64) -> Float64 {
  return c * 1.8 + 32.0;
}

pub fn fahrenheit_to_celsius(f: Float64) -> Float64 {
  return (f - 32.0) / 1.8;
}

pub fn celsius_to_kelvin(c: Float64) -> Float64 {
  return c + 273.15;
}

pub fn kelvin_to_celsius(k: Float64) -> Float64 {
  return k - 273.15;
}

pub fn fahrenheit_to_kelvin(f: Float64) -> Float64 {
  return (f + 459.67) * 5.0 / 9.0;
}

pub fn kelvin_to_fahrenheit(k: Float64) -> Float64 {
  return k * 1.8 - 459.67;
}

pub fn miles_to_km(m: Float64) -> Float64 {
  return m * 1.609344;
}

pub fn km_to_miles(km: Float64) -> Float64 {
  return km / 1.609344;
}

// Human-readable byte size: "512 B", "1.5 KB", "3.2 MB", ...
// Integer math only (the runtime lacks decimal float formatting).
pub fn human_size(bytes: Int) -> Str {
  if bytes < 0 { return "0 B"; }
  var units = Vec[Str].new();
  units.push("B"); units.push("KB"); units.push("MB");
  units.push("GB"); units.push("TB"); units.push("PB");
  var unit_idx = 0;
  var value = bytes;
  while value >= 1024 && unit_idx < units.len() - 1 {
    value = value / 1024;
    unit_idx = unit_idx + 1;
  }
  if unit_idx == 0 {
    return xiom.string.str_concat(xiom.core.to_string(bytes), " B");
  }
  // rounded to one decimal: scaled = value*10/unit with +unit/2 rounding
  var scaled = (bytes * 10 + 512) / 1024;
  var u = 1;
  while u < unit_idx {
    scaled = scaled / 1024;
    u = u + 1;
  }
  var whole = scaled / 10;
  var frac = scaled % 10;
  var body = xiom.string.str_concat(xiom.core.to_string(whole), ".");
  body = xiom.string.str_concat(body, xiom.core.to_string(frac));
  return xiom.string.str_concat(body, " " + units[unit_idx]);
}

