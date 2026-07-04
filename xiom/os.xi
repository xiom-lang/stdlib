// XIOM — OS Library
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.os

pub fn platform() -> Str;

pub fn cpu_count() -> Int;

pub fn total_memory() -> Int;

pub fn free_memory() -> Int;

pub fn env_set(name: Str, value: Str);

pub fn env_unset(name: Str);

pub fn current_dir() -> Str;

pub fn set_current_dir(path: Str) -> Result[Unit, Str];

pub fn temp_dir() -> Str;

pub fn home_dir() -> Option[Str];

// === Permissions ===
fn set_permissions(path: Str, mode: Int) -> Result[Unit, Str];
fn get_permissions(path: Str) -> Result[Int, Str];

// === Symlinks ===
fn read_link(path: Str) -> Result[Str, Str];
fn create_symlink(original: Str, link: Str) -> Result[Unit, Str];
fn is_symlink(path: Str) -> Bool;

// === Temp files ===
fn temp_file() -> Result[Str, Str];
fn temp_dir_os() -> Result[Str, Str];

// === Process ===
fn spawn(command: Str, args: Vec[Str]) -> Result[Int, Str];
fn spawn_piped(command: Str, args: Vec[Str]) -> Result[(Int, Int, Int), Str];
fn wait(pid: Int) -> Result[Int, Str];
fn kill(pid: Int) -> Result[Unit, Str];

pub type ChildProcess = {
  pid: Int;
  stdin: Int;
  stdout: Int;
  stderr: Int;
}

pub fn ChildProcess.wait(self) -> Result[Int, Str];
pub fn ChildProcess.kill(self) -> Result[Unit, Str];
pub fn ChildProcess.id(self) -> Int;

// === Environment ===
fn set_env(name: Str, value: Str);
fn unset_env(name: Str);
fn env_vars() -> Map[Str, Str];

// === OS type detection ===
fn is_windows() -> Bool;
fn is_linux() -> Bool;
fn is_macos() -> Bool;
fn arch() -> Str;

// === Filesystem walk (recursive) ===
pub fn walk_dir(path: Str, callback: fn(Str, Metadata) -> Unit) -> Result[Unit, Str];
pub fn walk_dir_filtered(path: Str, pattern: Str, callback: fn(Str, Metadata) -> Unit) -> Result[Unit, Str];

// === File system watch ===
pub type FileWatcher = { path: Str; recursive: Bool; }
pub fn watch_file(path: Str) -> Result[FileWatcher, Str];
pub fn watch_dir(path: Str, recursive: Bool) -> Result[FileWatcher, Str];
pub fn FileWatcher.poll(self) -> Result[Vec[FileEvent], Str];
pub fn FileWatcher.close(self);

pub type FileEvent = enum {
  Created(path: Str),
  Modified(path: Str),
  Deleted(path: Str),
  Renamed(from: Str, to: Str),
}

// === Signal handling ===
pub fn on_signal(signal: Int, handler: fn(Int) -> Unit);
pub fn raise_signal(signal: Int);
pub const SIGINT: Int;
pub const SIGTERM: Int;
pub const SIGKILL: Int;
pub const SIGUSR1: Int;
pub const SIGUSR2: Int;

// === Pipe ===
pub type Pipe = { read_fd: Int; write_fd: Int; }
pub fn create_pipe() -> Result[Pipe, Str];
pub fn Pipe.read(self, buf: &mut Vec[UInt8]) -> Result[Int, Str];
pub fn Pipe.write(self, data: &Vec[UInt8]) -> Result[Int, Str];
pub fn Pipe.close_read(self);
pub fn Pipe.close_write(self);

// === Disk usage ===
pub fn disk_free(path: Str) -> Result[Int, Str];
pub fn disk_total(path: Str) -> Result[Int, Str];
pub fn file_size_bytes(path: Str) -> Result[Int, Str];
