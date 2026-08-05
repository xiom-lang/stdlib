// XIOM — I/O Library
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.io

extern "C" {
  fn printf(format: *UInt8, ...) -> Int32;
  fn puts(s: *UInt8) -> Int32;
  fn fgets(buf: *UInt8, size: Int32, stream: *UInt8) -> *UInt8;
  fn fopen(path: *UInt8, mode: *UInt8) -> *UInt8;
  fn fclose(file: *UInt8) -> Int32;
  fn fread(buf: *UInt8, size: UInt, count: UInt, file: *UInt8) -> UInt;
  fn fwrite(buf: *UInt8, size: UInt, count: UInt, file: *UInt8) -> UInt;
  fn remove(path: *UInt8) -> Int32;
  fn rename(old: *UInt8, new: *UInt8) -> Int32;
  fn xiom_read_file(path: *UInt8) -> *UInt8;
  fn xiom_file_size(path: *UInt8) -> Int;
  fn xiom_free(ptr: *UInt8);
  fn exit(code: Int32);
  fn getenv(name: *UInt8) -> *UInt8;
  fn time(t: *Int) -> Int;
  fn usleep(usec: UInt) -> Int32;
  fn mkdir(path: *UInt8) -> Int32;
  fn chmod(path: *UInt8, mode: Int32) -> Int32;
  fn xiom_stdin() -> *UInt8;
  fn xiom_stdout() -> *UInt8;
  fn xiom_stderr() -> *UInt8;
  fn xiom_get_argc() -> Int;
  fn xiom_get_argv(i: Int) -> *UInt8;
  fn opendir(path: *UInt8) -> *UInt8;
  fn readdir(dir: *UInt8) -> *UInt8;
  fn closedir(dir: *UInt8) -> Int32;
  fn xiom_dirent_name(entry: *UInt8) -> *UInt8;
  fn xiom_stat_is_file(path: *UInt8) -> Int32;
  fn xiom_stat_is_dir(path: *UInt8) -> Int32;
  fn xiom_stat_size(path: *UInt8) -> Int;
  fn xiom_stat_mtime(path: *UInt8) -> Int;
  fn xiom_stat_ctime(path: *UInt8) -> Int;
  fn xiom_stat_mode(path: *UInt8) -> Int;
}

// === Error type ===
pub type IOError = {
  message: Str;
  code: Int;
}

// === SeekFrom ===
pub type SeekFrom = enum { Start(Int), End(Int), Current(Int) }

// === Console ===
pub fn print(msg: Str) {
  unsafe {
    printf("%s", msg.c_str());
  }
}

pub fn println(msg: Str) {
  unsafe {
    puts(msg.c_str());
  }
}

pub fn read_line() -> Str {
  var buf: Vec[UInt8] = Vec[UInt8]::with_capacity(4096);
  let ptr: *UInt8;
  unsafe {
    ptr = fgets(buf.as_mut_ptr(), 4096 as Int32, xiom_stdin());
  }
  if ptr == 0 {
    return "";
  }
  let raw = Str::from_c_str(ptr);
  strip_trailing_newline(raw)
}

fn strip_trailing_newline(s: Str) -> Str {
  let len = s.len();
  if len >= 2 && s.byte_at(len - 2) == 13 && s.byte_at(len - 1) == 10 {
    s.substr(0, len - 2)
  } elif len >= 1 && s.byte_at(len - 1) == 10 {
    s.substr(0, len - 1)
  } elif len >= 1 && s.byte_at(len - 1) == 13 {
    s.substr(0, len - 1)
  } else {
    s
  }
}

