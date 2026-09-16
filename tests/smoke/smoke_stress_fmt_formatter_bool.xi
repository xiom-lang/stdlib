// XIOM stdlib stress -- xiom.fmt Formatter.write_bool and finish
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
// Tests Formatter building a string from boolean writes.
// Returns 0 on success, nonzero on failure.

module smoke_stress_fmt_formatter_bool
use xiom.fmt;

fn main() -> Int {
  var f = fmt.Formatter.new();
  f.write_bool(true);
  var out = f.finish();
  if out != "true" { return 1; }

  var f2 = fmt.Formatter.new();
  f2.write_bool(false);
  var out2 = f2.finish();
  if out2 != "false" { return 2; }

  return 0;
}
