// XIOM stdlib smoke test -- xiom.os.sync_io + xiom.os.terminal
// Synchronous fd helpers (documented stubs) and terminal helpers.
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

  // --- sync_io: documented stubs ---
  {
    let r = sync_io.read_exact(0, &mkbuf());
    if r.is_ok {
      io.println("sync-read");
      return 11;
    }
  }
  {
    let r = sync_io.write_all(1, &mkbuf());
    if r.is_ok {
      io.println("sync-write");
      return 12;
    }
  }
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
    let r = sync_io.sync_fd(1);
    if r.is_ok {
      io.println("sync-sync");
      return 18;
    }
  }
  {
    let r = sync_io.fsync_dir(".");
    if r.is_ok {
      io.println("sync-dir");
      return 19;
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
  {
    let r = sync_io.file_lock(0);
    if r.is_ok {
      io.println("sync-lock");
      return 22;
    }
  }
  {
    let r = sync_io.file_unlock(0);
    if r.is_ok {
      io.println("sync-unlock");
      return 23;
    }
  }
  if sync_io.file_try_lock(0) {
    io.println("sync-trylock");
    return 24;
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
