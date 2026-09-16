// XIOM - Collections: TinyLFU
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.collect.tinylfu

// Depends on: none (pure)

// ============================================================================
// TinyLFU admission filter for caches. Uses a count-min sketch (CMS) of
// estimated access frequencies to decide whether an incoming key should
// displace an existing one. Includes the underlying CMS primitives as the
// building block; tinylfu_reset halves all counters to avoid saturation.
// ============================================================================

pub type CountMinSketch = {
  width: Int;
  depth: Int;
  counts: Vec[Int];
}

pub type TinyLfu = {
  sketch: CountMinSketch;
  capacity: Int;
}

// Per-row hash: SplitMix64-style mix seeded by the row index so each row uses
// an independent hash family. Folded to a non-negative value.
fn _row_hash(key: Int, row: Int) -> Int {
  var z = key + row * 0x9E3779B97F4A7C15 + 0x100000001B3;
  z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9;
  z = (z ^ (z >> 27)) * 0x94D049BB133111EB;
  z = z ^ (z >> 31);
  if z < 0 { z = -z; }
  return z;
}

/// Create a count-min sketch with `width` counters per row and `depth` rows.
/// Params: width - counters per row (clamped to >= 1); depth - number of
/// independent hash rows (clamped to >= 1).
/// Returns: a zeroed sketch.
/// Complexity: O(width * depth).
pub fn count_min_sketch_new(width: Int, depth: Int) -> CountMinSketch {
  var w = width;
  if w < 1 { w = 1; }
  var d = depth;
  if d < 1 { d = 1; }
  var counts = Vec[Int].new();
  var total = w * d;
  var i: Int = 0;
  while i < total {
    counts.push(0);
    i = i + 1;
  }
  return CountMinSketch{ width: w; depth: d; counts: counts; };
}

/// Increment the count of `key` in every row.
/// Params: sketch - the CMS; key - Int key to record one access for.
/// Complexity: O(depth).
pub fn cms_add(sketch: &mut CountMinSketch, key: Int) {
  var r: Int = 0;
  while r < sketch.depth {
    var h = _row_hash(key, r);
    var idx = r * sketch.width + (h % sketch.width);
    sketch.counts[idx] = sketch.counts[idx] + 1;
    r = r + 1;
  }
}

/// Estimated count of `key` (minimum over rows). Never underestimates.
/// Params: sketch - the CMS; key - Int key.
/// Returns: the minimum row count, which is >= the true count.
/// Complexity: O(depth).
pub fn cms_estimate(sketch: &CountMinSketch, key: Int) -> Int
  ensures: result >= 0
{
  var best: Int = 0;
  var first = true;
  var r: Int = 0;
  while r < sketch.depth {
    var h = _row_hash(key, r);
    var idx = r * sketch.width + (h % sketch.width);
    var c = sketch.counts[idx];
    if first {
      best = c;
      first = false;
    } else {
      if c < best { best = c; }
    }
    r = r + 1;
  }
  return best;
}

/// Zero all counters.
/// Params: sketch - the CMS.
/// Complexity: O(width * depth).
pub fn cms_clear(sketch: &mut CountMinSketch) {
  var i: Int = 0;
  while i < sketch.counts.len() {
    sketch.counts[i] = 0;
    i = i + 1;
  }
}

/// Create a TinyLFU filter sized for `capacity` cache entries.
/// Params: capacity - expected number of cache entries; the CMS is sized
/// with width = max(8, 4 * capacity) and 4 rows.
/// Returns: a TinyLfu admission filter.
/// Complexity: O(capacity).
pub fn tinylfu_new(capacity: Int) -> TinyLfu {
  var cap = capacity;
  if cap < 1 { cap = 1; }
  var w = cap * 4;
  if w < 8 { w = 8; }
  return TinyLfu{ sketch: count_min_sketch_new(w, 4); capacity: cap; };
}

/// Estimated access frequency of `key`.
/// Params: f - the filter; key - Int key.
/// Returns: the CMS estimate for the key (never underestimates).
/// Complexity: O(1) with a constant number of rows.
pub fn tinylfu_estimate(f: &TinyLfu, key: Int) -> Int
  ensures: result >= 0
{
  return cms_estimate(&f.sketch, key);
}

/// Record one access for `key`.
/// Params: f - the filter; key - Int key.
/// Complexity: O(1) with a constant number of rows.
pub fn tinylfu_increment(f: &mut TinyLfu, key: Int) {
  cms_add(&mut f.sketch, key);
}

/// True if `key` should be admitted over the competing entry.
/// Params: f - the filter; key - the incoming key; frequency - the estimated
/// frequency of the entry it would displace (e.g. the eviction candidate).
/// Returns: true when the sketch's estimate for `key` is at least
/// `frequency` (TinyLFU admission rule: keep the hotter key).
/// Complexity: O(1) with a constant number of rows.
pub fn tinylfu_admit(f: &TinyLfu, key: Int, frequency: Int) -> Bool {
  var est = cms_estimate(&f.sketch, key);
  return est >= frequency;
}

/// Halve all frequency estimates to avoid saturation.
/// Params: f - the filter.
/// Complexity: O(width * depth).
pub fn tinylfu_reset(f: &mut TinyLfu) {
  var i: Int = 0;
  while i < f.sketch.counts.len() {
    var c = f.sketch.counts[i];
    f.sketch.counts[i] = c / 2;
    i = i + 1;
  }
}
