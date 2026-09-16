// XIOM - I/O: Buffered I/O
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.io.buffer

// Depends on: xiom.io

// ============================================================================
// Buffered readers and writers over raw file descriptors.
// Uses the parent xiom.io BufReader / BufWriter handle types (an fd plus an
// internal Vec[UInt8] buffer). Reader helpers consume from the internal
// buffer first when `br_peek` has staged bytes; writer helpers buffer and
// flush through the fd.
// ============================================================================

use xiom.io;

extern "C" {
  fn fread(buf: *UInt8, size: UInt, count: UInt, stream: *UInt8) -> UInt;
  fn fwrite(buf: *UInt8, size: UInt, count: UInt, stream: *UInt8) -> UInt;
  fn fseek(stream: *UInt8, offset: Int32, whence: Int32) -> Int32;
  fn ftell(stream: *UInt8) -> Int32;
}

// Pop the front byte of a Vec[UInt8].
fn buf_pop_front(b: &mut Vec[UInt8]) -> UInt8 {
  var v = b[0];
  var i: Int = 0;
  while i + 1 < b.len() {
    b[i] = b[i + 1];
    i = i + 1;
  }
  b.pop();
  return v;
}

/// Wrap an fd; BufReader holds the fd and an internal buffer.
/// Params: fd - the file descriptor (FILE* as Int).
/// Returns: a buffered reader over `fd`.
/// Complexity: O(1).
pub fn buf_reader_new(fd: Int) -> BufReader {
  return BufReader{ inner: fd; buf: Vec[UInt8].new(); }
}

/// Read one line through the buffer.
/// Params: r - the reader.
/// Returns: Ok(line without the trailing newline), Err on read failure.
/// Complexity: O(n) where n is the line length.
pub fn br_read_line(r: &mut BufReader) -> Result[Str, Str] {
  var line: Vec[UInt8] = Vec[UInt8].new();
  var done = false;
  while !done {
    var byte: UInt8 = 0;
    var have = false;
    if r.buf.len() > 0 {
      byte = r.buf[0];
      var k: Int = 0;
      while k + 1 < r.buf.len() {
        r.buf[k] = r.buf[k + 1];
        k = k + 1;
      }
      r.buf.pop();
      have = true;
    } else {
      var one: [1]UInt8;
      var nread: UInt;
      unsafe {
        nread = fread(&one[0], 1 as UInt, 1 as UInt, r.inner as *UInt8);
      }
      if nread == 1 {
        byte = one[0];
        have = true;
      }
    }
    if !have {
      done = true;
    } else if byte == 10 {
      done = true;
    } else {
      line.push(byte);
    }
  }
  return Ok(Str::from_utf8(line));
}

