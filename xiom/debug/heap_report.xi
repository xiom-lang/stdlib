// XIOM - Debug: Heap Reporting
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.debug.heap_report

// Depends on: xiom.string

// ============================================================================
// Heap usage statistics, allocation/free counters, peak tracking, snapshot
// and text/JSON reporting. NOTE: current implementation lives in debug.xi -
// move the functions here during the implementation phase.
// TODO(compiler): implement.
// ============================================================================

// type HeapEntry - a heap snapshot entry: allocation address, size and call site.
// fn heap_usage() -> Int - current heap bytes in use. TODO(compiler): implement.
// fn heap_allocations() -> Int - total allocation count since start or reset. TODO(compiler): implement.
// fn heap_frees() -> Int - total free count since start or reset. TODO(compiler): implement.
// fn heap_live_objects() -> Int - allocations minus frees. TODO(compiler): implement.
// fn heap_report() -> Str - a human-readable heap summary. TODO(compiler): implement.
// fn heap_report_json() -> Str - the heap summary as JSON. TODO(compiler): implement.
// fn heap_peak_usage() -> Int - the highest heap bytes observed. TODO(compiler): implement.
// fn heap_reset_stats() - zero all counters, keeping the current usage. TODO(compiler): implement.
// fn heap_snapshot() -> Vec[HeapEntry] - capture all live allocations as entries. TODO(compiler): implement.
// fn heap_top_allocations(n: Int) -> Vec[HeapEntry] - the n largest live allocations. TODO(compiler): implement.
// fn heap_is_empty() -> Bool - true when no live allocations remain. TODO(compiler): implement.
