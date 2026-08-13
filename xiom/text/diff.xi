// XIOM - Text: Diff
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.text.diff

// Depends on: xiom.string

use xiom.string;
use xiom.convert;

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
  fn free(ptr: *UInt8);
}

// ============================================================================
// Line, word and byte-level diffing with Myers/LCS, unified and patch
// rendering plus similarity metrics.
//
// `diff_myers` and `diff_lcs` both compute the longest-common-subsequence
// diff (optimal edit script); the two entry points exist for API parity with
// classic tools. A DiffOp's `kind` is the string "eq" (kept), "ins" (added)
// or "del" (removed) — encoded as a string because cross-module reads of a
// leading Int field in a struct are unreliable in this build. Text is
// compared byte-wise (ASCII/UTF-8 bytes).
// ============================================================================

/// A diff operation. `data` encodes the operation as `"<op>:<text>"` where
/// `<op>` is `=` (equal/kept), `+` (insert/added) or `-` (delete/removed).
/// A single string field is used because multi-field structs returned inside
/// vectors mislay their fields when crossing module boundaries in this build;
/// use `diffop_kind`/`diffop_text` to decode.
pub type DiffOp = {
  data: Str;
} derive[Clone]

/// Read the operation kind of a DiffOp ("eq", "ins" or "del").
/// Complexity: O(1).
pub fn diffop_kind(op: DiffOp) -> Str {
  let data = op.data;
  if data.len() > 0 {
    let c = string.byte_at(data, 0);
    if c == 61 {
      return "eq";
    };
    if c == 43 {
      return "ins";
    };
    if c == 45 {
      return "del";
    };
  };
  "eq"
}

/// Read the operation text of a DiffOp.
/// Complexity: O(len(data)).
pub fn diffop_text(op: DiffOp) -> Str {
  let data = op.data;
  if data.len() > 2 {
    return string.str_slice(data, 2, data.len());
  };
  data
}

/// Read the operation kind of element `i` of a diff result. This reads the
/// Vec's backing memory directly, so it is reliable for cross-module results
/// (passing a DiffOp by value can mislay its layout in this build).
/// Complexity: O(1).
pub fn diffop_kind_at(ops: &Vec[DiffOp], i: Int) -> Str {
  let data = ops[i].data;
  if data.len() > 0 {
    let c = string.byte_at(data, 0);
    if c == 61 {
      return "eq";
    };
    if c == 43 {
      return "ins";
    };
    if c == 45 {
      return "del";
    };
  };
  "eq"
}

/// Read the operation text of element `i` of a diff result.
/// Complexity: O(len(data)).
pub fn diffop_text_at(ops: &Vec[DiffOp], i: Int) -> Str {
  let data = ops[i].data;
  if data.len() > 2 {
    return string.str_slice(data, 2, data.len());
  };
  data
}

/// True when `a` and `b` hold the same bytes.
fn str_eq(a: Str, b: Str) -> Bool {
  let la = a.len();
  let lb = b.len();
  if la != lb {
    return false;
  };
  var i: Int = 0;
  while i < la {
    if string.byte_at(a, i) != string.byte_at(b, i) {
      return false;
    };
    i = i + 1;
  };
  true
}

/// Render a single ASCII byte (0..255) as a 1-character string.
fn byte_to_str(code: Int) -> Str {
  unsafe {
    var buf = malloc(2);
    buf[0] = code as UInt8;
    buf[1] = 0;
    Str.from_cstring(buf)
  }
}

/// Copy a Vec[Str] into a fresh vector (catalog-returned vectors cannot be
/// re-borrowed into `&Vec` parameters in this build).
fn copy_strs(v: &Vec[Str]) -> Vec[Str] {
  var out = Vec[Str].new();
  var i: Int = 0;
  while i < v.len() {
    let s = v[i];
    out.push(s);
    i = i + 1;
  };
  out
}

/// Reverse a Vec[DiffOp] by building a new vector (in-place element writes
/// on Vec[DiffOp] miscompile in this build).
fn reverse_ops(ops: &Vec[DiffOp]) -> Vec[DiffOp] {
  var out = Vec[DiffOp].new();
  let n = ops.len();
  var i = n;
  while i > 0 {
    i = i - 1;
    let op = ops[i];
    out.push(op);
  };
  out
}

