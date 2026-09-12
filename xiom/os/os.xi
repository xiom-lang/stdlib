// XIOM -- OS Library
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.os

use xiom.os.mmap;
use xiom.os.sync_io;
use xiom.os.win;
use xiom.os.unix;

extern "C" {
  fn system(command: *UInt8) -> Int32;
  fn getcwd(buf: *UInt8, size: UInt) -> *UInt8;
  fn chdir(path: *UInt8) -> Int32;
  fn mkdir(path: *UInt8) -> Int32;
  fn rmdir(path: *UInt8) -> Int32;
  fn remove(path: *UInt8) -> Int32;
  fn rename(old: *UInt8, new: *UInt8) -> Int32;
  fn getenv(name: *UInt8) -> *UInt8;
  fn setenv(name: *UInt8, value: *UInt8, overwrite: Int32) -> Int32;
  fn unsetenv(name: *UInt8) -> Int32;
  fn xiom_total_memory() -> UInt64;
  fn xiom_free_memory() -> UInt64;
  fn xiom_cpu_count() -> Int32;
  fn xiom_readlink(path: *UInt8, buf: *UInt8, bufsiz: UInt) -> Int;
  fn xiom_symlink(target: *UInt8, linkpath: *UInt8) -> Int32;
  fn xiom_is_symlink(path: *UInt8) -> Int32;
  fn xiom_disk_free(path: *UInt8) -> UInt64;
  fn xiom_disk_total(path: *UInt8) -> UInt64;
  fn signal(signum: Int32, handler: *UInt8) -> *UInt8;
  fn raise_sig(sig: Int32) -> Int32;
  fn xiom_pipe(fds: *Int32) -> Int32;
  fn xiom_read(fd: Int32, buf: *UInt8, count: UInt) -> Int;
  fn xiom_write(fd: Int32, buf: *UInt8, count: UInt) -> Int;
  fn xiom_close(fd: Int32) -> Int32;
  // v0.56: Production process & hostname operations
  fn xiom_hostname() -> *UInt8;
  fn xiom_process_spawn(cmd: *UInt8) -> Int64;
  fn xiom_process_kill(pid: Int64) -> Int32;
  fn xiom_process_wait(pid: Int64) -> Int64;
  fn xiom_process_running(pid: Int64) -> Int32;
  fn xiom_os_version_str() -> *UInt8;
  fn xiom_getpid() -> Int64;
}

fn cstr(s: Str) -> *UInt8
  requires: true
{
  unsafe {
    return s as *UInt8;
  }
}

// === Platform & Architecture ===

pub fn platform() -> Str
  ensures: result.len() > 0
{
  return env.OS;
}

pub fn cpu_count() -> Int
  requires: true
  ensures: result > 0
{
  unsafe {
    let count = xiom_cpu_count();
    if count < 1 {
      return 1;
    };
    return count as Int;
  }
}

pub fn total_memory() -> Int
  requires: true
  ensures: result >= 0
{
  unsafe {
    return xiom_total_memory() as Int;
  }
}

pub fn free_memory() -> Int
  requires: true
  ensures: result >= 0
{
  unsafe {
    return xiom_free_memory() as Int;
  }
}

pub fn env_set(name: Str, value: Str) {
  env.set_var(name, value);
}

pub fn env_unset(name: Str) {
  env.remove_var(name);
}

pub fn current_dir() -> Str
  ensures: result.len() > 0
{
  let result = env.current_dir();
  match result {
    Ok(dir) => dir;
    Err(_) => ".";
  }
}

pub fn set_current_dir(path: Str) -> Result[Unit, Str]
  requires: path.len() > 0
{
  return env.set_current_dir(path);
}

pub fn temp_dir() -> Str
  ensures: result.len() > 0
{
  return env.temp_dir();
}

pub fn home_dir() -> Option[Str]
  ensures: result is Some => result.len() > 0
{
  return env.home_dir();
}

// === Permissions ===

fn set_permissions(path: Str, mode: Int) -> Result[Unit, Str]
  requires: path.len() > 0
  requires: mode >= 0
{
  let result = io.set_permissions(path, mode);
  match result {
    Ok(()) => Ok(());
    Err(e) => Err(e.message);
  }
}

fn get_permissions(path: Str) -> Result[Int, Str]
  requires: path.len() > 0
{
  let result = io.metadata(path);
  match result {
    Ok(meta) => Ok(meta.permissions);
    Err(e) => Err(e.message);
  }
}

// === Symlinks ===

