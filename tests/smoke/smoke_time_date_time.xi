// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_time_date_time
use xiom.time;

fn main() -> Int {
  var dt = time.DateTime.now();
  if dt.year() >= 2024 { return 0; }
  return 1;
}
