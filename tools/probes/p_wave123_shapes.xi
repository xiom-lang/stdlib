// p_wave123_shapes.xi -- wave 123 lock: signal delivery (signal_install /
// signal_wait / signal_pending; REL-20261012-1946-pulse ask 1, the last
// stdlib-side wave-2 row).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the poll-style delivery API on both platforms: raise before install
// is Err; install is Ok and idempotent; wait with no signal times out 0;
// raise(SIGTERM)/raise(SIGINT) deliver exactly those numbers (POSIX raise()
// through the self-pipe handler; Windows latches the console-event mapping
// via the same shim); signal_pending is the non-blocking wait(0); negative
// timeouts and uncatchable numbers are Err. Every returned value is bound
// before comparing. Returns 0 when all cases hold. Red pre-fix (the
// install/wait/pending surface does not exist), green post.

module p_wave123_shapes

use xiom.os.signal;
use xiom.io;

fn main() -> Int {
  // --- pure helpers stay consistent ---
  let n15 = signal.signal_name(15);
  if n15 != "TERM" {
    return 1;
  }
  let c15 = signal.signal_code("sigterm");
  match c15 {
    Some(v) => {
      if v != 15 {
        return 1;
      }
    },
    None => {
      return 1;
    },
  };
  let a15 = signal.signal_default_action(15);
  if a15 != "term" {
    return 1;
  }
  if signal.signal_is_catchable(9) {
    return 1;
  }

  // --- raise before install must be Err ---
  let pre = signal.signal_raise(15);
  match pre {
    Ok(_) => {
      return 2;
    },
    Err(_) => {},
  };
  // invalid numbers stay Err
  let z = signal.signal_raise(0);
  match z {
    Ok(_) => {
      return 3;
    },
    Err(_) => {},
  };
  let k = signal.signal_raise(9);
  match k {
    Ok(_) => {
      return 3;
    },
    Err(_) => {},
  };

  // --- install (idempotent) ---
  let i1 = signal.signal_install();
  match i1 {
    Ok(_) => {},
    Err(_) => {
      return 4;
    },
  };
  let i2 = signal.signal_install();
  match i2 {
    Ok(_) => {},
    Err(_) => {
      return 4;
    },
  };

  // --- timeout with no signal ---
  let w0 = signal.signal_wait(50);
  match w0 {
    Ok(v) => {
      if v != 0 {
        return 5;
      }
    },
    Err(_) => {
      return 5;
    },
  };

  // --- SIGTERM roundtrip ---
  let r15 = signal.signal_raise(15);
  match r15 {
    Ok(_) => {},
    Err(_) => {
      return 6;
    },
  };
  let w15 = signal.signal_wait(1000);
  match w15 {
    Ok(v) => {
      if v != 15 {
        return 7;
      }
    },
    Err(_) => {
      return 7;
    },
  };
  let w0b = signal.signal_wait(50);
  match w0b {
    Ok(v) => {
      if v != 0 {
        return 8;
      }
    },
    Err(_) => {
      return 8;
    },
  };

  // --- SIGINT roundtrip ---
  let r2 = signal.signal_raise(2);
  match r2 {
    Ok(_) => {},
    Err(_) => {
      return 9;
    },
  };
  let w2 = signal.signal_wait(1000);
  match w2 {
    Ok(v) => {
      if v != 2 {
        return 10;
      }
    },
    Err(_) => {
      return 10;
    },
  };

  // --- signal_pending is wait(0): clear after reading ---
  let p0 = signal.signal_pending();
  match p0 {
    Ok(v) => {
      if v != 0 {
        return 11;
      }
    },
    Err(_) => {
      return 11;
    },
  };
  let rp = signal.signal_raise(15);
  match rp {
    Ok(_) => {},
    Err(_) => {
      return 12;
    },
  };
  let p1 = signal.signal_pending();
  match p1 {
    Ok(v) => {
      if v != 15 {
        return 12;
      }
    },
    Err(_) => {
      return 12;
    },
  };
  let p2 = signal.signal_pending();
  match p2 {
    Ok(v) => {
      if v != 0 {
        return 13;
      }
    },
    Err(_) => {
      return 13;
    },
  };

  // --- negative timeout is Err ---
  let wn = signal.signal_wait(-1);
  match wn {
    Ok(_) => {
      return 14;
    },
    Err(_) => {},
  };
  return 0;
}