fn read_link(path: Str) -> Result[Str, Str] {
  let c_path = cstr(path);
  var buf: [4096]UInt8;
  let len: Int;
  unsafe {
    len = xiom_readlink(c_path, &buf[0], 4096 as UInt);
  }
  if len < 0 {
    return Err("failed to read link: " + path);
  };
  unsafe {
    buf[len] = 0;
    return Ok(Str.from_cstring(&buf[0]));
  }
}

fn create_symlink(original: Str, link: Str) -> Result[Unit, Str]
  requires: original.len() > 0
  requires: link.len() > 0
{
  let rc: Int32;
  unsafe {
    rc = xiom_symlink(cstr(original), cstr(link));
  }
  if rc != 0 {
    return Err("failed to create symlink: " + link + " -> " + original);
  };
  return Ok(());
}

fn is_symlink(path: Str) -> Bool
  requires: path.len() > 0
{
  let result: Int32;
  unsafe {
    result = xiom_is_symlink(cstr(path));
  }
  return result != 0;
}

// === Temp Files ===

fn temp_file() -> Result[Str, Str] {
  let t = temp_dir_os();
  match t {
    Ok(d) => {
      let ts = io.time_now();
      let name = string.str_concat(string.str_concat(d, env.path_separator()), string.str_concat("xiom_", core.to_string(ts)));
      return Ok(string.str_concat(name, ".tmp"));
    };
    Err(e) => Err(e);
  }
}

fn temp_dir_os() -> Result[Str, Str] {
  let t = temp_dir();
  if t.is_empty() {
    return Err("could not find temporary directory");
  };
  return Ok(t);
}

// === Process ===

fn build_command_string(command: Str, args: Vec[Str]) -> Str {
  var cmd = command;
  var i: Int = 0;
  while i < args.len() {
    cmd = string.str_concat(string.str_concat(cmd, " "), args[i]);
    i = i + 1;
  }
  return cmd;
}

fn spawn(command: Str, args: Vec[Str]) -> Result[Int, Str]
  requires: command.len() > 0
  ensures:  result is Ok => result >= 0
{
  let cmd = build_command_string(command, args);
  let rc: Int64;
  unsafe {
    rc = xiom_process_spawn(cstr(cmd));
  }
  if rc < 0 {
    return Err("failed to spawn process: " + command);
  };
  return Ok(rc as Int);
}

fn spawn_piped(command: Str, args: Vec[Str]) -> Result[(Int, Int, Int), Str]
  requires: command.len() > 0
{
  return Err("spawn_piped not supported via system()");
}

fn wait(pid: Int) -> Result[Int, Str]
  requires: pid > 0
{
  let rc: Int64;
  unsafe {
    rc = xiom_process_wait(pid as Int64);
  }
  if rc < 0 {
    return Err("process wait failed");
  };
  return Ok(rc as Int);
}

fn kill(pid: Int) -> Result[Unit, Str]
  requires: pid > 0
{
  let rc: Int32;
  unsafe {
    rc = xiom_process_kill(pid as Int64);
  }
  if rc != 0 {
    return Err("process kill failed");
  };
  return Ok(());
}

pub type ChildProcess = {
  pid: Int;
  stdin: Int;
  stdout: Int;
  stderr: Int;
}

pub fn ChildProcess.wait(self) -> Result[Int, Str]
  requires: self.pid > 0
{
  return wait(self.pid);
}

pub fn ChildProcess.kill(self) -> Result[Unit, Str]
  requires: pid > 0
{
  return kill(self.pid);
}

pub fn ChildProcess.id(self) -> Int
  ensures: result >= 0
{
  return self.pid;
}

// === Environment (private helpers) ===

fn set_env(name: Str, value: Str)
  requires: true
{
  unsafe {
    let _ = setenv(cstr(name), cstr(value), 1);
  }
}

fn unset_env(name: Str)
  requires: true
{
  unsafe {
    let _ = unsetenv(cstr(name));
  }
}

fn env_vars() -> Map[Str, Str] {
  var m: Map[Str, Str] = Map[Str, Str].new();
  return m;
}

// === OS Type Detection ===

fn is_windows() -> Bool {
  return env.OS == "windows";
}

fn is_linux() -> Bool {
  return env.OS == "linux";
}

fn is_macos() -> Bool {
  return env.OS == "macos";
}

fn arch() -> Str {
  return env.ARCH;
}

// === Filesystem Walk ===

