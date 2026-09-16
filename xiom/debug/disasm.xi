// XIOM - Debug: Disassembly
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.debug.disasm

// Depends on: xiom.string

// ============================================================================
// Instruction disassembly, instruction-length decoding, symbolization and
// debug-info lookups.
//
// NOTE: no disassembly backend is linked into this build, so the byte-level
// and address-level disassembly entry points return Err and the query
// functions report "unsupported"/None. The API is fully implemented; the
// runtime support is the compiler session's domain.
// ============================================================================

const disasm_unavailable: Str = "disassembly unavailable: no backend linked";

/// Disassemble raw bytes into mnemonic lines. Not supported in this build.
/// Complexity: O(1).
pub fn disasm_bytes(code: &Vec[UInt8], arch: Str) -> Result[Vec[Str], Str] {
  Err(disasm_unavailable)
}

/// Disassemble `length` bytes at an address. Not supported in this build.
/// Complexity: O(1).
pub fn disasm_function(ptr: Int, length: Int) -> Result[Vec[Str], Str] {
  Err(disasm_unavailable)
}

/// The byte length of the instruction at `offset`. Not supported in this
/// build.
/// Complexity: O(1).
pub fn disasm_instruction_length(code: &Vec[UInt8], offset: Int) -> Result[Int, Str] {
  Err(disasm_unavailable)
}

/// Whether an architecture string is supported by a disassembly backend.
/// Always false in this build.
/// Complexity: O(1).
pub fn disasm_arch_supported(arch: Str) -> Bool {
  false
}

/// Select Intel or AT&T syntax for an architecture. Not supported in this
/// build.
/// Complexity: O(1).
pub fn disasm_syntax(arch: Str, intel: Bool) -> Result[Unit, Str] {
  Err(disasm_unavailable)
}

/// Resolve an address to a symbol name. No symbol table is loaded in this
/// build, so this always returns None.
/// Complexity: O(1).
pub fn disasm_symbolize(addr: Int) -> Option[Str] {
  None
}

/// Source debug info (file, line) for an address. No debug info is loaded in
/// this build, so this always returns None.
/// Complexity: O(1).
pub fn disasm_debug_info(addr: Int) -> Option[(Str, Int)] {
  None
}
