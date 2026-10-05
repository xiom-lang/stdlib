// XIOM - Debug: Heap Reporting
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.debug.heap_report

// Depends on: xiom.string

use xiom.string;
use xiom.convert;

// ============================================================================
// Heap usage statistics, allocation/free counters, peak tracking, snapshot
// and text/JSON reporting.
//
// NOTE: the runtime allocator does not yet expose allocation callbacks, so
// the live counters never advance on their own. The counters can only change
// via `heap_reset_stats`; snapshots are empty. The API is fully implemented
// and all reports render the (zero) counters honestly.
// ============================================================================

/// A heap snapshot entry: allocation address, size and call site.
pub type HeapEntry = {
  address: Int;
  size: Int;
  call_site: Str;
} derive[Clone]

/// Current heap bytes in use.
var usage_bytes: Int = 0;

/// Total allocation count since start or reset.
var alloc_count: Int = 0;

/// Total free count since start or reset.
var free_count: Int = 0;

/// Highest heap bytes observed.
var peak_bytes: Int = 0;

/// Current heap bytes in use. See the header note: counters are inert in this
/// build.
/// Complexity: O(1).
pub fn heap_usage() -> Int
  ensures: result == usage_bytes
{
  usage_bytes
}

/// Total allocation count since start or reset.
/// Complexity: O(1).
pub fn heap_allocations() -> Int
  ensures: result == alloc_count
{
  alloc_count
}

/// Total free count since start or reset.
/// Complexity: O(1).
pub fn heap_frees() -> Int
  ensures: result == free_count
{
  free_count
}

/// Allocations minus frees.
/// Complexity: O(1).
pub fn heap_live_objects() -> Int
  ensures: result == alloc_count - free_count
{
  alloc_count - free_count
}

/// A human-readable heap summary.
/// Complexity: O(1).
pub fn heap_report() -> Str
  ensures: result.len() >= 12
{
  "heap usage: " + convert.int_to_string(usage_bytes) + " bytes, allocations: " + convert.int_to_string(alloc_count) + ", frees: " + convert.int_to_string(free_count) + ", live: " + convert.int_to_string(heap_live_objects()) + ", peak: " + convert.int_to_string(peak_bytes)
}

/// The heap summary as JSON.
/// Complexity: O(1).
pub fn heap_report_json() -> Str
  ensures: result.len() >= 2
{
  "{\"usage_bytes\":" + convert.int_to_string(usage_bytes) + ",\"allocations\":" + convert.int_to_string(alloc_count) + ",\"frees\":" + convert.int_to_string(free_count) + ",\"live\":" + convert.int_to_string(heap_live_objects()) + ",\"peak_bytes\":" + convert.int_to_string(peak_bytes) + "}"
}

/// The highest heap bytes observed.
/// Complexity: O(1).
pub fn heap_peak_usage() -> Int
  ensures: result == peak_bytes
{
  peak_bytes
}

/// Zero all counters, keeping the current usage. Callers can then observe
/// deltas. In this build the counters are already inert.
/// Complexity: O(1).
pub fn heap_reset_stats()
  ensures: alloc_count == 0 && free_count == 0 && peak_bytes == usage_bytes
{
  alloc_count = 0;
  free_count = 0;
  peak_bytes = usage_bytes;
}

/// Capture all live allocations as entries. No live-allocation registry is
/// available in this build, so the snapshot is empty.
/// Complexity: O(1).
pub fn heap_snapshot() -> Vec[HeapEntry]
  ensures: result.len() == 0
{
  Vec[HeapEntry].new()
}

/// The `n` largest live allocations. Empty in this build (no live
/// allocations are tracked).
/// Complexity: O(1).
pub fn heap_top_allocations(n: Int) -> Vec[HeapEntry]
  ensures: result.len() == 0
{
  Vec[HeapEntry].new()
}

/// True when no live allocations remain.
/// Complexity: O(1).
pub fn heap_is_empty() -> Bool
  ensures: (alloc_count == free_count) => (result == true)
  ensures: (alloc_count != free_count) => (result == false)
{
  heap_live_objects() == 0
}