pub fn read_int() -> Result[Int, Str] {
  let line = read_line();
  let trimmed = line.trim();
  if trimmed.is_empty() {
    return Err("empty input");
  }
  var sign: Int = 1;
  var start: Int = 0;
  if trimmed.byte_at(0) == 45 {
    sign = -1;
    start = 1;
  } elif trimmed.byte_at(0) == 43 {
    start = 1;
  }
  if start == trimmed.len() {
    return Err("no digits found");
  }
  var result: Int = 0;
  var i = start;
  while i < trimmed.len() {
    let b = trimmed.byte_at(i);
    if b < 48 || b > 57 {
      return Err("invalid integer: " + line);
    }
    result = result * 10 + (b as Int - 48);
    i = i + 1;
  }
  Ok(result * sign)
}

pub fn read_float() -> Result[Float64, Str] {
  let line = read_line();
  let trimmed = line.trim();
  if trimmed.is_empty() {
    return Err("empty input");
  }
  var sign: Float64 = 1.0;
  var start: Int = 0;
  if trimmed.byte_at(0) == 45 {
    sign = -1.0;
    start = 1;
  } elif trimmed.byte_at(0) == 43 {
    start = 1;
  }
  if start == trimmed.len() {
    return Err("no digits found");
  }
  var int_part: Float64 = 0.0;
  var frac_part: Float64 = 0.0;
  var frac_div: Float64 = 1.0;
  var in_fraction = false;
  var i = start;
  while i < trimmed.len() {
    let b = trimmed.byte_at(i);
    if b == 46 {
      if in_fraction {
        return Err("invalid float: " + line);
      }
      in_fraction = true;
    } elif b >= 48 && b <= 57 {
      let digit = (b as Float64 - 48.0);
      if in_fraction {
        frac_div = frac_div * 10.0;
        frac_part = frac_part * 10.0 + digit;
      } else {
        int_part = int_part * 10.0 + digit;
      }
    } else {
      return Err("invalid float: " + line);
    }
    i = i + 1;
  }
  Ok(sign * (int_part + frac_part / frac_div))
}

// === File system ===
pub fn read_file(path: Str) -> Result[Str, IOError]
  requires: path.len() > 0
  ensures:  result is Ok => result.len() >= 0
{
  let c_path = path.c_str();
  let ptr: *UInt8;
  let size: Int;
  unsafe {
    ptr = xiom_read_file(c_path);
    if ptr == 0 {
      return Err(IOError{ message: "failed to read file: " + path, code: 1 });
    }
    size = xiom_file_size(c_path);
  }
  var buf: Vec[UInt8] = Vec[UInt8]::with_capacity(size as UInt);
  unsafe {
    var i = 0;
    while i < size {
      buf.push(*(ptr.offset(i)));
      i = i + 1;
    }
    xiom_free(ptr);
  }
  Ok(Str::from_utf8(buf))
}

pub fn write_file(path: Str, content: Str) -> Result[Unit, IOError]
  requires: path.len() > 0
  ensures:  result is Ok => file_exists(path)
{
  let file: *UInt8;
  unsafe {
    file = fopen(path.c_str(), "w");
  }
  if file == 0 {
    return Err(IOError{ message: "failed to open file for writing: " + path, code: 2 });
  }
  let c_content = content.c_str();
  let content_len = content.len() as UInt;
  let written: UInt;
  unsafe {
    written = fwrite(c_content, 1 as UInt, content_len, file);
    let _ = fclose(file);
  }
  if written != content_len {
    return Err(IOError{ message: "failed to write all data to: " + path, code: 3 });
  }
  Ok(())
}

pub fn append_file(path: Str, content: Str) -> Result[Unit, IOError]
  requires: path.len() > 0
  ensures:  result is Ok => file_exists(path)
{
  let file: *UInt8;
  unsafe {
    file = fopen(path.c_str(), "a");
  }
  if file == 0 {
    return Err(IOError{ message: "failed to open file for appending: " + path, code: 4 });
  }
  let c_content = content.c_str();
  let content_len = content.len() as UInt;
  let written: UInt;
  unsafe {
    written = fwrite(c_content, 1 as UInt, content_len, file);
    let _ = fclose(file);
  }
  if written != content_len {
    return Err(IOError{ message: "failed to write all data to: " + path, code: 5 });
  }
  Ok(())
}

