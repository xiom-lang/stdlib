// Minimal compiler repro for REL-20261028-1641 on candidate ed2f38cff.
//
// A callee chain taking `&mut S` grows S.buf (a Vec field). The outermost
// function then returns S by value through Result. On ed2f38cff the returned
// S.buf data pointer is freed, so any later allocation reuses the buffer:
// without churn the bytes still look valid (p_wave162 row 1-11 pass), with
// churn the tail becomes 0x55. v0.64.8 is rc 0; e48213c66 crashes 0xC0000374;
// ed2f38cff is rc 3 (use-after-free) -- the double-free was converted into a
// stale read, not fixed.
//
// The trigger is the _read_head control flow: a while loop whose early
// `return Ok(...)` runs after a nested _fill(&mut conn) grew the Vec. A
// direct match (no loop) and a two-level main-owned shape both pass, so the
// stale drop is on the loop/early-return path of the borrowed aggregate.
//
// net.sse shape: _connect_core -> _read_head -> _fill. p_wave162_shapes then
// fails row 12 intermittently (sse_read_events returns 0 while the buffered
// event bytes have been zeroed or overwritten).
//
// Expected: run rc 0.
//
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_borrowed_mut_grown_vec_uaf

use xiom.io;

type S = { buf: Vec[UInt8]; }

fn _fill(conn: &mut S) -> Result[Int, Str] {
  var i = 0;
  while i < 18 {
    conn.buf.push(100);
    i = i + 1;
  }
  Ok(18)
}

fn _read_head(conn: &mut S) -> Result[Str, Str] {
  var guard = 0;
  while guard < 4 {
    if conn.buf.len() > 10 {
      return Ok("head");
    }
    match _fill(conn) {
      Ok(_) => {},
      Err(e) => { return Err(e); },
    }
    guard = guard + 1;
  }
  Err("not terminated")
}

fn _connect_core() -> Result[S, Str] {
  var conn = S{ buf: Vec[UInt8].new() };
  var head = "";
  match _read_head(&mut conn) {
    Ok(hd) => { head = hd; },
    Err(e) => { return Err(e); },
  }
  if head.len() == 0 {
    return Err("empty");
  }
  Ok(conn)
}

fn main() -> Int {
  var round = 0;
  while round < 300 {
    let r = _connect_core();
    if r.is_err { return 1; }
    let c = r.value;
    // Reuse the freed block: 0x55 lands in the stale buffer.
    var junk: Vec[UInt8] = Vec[UInt8].new();
    var k = 0;
    while k < 200000 {
      junk.push(85);
      k = k + 1;
    }
    if c.buf.len() != 18 {
      io.println("round " + round.to_str() + " len=" + c.buf.len().to_str());
      return 2;
    }
    if c.buf[17] != 100 {
      io.println("round " + round.to_str() + " byte=" + (c.buf[17] as Int).to_str());
      return 3;
    }
    round = round + 1;
  }
  io.println("borrowed mut grown vec ok");
  return 0;
}
