// p_wave205_iter_os.xi -- wave 205: final residual pass on iter/os.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// This wave adds no clauses: every remaining uncovered iter fn is a
// closure-adapter constructor/terminal/opaque driver, and every remaining
// uncovered os fn is a documented Err/default/no-op stub, a pass-through to
// one, or a Unit cleanup/printer with no observable post-state. The probe
// locks that classification at runtime:
// 1. iter: the clause-free adapters are exercised end to end (map/filter/
//    chain/inspect/for_each and all terminal methods; ZipIter.next/collect
//    for the tuple path -- see the v0.64.8 generic-helper limit in case 4).
// 2. os.err/os.term/os.os: documented defaults and no-ops, plus the one
//    print-only path.
// 3. os.event/ioctl/terminal/sync_io: documented Err stubs (and the
//    documented Unit no-ops).
// 4. os.fs_ffi/proc_ffi/unix/win/mmap/watch/lock: documented Err/default
//    stubs, lock-release and watch-close cleanup guards.
// Returns 0 when every case holds.

module p_wave205_iter_os

use xiom.iter;
use xiom.os as osflat;
use xiom.os.err as oserr;
use xiom.os.event;
use xiom.os.fs_ffi as osfs;
use xiom.os.ioctl as osioctl;
use xiom.os.lock as oslock;
use xiom.os.mmap as osmmap;
use xiom.os.proc_ffi as osproc;
use xiom.os.sync_io as ossync;
use xiom.os.term as osterm;
use xiom.os.terminal as osterminal;
use xiom.os.unix as osunix;
use xiom.os.watch as oswatch;
use xiom.os.win as oswin;

var _seen: Int = 0;

fn inc(x: Int) -> Int {
  return x + 1;
}

fn dbl(x: Int) -> Int {
  return x * 2;
}

fn add(a: Int, b: Int) -> Int {
  return a + b;
}

fn is_even(x: &Int) -> Bool {
  return *x % 2 == 0;
}

fn is_odd(x: &Int) -> Bool {
  return *x % 2 != 0;
}

fn is_pos(x: &Int) -> Bool {
  return *x > 0;
}

fn gt2(x: &Int) -> Bool {
  return *x > 2;
}

fn gt4(x: &Int) -> Bool {
  return *x > 4;
}

fn noop(_x: &Int) {
}

fn mark(_x: &Int) {
  _seen = _seen + 1;
}

