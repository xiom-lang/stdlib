// XIOM stdlib stress -- io.BufWriter from stdout
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
// Creates a BufWriter wrapping stdout and verifies construction succeeds.
// Returns 0 on success, nonzero on failure.

module smoke_stress_io_bufwriter
use xiom.io;

fn main() -> Int {
  var wr = io.stdout();
  var bw = io.BufWriter.new(wr);
  var _ = bw.flush();
  return 0;
}
