// XIOM - Conversion: AsRef
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.convert.asref

// Depends on: none

// ============================================================================
// Trait-style AsRef/AsMut byte-view helpers over generic values. as_ptr is a
// straightforward address query; the byte-view helpers reinterpret a value's
// memory as a Vec[UInt8] layout -- a raw, layout-dependent view intended for
// diagnostics/tooling, NOT for production marshalling. A safe implementation
// requires compiler support (TODO(compiler)).
// ============================================================================

/// View a value as raw bytes (unsafe reinterpretation of the value's memory
/// as a Vec[UInt8]).
/// Parameters: v -- the value to view.
/// Returns: a reference to the value's bytes.
/// Complexity: O(1).
/// NOTE: unsound for values that are not plain data; provided for
/// diagnostics only.
pub fn as_ref_bytes[T](v: &T) -> &Vec[UInt8]
  requires: true
{
  unsafe {
    return &*(v as *Vec[UInt8]);
  }
}

/// View a value as mutable raw bytes (unsafe reinterpretation of the value's
/// memory as a Vec[UInt8]).
/// Parameters: v -- the value to view.
/// Returns: a mutable reference to the value's bytes.
/// Complexity: O(1).
/// NOTE: unsound for values that are not plain data; provided for
/// diagnostics only.
pub fn as_mut_bytes[T](v: &mut T) -> &mut Vec[UInt8]
  requires: true
{
  unsafe {
    return &mut *(v as *Vec[UInt8]);
  }
}

/// Return a pointer to a value.
/// Parameters: v -- the value.
/// Returns: the address of the value as an Int (never 0 for a valid
///          reference).
/// Complexity: O(1).
pub fn as_ptr[T](v: &T) -> Int
  requires: true
{
  unsafe {
    return (v as *UInt8) as Int;
  }
}
