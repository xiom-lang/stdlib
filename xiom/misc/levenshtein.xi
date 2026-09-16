// XIOM - Misc: Levenshtein
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.misc.levenshtein

// Depends on: xiom.string

// ============================================================================
// Edit-distance metrics and algorithms: Levenshtein, Damerau-Levenshtein,
// OSA and Wagner-Fischer with alignment and matrix helpers.
// ============================================================================

extern "C" {
    fn malloc(size: UInt) -> *UInt8;
}

/// The minimum edit distance between a and b (insert/delete/substitute).
/// O(m*n) time, O(min(m,n)) space via a rolling row.
pub fn levenshtein_distance(a: Str, b: Str) -> Int {
  var m = a.len();
  var n = b.len();
  if m == 0 { return n; }
  if n == 0 { return m; }
  var shorter = a;
  var longer = b;
  var short_len = m;
  var long_len = n;
  if m > n {
    shorter = b;
    longer = a;
    short_len = n;
    long_len = m;
  }
  var prev = Vec[Int].new();
  var j = 0;
  while j <= short_len {
    prev.push(j);
    j = j + 1;
  }
  var i = 1;
  while i <= long_len {
    var curr = Vec[Int].new();
    curr.push(i);
    j = 1;
    while j <= short_len {
      var cost = 1;
      if longer.char_at(i - 1) == shorter.char_at(j - 1) {
        cost = 0;
      }
      var del = prev[j] + 1;
      var ins = curr[j - 1] + 1;
      var sub = prev[j - 1] + cost;
      var min_val = del;
      if ins < min_val { min_val = ins; }
      if sub < min_val { min_val = sub; }
      curr.push(min_val);
      j = j + 1;
    }
    prev = curr;
    i = i + 1;
  }
  prev[short_len]
}

/// Edit distance capped at max. Returns the true distance when it is <= max,
/// otherwise returns max + 1 (indicating the distance exceeds the cap).
/// O(m*n) worst but only evaluates the diagonal band that can stay within
/// the limit, so long divergent strings exit early.
pub fn levenshtein_distance_limited(a: Str, b: Str, max: Int) -> Int {
  var m = a.len();
  var n = b.len();
  if m == 0 { var r1 = n; if r1 > max { return max + 1; } return r1; }
  if n == 0 { var r2 = m; if r2 > max { return max + 1; } return r2; }
  var limit = max;
  if limit < 0 { limit = 0; }
  var shorter = a;
  var longer = b;
  var short_len = m;
  var long_len = n;
  if m > n {
    shorter = b;
    longer = a;
    short_len = n;
    long_len = m;
  }
  if long_len - short_len > limit { return limit + 1; }
  var big = limit + 1;
  var prev = Vec[Int].new();
  var j = 0;
  while j <= short_len {
    prev.push(j);
    j = j + 1;
  }
  var i = 1;
  while i <= long_len {
    var curr = Vec[Int].new();
    curr.push(i);
    var lo = i - limit;
    if lo < 1 { lo = 1; }
    var hi = i + limit;
    if hi > short_len { hi = short_len; }
    j = 1;
    while j < lo {
      curr.push(big);
      j = j + 1;
    }
    while j <= hi {
      var cost = 1;
      if longer.char_at(i - 1) == shorter.char_at(j - 1) {
        cost = 0;
      }
      var del = prev[j] + 1;
      var ins = curr[j - 1] + 1;
      var sub = prev[j - 1] + cost;
      var min_val = del;
      if ins < min_val { min_val = ins; }
      if sub < min_val { min_val = sub; }
      curr.push(min_val);
      j = j + 1;
    }
    while j <= short_len {
      curr.push(big);
      j = j + 1;
    }
    prev = curr;
    i = i + 1;
  }
  var result = prev[short_len];
  if result > limit { result = limit + 1; }
  result
}

/// Normalized similarity in [0, 1]: 1 - dist / max(len_a, len_b).
/// Equal strings score 1.0; completely different strings approach 0.0.
pub fn levenshtein_similarity(a: Str, b: Str) -> Float64 {
  var m = a.len();
  var n = b.len();
  var max_len = m;
  if n > max_len { max_len = n; }
  if max_len == 0 { return 1.0; }
  var d = levenshtein_distance(a, b);
  1.0 - (d as Float64) / (max_len as Float64)
}