pub fn walk_dir(path: Str, callback: fn(Str, Metadata) -> Unit) -> Result[Unit, Str]
  requires: path.len() > 0
{
  let entries = io.list_dir(path);
  match entries {
    Ok(items) => {
      var i: Int = 0;
      while i < items.len() {
        let full = io.join_paths(path, items[i]);
        let meta = io.metadata(full);
        match meta {
          Ok(m) => {
            callback(full, m);
            if m.is_dir {
              let result = walk_dir(full, callback);
              if result.is_ok == false {
                return result;
              };
            };
          };
          Err(e) => {
            return Err(e.message);
          };
        };
        i = i + 1;
      };
      return Ok(());
    };
    Err(e) => Err(e.message);
  }
}

pub fn walk_dir_filtered(path: Str, pattern: Str, callback: fn(Str, Metadata) -> Unit) -> Result[Unit, Str]
  requires: path.len() > 0
{
  let entries = io.list_dir(path);
  match entries {
    Ok(items) => {
      var i: Int = 0;
      while i < items.len() {
        let name = items[i];
        if string.str_contains(name, pattern) {
          let full = io.join_paths(path, name);
          let meta = io.metadata(full);
          match meta {
            Ok(m) => {
              callback(full, m);
              if m.is_dir {
                let result = walk_dir_filtered(full, pattern, callback);
                if result.is_ok == false {
                  return result;
                };
              };
            };
            Err(e) => {
              return Err(e.message);
            };
          };
        };
        i = i + 1;
      };
      return Ok(());
    };
    Err(e) => Err(e.message);
  }
}

// === File System Watch ===

pub type FileWatcher = {
  path: Str;
  recursive: Bool;
}

pub fn watch_file(path: Str) -> Result[FileWatcher, Str]
  requires: path.len() > 0
{
  return watch_dir(path, false);
}

pub fn watch_dir(path: Str, recursive: Bool) -> Result[FileWatcher, Str]
  requires: path.len() > 0
{
  return Ok(FileWatcher{
    path: path;
    recursive: recursive;
  });
}

pub fn FileWatcher.poll(self) -> Result[Vec[FileEvent], Str]
  ensures: result is Ok => result.len() >= 0
{
  var events: Vec[FileEvent] = Vec[FileEvent].new();
  let entries = io.list_dir(self.path);
  match entries {
    Ok(items) => {
      var i: Int = 0;
      while i < items.len() {
        let full = io.join_paths(self.path, items[i]);
        let meta = io.metadata(full);
        match meta {
          Ok(m) => {
            if m.is_dir {
              events.push(FileEvent.Created(full));
            } else {
              events.push(FileEvent.Modified(full));
            };
          };
          Err(_) => {
            events.push(FileEvent.Deleted(full));
          };
        };
        i = i + 1;
      };
      return Ok(events);
    };
    Err(e) => Err(e.message);
  }
}

pub fn FileWatcher.close(self) {
}

pub type FileEvent = enum {
  Created(path: Str),
  Modified(path: Str),
  Deleted(path: Str),
  Renamed(from: Str, to: Str),
}

// === Signal Handling ===

pub fn on_signal(signal: Int, handler: fn(Int) -> Unit)
  requires: signal > 0
{
}

pub fn raise_signal(signal: Int)
  requires: signal > 0
{
  unsafe {
    let _ = raise_sig(signal as Int32);
  }
}

pub const SIGINT: Int = 2;
pub const SIGTERM: Int = 15;
pub const SIGKILL: Int = 9;
pub const SIGUSR1: Int = 10;
pub const SIGUSR2: Int = 12;

// === Pipe ===

pub type Pipe = {
  read_fd: Int;
  write_fd: Int;
}

pub fn create_pipe() -> Result[Pipe, Str]
  ensures: result is Ok => result.read_fd >= 0 && result.write_fd >= 0
{
  var fds: [2]Int32;
  let rc: Int32;
  unsafe {
    rc = xiom_pipe(&fds[0]);
  }
  if rc != 0 {
    return Err("failed to create pipe");
  };
  return Ok(Pipe{
    read_fd: fds[0] as Int;
    write_fd: fds[1] as Int;
  });
}

pub fn Pipe.read(self, buf: &mut Vec[UInt8]) -> Result[Int, Str]
  requires: self.read_fd >= 0
  ensures:  result is Ok => result >= 0
{
  let n: Int;
  unsafe {
    n = xiom_read(self.read_fd as Int32, buf.as_mut_ptr(), buf.len());
  }
  if n < 0 {
    return Err("failed to read from pipe");
  };
  return Ok(n);
}

pub fn Pipe.write(self, data: &Vec[UInt8]) -> Result[Int, Str]
  requires: self.write_fd >= 0
  ensures:  result is Ok => result >= 0
{
  let n: Int;
  unsafe {
    n = xiom_write(self.write_fd as Int32, data.as_ptr(), data.len() as UInt);
  }
  if n < 0 {
    return Err("failed to write to pipe");
  };
  return Ok(n);
}

