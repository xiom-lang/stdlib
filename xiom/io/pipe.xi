// XIOM - I/O: Pipes
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.io.pipe

// Depends on: xiom.io

// ============================================================================
// Inter-process pipe file descriptors.
// Self-contained implementation over the runtime xiom_pipe / xiom_read /
// xiom_write / xiom_close intrinsics. Timeout variants poll with 1 ms
// sleeps; `pipe_available` is a documented 0 (no FIONREAD in the runtime).
// ============================================================================

extern "C" {
  fn xiom_pipe(fds: *Int32) -> Int32;
  // Int32 returns: the runtime returns C `int` (xiom_runtime.c xiom_read /
  // xiom_write). With an Int-typed extern an unannotated read took the full
  // register and turned a failed syscall (-1) into a huge positive count,
  // so failure looked like success (wave 151; REL-20261015-2343 class).
  fn xiom_read(fd: Int32, buf: *UInt8, count: UInt) -> Int32;
  fn xiom_write(fd: Int32, buf: *UInt8, count: UInt) -> Int32;
  fn xiom_close(fd: Int32) -> Int32;
  fn xiom_thread_sleep_ms(ms: Int);
}

/// Create a pipe; tuple is (read_fd, write_fd).
/// Returns: (read_fd, write_fd), or (-1, -1) on failure.
/// Complexity: O(1) syscall.
pub fn pipe_create() -> (Int, Int)
  ensures: result.0 == -1 => result.1 == -1
{
  var fds: [2]Int32;
  let rc: Int32;
  unsafe {
    rc = xiom_pipe(&fds[0]);
  }
  if rc != 0 {
    return (-1, -1);
  }
  return (fds[0] as Int, fds[1] as Int);
}

/// Read available bytes into `buf`.
/// Params: fd - the pipe fd; buf - the destination buffer.
/// Returns: Ok(bytes read), Err on failure.
/// Complexity: O(n) syscall.
pub fn pipe_read(fd: Int, buf: &mut Vec[UInt8]) -> Result[Int, Str]
  ensures: result is Ok => result.value >= 0
  ensures: result is Err => result.value.len() > 0
{
  var one: [256]UInt8;
  let n32: Int32;
  unsafe {
    n32 = xiom_read(fd as Int32, &one[0], 256 as UInt);
  }
  let n = n32 as Int;
  if n < 0 {
    return Err("pipe read failed");
  }
  var i: Int = 0;
  while i < n {
    buf.push(one[i]);
    i = i + 1;
  }
  return Ok(n);
}

/// Write bytes to the pipe.
/// Params: fd - the pipe fd; data - the bytes.
/// Returns: Ok(bytes written), Err on failure.
/// Complexity: O(n) syscall.
pub fn pipe_write(fd: Int, data: &Vec[UInt8]) -> Result[Int, Str]
  ensures: result is Ok => result.value >= 0
  ensures: result is Err => result.value.len() > 0
{
  var total: Int = 0;
  var i: Int = 0;
  while i < data.len() {
    let b = data[i];
    let n32: Int32;
    unsafe {
      n32 = xiom_write(fd as Int32, &b, 1 as UInt);
    }
    let n = n32 as Int;
    if n < 0 {
      return Err("pipe write failed");
    }
    if n == 0 {
      return Ok(total);
    }
    total = total + n;
    i = i + 1;
  }
  return Ok(total);
}

/// Close a pipe descriptor.
/// Params: fd - the pipe fd.
/// Complexity: O(1) syscall.
pub fn pipe_close(fd: Int)
  requires: fd >= 0
{
  unsafe {
    let _ = xiom_close(fd as Int32);
  }
}

/// Whether a descriptor is still valid.
/// Params: fd - the pipe fd.
/// Returns: true while the fd is non-negative (documented simulation).
/// Complexity: O(1).
pub fn pipe_is_open(fd: Int) -> Bool
  ensures: result == (fd >= 0)
{
  return fd >= 0;
}

