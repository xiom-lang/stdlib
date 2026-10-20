// XIOM - Collections: group-by-key fold with running aggregate
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.collect.groupfold

// Depends on: none (built-in Vec only)

// ============================================================================
// GroupFold -- group-by-key running aggregate (packages wishlist row 15:
// "group-by-key fold with running aggregate (OHLCV-style buckets, top-N
// depth)" -- requesters: exchanger (candles, depth), stats-ml (bins)).
//
// One pass over (key, value) pairs maintains, per key: count, sum, min, max,
// first (oldest) and last (newest) value. The OHLCV mapping is first = open,
// last = close, min = low, max = high, plus sum/count for volume averages.
//
// Buckets keep first-introduction order; `_gf_find` is a linear scan over the
// live bucket keys, sized for the bounded-bucket workloads named in the
// wishlist (candle windows, top-N depth sides). Values accumulate with the
// language's wrapping Int arithmetic (documented at `group_fold_add`).
// ============================================================================

/// Per-key running aggregate: count/sum/min/max/first/last.
pub type GroupFold = {
  keys: Vec[Int];
  counts: Vec[Int];
  sums: Vec[Int];
  mins: Vec[Int];
  maxs: Vec[Int];
  firsts: Vec[Int];
  lasts: Vec[Int];
}

/// Create an empty fold: no buckets.
pub fn group_fold_new() -> GroupFold
  ensures: result.keys.len() == 0
{
  return GroupFold{ keys: Vec[Int].new(); counts: Vec[Int].new(); sums: Vec[Int].new(); mins: Vec[Int].new(); maxs: Vec[Int].new(); firsts: Vec[Int].new(); lasts: Vec[Int].new(); };
}

// Bucket index of `key`, or -1 when the key has no bucket yet.
fn _gf_find(g: &GroupFold, key: Int) -> Int {
  var i = 0;
  while i < g.keys.len() {
    if g.keys[i] == key { return i; }
    i = i + 1;
  }
  return -1;
}

/// Fold one value into `key`'s bucket, creating the bucket on first use.
/// `count` increments, `sum`/`min`/`max` update, the first value becomes the
/// bucket's `first` and every value becomes `last`. Sums use the language's
/// wrapping Int arithmetic.
pub fn group_fold_add(g: &mut GroupFold, key: Int, value: Int)
  ensures: group_fold_count(g, key) >= 1
{
  var idx = _gf_find(g, key);
  if idx < 0 {
    g.keys.push(key);
    g.counts.push(1);
    g.sums.push(value);
    g.mins.push(value);
    g.maxs.push(value);
    g.firsts.push(value);
    g.lasts.push(value);
    return;
  }
  g.counts[idx] = g.counts[idx] + 1;
  g.sums[idx] = g.sums[idx] + value;
  if value < g.mins[idx] { g.mins[idx] = value; }
  if value > g.maxs[idx] { g.maxs[idx] = value; }
  g.lasts[idx] = value;
}

/// True when `key` has a bucket.
pub fn group_fold_contains(g: &GroupFold, key: Int) -> Bool
  ensures: result == (_gf_find(g, key) >= 0)
{
  return _gf_find(g, key) >= 0;
}

/// Number of buckets (distinct keys).
pub fn group_fold_size(g: &GroupFold) -> Int
  ensures: result >= 0
{
  return g.keys.len();
}

/// Values folded into `key` (0 when the key has no bucket).
pub fn group_fold_count(g: &GroupFold, key: Int) -> Int
  ensures: result >= 0
{
  var idx = _gf_find(g, key);
  if idx < 0 { return 0; }
  return g.counts[idx];
}

/// Sum of `key`'s values (0 when the key has no bucket).
pub fn group_fold_sum(g: &GroupFold, key: Int) -> Int
  ensures: !group_fold_contains(g, key) => result == 0
{
  var idx = _gf_find(g, key);
  if idx < 0 { return 0; }
  return g.sums[idx];
}

/// Smallest value folded into `key` (None when the key has no bucket).
pub fn group_fold_min(g: &GroupFold, key: Int) -> Option[Int]
  ensures: result.is_some == group_fold_contains(g, key)
{
  var idx = _gf_find(g, key);
  if idx < 0 { return None; }
  return Some(g.mins[idx]);
}

/// Largest value folded into `key` (None when the key has no bucket).
pub fn group_fold_max(g: &GroupFold, key: Int) -> Option[Int]
  ensures: result.is_some == group_fold_contains(g, key)
{
  var idx = _gf_find(g, key);
  if idx < 0 { return None; }
  return Some(g.maxs[idx]);
}

/// First (oldest) value folded into `key` (None when the key has no bucket).
pub fn group_fold_first(g: &GroupFold, key: Int) -> Option[Int]
  ensures: result.is_some == group_fold_contains(g, key)
{
  var idx = _gf_find(g, key);
  if idx < 0 { return None; }
  return Some(g.firsts[idx]);
}

/// Last (newest) value folded into `key` (None when the key has no bucket).
pub fn group_fold_last(g: &GroupFold, key: Int) -> Option[Int]
  ensures: result.is_some == group_fold_contains(g, key)
{
  var idx = _gf_find(g, key);
  if idx < 0 { return None; }
  return Some(g.lasts[idx]);
}

/// Mean of `key`'s values (sum / count, integer division; None when the key
/// has no bucket). Documented as truncating integer mean.
pub fn group_fold_avg(g: &GroupFold, key: Int) -> Option[Int]
  ensures: result.is_some == group_fold_contains(g, key)
{
  var idx = _gf_find(g, key);
  if idx < 0 { return None; }
  return Some(g.sums[idx] / g.counts[idx]);
}

/// Bucket keys in first-introduction order.
pub fn group_fold_keys(g: &GroupFold) -> Vec[Int]
  ensures: result.len() == g.keys.len()
{
  var out = Vec[Int].new();
  var i = 0;
  while i < g.keys.len() {
    out.push(g.keys[i]);
    i = i + 1;
  }
  return out;
}

/// Key of bucket `i` in first-introduction order (None when out of range).
pub fn group_fold_bucket_key(g: &GroupFold, i: Int) -> Option[Int]
  ensures: result.is_some == (i >= 0 && i < g.keys.len())
{
  if i < 0 || i >= g.keys.len() { return None; }
  return Some(g.keys[i]);
}
