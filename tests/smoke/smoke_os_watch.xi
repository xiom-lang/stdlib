// XIOM stdlib smoke test -- xiom.os.watch
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Pure kind names plus the documented error surface (empty/missing dirs,
// bad handles). The real Windows roundtrip lives in p_wave124_shapes.xi.
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_os_watch

use xiom.os.watch;

fn main() -> Int {
  let n1 = watch.watch_kind_name(1);
  if n1 != "create" { return 1; }
  let n2 = watch.watch_kind_name(2);
  if n2 != "modify" { return 1; }
  let n3 = watch.watch_kind_name(3);
  if n3 != "remove" { return 1; }
  let n4 = watch.watch_kind_name(4);
  if n4 != "rename" { return 1; }
  let n5 = watch.watch_kind_name(5);
  if n5 != "overflow" { return 1; }
  let n0 = watch.watch_kind_name(0);
  if n0 != "unknown" { return 1; }

  let e = watch.watch_dir("", false);
  if e.is_ok { return 2; }
  let m = watch.watch_dir("p_smoke_missing_dir_zz", false);
  if m.is_ok { return 3; }

  let p = watch.watch_poll(0, 0);
  if p.is_ok { return 4; }
  let pn = watch.watch_poll(1, -5);
  if pn.is_ok { return 5; }

  watch.watch_close(0);
  return 0;
}