/// Compute the full (m+1) x (n+1) dynamic-programming matrix for a and b.
/// matrix[i][j] is the edit distance between a[0..i) and b[0..j).
/// O(m*n). NOTE: nested Vec[Vec[Int]] element access is unreliable in the
/// current compiler - treat the result as opaque.
pub fn levenshtein_matrix(a: Str, b: Str) -> Vec[Vec[Int]] {
  var m = a.len();
  var n = b.len();
  var matrix = Vec[Vec[Int]].new();
  var row0 = Vec[Int].new();
  var j = 0;
  while j <= n {
    row0.push(j);
    j = j + 1;
  }
  matrix.push(row0);
  var i = 1;
  while i <= m {
    var row = Vec[Int].new();
    row.push(i);
    var prev_row = matrix[i - 1];
    j = 1;
    while j <= n {
      var cost = 1;
      if a.char_at(i - 1) == b.char_at(j - 1) {
        cost = 0;
      }
      var del = prev_row[j] + 1;
      var ins = row[j - 1] + 1;
      var sub = prev_row[j - 1] + cost;
      var min_val = del;
      if ins < min_val { min_val = ins; }
      if sub < min_val { min_val = sub; }
      row.push(min_val);
      j = j + 1;
    }
    matrix.push(row);
    i = i + 1;
  }
  matrix
}

/// Optimal alignment of a and b as (aligned_a, aligned_b) with '-' marking
/// gaps. O(m*n) time, O(m*n) space.
pub fn levenshtein_align(a: Str, b: Str) -> (Str, Str) {
  var m = a.len();
  var n = b.len();
  var d = Vec[Int].new();
  var idx = 0;
  while idx < (m + 1) * (n + 1) {
    d.push(0);
    idx = idx + 1;
  }
  d[0] = 0;
  var i = 1;
  while i <= m {
    d[i * (n + 1)] = i;
    i = i + 1;
  }
  var j = 1;
  while j <= n {
    d[j] = j;
    j = j + 1;
  }
  i = 1;
  while i <= m {
    j = 1;
    while j <= n {
      var cost = 1;
      if a.char_at(i - 1) == b.char_at(j - 1) {
        cost = 0;
      }
      var del = d[(i - 1) * (n + 1) + j] + 1;
      var ins = d[i * (n + 1) + j - 1] + 1;
      var sub = d[(i - 1) * (n + 1) + j - 1] + cost;
      var min_val = del;
      if ins < min_val { min_val = ins; }
      if sub < min_val { min_val = sub; }
      d[i * (n + 1) + j] = min_val;
      j = j + 1;
    }
    i = i + 1;
  }
  var size = m + n + 2;
  unsafe {
    var buf_a = malloc(size as UInt);
    var buf_b = malloc(size as UInt);
    var out_a = size - 1;
    var out_b = size - 1;
    i = m;
    j = n;
    while i > 0 || j > 0 {
      if i > 0 && j > 0 && a.char_at(i - 1) == b.char_at(j - 1) {
        out_a = out_a - 1;
        out_b = out_b - 1;
        buf_a[out_a] = a.char_at(i - 1) as UInt8;
        buf_b[out_b] = b.char_at(j - 1) as UInt8;
        i = i - 1;
        j = j - 1;
      } elif i > 0 && j > 0 && d[i * (n + 1) + j] == d[(i - 1) * (n + 1) + (j - 1)] + 1 && d[i * (n + 1) + j] == d[(i - 1) * (n + 1) + j] + 1 && d[i * (n + 1) + j] == d[i * (n + 1) + j - 1] + 1 {
        out_a = out_a - 1;
        out_b = out_b - 1;
        buf_a[out_a] = a.char_at(i - 1) as UInt8;
        buf_b[out_b] = b.char_at(j - 1) as UInt8;
        i = i - 1;
        j = j - 1;
      } elif i > 0 && d[i * (n + 1) + j] == d[(i - 1) * (n + 1) + j] + 1 {
        out_a = out_a - 1;
        buf_a[out_a] = a.char_at(i - 1) as UInt8;
        out_b = out_b - 1;
        buf_b[out_b] = 45;
        i = i - 1;
      } else {
        out_a = out_a - 1;
        buf_a[out_a] = 45;
        out_b = out_b - 1;
        buf_b[out_b] = b.char_at(j - 1) as UInt8;
        j = j - 1;
      }
    }
    var total = size - 1 - out_a;
    var k = 0;
    while k < total {
      buf_a[k] = buf_a[out_a + k];
      buf_b[k] = buf_b[out_b + k];
      k = k + 1;
    }
    buf_a[total] = 0;
    buf_b[total] = 0;
    var ra = Str.from_cstring(buf_a);
    var rb = Str.from_cstring(buf_b);
    (ra, rb)
  }
}

