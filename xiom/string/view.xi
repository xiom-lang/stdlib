// XIOM - String: Borrowed Str Views
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.view

// Depends on: xiom.string (materializing slices only)

// ============================================================================
// Non-owning Str views (2026-10-02 intake row 19: context / parsing /
// diagrams -- split out of str_slice-per-lookup allocation churn; also the
// row-44 span half). A StrView is an offset+len window over a source Str with
// a cached raw base pointer: every scan reads bytes in place, allocates
// nothing, and copies only on explicit view_to_str. Windows ALIAS the source
// buffer -- the source must outlive the view (no lifetime checking yet, the
// same host obligation as the byte-range accessors in xiom.string.lines).
// Validation: view_range clamps like str_slice; view_range_checked is the
// strict variant returning None on any out-of-bounds input.
// ============================================================================

use xiom.string;

// Raw byte at `i` over the view's cached base (T007 confinement; callers
// bound i against the view's len).
fn _view_raw(base: *UInt8, i: Int) -> UInt8
  requires: true
{
  unsafe { return *(base + i); }
}

/// struct StrView { src: Str; base: *UInt8; start: Int; len: Int }
/// `src` keeps the source alive by convention; `base` is the cached
/// `src.c_str()` pointer so per-byte scans stay O(1).
pub type StrView = { src: Str; base: *UInt8; start: Int; len: Int; }

/// View over all of `s`. Complexity: O(1) plus the c_str() bind.
pub fn view_of(s: Str) -> StrView
  requires: true  // c_str() read confined to the view fields (T007)
  ensures: result.len == s.len()
  ensures: result.start == 0
{
  unsafe {
    return StrView{ src: s; base: s.c_str(); start: 0; len: s.len() };
  }
}

/// Clamped window [start, start+len): a negative `start`/`len` clamps to 0
/// and the window truncates at the end of `s` -- the same convention as
/// string.str_slice. Complexity: O(1) plus the c_str() bind.
pub fn view_range(s: Str, start: Int, len: Int) -> StrView
  requires: true  // c_str() read confined to the view fields (T007)
  ensures: result.len >= 0
  ensures: result.start >= 0
{
  let slen = s.len();
  var v_start = start;
  var v_len = len;
  if v_start < 0 {
    v_start = 0;
  };
  if v_len < 0 {
    v_len = 0;
  };
  if v_start > slen {
    v_start = slen;
  };
  if v_start + v_len > slen {
    v_len = slen - v_start;
  };
  unsafe {
    return StrView{ src: s; base: s.c_str(); start: v_start; len: v_len };
  }
}

/// Strict window: Some only when 0 <= start <= s.len(), 0 <= len and
/// start + len <= s.len() -- otherwise None. Complexity: O(1).
pub fn view_range_checked(s: Str, start: Int, len: Int) -> Option[StrView]
  requires: true  // c_str() read confined to the view fields (T007)
{
  if start < 0 || len < 0 {
    return None;
  };
  let slen = s.len();
  if start > slen || start + len > slen {
    return None;
  };
  unsafe {
    return Some(StrView{ src: s; base: s.c_str(); start: start; len: len });
  }
}

/// Number of bytes in the view.
pub fn view_len(v: &StrView) -> Int
  ensures: result >= 0
{
  v.len
}

/// True when the view has zero bytes.
pub fn view_is_empty(v: &StrView) -> Bool
  ensures: result == (v.len == 0)
{
  v.len == 0
}

/// Byte at `i` within the view, or 0 when out of bounds (string.byte_at
/// convention). Complexity: O(1).
pub fn view_byte_at(v: &StrView, i: Int) -> UInt8
  requires: true  // raw read confined to view_byte_at (T007)
{
  if i < 0 || i >= v.len {
    return 0u8;
  };
  _view_raw(v.base, v.start + i)
}

/// Sub-window of `v`, clamped into it (same convention as view_range).
/// Complexity: O(1).
pub fn view_slice(v: &StrView, start: Int, len: Int) -> StrView
  ensures: result.len >= 0
{
  var v_start = start;
  var v_len = len;
  if v_start < 0 {
    v_start = 0;
  };
  if v_len < 0 {
    v_len = 0;
  };
  if v_start > v.len {
    v_start = v.len;
  };
  if v_start + v_len > v.len {
    v_len = v.len - v_start;
  };
  StrView{ src: v.src; base: v.base; start: v.start + v_start; len: v_len }
}

/// Materialize the window as a fresh Str (the only copying operation here).
/// Complexity: O(view length).
pub fn view_to_str(v: &StrView) -> Str
  ensures: result.len() == v.len
{
  string.str_slice(v.src, v.start, v.start + v.len)
}

/// Byte-wise equality of two views (length first, then bytes).
/// Complexity: O(min lengths) on unequal, O(len) on equal.
pub fn view_eq(a: &StrView, b: &StrView) -> Bool
  ensures: result => a.len == b.len
{
  if a.len != b.len {
    return false;
  };
  var i = 0;
  while i < a.len {
    if _view_raw(a.base, a.start + i) != _view_raw(b.base, b.start + i) {
      return false;
    };
    i = i + 1;
  };
  true
}

/// True when the view starts with the bytes of `prefix` (an empty prefix
/// always matches). Complexity: O(|prefix|).
pub fn view_starts_with(v: &StrView, prefix: Str) -> Bool
  ensures: result => prefix.len() <= v.len
{
  let plen = prefix.len();
  if plen > v.len {
    return false;
  };
  let pbase = prefix.c_str();
  var i = 0;
  while i < plen {
    if _view_raw(v.base, v.start + i) != _view_raw(pbase, i) {
      return false;
    };
    i = i + 1;
  };
  true
}

/// Byte offset (relative to the view start) of the first occurrence of
/// `needle`, or None. An empty needle matches at 0 (index_of convention).
/// Complexity: O(view length * |needle|).
pub fn view_find(v: &StrView, needle: Str) -> Option[Int]
  ensures: result is Some => result.value >= 0
  ensures: result is Some => result.value + needle.len() <= v.len
{
  let nlen = needle.len();
  if nlen == 0 {
    return Some(0);
  };
  if nlen > v.len {
    return None;
  };
  let nbase = needle.c_str();
  var at = 0;
  while at + nlen <= v.len {
    var matched = true;
    var k = 0;
    while k < nlen {
      if _view_raw(v.base, v.start + at + k) != _view_raw(nbase, k) {
        matched = false;
        break;
      };
      k = k + 1;
    };
    if matched {
      return Some(at);
    };
    at = at + 1;
  };
  None
}