pub fn file_exists(path: Str) -> Bool
  requires: path.len() > 0
{
  let file: *UInt8;
  unsafe {
    file = fopen(path.c_str(), "r");
  }
  if file == 0 {
    return false;
  }
  unsafe {
    let _ = fclose(file);
  }
  true
}

pub fn is_dir(path: Str) -> Bool
  requires: path.len() > 0
{
  let result: Int32;
  unsafe {
    result = xiom_stat_is_dir(path.c_str());
  }
  result != 0
}

pub fn create_dir(path: Str) -> Result[Unit, IOError]
  requires: path.len() > 0
  requires: !file_exists(path)
  ensures:  result is Ok => is_dir(path)
{
  let rc: Int32;
  unsafe {
    rc = mkdir(path.c_str());
  }
  if rc != 0 {
    return Err(IOError{ message: "failed to create directory: " + path, code: 6 });
  }
  Ok(())
}

pub fn list_dir(path: Str) -> Result[Vec[Str], IOError]
  requires: path.len() > 0
  requires: is_dir(path)
  ensures:  result is Ok => result.len() >= 0
{
  let dir: *UInt8;
  unsafe {
    dir = opendir(path.c_str());
  }
  if dir == 0 {
    return Err(IOError{ message: "failed to open directory: " + path, code: 7 });
  }
  var entries: Vec[Str] = Vec[Str]::new();
  var entry: *UInt8;
  unsafe {
    entry = readdir(dir);
  }
  while entry != 0 {
    let name_ptr: *UInt8;
    unsafe {
      name_ptr = xiom_dirent_name(entry);
    }
    let name = Str::from_c_str(name_ptr);
    if name != "." && name != ".." {
      entries.push(name);
    }
    unsafe {
      entry = readdir(dir);
    }
  }
  unsafe {
    let _ = closedir(dir);
  }
  Ok(entries)
}

pub fn remove_file(path: Str) -> Result[Unit, IOError]
  requires: path.len() > 0
  ensures:  result is Ok => !file_exists(path)
{
  let rc: Int32;
  unsafe {
    rc = remove(path.c_str());
  }
  if rc != 0 {
    return Err(IOError{ message: "failed to remove file: " + path, code: 8 });
  }
  Ok(())
}

pub fn copy_file(src: Str, dst: Str) -> Result[Unit, IOError]
  requires: src.len() > 0
  requires: dst.len() > 0
  requires: src != dst
  requires: file_exists(src)
  ensures:  result is Ok => file_exists(dst)
{
  let content = read_file(src)?;
  write_file(dst, content)
}

pub fn rename(src: Str, dst: Str) -> Result[Unit, IOError]
  requires: src.len() > 0
  requires: dst.len() > 0
  ensures:  result is Ok => !file_exists(src) && file_exists(dst)
{
  let rc: Int32;
  unsafe {
    rc = rename(src.c_str(), dst.c_str());
  }
  if rc != 0 {
    return Err(IOError{ message: "failed to rename " + src + " to " + dst, code: 9 });
  }
  Ok(())
}

// === Process ===
pub fn exit(code: Int)
  requires: code >= 0
{
  unsafe {
    exit(code as Int32);
  }
}

pub fn args() -> Vec[Str] {
  let argc: Int;
  unsafe {
    argc = xiom_get_argc();
  }
  var result: Vec[Str] = Vec[Str]::with_capacity(argc as UInt);
  var i = 0;
  while i < argc {
    let arg_ptr: *UInt8;
    unsafe {
      arg_ptr = xiom_get_argv(i);
    }
    result.push(Str::from_c_str(arg_ptr));
    i = i + 1;
  }
  result
}

pub fn env_var(name: Str) -> Option[Str]
  requires: name.len() > 0
{
  let ptr: *UInt8;
  unsafe {
    ptr = getenv(name.c_str());
  }
  if ptr == 0 {
    return None;
  }
  Some(Str::from_c_str(ptr))
}

