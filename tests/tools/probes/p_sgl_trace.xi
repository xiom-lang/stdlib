// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_sgl_trace
use xiom.io.console;
use xiom.convert;
fn main() -> Int {
  // glob section
  var g1 = xiom.string.glob.glob_match("*.xi", "main.xi");
  console.console_write_line("glob done: " + convert.bool_to_string(g1));
  console.console_flush();
  // segment section
  var cl = xiom.string.segment.unicode_grapheme_clusters("abc");
  console.console_write_line("seg clusters len=" + convert.int_to_string(cl.len()));
  console.console_flush();
  var offs = xiom.string.segment.unicode_segment_graphemes("abc");
  console.console_write_line("seg offsets len=" + convert.int_to_string(offs.len()));
  console.console_flush();
  // unescape section
  var u1 = xiom.string.unescape.str_unescape("a\\nb");
  console.console_write_line("uesc plain done");
  console.console_flush();
  var u2 = xiom.string.unescape.str_unescape_ascii("\\x41");
  console.console_write_line("uesc ascii done");
  console.console_flush();
  var u3 = xiom.string.unescape.str_unescape_unicode("\\u0041");
  console.console_write_line("uesc unicode done");
  console.console_flush();
  return 0;
}
