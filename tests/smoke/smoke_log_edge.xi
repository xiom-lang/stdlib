// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_log_edge
use xiom.log;

fn main() -> Int {
  log.set_level(log.LogLevel.Fatal);
  log.trace("no");
  log.debug("no");
  log.info("no");
  log.warn("no");
  log.error("no");
  log.fatal("yes");

  log.clear_log();
  log.clear_log();

  return 0;
}
