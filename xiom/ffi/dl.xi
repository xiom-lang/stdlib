// XIOM - FFI: Dynamic Loading
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.ffi.dl

// Depends on: xiom.ffi

// ============================================================================
// Dynamic library loading and symbol resolution. NOTE: current implementation
// lives in ffi.xi - move the functions here during the implementation phase.
// TODO(compiler): implement.
// ============================================================================

// fn dl_open(path: Str) -> Result[Int, Str] - load a shared library and return a handle. TODO(compiler): implement.
// fn dl_sym(handle: Int, name: Str) -> Result[Int, Str] - resolve a symbol address in a library. TODO(compiler): implement.
// fn dl_close(handle: Int) -> Result[Unit, Str] - unload a library. TODO(compiler): implement.
// fn dl_error() -> Str - description of the last dynamic-loading error. TODO(compiler): implement.
// fn dl_self() -> Int - handle of the current executable. TODO(compiler): implement.
// fn dl_open_global(path) -> Result[Int, Str] - load a library with global symbol visibility. TODO(compiler): implement.
// fn dl_sym_address(handle, name) -> Result[Int, Str] - resolve a symbol as a data address. TODO(compiler): implement.
// fn dl_has_symbol(handle, name) -> Bool - whether a symbol exists in a library. TODO(compiler): implement.