pub fn Pipe.close_read(self)
  requires: self.read_fd >= 0
{
  unsafe {
    let _ = xiom_close(self.read_fd as Int32);
  }
}

pub fn Pipe.close_write(self)
  requires: self.write_fd >= 0
{
  unsafe {
    let _ = xiom_close(self.write_fd as Int32);
  }
}

// === Disk Usage ===

pub fn disk_free(path: Str) -> Result[Int, Str]
  requires: path.len() > 0
  ensures:  result is Ok => result >= 0
{
  let c_path = cstr(path);
  let free: UInt64;
  unsafe {
    free = xiom_disk_free(c_path);
  }
  return Ok(free as Int);
}

pub fn disk_total(path: Str) -> Result[Int, Str]
  requires: path.len() > 0
  ensures:  result is Ok => result >= 0
{
  let c_path = cstr(path);
  let total: UInt64;
  unsafe {
    total = xiom_disk_total(c_path);
  }
  return Ok(total as Int);
}

pub fn file_size_bytes(path: Str) -> Result[Int, Str]
  requires: path.len() > 0
  ensures:  result is Ok => result >= 0
{
  let result = io.metadata(path);
  match result {
    Ok(meta) => Ok(meta.size);
    Err(e) => Err(e.message);
  }
}

// ----------------------------------------------------------
//  Extended OS queries
// ----------------------------------------------------------

// hostname returns the system hostname via gethostname (POSIX) or
// GetComputerNameA (Windows).  Uses an internal static buffer in the
// C runtime.  Returns Err on failure.
pub fn hostname() -> Result[Str, Str]
  requires: true
{
  unsafe {
    let raw = xiom_hostname();
    if raw == null {
      return Err("hostname: system call failed");
    };
    return Ok(Str.from_cstring(raw));
  }
}

// os_version_str returns a best-effort OS version string via the
// xiom_os_version_str runtime intrinsic (GetVersionExA on Windows,
// uname on POSIX).
pub fn os_version_str() -> Str
  requires: true
{
  unsafe {
    let raw = xiom_os_version_str();
    return Str.from_cstring(raw);
  }
}

// is_unix returns true if the platform is linux or macos.
pub fn is_unix() -> Bool {
  return is_linux() || is_macos();
}

// user_name returns the current user name by reading the
// USERNAME (Windows) or USER (Unix) environment variable.
pub fn user_name() -> Option[Str] {
  let v = env.var_opt("USERNAME");
  match v {
    Some(name) => return Some(name);
    None => {};
  };
  return env.var_opt("USER");
}

// total_memory_mb returns total system memory in MiB.
// Wraps total_memory() / (1024 * 1024).  Complexity: O(1).
pub fn total_memory_mb() -> Int {
  let total = total_memory();
  return total / (1024 * 1024);
}

// free_memory_mb returns free system memory in MiB.
// Wraps free_memory() / (1024 * 1024).  Complexity: O(1).
pub fn free_memory_mb() -> Int {
  let free = free_memory();
  return free / (1024 * 1024);
}

// page_size returns the system page size in bytes.
// Returns 4096 -- the runtime does not expose sysconf(_SC_PAGESIZE).
pub fn page_size() -> Int {
  return 4096;
}

// terminal_width returns the terminal width in columns, if detectable.
// The Xiom runtime does not expose TIOCGWINSZ -- always returns None.
pub fn terminal_width() -> Option[Int] {
  return None;
}

// sleep_millis sleeps for at least the given number of milliseconds.
// Uses busy-wait; usleep is not available on Windows MSVC.
pub fn sleep_millis(ms: Int) {
  if ms <= 0 {
    return;
  };
  let start = io.time_now();
  let end_secs = start + ms / 1000;
  if ms < 1000 {
    let target = io.time_now() + 1;
    while io.time_now() < target {
    };
    return;
  };
  while io.time_now() < end_secs {
  };
}

// current_exe_path returns the path of the currently running executable.
// Delegates to env.current_exe().  Returns None on failure.
pub fn current_exe_path() -> Option[Str] {
  let result = env.current_exe();
  match result {
    Ok(path) => Some(path);
    Err(_) => None;
  }
}

// process_id returns the current process ID via the xiom_getpid
// runtime intrinsic.
pub fn process_id() -> Int
  requires: true
{
  unsafe {
    return xiom_getpid() as Int;
  }
}

// cpu_model returns a human-readable CPU model string.
// The Xiom runtime does not expose CPUID or /proc/cpuinfo.
// Always returns "unknown".
pub fn cpu_model() -> Str {
  return "unknown";
}
