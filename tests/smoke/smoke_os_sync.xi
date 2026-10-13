// XIOM stdlib smoke test -- xiom.os.sync_io + xiom.os.terminal
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Synchronous fd durability primitives (real since wave 115: open_append/
// open_read/write_all/read_exact/sync_fd/close_fd/fsync_dir), the remaining
// documented stubs, and terminal helpers.
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_os_sync

use xiom.os.sync_io;
use xiom.os.terminal;
use xiom.io;

fn main() -> Int {
  // --- terminal: escape helpers ---
  let title = terminal.terminal_title("xiom test");
  if title != "\x1b]0;xiom test\x07" {
    io.println("term-title");
    return 1;
  }
  if terminal.terminal_bell() != "\x07" {
    io.println("term-bell");
    return 2;
  }
  if terminal.terminal_width() != 0 {
    io.println("term-width");
    return 3;
  }
  if terminal.terminal_height() != 0 {
    io.println("term-height");
    return 4;
  }
  if terminal.isatty(1) {
    io.println("term-isatty");
    return 5;
  }

  // --- terminal: documented stubs ---
  {
    let r = terminal.tty_name(0);
    if r.is_ok {
      io.println("term-tty");
      return 6;
    }
  }
  {
    let r = terminal.winsize(0);
    if r.is_ok {
      io.println("term-winsize");
      return 7;
    }
  }
  {
    let r = terminal.raw_mode(0);
    if r.is_ok {
      io.println("term-raw");
      return 8;
    }
  }
  {
    let r = terminal.nonblock(0);
    if r.is_ok {
      io.println("term-nonblock");
      return 9;
    }
  }
  {
    let r = terminal.pty_open();
    if r.is_ok {
      io.println("term-pty");
      return 10;
    }
  }

  // --- sync_io: real durability primitives (wave 115) ---
  let fixture = "os_sync_tmp.dat";
  {
    let h = sync_io.open_append(fixture);
    match h {
      Ok(fd) => {
        let w = sync_io.write_all(fd, &mkbuf());
        match w {
          Ok(n) => {
            if n != 2 {
              io.println("sync-write");
              return 12;
            }
          },
          Err(_) => {
            io.println("sync-write");
            return 12;
          },
        };
        let s = sync_io.sync_fd(fd);
        match s {
          Ok(_) => {},
          Err(_) => {
            io.println("sync-sync");
            return 18;
          },
        };
        let c = sync_io.close_fd(fd);
        match c {
          Ok(_) => {},
          Err(_) => {
            io.println("sync-close");
            return 25;
          },
        };
      },
      Err(_) => {
        io.println("sync-open");
        return 26;
      },
    };
    let rh = sync_io.open_read(fixture);
    match rh {
      Ok(fd2) => {
        var buf = Vec[UInt8].with_len(2);
        let r = sync_io.read_exact(fd2, &mut buf);
        match r {
          Ok(n) => {
            if n != 2 {
              io.println("sync-read");
              return 11;
            }
          },
          Err(_) => {
            io.println("sync-read");
            return 11;
          },
        };
        if buf[0] != (97 as UInt8) {
          io.println("sync-read-data");
          return 27;
        }
        if buf[1] != (98 as UInt8) {
          io.println("sync-read-data");
          return 27;
        }
        var big = Vec[UInt8].with_len(8);
        let r2 = sync_io.read_exact(fd2, &mut big);
        match r2 {
          Ok(_) => {
            io.println("sync-read-eof");
            return 28;
          },
          Err(_) => {},
        };
        let c2 = sync_io.close_fd(fd2);
        match c2 {
          Ok(_) => {},
          Err(_) => {
            io.println("sync-close");
            return 25;
          },
        };
      },
      Err(_) => {
        io.println("sync-openread");
        return 29;
      },
    };
    let d = sync_io.fsync_dir(".");
    match d {
      Ok(_) => {},
      Err(_) => {
        io.println("sync-dir");
        return 19;
      },
    };
    let rm = io.remove_file(fixture);
    match rm {
      Ok(_) => {},
      Err(_) => {
        io.println("sync-cleanup");
        return 30;
      },
    };
  }

  // --- sync_io: remaining documented stubs ---
  {
    let r = sync_io.read_until_eof(0);
    if r.is_ok {
      io.println("sync-eof");
      return 13;
    }
  }
  {
    let r = sync_io.read_line_buffered(0);
    if r.is_ok {
      io.println("sync-line");
      return 14;
    }
  }
  {
    let r = sync_io.copy_fd(0, 1);
    if r.is_ok {
      io.println("sync-copy");
      return 15;
    }
  }
  {
    let r = sync_io.copy_fd_n(0, 1, 100);
    if r.is_ok {
      io.println("sync-copyn");
      return 16;
    }
  }
  {
    let r = sync_io.flush_fd(1);
    if r.is_ok {
      io.println("sync-flush");
      return 17;
    }
  }
  {
    let r = sync_io.file_advise(0, 0, 100, 1);
    if r.is_ok {
      io.println("sync-advise");
      return 20;
    }
  }
  {
    let r = sync_io.file_allocate(0, 0, 100);
    if r.is_ok {
      io.println("sync-alloc");
      return 21;
    }
  }
  // --- sync_io: real advisory locking (wave 118) ---
  {
    let fh = sync_io.open_append("os_sync_lock.dat");
    match fh {
      Ok(lfd) => {
        let t0 = sync_io.file_try_lock(lfd);
        if !t0 {
          io.println("sync-trylock");
          return 24;
        }
        let u0 = sync_io.file_unlock(lfd);
        if u0.is_err {
          io.println("sync-unlock");
          return 23;
        };
        let lk = sync_io.file_lock(lfd);
        if lk.is_err {
          io.println("sync-lock");
          return 22;
        };
        let ul = sync_io.file_unlock(lfd);
        if ul.is_err {
          io.println("sync-unlock");
          return 23;
        };
        let cl = sync_io.close_fd(lfd);
        if cl.is_err {
          io.println("sync-lock-close");
          return 25;
        };
      },
      Err(_) => {
        io.println("sync-lock-open");
        return 26;
      },
    };
    let _ = io.remove_file("os_sync_lock.dat");
  }

  io.println("OK");
  return 0;
}

fn mkbuf() -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  v.push(97);
  v.push(98);
  v
}