/// Read exactly `n` bytes.
/// Params: r - the reader; n - the byte count (clamped to >= 0).
/// Returns: Ok(bytes read; fewer than n only at EOF), Err on read failure.
/// Complexity: O(n).
pub fn br_read_bytes(r: &mut BufReader, n: Int) -> Result[Vec[UInt8], Str> {
  var count = n;
  if count < 0 {
    count = 0;
  }
  var out: Vec[UInt8] = Vec[UInt8]::with_capacity(count as UInt);
  while out.len() < count && r.buf.len() > 0 {
    out.push(r.buf[0]);
    var k: Int = 0;
    while k + 1 < r.buf.len() {
      r.buf[k] = r.buf[k + 1];
      k = k + 1;
    }
    r.buf.pop();
  }
  while out.len() < count {
    var one: [1]UInt8;
    var nread: UInt;
    unsafe {
      nread = fread(&one[0], 1 as UInt, 1 as UInt, r.inner as *UInt8);
    }
    if nread == 0 {
      break;
    }
    out.push(one[0]);
  }
  return Ok(out);
}

/// Read bytes up to a delimiter (inclusive).
/// Params: r - the reader; delim - the delimiter byte.
/// Returns: Ok(bytes including the delimiter), Err on read failure.
/// Complexity: O(n) where n is the number of bytes read.
pub fn br_read_until(r: &mut BufReader, delim: UInt8) -> Result[Vec[UInt8], Str> {
  var out: Vec[UInt8] = Vec[UInt8].new();
  var done = false;
  while !done {
    var byte: UInt8 = 0;
    var have = false;
    if r.buf.len() > 0 {
      byte = r.buf[0];
      var k: Int = 0;
      while k + 1 < r.buf.len() {
        r.buf[k] = r.buf[k + 1];
        k = k + 1;
      }
      r.buf.pop();
      have = true;
    } else {
      var one: [1]UInt8;
      var nread: UInt;
      unsafe {
        nread = fread(&one[0], 1 as UInt, 1 as UInt, r.inner as *UInt8);
      }
      if nread == 1 {
        byte = one[0];
        have = true;
      }
    }
    if !have {
      done = true;
    } else {
      out.push(byte);
      if byte == delim {
        done = true;
      }
    }
  }
  return Ok(out);
}

/// Look ahead `n` bytes without consuming.
/// Params: r - the reader; n - the byte count (clamped to >= 0).
/// Returns: Ok(bytes staged in the internal buffer), Err on read failure.
/// Complexity: O(n).
pub fn br_peek(r: &mut BufReader, n: Int) -> Result[Vec[UInt8], Str> {
  var count = n;
  if count < 0 {
    count = 0;
  }
  while r.buf.len() < count {
    var one: [1]UInt8;
    var nread: UInt;
    unsafe {
      nread = fread(&one[0], 1 as UInt, 1 as UInt, r.inner as *UInt8);
    }
    if nread == 0 {
      break;
    }
    r.buf.push(one[0]);
  }
  var out: Vec[UInt8] = Vec[UInt8]::with_capacity(count as UInt);
  var i: Int = 0;
  while i < count && i < r.buf.len() {
    out.push(r.buf[i]);
    i = i + 1;
  }
  return Ok(out);
}

/// Move the underlying read position.
/// Params: r - the reader; pos - the byte offset from the start.
/// Complexity: O(1) syscall.
pub fn br_seek(r: &mut BufReader, pos: Int)
  requires: pos >= -2147483648 && pos <= 2147483647
  requires: r.inner != 0
{
  unsafe {
    let _ = fseek(r.inner as *UInt8, pos as Int32, 0 as Int32);
  }
}

/// Current read position.
/// Params: r - the reader.
/// Returns: the byte offset of the underlying stream.
/// Complexity: O(1) syscall.
pub fn br_tell(r: &BufReader) -> Int
  requires: r.inner != 0
{
  unsafe { return ftell(r.inner as *UInt8) as Int; }
}

/// Wrap an fd; BufWriter holds the fd and an internal buffer.
/// Params: fd - the file descriptor (FILE* as Int).
/// Returns: a buffered writer over `fd`.
/// Complexity: O(1).
pub fn buf_writer_new(fd: Int) -> BufWriter {
  return BufWriter{ inner: fd; buf: Vec[UInt8].new(); }
}

/// Buffer bytes for writing.
/// Params: w - the writer; data - the bytes to buffer.
/// Returns: Ok(()) on success.
/// Complexity: O(n) where n is the data length.
pub fn bw_write(w: &mut BufWriter, data: &Vec[UInt8]) -> Result[Unit, Str> {
  var i: Int = 0;
  while i < data.len() {
    w.buf.push(data[i]);
    i = i + 1;
  }
  return Ok(());
}

/// Buffer a string for writing.
/// Params: w - the writer; s - the string.
/// Returns: Ok(()) on success.
/// Complexity: O(n) where n is the string length.
pub fn bw_write_str(w: &mut BufWriter, s: Str) -> Result[Unit, Str> {
  var i: Int = 0;
  while i < s.len() {
    w.buf.push(s.byte_at(i));
    i = i + 1;
  }
  return Ok(());
}

/// Flush buffered bytes to the fd.
/// Params: w - the writer.
/// Returns: Ok(()) on success, Err if fewer bytes than buffered were written.
/// Complexity: O(n) where n is the buffer length.
pub fn bw_flush(w: &mut BufWriter) -> Result[Unit, Str> {
  if w.buf.len() == 0 {
    return Ok(());
  }
  var i: Int = 0;
  while i < w.buf.len() {
    let b = w.buf[i];
    let written: UInt;
    unsafe {
      written = fwrite(&b, 1 as UInt, 1 as UInt, w.inner as *UInt8);
    }
    if written == 0 {
      return Err("buffered write failed");
    }
    i = i + 1;
  }
  while w.buf.len() > 0 {
    w.buf.pop();
  }
  return Ok(());
}

/// Flush and return the underlying fd.
/// Params: w - the writer (consumed).
/// Returns: the file descriptor.
/// Complexity: O(n) where n is the buffer length.
pub fn bw_into_inner(w: &mut BufWriter) -> Int {
  let fd = w.inner;
  let r = bw_flush(w);
  return fd;
}