fn main() -> Int {
  // ---- 1. iter: Range adapters ----
  var m = iter.range(1, 5).map(dbl);
  match m.next() {
    Some(v) => { if v != 2 { return 1; } },
    None => { return 2; },
  };
  let mc = iter.range(1, 4).map(dbl).collect();
  if mc.len() != 3 { return 3; }
  if mc[0] != 2 || mc[1] != 4 || mc[2] != 6 { return 4; }
  if iter.range(1, 4).map(dbl).fold(0, add) != 12 { return 5; }
  if iter.range(1, 4).map(dbl).sum() != 12 { return 6; }
  if iter.range(1, 4).map(dbl).product() != 48 { return 7; }
  match iter.range(1, 4).map(dbl).max() {
    Some(v) => { if v != 6 { return 8; } },
    None => { return 9; },
  };
  match iter.range(1, 4).map(dbl).min() {
    Some(v) => { if v != 2 { return 10; } },
    None => { return 11; },
  };
  match iter.range(1, 4).map(dbl).find(is_even) {
    Some(v) => { if v != 2 { return 12; } },
    None => { return 13; },
  };
  if !iter.range(1, 4).map(dbl).all(is_pos) { return 14; }
  if !iter.range(1, 4).map(dbl).any(is_even) { return 15; }
  match iter.range(1, 4).map(dbl).nth(1) {
    Some(v) => { if v != 4 { return 16; } },
    None => { return 17; },
  };
  match iter.range(1, 4).map(dbl).last() {
    Some(v) => { if v != 6 { return 18; } },
    None => { return 19; },
  };

  let mm = iter.range(1, 4).map(dbl).map(inc).collect();
  if mm.len() != 3 { return 20; }
  if mm[0] != 3 || mm[2] != 7 { return 21; }
  let mflt = iter.range(1, 6).map(dbl).filter(gt2).collect();
  if mflt.len() != 4 { return 22; }
  if mflt[0] != 4 { return 23; }
  let mch = iter.range(1, 3).map(dbl).chain(iter.range(10, 12)).collect();
  if mch.len() != 4 { return 24; }
  if mch[0] != 2 || mch[2] != 10 || mch[3] != 11 { return 25; }
  let mz = iter.range(1, 4).map(dbl).zip(iter.range(10, 13)).collect();
  if mz.len() != 3 { return 26; }

  // ---- 2. iter: FilterIter adapters ----
  var f = iter.range(1, 7).filter(is_even);
  match f.next() {
    Some(v) => { if v != 2 { return 27; } },
    None => { return 28; },
  };
  let fc = iter.range(1, 6).filter(is_even).collect();
  if fc.len() != 2 { return 29; }
  if fc[0] != 2 || fc[1] != 4 { return 30; }
  if iter.range(1, 6).filter(is_even).fold(0, add) != 6 { return 31; }
  if iter.range(1, 6).filter(is_even).sum() != 6 { return 32; }
  if iter.range(1, 6).filter(is_even).product() != 8 { return 33; }
  match iter.range(1, 6).filter(is_even).max() {
    Some(v) => { if v != 4 { return 34; } },
    None => { return 35; },
  };
  match iter.range(1, 6).filter(is_even).min() {
    Some(v) => { if v != 2 { return 36; } },
    None => { return 37; },
  };
  match iter.range(1, 6).filter(is_even).find(is_even) {
    Some(v) => { if v != 2 { return 38; } },
    None => { return 39; },
  };
  if !iter.range(1, 6).filter(is_even).all(is_pos) { return 40; }
  if iter.range(1, 6).filter(is_even).any(is_odd) { return 41; }
  match iter.range(1, 6).filter(is_even).nth(1) {
    Some(v) => { if v != 4 { return 42; } },
    None => { return 43; },
  };
  match iter.range(1, 6).filter(is_even).last() {
    Some(v) => { if v != 4 { return 44; } },
    None => { return 45; },
  };
  let fm = iter.range(1, 6).filter(is_even).map(dbl).collect();
  if fm.len() != 2 { return 46; }
  if fm[0] != 4 || fm[1] != 8 { return 47; }
  let ff = iter.range(1, 10).filter(is_even).filter(gt4).collect();
  if ff.len() != 2 { return 48; }
  if ff[0] != 6 || ff[1] != 8 { return 49; }
  let fch = iter.range(1, 5).filter(is_even).chain(iter.range(10, 12)).collect();
  if fch.len() != 4 { return 50; }
  if fch[0] != 2 || fch[2] != 10 { return 51; }
  let fz = iter.range(1, 5).filter(is_even).zip(iter.range(10, 12)).collect();
  if fz.len() != 2 { return 52; }

  // ---- 3. iter: ChainIter adapters ----
  var ch = iter.range(1, 3).chain(iter.range(10, 12));
  match ch.next() {
    Some(v) => { if v != 1 { return 53; } },
    None => { return 54; },
  };
  let cc = iter.range(1, 3).chain(iter.range(10, 12)).collect();
  if cc.len() != 4 { return 55; }
  if cc[0] != 1 || cc[2] != 10 || cc[3] != 11 { return 56; }
  let cm = iter.range(1, 3).chain(iter.range(10, 12)).map(dbl).collect();
  if cm.len() != 4 { return 57; }
  if cm[0] != 2 || cm[2] != 20 || cm[3] != 22 { return 58; }
  match iter.range(1, 3).chain(iter.range(10, 12)).find(is_even) {
    Some(v) => { if v != 2 { return 59; } },
    None => { return 60; },
  };
  if !iter.range(1, 3).chain(iter.range(10, 12)).all(is_pos) { return 61; }
  if !iter.range(1, 3).chain(iter.range(10, 12)).any(is_even) { return 62; }
  match iter.range(1, 3).chain(iter.range(10, 12)).nth(2) {
    Some(v) => { if v != 10 { return 63; } },
    None => { return 64; },
  };
  match iter.range(1, 3).chain(iter.range(10, 12)).last() {
    Some(v) => { if v != 11 { return 65; } },
    None => { return 66; },
  };

  // ---- 4. iter: ZipIter adapters ----
  var z = iter.range(1, 3).zip(iter.range(10, 12));
  match z.next() {
    Some(_) => {},
    None => { return 67; },
  };
  // The tuple-instantiation terminals (find/all/any/nth/last) are NOT
  // called here: on v0.64.8 the private _max_via[Int]/_min_via[Int]
  // instantiation plus a tuple instantiation of another _*_via helper
  // mis-lowers (icmp sgt on a {i64,i64} tuple; new compiler limit reported
  // with this wave). ZipIter.next/collect exercise the tuple path safely.
  let zc = iter.range(1, 3).zip(iter.range(10, 12)).collect();
  if zc.len() != 2 { return 69; }

  // ---- 5. iter: inspect + for_each ----
  var ins = iter.range(1, 4).inspect(noop);
  match ins.next() {
    Some(v) => { if v != 1 { return 79; } },
    None => { return 80; },
  };
  match ins.next() {
    Some(v) => { if v != 2 { return 81; } },
    None => { return 82; },
  };
  var vv: Vec[Int] = Vec[Int].new();
  vv.push(5);
  vv.push(6);
  vv.push(7);
  xiom.iter.fold.iter_for_each(&vv, mark);
  if _seen != 3 { return 83; }

  // ---- 6. os.err (documented defaults) ----
  if oserr.errno() != 0 { return 90; }
  oserr.errno_set(5);
  if oserr.backtrace().len() != 0 { return 91; }
  if oserr.backtrace_symbols(&Vec[Int].new()).len() != 0 { return 92; }
  if oserr.last_error() != "" { return 93; }
  oserr.perror("wave205");

  // ---- 7. os.term / os.os real paths and documented defaults ----
  if osterm.term_is_tty(1) { return 94; }
  if osterm.term_width() != 0 { return 95; }
  osflat.sleep_millis(0);
  osflat.sleep_millis(1);
  var fw = osflat.FileWatcher{ path: "wave205"; recursive: false };
  fw.close();

  // ---- 8. os.event stubs ----
  if !event.epoll_create().is_err { return 96; }
  if !event.epoll_add(0, 0, 0).is_err { return 97; }
  if !event.epoll_mod(0, 0, 0).is_err { return 98; }
  if !event.epoll_del(0, 0).is_err { return 99; }
  if !event.epoll_wait(0, 0, 0).is_err { return 100; }
  event.epoll_close(0);
  if !event.kqueue_create().is_err { return 101; }
  event.kqueue_add_read(0, 0);
  event.kqueue_add_write(0, 0);
  if !event.kqueue_wait(0, 0).is_err { return 102; }
  event.kqueue_close(0);
  if !event.eventfd_new(0).is_err { return 103; }
  if !event.eventfd_read(0).is_err { return 104; }
  if !event.eventfd_write(0, 0).is_err { return 105; }
  if !event.timerfd_new().is_err { return 106; }
  if !event.timerfd_set(0, 0).is_err { return 107; }
  if !event.signalfd_new(&Vec[Int].new()).is_err { return 108; }
  var pfds: Vec[PollFd] = Vec[PollFd].new();
  if !event.poll(&pfds, 0).is_err { return 109; }
  if !event.ppoll(&pfds, 0).is_err { return 110; }
  if !event.select(&Vec[Int].new(), &Vec[Int].new(), 0).is_err { return 111; }
  if !event.pselect(&Vec[Int].new(), &Vec[Int].new(), 0).is_err { return 112; }

  // ---- 9. os.fs_ffi stubs ----
  if !osfs.symlink("a", "b").is_err { return 113; }
  if !osfs.readlink("a").is_err { return 114; }
  if osfs.is_symlink("a") { return 115; }
  if !osfs.hard_link("a", "b").is_err { return 116; }
  if !osfs.chown("a", 0, 0).is_err { return 117; }
  if !osfs.dup(0).is_err { return 118; }
  if !osfs.dup2(0, 1).is_err { return 119; }
  if !osfs.truncate("a", 0).is_err { return 120; }
  if !osfs.ftruncate(0, 0).is_err { return 121; }
  if !osfs.fallocate(0, 0, 0).is_err { return 122; }
  if !osfs.pread(0, 0, 0).is_err { return 123; }
  if !osfs.pwrite(0, 0, &Vec[UInt8].new()).is_err { return 124; }
  if !osfs.readv(0, &Vec[Vec[UInt8]].new()).is_err { return 125; }
  if !osfs.splice(0, 1, 0).is_err { return 126; }
  if !osfs.mkfifo("a", 0).is_err { return 127; }
  if !osfs.fifo_open("a").is_err { return 128; }

  // ---- 10. os.ioctl stubs ----
  if !osioctl.ioctl(0, 0, 0).is_err { return 129; }
  if !osioctl.ioctl_get_winsize(0).is_err { return 130; }
  if !osioctl.ioctl_set_nonblock(0, false).is_err { return 131; }
  if !osioctl.ioctl_fionread(0).is_err { return 132; }

  // ---- 11. os.sync_io stubs (the real primitives have their own smokes) ----
  if !ossync.read_until_eof(0).is_err { return 133; }
  if !ossync.read_line_buffered(0).is_err { return 134; }
  if !ossync.copy_fd(0, 1).is_err { return 135; }
  if !ossync.copy_fd_n(0, 1, 8).is_err { return 136; }
  if !ossync.flush_fd(0).is_err { return 137; }
  if !ossync.file_advise(0, 0, 8, 1).is_err { return 138; }
  if !ossync.file_allocate(0, 0, 8).is_err { return 139; }

  // ---- 12. os.terminal stubs ----
  if osterminal.isatty(1) { return 140; }
  if !osterminal.tty_name(0).is_err { return 141; }
  if !osterminal.pty_open().is_err { return 142; }
  osterminal.pty_close(0, 0);
  if !osterminal.termios_get(0).is_err { return 143; }
  var tio = osterminal.Termios{ c_iflag: 0; c_oflag: 0; c_cflag: 0; c_lflag: 0; c_cc: Vec[UInt8].new() };
  if !osterminal.termios_set(0, tio).is_err { return 144; }
  var tio2 = osterminal.Termios{ c_iflag: 0; c_oflag: 0; c_cflag: 0; c_lflag: 0; c_cc: Vec[UInt8].new() };
  if !osterminal.raw_mode(0).is_err { return 145; }
  if !osterminal.restore_mode(0, tio2).is_err { return 146; }
  if !osterminal.cbreak_mode(0).is_err { return 147; }
  if !osterminal.canonical_mode(0).is_err { return 148; }
  if !osterminal.nonblock(0).is_err { return 149; }
  if !osterminal.blocking(0).is_err { return 150; }
  if !osterminal.winsize(0).is_err { return 151; }
  if !osterminal.set_winsize(0, 0, 0).is_err { return 152; }
  if osterminal.terminal_width() != 0 { return 153; }
  if osterminal.terminal_height() != 0 { return 154; }

  // ---- 13. os.proc_ffi stubs ----
  if !osproc.fork().is_err { return 155; }
  if !osproc.waitpid(0, 0).is_err { return 156; }
  if !osproc.wait().is_err { return 157; }
  if !osproc.execv("a", &Vec[Str].new()).is_err { return 158; }
  if !osproc.execvp("a", &Vec[Str].new()).is_err { return 159; }
  if osproc.getppid() != 0 { return 160; }
  if osproc.getsid(0) != 0 { return 161; }
  if !osproc.raise(0).is_err { return 162; }
  if osproc.process_status(0).is_some { return 163; }

  // ---- 14. os.unix stubs ----
  if osunix.unix_umask(0) != 0 { return 164; }
  if osunix.unix_uid() != 0 { return 165; }
  if osunix.unix_gid() != 0 { return 166; }
  if !osunix.unix_username(0).is_err { return 167; }
  if !osunix.unix_groupname(0).is_err { return 168; }
  if osunix.unix_hostname() != "" { return 169; }
  if osunix.unix_domainname() != "" { return 170; }
  if osunix.unix_uptime() != 0 { return 171; }
  let la = osunix.unix_loadavg();
  if la.0 != 0.0 || la.1 != 0.0 || la.2 != 0.0 { return 172; }
  if osunix.unix_sysconf(0) != 0 { return 173; }
  if osunix.unix_pathconf("a", 0) != 0 { return 174; }
  let rl = osunix.unix_getrlimit(0);
  if rl.0 != 0 || rl.1 != 0 { return 175; }
  if !osunix.unix_setrlimit(0, 0, 0).is_err { return 176; }
  if !osunix.unix_utime("a", 0, 0).is_err { return 177; }
  if !osunix.unix_chroot("a").is_err { return 178; }
  if !osunix.unix_nice(0).is_err { return 179; }

  // ---- 15. os.win stubs ----
  if !oswin.win_registry_read(0, "a", "b").is_err { return 180; }
  if !oswin.win_registry_write(0, "a", "b", "c").is_err { return 181; }
  if !oswin.win_registry_delete(0, "a", "b").is_err { return 182; }
  if !oswin.win_set_environment_var("a", "b").is_err { return 183; }
  if oswin.win_service_status("a") != "unknown" { return 184; }
  if !oswin.win_service_start("a").is_err { return 185; }
  if !oswin.win_service_stop("a").is_err { return 186; }
  if !oswin.win_shell_execute("open", "a", "").is_err { return 187; }
  if oswin.win_is_admin() { return 188; }

  // ---- 16. os.mmap / os.watch / os.lock residuals ----
  if !osmmap.mmap_resize(0, 0, 8).is_err { return 189; }
  oswatch.watch_close(0);
  oswatch.watch_close(-1);
  oslock.file_lock_release(oslock.FileLock{ fd: -1; path: "" });

  return 0;
}
