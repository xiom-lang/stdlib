// XIOM stdlib smoke test -- xiom.error
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_error
use xiom.error;

fn main() -> Int {
  var errs = Vec[Str].new();
  errs.push("smoke failure");
  var chain = ErrorChain{ errors: errs };
  if chain.display().len() > 0 {
    return 0;
  }
  return 1;
}