/// The sequence of edit operations transforming a into b. Operations are
/// "keep:c", "del:c", "ins:c" and "sub:x>y". O(m*n).
pub fn levenshtein_edit_script(a: Str, b: Str) -> Vec[Str] {
  var ops = Vec[Str].new();
  var m = a.len();
  var n = b.len();
  var d = Vec[Int].new();
  var idx = 0;
  while idx < (m + 1) * (n + 1) {
    d.push(0);
    idx = idx + 1;
  }
  d[0] = 0;
  var i = 1;
  while i <= m {
    d[i * (n + 1)] = i;
    i = i + 1;
  }
  var j = 1;
  while j <= n {
    d[j] = j;
    j = j + 1;
  }
  i = 1;
  while i <= m {
    j = 1;
    while j <= n {
      var cost = 1;
      if a.char_at(i - 1) == b.char_at(j - 1) {
        cost = 0;
      }
      var del = d[(i - 1) * (n + 1) + j] + 1;
      var ins = d[i * (n + 1) + j - 1] + 1;
      var sub = d[(i - 1) * (n + 1) + j - 1] + cost;
      var min_val = del;
      if ins < min_val { min_val = ins; }
      if sub < min_val { min_val = sub; }
      d[i * (n + 1) + j] = min_val;
      j = j + 1;
    }
    i = i + 1;
  }
  var rev = Vec[Str].new();
  i = m;
  j = n;
  while i > 0 || j > 0 {
    if i > 0 && j > 0 && a.char_at(i - 1) == b.char_at(j - 1) {
      rev.push(op_keep(a.char_at(i - 1)));
      i = i - 1;
      j = j - 1;
    } elif i > 0 && j > 0 && d[i * (n + 1) + j] == d[(i - 1) * (n + 1) + (j - 1)] + 1 && d[i * (n + 1) + j] == d[(i - 1) * (n + 1) + j] + 1 && d[i * (n + 1) + j] == d[i * (n + 1) + j - 1] + 1 {
      rev.push(op_sub(a.char_at(i - 1), b.char_at(j - 1)));
      i = i - 1;
      j = j - 1;
    } elif i > 0 && d[i * (n + 1) + j] == d[(i - 1) * (n + 1) + j] + 1 {
      rev.push(op_del(a.char_at(i - 1)));
      i = i - 1;
    } else {
      rev.push(op_ins(b.char_at(j - 1)));
      j = j - 1;
    }
  }
  var k = rev.len();
  while k > 0 {
    ops.push(rev[k - 1]);
    k = k - 1;
  }
  ops
}

/// Build a "keep:c" operation string.
fn op_keep(c: Char) -> Str
  requires: true
{
  unsafe {
    var buf = malloc(8 as UInt);
    buf[0] = 107;
    buf[1] = 101;
    buf[2] = 101;
    buf[3] = 112;
    buf[4] = 58;
    buf[5] = c as UInt8;
    buf[6] = 0;
    return Str.from_cstring(buf);
  }
}

/// Build a "del:c" operation string.
fn op_del(c: Char) -> Str
  requires: true
{
  unsafe {
    var buf = malloc(8 as UInt);
    buf[0] = 100;
    buf[1] = 101;
    buf[2] = 108;
    buf[3] = 58;
    buf[4] = c as UInt8;
    buf[5] = 0;
    return Str.from_cstring(buf);
  }
}

/// Build an "ins:c" operation string.
fn op_ins(c: Char) -> Str
  requires: true
{
  unsafe {
    var buf = malloc(8 as UInt);
    buf[0] = 105;
    buf[1] = 110;
    buf[2] = 115;
    buf[3] = 58;
    buf[4] = c as UInt8;
    buf[5] = 0;
    return Str.from_cstring(buf);
  }
}

/// Build a "sub:x>y" operation string.
fn op_sub(a: Char, b: Char) -> Str
  requires: true
{
  unsafe {
    var buf = malloc(10 as UInt);
    buf[0] = 115;
    buf[1] = 117;
    buf[2] = 98;
    buf[3] = 58;
    buf[4] = a as UInt8;
    buf[5] = 62;
    buf[6] = b as UInt8;
    buf[7] = 0;
    return Str.from_cstring(buf);
  }
}

