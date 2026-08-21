// XIOM stdlib smoke test -- xiom.os.fs_ffi + xiom.os.proc_ffi + xiom.os.ioctl +
// xiom.os.mmap + xiom.os.win + xiom.os.unix
// FFI-backed OS helpers: only what each stub documents as implementable is
// verified; the rest are documented stubs returning Err or defaults.
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_os_ffi

use xiom.os.fs_ffi;
use xiom.os.proc_ffi;
use xiom.os.ioctl;
use xiom.os.mmap;
use xiom.os.win;
use xiom.os.unix;
use xiom.io;

fn main() -> Int {
  // --- fs_ffi: chmod (delegates to xiom.io) ---
  let tmp = "C:\\Users\\lefte\\AppData\\Local\\Temp\\kilo\\agent_net2\\ffi_chmod.txt";
  {
    let w = io.write_file(tmp, "test");
    if w.is_err {
      io.println("ffi-write");
      return 1;
    }
  }
  {
    let r = fs_ffi.chmod(tmp, 644);
    if r.is_err {
      io.println("ffi-chmod");
      return 2;
    }
  }
  {
    let _ = io.remove_file(tmp);
  }

  // --- fs_ffi: documented stubs ---
  if fs_ffi.is_symlink(tmp) {
    io.println("ffi-islink");
    return 3;
  }
  {
    let r = fs_ffi.symlink("target", "link");
    if r.is_ok {
      io.println("ffi-symlink");
      return 4;
    }
  }
  {
    let r = fs_ffi.readlink(tmp);
    if r.is_ok {
      io.println("ffi-readlink");
      return 5;
    }
  }
  {
    let r = fs_ffi.hard_link("a", "b");
    if r.is_ok {
      io.println("ffi-hardlink");
      return 6;
    }
  }
  {
    let r = fs_ffi.chown(tmp, 0, 0);
    if r.is_ok {
      io.println("ffi-chown");
      return 7;
    }
  }
  {
    let r = fs_ffi.dup(1);
    if r.is_ok {
      io.println("ffi-dup");
      return 8;
    }
  }
  {
    let r = fs_ffi.truncate(tmp, 0);
    if r.is_ok {
      io.println("ffi-truncate");
      return 9;
    }
  }
  {
    let r = fs_ffi.fsync(1);
    if r.is_ok {
      io.println("ffi-fsync");
      return 10;
    }
  }
  {
    let r = fs_ffi.mkfifo(tmp, 644);
    if r.is_ok {
      io.println("ffi-mkfifo");
      return 11;
    }
  }
  {
    let r = fs_ffi.fifo_open(tmp);
    if r.is_ok {
      io.println("ffi-fifo");
      return 12;
    }
  }

  // --- proc_ffi: identity + wait-status math ---
  let pid = proc_ffi.getpid();
  if pid <= 0 {
    io.println("proc-pid");
    return 13;
  }
  if proc_ffi.getppid() != 0 {
    io.println("proc-ppid");
    return 14;
  }
  if proc_ffi.exit_code(256) != 1 {
    io.println("proc-exitcode");
    return 15;
  }
  if proc_ffi.exit_code(0) != 0 {
    io.println("proc-exitcode0");
    return 16;
  }
  if proc_ffi.exit_signal(11) != 11 {
    io.println("proc-exitsig");
    return 17;
  }
  {
    let r = proc_ffi.process_status(pid);
    if r.is_some {
      io.println("proc-status");
      return 18;
    }
  }
  {
    let r = proc_ffi.fork();
    if r.is_ok {
      io.println("proc-fork");
      return 19;
    }
  }
  {
    let r = proc_ffi.kill(pid, 0);
    if r.is_ok {
      io.println("proc-kill");
      return 20;
    }
  }
  {
    let r = proc_ffi.raise(0);
    if r.is_ok {
      io.println("proc-raise");
      return 21;
    }
  }

  // --- ioctl: documented stubs ---
  {
    let r = ioctl.ioctl(0, 0, 0);
    if r.is_ok {
      io.println("ioctl-raw");
      return 22;
    }
  }
  {
    let r = ioctl.ioctl_get_winsize(0);
    if r.is_ok {
      io.println("ioctl-winsize");
      return 23;
    }
  }
  {
    let r = ioctl.ioctl_set_nonblock(0, true);
    if r.is_ok {
      io.println("ioctl-nonblock");
      return 24;
    }
  }
  {
    let r = ioctl.ioctl_fionread(0);
    if r.is_ok {
      io.println("ioctl-fionread");
      return 25;
    }
  }

  // --- mmap: documented stubs ---
  {
    let r = mmap.mmap_anonymous(4096);
    if r.is_ok {
      io.println("mmap-anon");
      return 26;
    }
  }
  {
    let r = mmap.mmap_file(1, 0, 4096);
    if r.is_ok {
      io.println("mmap-file");
      return 27;
    }
  }
  {
    let r = mmap.mmap_writeable(1, 0, 4096);
    if r.is_ok {
      io.println("mmap-writeable");
      return 28;
    }
  }
  {
    let r = mmap.mmap_unmap(0, 4096);
    if r.is_ok {
      io.println("mmap-unmap");
      return 29;
    }
  }
  {
    let r = mmap.mmap_sync(0, 4096, 0);
    if r.is_ok {
      io.println("mmap-sync");
      return 30;
    }
  }
  if mmap.mmap_copy(0, 10).len() != 0 {
    io.println("mmap-copy");
    return 31;
  }
  {
    let r = mmap.mmap_write(0, &mkbytes());
    if r.is_ok {
      io.println("mmap-write");
      return 32;
    }
  }
  {
    let r = mmap.mmap_resize(0, 4096, 8192);
    if r.is_ok {
      io.println("mmap-resize");
      return 33;
    }
  }

  // --- win: environment + identity ---
  {
    let v = win.win_environment_var("USERNAME");
    match v {
      None => {
        io.println("win-var");
        return 34;
      }
      Some(u) => {
        if u.len() == 0 {
          io.println("win-var-empty");
          return 35;
        }
      }
    }
  }
  {
    let r = win.win_set_environment_var("XIOM_SMOKE_TEST", "42");
    if r.is_ok {
      io.println("win-set");
      return 36;
    }
  }
  if win.win_is_admin() {
    io.println("win-admin");
    return 39;
  }
  {
    let wv = win.win_version();
    if wv.len() == 0 {
      io.println("win-ver");
      return 40;
    }
  }
  {
    let wu = win.win_username();
    if wu.len() == 0 {
      io.println("win-user");
      return 41;
    }
  }
  {
    let svc = win.win_service_status("nonexistent");
    if svc != "unknown" {
      io.println("win-service");
      return 42;
    }
  }
  {
    let r = win.win_registry_read(0, "path", "name");
    if r.is_ok {
      io.println("win-reg");
      return 43;
    }
  }
  {
    let r = win.win_shell_execute("open", "nonexistent", "");
    if r.is_ok {
      io.println("win-shell");
      return 44;
    }
  }

  // --- unix: environment + documented defaults ---
  {
    let uh = unix.unix_home_dir();
    if uh.len() == 0 {
      io.println("unix-home");
      return 45;
    }
  }
  if unix.unix_uid() != 0 {
    io.println("unix-uid");
    return 46;
  }
  if unix.unix_gid() != 0 {
    io.println("unix-gid");
    return 47;
  }
  if unix.unix_umask(0) != 0 {
    io.println("unix-umask");
    return 48;
  }
  if unix.unix_hostname() != "" {
    io.println("unix-hostname");
    return 49;
  }
  if unix.unix_uptime() != 0 {
    io.println("unix-uptime");
    return 50;
  }
  if unix.unix_sysconf(0) != 0 {
    io.println("unix-sysconf");
    return 51;
  }
  {
    let la = unix.unix_loadavg();
    if la.0 != 0.0 || la.1 != 0.0 || la.2 != 0.0 {
      io.println("unix-loadavg");
      return 52;
    }
  }
  {
    let rl = unix.unix_getrlimit(0);
    if rl.0 != 0 || rl.1 != 0 {
      io.println("unix-rlimit");
      return 53;
    }
  }
  {
    let r = unix.unix_username(0);
    if r.is_ok {
      io.println("unix-username");
      return 54;
    }
  }
  {
    let r = unix.unix_nice(1);
    if r.is_ok {
      io.println("unix-nice");
      return 55;
    }
  }
  {
    let r = unix.unix_setrlimit(0, 0, 0);
    if r.is_ok {
      io.println("unix-setrlimit");
      return 56;
    }
  }
  {
    let r = unix.unix_chroot(".");
    if r.is_ok {
      io.println("unix-chroot");
      return 57;
    }
  }

  io.println("OK");
  return 0;
}

fn mkbytes() -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  v.push(97);
  v.push(98);
  v
}
