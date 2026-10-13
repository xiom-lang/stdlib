// p_wave118_shapes.xi -- wave 118 lock: P4 advisory file locking
// (sync_io.file_lock / file_unlock / file_try_lock real).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the landed semantics: on a fresh open append handle the lock is
// acquirable (try true), unlock returns Ok, the blocking lock on a free
// range returns Ok and the range is acquirable again afterwards.
// Re-locking a range while it is already held by the same handle is NOT
// exercised (Windows LockFileEx can block on a self-held range); the
// contention semantics are OS advisory behavior and are documented, not
// asserted here. Every returned value is bound before comparing. Returns
// 0 when all cases hold. Red pre-fix (the stubs return Err/false),
// green post.

module p_wave118_shapes

use xiom.io;
use xiom.os.sync_io;

fn main() -> Int {
  let f = "p_wave118_lock.tmp";
  var empty = Vec[UInt8].new();
  let pre = io.write_file_bytes(f, &empty);
  match pre {
    Ok(_) => {},
    Err(_) => { return 1; },
  };
  let h = sync_io.open_append(f);
  match h {
    Ok(fd) => {
      let t1 = sync_io.file_try_lock(fd); // fresh: acquirable
      if !t1 { return 2; }
      let u0 = sync_io.file_unlock(fd); // release before any blocking call
      match u0 {
        Ok(_) => {},
        Err(_) => { return 3; },
      };
      let l1 = sync_io.file_lock(fd); // blocking lock on a free range
      match l1 {
        Ok(_) => {},
        Err(_) => { return 3; },
      };
      let u1 = sync_io.file_unlock(fd);
      match u1 {
        Ok(_) => {},
        Err(_) => { return 5; },
      };
      let t3 = sync_io.file_try_lock(fd); // acquirable after unlock
      if !t3 { return 6; }
      let u2 = sync_io.file_unlock(fd);
      let _ = u2;
      let c = sync_io.close_fd(fd);
      match c {
        Ok(_) => {},
        Err(_) => { return 7; },
      };
    },
    Err(_) => { return 1; },
  };
  let rm = io.remove_file(f);
  let _ = rm;
  return 0;
}
