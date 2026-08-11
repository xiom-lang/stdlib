// XIOM - Conversion: TryFrom
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.convert.tryfrom

// Depends on: none

// ============================================================================
// Trait-style TryFrom helpers that fail instead of losing information. NOTE:
// current implementation lives in convert (trait-style) - move the functions
// here during the implementation phase. TODO(compiler): implement.
// ============================================================================

// fn try_from_int(n: Int) -> Result[Float64, Str] - widen an integer to a float if lossless. TODO(compiler): implement.
// fn try_from_float(f: Float64) -> Result[Int, Str] - truncate a float only if it fits. TODO(compiler): implement.
// fn try_from_str(s: Str) -> Result[Int, Str] - parse a string to an integer if valid. TODO(compiler): implement.
