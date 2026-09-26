// p_relay_arity_fixes.xi -- locks the compiler-relay item-3 call-site fixes.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Sites fixed (relay 2026-09-26, item 3 list):
// 1. _scrypt_blockmix is declared (b, r); both ROMix calls passed only &x,
//    dropping r. scrypt itself is not executed here (the build's known
//    returned-Vec-into-&Vec miscompile), so the fix is compile-checked.
// 2. Path.components called unqualified `replace`; now qualified as
//    xiom.string.replace -- exercised at runtime below.
// 3. the printf extern is declared with the fixed (format, arg) shape its
//    three call sites use -- exercised via io.print at runtime below.
// Returns 0 when the runtime cases hold.

module p_relay_arity_fixes

use xiom.io;
use xiom.path;

fn main() -> Int {
  io.print("arity-fix-probe\n");
  var p = path.Path.new("a\\b\\c");
  var parts = p.components();
  if parts.len() != 3 { return 1; }
  return 0;
}
