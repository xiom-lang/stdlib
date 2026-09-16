// p_duration_since.xi -- exercises SystemTime.duration_since across all
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
// branches (Ok, Err, equal, nano-borrow edge) to validate the new active
// contract shape: result.is_ok == (secs > || (secs == && nanos >=)).
module p_duration_since
use xiom.time;
use xiom.io;

fn main() -> Int {
  let t10_500 = SystemTime{ secs: 10; nanos: 500; };
  let t10_200 = SystemTime{ secs: 10; nanos: 200; };
  let t9_900 = SystemTime{ secs: 9; nanos: 900; };
  let t10_eq = SystemTime{ secs: 10; nanos: 500; };

  // Ok: later secs
  match t10_500.duration_since(t9_900) {
    Ok(d) => { if d.secs != 0 || d.nanos != 999999600 { io.println("A diff secs=" + d.secs + " nanos=" + d.nanos); return 1; } },
    Err(e) => { io.println("A err " + e); return 2; },
  }

  // Ok: equal secs, self.nanos >= earlier.nanos
  match t10_500.duration_since(t10_200) {
    Ok(d) => { if d.secs != 0 || d.nanos != 300 { io.println("B diff"); return 3; } },
    Err(e) => { io.println("B err " + e); return 4; },
  }

  // Ok: identical
  match t10_500.duration_since(t10_eq) {
    Ok(d) => { if d.secs != 0 || d.nanos != 0 { io.println("C diff"); return 5; } },
    Err(e) => { io.println("C err " + e); return 6; },
  }

  // Err: equal secs, nano borrow makes sec_diff -1 (contract edge)
  match t10_200.duration_since(t10_500) {
    Ok(_) => { io.println("D expected Err"); return 7; },
    Err(_) => { },
  }

  // Err: earlier secs
  match t9_900.duration_since(t10_500) {
    Ok(_) => { io.println("E expected Err"); return 8; },
    Err(_) => { },
  }

  io.println("DURATION_SINCE OK");
  return 0;
}
