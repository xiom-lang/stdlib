// p_wave152_shapes.xi -- wave 152 lock: advisory whole-file locks
// (xiom.os.lock file_lock_try / file_lock / file_lock_release; runtime
// LockFileEx + fcntl F_SETLK/F_SETLKW shims; REL-20261016-1128-orbitdb /
// -1129-xvector, plan item 12).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Shape lock: the lock wrappers require an EXISTING file (documented
// no-create), so the probe seeds two sentinel files first. Rows:
// try-acquire Ok (fd >= 0, path intact); release; re-acquire Ok after
// release; blocking acquire Ok on a free file; try on a SECOND path Ok;
// missing file (both variants) and empty path are Err (the open fails --
// no hang). The same-process second-open shape is the deterministic
// contention stand-in: Windows LockFileEx is per-handle and MUST return
// Err(LOCK_HELD_MSG) here, POSIX fcntl is per-process and MUST return Ok
// (documented in xiom/os/lock.xi; not a defect). Double release is a
// compile error (FileLock is not Clone; release consumes the value), so
// it is documented, not a runtime row. Cross-PROCESS contention needs a
// second process (not available in the probe harness) and stays
// documented, untested here. Every returned value is bound before
// comparing. Returns 0 when all cases hold. Red pre-fix (the module does
// not exist), green post.

module p_wave152_shapes

use xiom.io;
use xiom.env;
use xiom.os.lock;

fn main() -> Int {
  let a = "p_wave152_a.lock";
  let b = "p_wave152_b.lock";

  // Sentinels: locks attach to an existing file (no create).
  let wa = io.write_file(a, "");
  match wa {
    Ok(_) => {},
    Err(_) => { return 1; },
  };
  let wb = io.write_file(b, "");
  match wb {
    Ok(_) => {},
    Err(_) => { return 1; },
  };

  // 1) try-acquire on a free file: Ok, fields intact; 2) release.
  let t1 = lock.file_lock_try(a);
  match t1 {
    Ok(l1) => {
      if l1.fd < 0 { return 2; }
      if l1.path != a { return 2; }
      lock.file_lock_release(l1);
    },
    Err(_) => { return 2; },
  };

  // 3) re-acquire after release: Ok (the release really released).
  let t2 = lock.file_lock_try(a);
  match t2 {
    Ok(l2) => { lock.file_lock_release(l2); },
    Err(_) => { return 3; },
  };

  // 4) blocking acquire on the free file: Ok; release.
  let t3 = lock.file_lock(a);
  match t3 {
    Ok(l3) => { lock.file_lock_release(l3); },
    Err(_) => { return 4; },
  };

  // 5) try on a SECOND path: Ok; release.
  let t4 = lock.file_lock_try(b);
  match t4 {
    Ok(l4) => { lock.file_lock_release(l4); },
    Err(_) => { return 5; },
  };

  // 6) invalid inputs: missing file (both variants) and empty path Err.
  let m1 = lock.file_lock_try("p_wave152_missing.lock");
  match m1 {
    Ok(_) => { return 6; },
    Err(_) => {},
  };
  let m2 = lock.file_lock("p_wave152_missing.lock");
  match m2 {
    Ok(_) => { return 7; },
    Err(_) => {},
  };
  let m3 = lock.file_lock_try("");
  match m3 {
    Ok(_) => { return 8; },
    Err(_) => {},
  };
  let m4 = lock.file_lock("");
  match m4 {
    Ok(_) => { return 8; },
    Err(_) => {},
  };

  // 7) same-process second-open contention shape (documented divergence).
  let held = lock.file_lock(a);
  match held {
    Ok(lh) => {
      let second = lock.file_lock_try(a);
      match second {
        Ok(ls) => {
          // POSIX converts the process lock silently; Windows must contend.
          lock.file_lock_release(ls);
          if env.FAMILY == "windows" { return 9; }
        },
        Err(m) => {
          if env.FAMILY == "windows" {
            if m != lock.LOCK_HELD_MSG { return 10; }
          } else {
            return 11; // POSIX same-process try must not contend
          }
        },
      };
      lock.file_lock_release(lh);
    },
    Err(_) => { return 12; },
  };

  // 8) cleanup.
  let _ = io.remove_file(a);
  let _ = io.remove_file(b);
  return 0;
}
