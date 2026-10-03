// p_sync_arc_count.xi -- Arc.strong_count() != 1 on the m178 dev build
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Open finding 2026-10-03 (compiler main 659f6ec1 / m178 dev build only;
// GREEN on the v0.61.3 gate pin): xiom.sync.Arc.new(42) reports
// strong_count() != 1 (rc=1) immediately after construction.
// Verified: v0.61.3 compile=0 run=0; m178 build compile=0 run=1.
//
// COMPILER-SIDE, per the compiler lane (2026-10-03): the m166 direct
// (inlined) unsafe path allocates 8 bytes for a 16-byte ArcInner
// (malloc(8) then a 16-byte struct store); the confined path allocates
// correctly. Annotated generic sync functions (Mutex/RwLock/Arc/Barrier)
// can show related failures until their fix lands. DO NOT strip the
// #[unsafe_direct] annotations on xiom/sync/sync.xi -- Gate P depends on
// them; expect sync-probe noise until the compiler fix ships.

module p_sync_arc_count

use xiom.sync;

fn main() -> Int {
  var a = sync.Arc.new(42);
  if a.strong_count() != 1 { return 1; }
  if a.get() != 42 { return 2; }
  return 0;
}
