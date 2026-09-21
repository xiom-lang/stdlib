// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_time_sleep
use xiom.time;

fn main() -> Int {
  var d = time.Duration.from_millis(1);
  time.sleep(d);

  var before = time.Instant.now();
  time.sleep_ms(1);
  var after = time.Instant.now();
  var elapsed = after.duration_since(before);
  if elapsed.as_millis() >= 0 { return 0; }
  return 1;
}