/// Longest-common-subsequence diff of `a` and `b` (optimal edit script).
/// Complexity: O(|a| * |b|) time and space.
fn lcs_ops(a: &Vec[Str], b: &Vec[Str]) -> Vec[DiffOp] {
  let n = a.len();
  let m = b.len();
  let w = m + 1;
  var table = Vec[Int].new();
  var i: Int = 0;
  while i <= n {
    var j: Int = 0;
    while j <= m {
      table.push(0);
      j = j + 1;
    };
    i = i + 1;
  };
  i = 1;
  while i <= n {
    let ai = a[i - 1];
    var j: Int = 1;
    while j <= m {
      let bj = b[j - 1];
      if str_eq(ai, bj) {
        table[i * w + j] = table[(i - 1) * w + (j - 1)] + 1;
      } else {
        let up = table[(i - 1) * w + j];
        let left = table[i * w + (j - 1)];
        if up >= left {
          table[i * w + j] = up;
        } else {
          table[i * w + j] = left;
        };
      };
      j = j + 1;
    };
    i = i + 1;
  };
  var ops = Vec[DiffOp].new();
  var x = n;
  var y = m;
  while x > 0 && y > 0 {
    let ai = a[x - 1];
    let bj = b[y - 1];
    if str_eq(ai, bj) {
      ops.push(DiffOp{ data: string.str_concat("=:", ai); });
      x = x - 1;
      y = y - 1;
    } elif table[(x - 1) * w + y] >= table[x * w + (y - 1)] {
      let d = a[x - 1];
      ops.push(DiffOp{ data: string.str_concat("-:", d); });
      x = x - 1;
    } else {
      let ins = b[y - 1];
      ops.push(DiffOp{ data: string.str_concat("+:", ins); });
      y = y - 1;
    };
  };
  while x > 0 {
    let d = a[x - 1];
    ops.push(DiffOp{ data: string.str_concat("-:", d); });
    x = x - 1;
  };
  while y > 0 {
    let ins = b[y - 1];
    ops.push(DiffOp{ data: string.str_concat("+:", ins); });
    y = y - 1;
  };
  reverse_ops(&ops)
}

/// Compute an optimal line diff with the longest-common-subsequence method
/// (equivalent result to Myers' algorithm for the edit script).
/// Complexity: O(|a| * |b|).
pub fn diff_myers(a: &Vec[Str], b: &Vec[Str]) -> Vec[DiffOp] {
  lcs_ops(a, b)
}

/// Split `a` and `b` into lines and diff them.
/// Complexity: O(|a| * |b|) over the line counts.
pub fn diff_myers_lines(a: Str, b: Str) -> Vec[DiffOp] {
  let la_raw = string.str_split(a, "\n");
  let lb_raw = string.str_split(b, "\n");
  let la = copy_strs(&la_raw);
  let lb = copy_strs(&lb_raw);
  lcs_ops(&la, &lb)
}

/// Compute a diff via the longest common subsequence.
/// Complexity: O(|a| * |b|).
pub fn diff_lcs(a: &Vec[Str], b: &Vec[Str]) -> Vec[DiffOp] {
  lcs_ops(a, b)
}

/// Render a unified diff of the lines of `a` and `b`. `context` is reserved
/// (a single hunk covering the whole change is emitted; context-line trimming
/// is not applied). The header uses `--- a` / `+++ b`.
/// Complexity: O(|a| * |b|) for the diff plus O(ops) rendering.
pub fn diff_unified(a: Str, b: Str, context: Int) -> Str {
  let ops = diff_myers_lines(a, b);
  var out = "--- a\n+++ b\n@@ -0,";
  var before_count: Int = 0;
  var after_count: Int = 0;
  var i: Int = 0;
  while i < ops.len() {
    let k = diffop_kind_at(&ops, i);
    if k == "del" || k == "eq" {
      before_count = before_count + 1;
    };
    if k == "ins" || k == "eq" {
      after_count = after_count + 1;
    };
    i = i + 1;
  };
  out = string.str_concat(out, convert.int_to_string(before_count));
  out = string.str_concat(out, " +0,");
  out = string.str_concat(out, convert.int_to_string(after_count));
  out = string.str_concat(out, " @@\n");
  i = 0;
  while i < ops.len() {
    let k = diffop_kind_at(&ops, i);
    if k == "eq" {
      out = string.str_concat(out, " ");
    } elif k == "ins" {
      out = string.str_concat(out, "+");
    } else {
      out = string.str_concat(out, "-");
    };
    out = string.str_concat(out, diffop_text_at(&ops, i));
    out = string.str_concat(out, "\n");
    i = i + 1;
  };
  out
}

/// Render a compact patch text from `a` to `b`: one line per operation with a
/// `- ` / `+ ` / `  ` prefix. Diffable with `diff_apply`.
/// Complexity: O(|a| * |b|).
pub fn diff_patch(a: Str, b: Str) -> Str {
  let ops = diff_myers_lines(a, b);
  var out = "";
  var i: Int = 0;
  while i < ops.len() {
    let k = diffop_kind_at(&ops, i);
    if k == "eq" {
      out = string.str_concat(out, "  ");
    } elif k == "ins" {
      out = string.str_concat(out, "+ ");
    } else {
      out = string.str_concat(out, "- ");
    };
    out = string.str_concat(out, diffop_text_at(&ops, i));
    out = string.str_concat(out, "\n");
    i = i + 1;
  };
  out
}

