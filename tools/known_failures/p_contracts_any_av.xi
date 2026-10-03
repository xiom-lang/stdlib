// p_contracts_any_av.xi -- any_contracts() crashes on the m178 dev build
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Open finding 2026-10-03 (compiler main 659f6ec1 / m178 dev build only;
// GREEN on the v0.61.3 gate pin): xiom.contracts.any_contracts() crashes
// with 0xC0000005 (access violation) at run time.
// Verified: v0.61.3 compile=0 run=0; m178 build compile=0 run=0xC0000005.
// Found while bisecting tools/probes/p_never_called_zeroarg.xi (call 3 of
// 71) during the pre-v0.62.3 tag check.
// Minimal compile-and-run repro; rc is the process exit code.

module p_contracts_any_av

use xiom.contracts;

fn main() -> Int {
  xiom.contracts.any_contracts();
  return 0;
}
