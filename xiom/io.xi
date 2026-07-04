// XIOM — I/O Library
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.io

// === Console ===
fn print(msg: Str);

fn println(msg: Str);

fn read_line() -> Str;

fn read_int() -> Result[Int, Str];

fn read_float() -> Result[Float64, Str];

// === File system ===
fn read_file(path: Str) -> Result[Str, IOError];

fn write_file(path: Str, content: Str) -> Result[Unit, IOError];

fn append_file(path: Str, content: Str) -> Result[Unit, IOError];

fn file_exists(path: Str) -> Bool;

fn is_dir(path: Str) -> Bool;

fn create_dir(path: Str) -> Result[Unit, IOError];

fn list_dir(path: Str) -> Result[Vec[Str], IOError];

fn remove_file(path: Str) -> Result[Unit, IOError];

fn copy_file(src: Str, dst: Str) -> Result[Unit, IOError];

fn rename(src: Str, dst: Str) -> Result[Unit, IOError];

// === Process ===
fn exit(code: Int);

fn args() -> Vec[Str];

fn env_var(name: Str) -> Option[Str];

// === Time ===
fn time_now() -> Int;

fn sleep(ms: Int);

// === Error type ===
type IOError = {
  message: Str;
  code: Int;
}

// === Read / Write / Seek traits ===
interface Read {
  fn read(self, buf: &mut Vec[UInt8]) -> Result[Int, IOError];
  fn read_to_end(self, buf: &mut Vec[UInt8]) -> Result[Int, IOError];
  fn read_to_string(self) -> Result[Str, IOError];
  fn read_exact(self, buf: &mut Vec[UInt8]) -> Result[Unit, IOError];
}

interface Write {
  fn write(self, buf: &Vec[UInt8]) -> Result[Int, IOError];
  fn write_all(self, buf: &Vec[UInt8]) -> Result[Unit, IOError];
  fn flush(self) -> Result[Unit, IOError];
}

interface Seek {
  fn seek(self, pos: SeekFrom) -> Result[Int, IOError];
  fn stream_position(self) -> Result[Int, IOError];
}

type SeekFrom = enum { Start(Int), End(Int), Current(Int) }

// === Buffered I/O ===
type BufReader = { inner: Int; buf: Vec[UInt8]; }
fn BufReader.new(reader: Int) -> BufReader;
fn BufReader.read_line(self, buf: &mut Str) -> Result[Int, IOError];
fn BufReader.lines(self) -> Vec[Str];

type BufWriter = { inner: Int; buf: Vec[UInt8]; }
fn BufWriter.new(writer: Int) -> BufWriter;

// === File metadata ===
type Metadata = {
  size: Int;
  is_file: Bool;
  is_dir: Bool;
  modified: Int;
  created: Int;
  permissions: Int;
}

fn metadata(path: Str) -> Result[Metadata, IOError];
fn set_permissions(path: Str, perm: Int) -> Result[Unit, IOError];

// === Standard streams ===
fn stdin() -> Int;
fn stdout() -> Int;
fn stderr() -> Int;
fn print_line(s: Str);

// === Memory I/O ===
type Cursor = { data: Vec[UInt8]; pos: Int; }
fn Cursor.new(data: Vec[UInt8]) -> Cursor;
fn Cursor.into_inner(self) -> Vec[UInt8];

// === Path operations ===
fn join_paths(base: Str, child: Str) -> Str;
fn parent_path(path: Str) -> Option<Str>;
fn file_name(path: Str) -> Option<Str>;
fn extension(path: Str) -> Option<Str>;
fn is_absolute(path: Str) -> Bool;
