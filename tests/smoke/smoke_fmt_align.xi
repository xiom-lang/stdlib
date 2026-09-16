// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_fmt_align
use xiom.fmt;

fn main() -> Int {
  var f = fmt.Formatter.new();
  f.write_int(42);
  var s = f.finish();
  if s != "42" { return 1; }

  return 0;
}
