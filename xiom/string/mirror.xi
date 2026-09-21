// XIOM - String: Mirror
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.mirror

// Depends on: none

// ============================================================================
// Unicode bidi mirroring of characters. NOTE: current implementation lives in
// string.unicode stub - move the functions here during the implementation phase. TODO(compiler): implement.
// ============================================================================

use xiom.convert;

// Mirror code point of `code`, or -1 when the code point is not mirrored.
// Covers the common Bidi_Mirrored pairs: ASCII brackets, braces, parens,
// angle brackets, slash pairs, and the guillemet/single-angle quote pairs.
// Complexity: O(1).
fn _mirror_code(code: Int) -> Int {
  if code == 40 { return 41; };
  if code == 41 { return 40; };
  if code == 91 { return 93; };
  if code == 93 { return 91; };
  if code == 123 { return 125; };
  if code == 125 { return 123; };
  if code == 60 { return 62; };
  if code == 62 { return 60; };
  if code == 47 { return 92; };
  if code == 92 { return 47; };
  if code == 171 { return 187; };
  if code == 187 { return 171; };
  if code == 139 { return 155; };
  if code == 155 { return 139; };
  -1
}

/// Return the mirror image of `c` per the Unicode Bidi_Mirrored property for
/// the covered pairs: parentheses, square brackets, curly braces, angle
/// brackets, slash pairs, guillemets and single-angle quotes. Characters
/// without a mirror mapping are returned unchanged.
/// Params: c the character to mirror.
/// Returns: the mirrored character, or `c` itself.
/// Error case: none.
/// Complexity: O(1).
pub fn unicode_mirror_char(c: Char) -> Char {
  let code = convert.char_to_int(c);
  let m = _mirror_code(code);
  if m < 0 {
    return c;
  };
  let c_opt = convert.int_to_char(m);
  match c_opt {
    Some(mc) => {
      return mc;
    };
    None => {
      return c;
    };
  }
}

/// Return true when `c` has the Unicode Bidi_Mirrored property for the
/// covered pairs listed in `unicode_mirror_char`.
/// Params: c the character to test.
/// Returns: true when `c` has a mirror image, false otherwise.
/// Error case: none.
/// Complexity: O(1).
pub fn unicode_is_mirrored(c: Char) -> Bool {
  let code = convert.char_to_int(c);
  let m = _mirror_code(code);
  m >= 0
}
