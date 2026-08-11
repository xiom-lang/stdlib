// XIOM - FFI: Errno
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.ffi.errno

// Depends on: xiom.ffi

// ============================================================================
// Errno access and C error string helpers. NOTE: current implementation lives
// in ffi.xi - move the functions here during the implementation phase.
// TODO(compiler): implement.
// ============================================================================

// fn errno_get() -> Int - read the current errno value. TODO(compiler): implement.
// fn errno_set(code: Int) - set the errno value. TODO(compiler): implement.
// fn errno_strerror(code: Int) -> Str - human-readable message for an error code. TODO(compiler): implement.
// fn errno_perror(msg: Str) - print msg followed by the current errno message. TODO(compiler): implement.
// fn errno_last() -> Int - last recorded errno (snapshot). TODO(compiler): implement.
// fn errno_is_error(code) -> Bool - whether a code represents an error. TODO(compiler): implement.
// fn errno_name(code) -> Str - symbolic name (for example "ENOENT"). TODO(compiler): implement.