/// Damerau-Levenshtein distance with unrestricted adjacent transpositions.
/// O(m*n) time, O(m*n) space. Uses the classic last-occurrence algorithm.
pub fn damerau_levenshtein(a: Str, b: Str) -> Int {
  var m = a.len();
  var n = b.len();
  if m == 0 { return n; }
  if n == 0 { return m; }
  var d = Vec[Int].new();
  var idx = 0;
  while idx < (m + 1) * (n + 1) {
    d.push(0);
    idx = idx + 1;
  }
  var i = 1;
  while i <= m {
    d[i * (n + 1)] = i;
    i = i + 1;
  }
  var j = 1;
  while j <= n {
    d[j] = j;
    j = j + 1;
  }
  var da = Vec[Int].new();
  var b2 = 0;
  while b2 < 256 {
    da.push(0);
    b2 = b2 + 1;
  }
  i = 1;
  while i <= m {
    var last = 0;
    j = 1;
    while j <= n {
      var cost = 1;
      if a.char_at(i - 1) == b.char_at(j - 1) {
        cost = 0;
      }
      var k = da[b.char_at(j - 1) as Int];
      var l = last;
      var del = d[(i - 1) * (n + 1) + j] + 1;
      var ins = d[i * (n + 1) + j - 1] + 1;
      var sub = d[(i - 1) * (n + 1) + j - 1] + cost;
      var min_val = del;
      if ins < min_val { min_val = ins; }
      if sub < min_val { min_val = sub; }
      if k > 0 && l > 0 {
        var trans = d[(k - 1) * (n + 1) + (l - 1)] + (i - k - 1) + 1 + (j - l - 1);
        if trans < min_val { min_val = trans; }
      }
      d[i * (n + 1) + j] = min_val;
      if cost == 0 {
        last = j;
      }
      da[b.char_at(j - 1) as Int] = i;
      j = j + 1;
    }
    i = i + 1;
  }
  d[m * (n + 1) + n]
}

/// Optimal string alignment (restricted transposition) distance.
/// O(m*n) time, O(m*n) space. Only allows adjacent transpositions that are
/// not themselves part of further transpositions.
pub fn osa_distance(a: Str, b: Str) -> Int {
  var m = a.len();
  var n = b.len();
  if m == 0 { return n; }
  if n == 0 { return m; }
  var d = Vec[Int].new();
  var idx = 0;
  while idx < (m + 1) * (n + 1) {
    d.push(0);
    idx = idx + 1;
  }
  var i = 1;
  while i <= m {
    d[i * (n + 1)] = i;
    i = i + 1;
  }
  var j = 1;
  while j <= n {
    d[j] = j;
    j = j + 1;
  }
  i = 1;
  while i <= m {
    j = 1;
    while j <= n {
      var cost = 1;
      if a.char_at(i - 1) == b.char_at(j - 1) {
        cost = 0;
      }
      var del = d[(i - 1) * (n + 1) + j] + 1;
      var ins = d[i * (n + 1) + j - 1] + 1;
      var sub = d[(i - 1) * (n + 1) + j - 1] + cost;
      var min_val = del;
      if ins < min_val { min_val = ins; }
      if sub < min_val { min_val = sub; }
      if i > 1 && j > 1 && a.char_at(i - 1) == b.char_at(j - 2) && a.char_at(i - 2) == b.char_at(j - 1) {
        var trans = d[(i - 2) * (n + 1) + (j - 2)] + 1;
        if trans < min_val { min_val = trans; }
      }
      d[i * (n + 1) + j] = min_val;
      j = j + 1;
    }
    i = i + 1;
  }
  d[m * (n + 1) + n]
}

/// Classic Wagner-Fischer edit distance (full-matrix variant of the standard
/// Levenshtein distance). O(m*n) time, O(m*n) space.
pub fn wagner_fischer(a: Str, b: Str) -> Int {
  var m = a.len();
  var n = b.len();
  if m == 0 { return n; }
  if n == 0 { return m; }
  var d = Vec[Int].new();
  var idx = 0;
  while idx < (m + 1) * (n + 1) {
    d.push(0);
    idx = idx + 1;
  }
  var i = 1;
  while i <= m {
    d[i * (n + 1)] = i;
    i = i + 1;
  }
  var j = 1;
  while j <= n {
    d[j] = j;
    j = j + 1;
  }
  i = 1;
  while i <= m {
    j = 1;
    while j <= n {
      var cost = 1;
      if a.char_at(i - 1) == b.char_at(j - 1) {
        cost = 0;
      }
      var del = d[(i - 1) * (n + 1) + j] + 1;
      var ins = d[i * (n + 1) + j - 1] + 1;
      var sub = d[(i - 1) * (n + 1) + j - 1] + cost;
      var min_val = del;
      if ins < min_val { min_val = ins; }
      if sub < min_val { min_val = sub; }
      d[i * (n + 1) + j] = min_val;
      j = j + 1;
    }
    i = i + 1;
  }
  d[m * (n + 1) + n]
}
