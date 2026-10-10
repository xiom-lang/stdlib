// p_path_println_context_crash.xi -- Path.exists + trailing printlns
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Expected: rc 0 with "exists-ok" on stdout -- Path.new("") + exists()
// is false and the println after it works.
// Observed on compiler v0.64.2 (official archive, Windows x64): the run
// dies with exit -1073741795 (0xC000001D, stack/illegal-instruction trap)
// before printing anything. The crash is context-dependent on the
// statement sequence, not on the calls themselves:
//   - this file (io import + two trailing printlns) DIES;
//   - the same body without any println (scratch_path4 shape) is rc 0;
//   - the same body with a println BEFORE the check plus the trailing
//     ones (scratch_path2 shape) is rc 0;
//   - exist-only without the io import (scratch_path3 shape) is rc 0.
// Found while building the wave-103 os probe (the full probe's path
// section crashes the same way). Same context-dependent codegen family
// as the tostring-import corruption; workaround: do not call
// Path.exists/is_dir in a compile unit whose only prints come after the
// calls -- hoist a print before the calls or bind the predicate result
// first (both pass today).

module p_path_println_context_crash

use xiom.path as path;
use xiom.io as io;

fn main() -> Int {
  let pe = path.Path.new("");
  let pex = pe.exists();
  if pex != false { return 1; }
  io.println("exists-ok");
  let pid = pe.is_dir();
  if pid != false { return 2; }
  io.println("is_dir-ok");
  return 0;
}