// === Time ===
pub fn time_now() -> Int {
  unsafe {
    time(0)
  }
}

pub fn sleep(ms: Int) {
  unsafe {
    usleep((ms as UInt) * 1000 as UInt);
  }
}

// === Read / Write / Seek traits ===
pub interface Read {
  fn read(self, buf: &mut Vec[UInt8]) -> Result[Int, IOError];
  fn read_to_end(self, buf: &mut Vec[UInt8]) -> Result[Int, IOError];
  fn read_to_string(self) -> Result[Str, IOError];
  fn read_exact(self, buf: &mut Vec[UInt8]) -> Result[Unit, IOError];
}

pub interface Write {
  fn write(self, buf: &Vec[UInt8]) -> Result[Int, IOError];
  fn write_all(self, buf: &Vec[UInt8]) -> Result[Unit, IOError];
  fn flush(self) -> Result[Unit, IOError];
}

pub interface Seek {
  fn seek(self, pos: SeekFrom) -> Result[Int, IOError];
  fn stream_position(self) -> Result[Int, IOError];
}

// === Buffered I/O ===
pub type BufReader = {
  inner: Int;
  buf: Vec[UInt8];
  invariant: inner >= 0;
}

pub fn BufReader.new(reader: Int) -> BufReader {
  var buf: Vec[UInt8] = Vec[UInt8]::with_capacity(4096);
  BufReader{ inner: reader; buf: buf; }
}

pub fn BufReader.read_line(self, buf: &mut Str) -> Result[Int, IOError]
  requires: inner >= 0
  ensures:  result is Ok => result >= 0
{
  var temp: Vec[UInt8] = Vec[UInt8]::with_capacity(1024);
  var found_nl = false;
  var total: Int = 0;
  while !found_nl {
    var byte_buf: Vec[UInt8] = Vec[UInt8]::with_capacity(1);
    let nread: UInt;
    unsafe {
      nread = fread(byte_buf.as_mut_ptr(), 1 as UInt, 1 as UInt, self.inner as *UInt8);
    }
    if nread == 0 {
      break;
    }
    let b = byte_buf[0];
    if b == 10 {
      found_nl = true;
    } else {
      temp.push(b);
      total = total + 1;
    }
  }
  *buf = Str::from_utf8(temp);
  Ok(total)
}

pub fn BufReader.lines(self) -> Vec[Str] {
  var result: Vec[Str] = Vec[Str]::new();
  var raw: Vec[UInt8] = Vec[UInt8]::with_capacity(4096);
  let nread: UInt;
  unsafe {
    nread = fread(raw.as_mut_ptr(), 1 as UInt, 4096 as UInt, self.inner as *UInt8);
  }
  var i: UInt = 0;
  var line_start: UInt = 0;
  while i < nread {
    if raw[i as Int] == 10 {
      var line_bytes: Vec[UInt8] = Vec[UInt8]::with_capacity((i - line_start) as UInt);
      var j = line_start;
      while j < i {
        line_bytes.push(raw[j as Int]);
        j = j + 1;
      }
      result.push(Str::from_utf8(line_bytes));
      line_start = i + 1;
    }
    i = i + 1;
  }
  if line_start < nread {
    var line_bytes: Vec[UInt8] = Vec[UInt8]::with_capacity((nread - line_start) as UInt);
    var j = line_start;
    while j < nread {
      line_bytes.push(raw[j as Int]);
      j = j + 1;
    }
    result.push(Str::from_utf8(line_bytes));
  }
  result
}

pub type BufWriter = { inner: Int; buf: Vec[UInt8]; }

pub fn BufWriter.new(writer: Int) -> BufWriter {
  var buf: Vec[UInt8] = Vec[UInt8]::with_capacity(4096);
  BufWriter{ inner: writer; buf: buf; }
}

// === File metadata ===
pub type Metadata = {
  size: Int;
  is_file: Bool;
  is_dir: Bool;
  modified: Int;
  created: Int;
  permissions: Int;
}

