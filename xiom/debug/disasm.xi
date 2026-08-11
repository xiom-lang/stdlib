// XIOM - Debug: Disassembly
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.debug.disasm

// Depends on: xiom.string

// ============================================================================
// Instruction disassembly, instruction-length decoding, symbolization and
// debug-info lookups. NOTE: current implementation lives in debug.xi - move
// the functions here during the implementation phase. TODO(compiler): implement.
// ============================================================================

// fn disasm_bytes(code: &Vec[UInt8], arch: Str) -> Result[Vec[Str], Str] - disassemble raw bytes into mnemonic lines. TODO(compiler): implement.
// fn disasm_function(ptr: Int, length: Int) -> Result[Vec[Str], Str] - disassemble length bytes at an address. TODO(compiler): implement.
// fn disasm_instruction_length(code: &Vec[UInt8], offset: Int) -> Result[Int, Str] - the byte length of the instruction at offset. TODO(compiler): implement.
// fn disasm_arch_supported(arch: Str) -> Bool - whether an architecture string is supported. TODO(compiler): implement.
// fn disasm_syntax(arch: Str, intel: Bool) -> Result[Unit, Str] - select Intel or AT&T syntax for an architecture. TODO(compiler): implement.
// fn disasm_symbolize(addr: Int) -> Option[Str] - resolve an address to a symbol name. TODO(compiler): implement.
// fn disasm_debug_info(addr: Int) -> Option[(Str, Int)] - source debug info; the tuple is (file, line). TODO(compiler): implement.
