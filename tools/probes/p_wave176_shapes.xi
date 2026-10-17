// p_wave176_shapes.xi -- wave 176 lock: the Linux epoll-backed event loop
// (eventloop_new/add/wait/modify/remove/close) and its explicit Err surface
// on non-Linux platforms (Windows/macOS stay stubs until their backend
// waves; docs/EVENT_LOOP_PLAN.md).
// Linux rows: empty wait, read readiness on a pipe, writable registration,
// remove then empty wait, close + idempotent second close, closed-loop Err.
// Non-Linux: eventloop_new is Err (no backend yet).
// Returns 0 when all rows hold; a nonzero return names the first failing row.
//
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_wave176_shapes

use xiom.net.socket;
use xiom.io.pipe;
use xiom.os.platform as plat;

fn main() -> Int {
  let created = socket.eventloop_new();
  if !plat.platform_is_linux() {
    // --- row 1: non-Linux is the documented Err until the backend wave ---
    if !created.is_err { return 1; }
    return 0;
  };

  // --- row 2: create ---
  var loop: socket.EventLoop;
  match created {
    Ok(l) => { loop = l; },
    Err(_) => { return 2; },
  };

  let (rfd, wfd) = pipe.pipe_create();
  if rfd < 0 || wfd < 0 { return 3; }

  // --- row 4: register the read end, empty immediate wait ---
  let add = socket.eventloop_add(&loop, rfd, true, false);
  if !add.is_ok { return 4; }
  var batch0 = socket.eventbatch_new();
  let wait0 = socket.eventloop_wait(&loop, 0, &mut batch0);
  match wait0 {
    Ok(n) => { if n != 0 { return 4; } },
    Err(_) => { return 4; },
  };

  // --- row 5: write one byte -> read readiness ---
  var byte = Vec[UInt8].new();
  byte.push(65);
  let wr = pipe.pipe_write(wfd, &byte);
  if !wr.is_ok { return 5; }
  var batch1 = socket.eventbatch_new();
  let wait1 = socket.eventloop_wait(&loop, 1000, &mut batch1);
  match wait1 {
    Ok(n) => { if n != 1 { return 5; } },
    Err(_) => { return 5; },
  };
  if batch1.fds.len() != 1 || batch1.flags.len() != 1 { return 5; }
  if batch1.fds[0] != rfd { return 5; }
  if (batch1.flags[0] & 1) == 0 { return 5; }

  // --- row 6: drain the pipe ---
  var sink = Vec[UInt8].new();
  let rd = pipe.pipe_read(rfd, &mut sink);
  if !rd.is_ok { return 6; }

  // --- row 7: register the write end -> writable readiness ---
  let addw = socket.eventloop_add(&loop, wfd, false, true);
  if !addw.is_ok { return 7; }
  var batch2 = socket.eventbatch_new();
  let wait2 = socket.eventloop_wait(&loop, 1000, &mut batch2);
  match wait2 {
    Ok(n) => { if n != 1 { return 7; } },
    Err(_) => { return 7; },
  };
  if batch2.fds[0] != wfd { return 7; }
  if (batch2.flags[0] & 2) == 0 { return 7; }

  // --- row 8: modify the read end's interest (still registered, no data) ---
  let mod = socket.eventloop_modify(&loop, rfd, true, true);
  if !mod.is_ok { return 8; }

  // --- row 9: remove both fds, then an immediate wait is empty ---
  let rem_r = socket.eventloop_remove(&loop, rfd);
  if !rem_r.is_ok { return 9; }
  let rem_w = socket.eventloop_remove(&loop, wfd);
  if !rem_w.is_ok { return 9; }
  var batch3 = socket.eventbatch_new();
  let wait3 = socket.eventloop_wait(&loop, 50, &mut batch3);
  match wait3 {
    Ok(n) => { if n != 0 { return 9; } },
    Err(_) => { return 9; },
  };

  // --- row 10: close is true once, false the second time ---
  let closed0 = socket.eventloop_close(&mut loop);
  if !closed0 { return 10; }
  let closed1 = socket.eventloop_close(&mut loop);
  if closed1 { return 10; }

  // --- row 11: closed-loop operations are Err ---
  var batch4 = socket.eventbatch_new();
  let wait4 = socket.eventloop_wait(&loop, 0, &mut batch4);
  if !wait4.is_err { return 11; }
  let add_closed = socket.eventloop_add(&loop, rfd, true, false);
  if !add_closed.is_err { return 11; }

  // --- row 12: timeout below -1 is Err ---
  let bad_timeout = socket.eventloop_wait(&loop, 0 - 2, &mut batch4);
  if !bad_timeout.is_err { return 12; }

  pipe.pipe_close(rfd);
  pipe.pipe_close(wfd);
  return 0;
}
