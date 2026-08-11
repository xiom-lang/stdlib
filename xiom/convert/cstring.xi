// XIOM - Conversion: CString
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.convert.cstring

// Depends on: xiom.ffi

// ============================================================================
// C-string (NUL-terminated) interop helpers. NOTE: current implementation
// lives in ffi.Str - move the functions here during the implementation phase.
// TODO(compiler): implement.
// ============================================================================

// fn from_cstring(ptr: Int) -> Str - copy a NUL-terminated C string into a XIOM string. TODO(compiler): implement.
// fn to_cstring(s: Str) -> Int - allocate a NUL-terminated copy and return its pointer. TODO(compiler): implement.
// fn cstring_len(ptr: Int) -> Int - length of a C string excluding the terminating NUL. TODO(compiler): implement.
// fn cstring_copy(ptr: Int) -> Int - duplicate a C string and return the new pointer. TODO(compiler): implement.