pub fn metadata(path: Str) -> Result[Metadata, IOError]
  requires: path.len() > 0
  ensures:  result is Ok => result.size >= 0
{
  let c_path = path.c_str();
  let is_f: Int32;
  let is_d: Int32;
  let sz: Int;
  let mt: Int;
  let ct: Int;
  let mode: Int;
  unsafe {
    is_f = xiom_stat_is_file(c_path);
    is_d = xiom_stat_is_dir(c_path);
    sz = xiom_stat_size(c_path);
    mt = xiom_stat_mtime(c_path);
    ct = xiom_stat_ctime(c_path);
    mode = xiom_stat_mode(c_path);
  }
  if is_f == 0 && is_d == 0 {
    return Err(IOError{ message: "failed to stat: " + path, code: 10 });
  }
  Ok(Metadata{
    size: sz;
    is_file: is_f != 0;
    is_dir: is_d != 0;
    modified: mt;
    created: ct;
    permissions: mode;
  })
}

pub fn set_permissions(path: Str, perm: Int) -> Result[Unit, IOError]
  requires: path.len() > 0
  requires: perm >= 0
{
  let rc: Int32;
  unsafe {
    rc = chmod(path.c_str(), perm as Int32);
  }
  if rc != 0 {
    return Err(IOError{ message: "failed to set permissions: " + path, code: 11 });
  }
  Ok(())
}

// === Standard streams ===
pub fn stdin() -> Int
  ensures: result >= 0
{
  0
}

pub fn stdout() -> Int
  ensures: result >= 0
{
  1
}

pub fn stderr() -> Int
  ensures: result >= 0
{
  2
}

fn print_line(s: Str) {
  unsafe {
    puts(s.c_str());
  }
}

// === Memory I/O ===
pub type Cursor = {
  data: Vec[UInt8];
  pos: Int;
  invariant: pos >= 0;
  invariant: pos <= data.len();
}

pub fn Cursor.new(data: Vec[UInt8]) -> Cursor
  ensures: self.pos == 0
{
  Cursor{ data: data; pos: 0; }
}

pub fn Cursor.into_inner(self) -> Vec[UInt8] {
  self.data
}

// === Path operations ===
pub fn join_paths(base: Str, child: Str) -> Str {
  if base.is_empty() {
    return child;
  }
  if child.is_empty() {
    return base;
  }
  let base_ends_sep = base.byte_at(base.len() - 1) == 47;
  let child_starts_sep = child.byte_at(0) == 47;
  if base_ends_sep && child_starts_sep {
    base + child.substr(1, child.len())
  } elif base_ends_sep || child_starts_sep {
    base + child
  } else {
    base + "/" + child
  }
}

pub fn parent_path(path: Str) -> Option[Str] {
  var i = path.len() - 1;
  while i >= 0 {
    if path.byte_at(i) == 47 {
      if i == 0 {
        return Some("/");
      }
      return Some(path.substr(0, i));
    }
    i = i - 1;
  }
  None
}

pub fn file_name(path: Str) -> Option[Str] {
  if path.is_empty() {
    return None;
  }
  var i = path.len() - 1;
  while i >= 0 {
    if path.byte_at(i) == 47 {
      if i == path.len() - 1 {
        return None;
      }
      return Some(path.substr(i + 1, path.len()));
    }
    i = i - 1;
  }
  Some(path)
}

pub fn extension(path: Str) -> Option[Str] {
  let name = file_name(path)?;
  if name == "." || name == ".." {
    return None;
  }
  var i = name.len() - 1;
  while i >= 0 {
    if name.byte_at(i) == 46 {
      if i == 0 || i == name.len() - 1 {
        return None;
      }
      return Some(name.substr(i + 1, name.len()));
    }
    i = i - 1;
  }
  None
}

pub fn is_absolute(path: Str) -> Bool {
  if path.is_empty() {
    return false;
  }
  path.byte_at(0) == 47
}