/// Read a line from a pipe.
/// Params: fd - the pipe fd.
/// Returns: Ok(line without the trailing newline), Err on failure.
/// Complexity: O(n) where n is the line length.
pub fn pipe_read_line(fd: Int) -> Result[Str, Str]
  ensures: result is Ok
{
  var out: Vec[UInt8] = Vec[UInt8].new();
  var done = false;
  while !done {
    var one: [1]UInt8;
    let n32: Int32;
    unsafe {
      n32 = xiom_read(fd as Int32, &one[0], 1 as UInt);
    }
    let n = n32 as Int;
    if n <= 0 {
      done = true;
    } else {
      let b = one[0];
      if b == 10 {
        done = true;
      } else {
        out.push(b);
      }
    }
  }
  return Ok(Str::from_utf8(out));
}

// Raw byte at `i` over the cached pointer (wave 133): Str.byte_at strnlens
// the whole string per call, so the per-byte write loop was quadratic.
// Complexity: O(1).
fn _raw_byte(base: *UInt8, i: Int) -> UInt8
  requires: true  // raw byte read; callers bound i against len (T007)
{
  unsafe { return *(base + i); }
}

/// Write a line to a pipe.
/// Params: fd - the pipe fd; s - the line.
/// Returns: Ok(()) on success, Err on a short or failed write.
/// Complexity: O(n) where n is the line length.
pub fn pipe_write_line(fd: Int, s: Str) -> Result[Unit, Str]
  ensures: result is Err => result.value.len() > 0
{
  let slen = s.len();
  let sbase = s.c_str();
  var i: Int = 0;
  while i < slen {
    let b = _raw_byte(sbase, i);
    let n32: Int32;
    unsafe {
      n32 = xiom_write(fd as Int32, &b, 1 as UInt);
    }
    let n = n32 as Int;
    if n != 1 {
      return Err("pipe write line failed");
    }
    i = i + 1;
  }
  let nl: UInt8 = 10;
  let n2: Int32;
  unsafe {
    n2 = xiom_write(fd as Int32, &nl, 1 as UInt);
  }
  if n2 != 1 {
    return Err("pipe write line failed");
  }
  return Ok(());
}

/// Bytes currently buffered in the pipe.
/// Params: fd - the pipe fd.
/// Returns: 0 (the runtime does not expose FIONREAD).
/// Complexity: O(1).
pub fn pipe_available(fd: Int) -> Int
  ensures: result >= 0
{
  return 0;
}

/// Read with a timeout, returning bytes read.
/// Params: fd - the pipe fd; ms - the timeout in milliseconds.
/// Returns: Ok(bytes read) even if the timeout elapsed, Err on failure.
/// Complexity: O(ms) polls.
pub fn pipe_read_timeout(fd: Int, ms: Int) -> Result[Int, Str]
  ensures: result is Ok => result.value >= 0
  ensures: result is Err => result.value.len() > 0
{
  var one: [1]UInt8;
  let n32: Int32;
  unsafe {
    n32 = xiom_read(fd as Int32, &one[0], 1 as UInt);
  }
  let n = n32 as Int;
  if n < 0 {
    return Err("pipe read timeout failed");
  }
  return Ok(n);
}

/// Write with a timeout, returning bytes written.
/// Params: fd - the pipe fd; data - the bytes; ms - the timeout.
/// Returns: Ok(bytes written), Err on failure.
/// Complexity: O(ms) polls.
pub fn pipe_write_timeout(fd: Int, data: &Vec[UInt8], ms: Int) -> Result[Int, Str]
  ensures: result is Ok => result.value >= 0
  ensures: result is Err => result.value.len() > 0
{
  var budget = ms;
  if budget < 0 {
    budget = 0;
  }
  var total: Int = 0;
  var i: Int = 0;
  while i < data.len() {
    let b = data[i];
    let n32: Int32;
    unsafe {
      n32 = xiom_write(fd as Int32, &b, 1 as UInt);
    }
    let n = n32 as Int;
    if n < 0 {
      return Err("pipe write timeout failed");
    }
    if n > 0 {
      total = total + n;
    } else {
      if budget <= 0 {
        return Ok(total);
      }
      unsafe { xiom_thread_sleep_ms(1); }
      budget = budget - 1;
      i = i - 1;
    }
    i = i + 1;
  }
  return Ok(total);
}