/// Apply a patch produced by `diff_patch` to `a`. Returns Err on a malformed
/// patch or a context/deletion mismatch.
/// Complexity: O(|patch lines| * |a lines|).
pub fn diff_apply(a: Str, patch: Str) -> Result[Str, Str] {
  let a_raw = string.str_split(a, "\n");
  let a_lines = copy_strs(&a_raw);
  let p_raw = string.str_split(patch, "\n");
  let p_lines = copy_strs(&p_raw);
  var out = Vec[Str].new();
  var ai: Int = 0;
  var pi: Int = 0;
  while pi < p_lines.len() {
    let line = p_lines[pi];
    if line.len() >= 2 {
      let prefix = string.str_slice(line, 0, 2);
      let content = string.str_slice(line, 2, line.len());
      if prefix == "+ " {
        out.push(content);
      } elif prefix == "- " {
        if ai >= a_lines.len() {
          return Err("diff_apply: deletion beyond input");
        };
        let expect = a_lines[ai];
        if !str_eq(expect, content) {
          return Err("diff_apply: deletion does not match input");
        };
        ai = ai + 1;
      } else {
        if ai >= a_lines.len() {
          return Err("diff_apply: context beyond input");
        };
        let expect = a_lines[ai];
        if !str_eq(expect, content) {
          return Err("diff_apply: context does not match input");
        };
        out.push(content);
        ai = ai + 1;
      };
    };
    pi = pi + 1;
  };
  var result = "";
  var i: Int = 0;
  while i < out.len() {
    if i > 0 {
      result = string.str_concat(result, "\n");
    };
    result = string.str_concat(result, out[i]);
    i = i + 1;
  };
  Ok(result)
}

/// Normalized similarity in [0,1]: length of the longest common byte
/// subsequence divided by the longer input.
/// Complexity: O(|a| * |b|).
pub fn diff_similarity(a: Str, b: Str) -> Float64 {
  let l = byte_lcs_len(a, b);
  let la = a.len();
  let lb = b.len();
  var maxl = la;
  if lb > maxl {
    maxl = lb;
  };
  if maxl == 0 {
    return 1.0;
  };
  convert.int_to_float(l) / convert.int_to_float(maxl)
}

/// 2 * matches / (len_a + len_b) where matches is the longest common byte
/// subsequence length. Returns 1.0 when both inputs are empty.
/// Complexity: O(|a| * |b|).
pub fn diff_ratio(a: Str, b: Str) -> Float64 {
  let l = byte_lcs_len(a, b);
  let la = a.len();
  let lb = b.len();
  let total = la + lb;
  if total == 0 {
    return 1.0;
  };
  (2.0 * convert.int_to_float(l)) / convert.int_to_float(total)
}

/// Length of the longest common byte subsequence of `a` and `b` (two-row DP).
fn byte_lcs_len(a: Str, b: Str) -> Int {
  let la = a.len();
  let lb = b.len();
  var prev = Vec[Int].new();
  var i: Int = 0;
  while i <= lb {
    prev.push(0);
    i = i + 1;
  };
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
    };
    prev = cur;
    j = j + 1;
  };
  prev[lb]
}

/// True when a byte is a word character (alphanumeric or underscore).
fn is_word_byte(b: UInt8) -> Bool {
  (b >= 48 && b <= 57) || (b >= 65 && b <= 90) || (b >= 97 && b <= 122) || b == 95
}

/// Tokenize `s` into words (alphanumeric runs) and single punctuation bytes.
fn tokenize(s: Str) -> Vec[Str] {
  var tokens = Vec[Str].new();
  let len = s.len();
  var i: Int = 0;
  while i < len {
    let b = string.byte_at(s, i);
    if is_word_byte(b) {
      var j = i;
      while j < len && is_word_byte(string.byte_at(s, j)) {
        j = j + 1;
      };
      let tok = string.str_slice(s, i, j);
      tokens.push(tok);
      i = j;
    } else {
      let tok = string.str_slice(s, i, i + 1);
      tokens.push(tok);
      i = i + 1;
    };
  };
  tokens
}

/// Diff `a` and `b` tokenized into words (alphanumeric runs and punctuation
/// characters).
/// Complexity: O(|tokens|^2).
pub fn diff_word_level(a: Str, b: Str) -> Vec[DiffOp] {
  let ta = tokenize(a);
  let tb = tokenize(b);
  lcs_ops(&ta, &tb)
}

/// Diff two byte sequences.
/// Complexity: O(|a| * |b|).
pub fn diff_byte_level(a: &Vec[UInt8], b: &Vec[UInt8]) -> Vec[DiffOp] {
  var ta = Vec[Str].new();
  var i: Int = 0;
  while i < a.len() {
    let byte = a[i];
    ta.push(byte_to_str(byte as Int));
    i = i + 1;
  };
  var tb = Vec[Str].new();
  i = 0;
  while i < b.len() {
    let byte = b[i];
    tb.push(byte_to_str(byte as Int));
    i = i + 1;
  };
  lcs_ops(&ta, &tb)
}
