// XIOM — Miscellaneous Pure Algorithm Utilities
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.
//
// Collection of pure functions: version comparison, string distance,
// glob matching, natural sort, slugify, soundex, etc.
// NOTE: UUID generation lives in xiom.rand (rand.uuid_v4 / rand.uuid_v7).

module xiom.misc

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
