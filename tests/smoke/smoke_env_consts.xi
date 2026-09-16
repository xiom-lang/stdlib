// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_env_consts
use xiom.env;

fn main() -> Int {
  if env.OS == "" { return 1; }
  if env.ARCH == "" { return 2; }
  if env.FAMILY == "" { return 3; }

  var t = env.temp_dir();
  if t == "" { return 4; }

  return 0;
}
