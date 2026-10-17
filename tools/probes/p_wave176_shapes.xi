// p_wave176_shapes.xi -- waves 176/177 lock: the readiness event loop.
// Linux uses epoll; Windows uses the WSAPoll readiness shim; macOS/BSD are
// the documented Err until the kqueue wave (docs/EVENT_LOOP_PLAN.md).
// Linux rows: empty wait, pipe read readiness, writable registration,
// modify, remove, close idempotence, closed-loop Err, bad timeout.
// Windows rows: listener readiness, accept, read readiness on the accepted
// socket, remove/close, and the closed-loop guard.
// macOS row: eventloop_new is Err.
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

  if plat.platform_is_macos() {
    // --- row 1: macOS is the documented Err until the kqueue wave ---
    if !created.is_err { return 1; }
    return 0;
  };

  if plat.platform_is_windows() {
    // --- Windows: WSAPoll readiness shim ---
    var wloop: socket.EventLoop;
    match created {
      Ok(l) => { wloop = l; },
      Err(_) => { return 2; },
    };
    let wsrv_r = socket.socket_tcp();
    var wsrv: Int = -1;
    match wsrv_r {
      Ok(fd) => { wsrv = fd; },
      Err(_) => { return 3; },
    };
    let wport = 45993;
    let wbind = socket.socket_bind(wsrv, "127.0.0.1", wport);
    if !wbind.is_ok { socket.socket_close(wsrv); return 41; }
    let wlisten = socket.socket_listen(wsrv, 16);
    if !wlisten.is_ok { socket.socket_close(wsrv); return 42; }
    let wadd = socket.eventloop_add(&wloop, wsrv, true, false);
    if !wadd.is_ok { socket.socket_close(wsrv); return 5; }
    var wb0 = socket.eventbatch_new();
    let ww0 = socket.eventloop_wait(&wloop, 0, &mut wb0);
    match ww0 {
      Ok(n) => { if n != 0 { return 5; } },
      Err(_) => { return 5; },
    };
    let wcli_r = socket.socket_tcp();
    var wcli: Int = -1;
    match wcli_r {
      Ok(fd) => { wcli = fd; },
      Err(_) => { return 6; },
    };
    let wconn = socket.socket_connect(wcli, "127.0.0.1", wport);
    if !wconn.is_ok { return 6; }
    var wb1 = socket.eventbatch_new();
    let ww1 = socket.eventloop_wait(&wloop, 1000, &mut wb1);
    match ww1 {
      Ok(n) => { if n != 1 { return 7; } },
      Err(_) => { return 7; },
    };
    if wb1.fds[0] != wsrv { return 7; }
    if (wb1.flags[0] & 1) == 0 { return 7; }
    let wacc_r = socket.socket_accept(wsrv);
    var wacc: Int = -1;
    match wacc_r {
      Ok(fd) => { wacc = fd; },
      Err(_) => { return 8; },
    };
    let wrem = socket.eventloop_remove(&wloop, wsrv);
    if !wrem.is_ok { return 8; }
    let wadd_acc = socket.eventloop_add(&wloop, wacc, true, false);
    if !wadd_acc.is_ok { return 8; }
    var wbyte = Vec[UInt8].new();
    wbyte.push(65);
    let wsent = socket.socket_send(wcli, &wbyte);
    if !wsent.is_ok { return 9; }
    var wb2 = socket.eventbatch_new();
    let ww2 = socket.eventloop_wait(&wloop, 1000, &mut wb2);
    match ww2 {
      Ok(n) => { if n != 1 { return 9; } },
      Err(_) => { return 9; },
    };
    if wb2.fds[0] != wacc { return 9; }
    if (wb2.flags[0] & 1) == 0 { return 9; }
    let wrecv = socket.socket_recv(wacc, 16);
    match wrecv {
      Ok(v) => {
        if v.len() != 1 || v[0] != 65 { return 9; }
      },
      Err(_) => { return 9; },
    };
    let wrem_acc = socket.eventloop_remove(&wloop, wacc);
    if !wrem_acc.is_ok { return 10; }
    let wc0 = socket.eventloop_close(&mut wloop);
    if !wc0 { return 10; }
    let wc1 = socket.eventloop_close(&mut wloop);
    if wc1 { return 10; }
    var wb3 = socket.eventbatch_new();
    let ww3 = socket.eventloop_wait(&wloop, 0, &mut wb3);
    if !ww3.is_err { return 10; }
    socket.socket_close(wsrv);
    socket.socket_close(wcli);
    socket.socket_close(wacc);
    return 0;
  };

  // --- Linux: epoll ---
  var loop: socket.EventLoop;
  match created {
    Ok(l) => { loop = l; },
    Err(_) => { return 11; },
  };
  let (rfd, wfd) = pipe.pipe_create();
  if rfd < 0 || wfd < 0 { return 12; }
  let add = socket.eventloop_add(&loop, rfd, true, false);
  if !add.is_ok { return 13; }
  var batch0 = socket.eventbatch_new();
  let wait0 = socket.eventloop_wait(&loop, 0, &mut batch0);
  match wait0 {
    Ok(n) => { if n != 0 { return 13; } },
    Err(_) => { return 13; },
  };
  var byte = Vec[UInt8].new();
  byte.push(65);
  let wr = pipe.pipe_write(wfd, &byte);
  if !wr.is_ok { return 14; }
  var batch1 = socket.eventbatch_new();
  let wait1 = socket.eventloop_wait(&loop, 1000, &mut batch1);
  match wait1 {
    Ok(n) => { if n != 1 { return 15; } },
    Err(_) => { return 15; },
  };
  if batch1.fds.len() != 1 || batch1.flags.len() != 1 { return 15; }
  if batch1.fds[0] != rfd { return 15; }
  if (batch1.flags[0] & 1) == 0 { return 15; }
  var sink = Vec[UInt8].new();
  let rd = pipe.pipe_read(rfd, &mut sink);
  if !rd.is_ok { return 16; }
  let addw = socket.eventloop_add(&loop, wfd, false, true);
  if !addw.is_ok { return 17; }
  var batch2 = socket.eventbatch_new();
  let wait2 = socket.eventloop_wait(&loop, 1000, &mut batch2);
  match wait2 {
    Ok(n) => { if n != 1 { return 17; } },
    Err(_) => { return 17; },
  };
  if batch2.fds[0] != wfd { return 17; }
  if (batch2.flags[0] & 2) == 0 { return 17; }
  let mod = socket.eventloop_modify(&loop, rfd, true, true);
  if !mod.is_ok { return 18; }
  let rem_r = socket.eventloop_remove(&loop, rfd);
  if !rem_r.is_ok { return 19; }
  let rem_w = socket.eventloop_remove(&loop, wfd);
  if !rem_w.is_ok { return 19; }
  var batch3 = socket.eventbatch_new();
  let wait3 = socket.eventloop_wait(&loop, 50, &mut batch3);
  match wait3 {
    Ok(n) => { if n != 0 { return 19; } },
    Err(_) => { return 19; },
  };
  let closed0 = socket.eventloop_close(&mut loop);
  if !closed0 { return 20; }
  let closed1 = socket.eventloop_close(&mut loop);
  if closed1 { return 20; }
  var batch4 = socket.eventbatch_new();
  let wait4 = socket.eventloop_wait(&loop, 0, &mut batch4);
  if !wait4.is_err { return 21; }
  let add_closed = socket.eventloop_add(&loop, rfd, true, false);
  if !add_closed.is_err { return 21; }
  let bad_timeout = socket.eventloop_wait(&loop, 0 - 2, &mut batch4);
  if !bad_timeout.is_err { return 22; }
  pipe.pipe_close(rfd);
  pipe.pipe_close(wfd);
  return 0;
}
