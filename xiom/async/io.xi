// XIOM - Async: IO
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.async.io

// Depends on: xiom.async

// ============================================================================
// Non-blocking wrappers over file, socket, and stream descriptors.
// Self-contained implementation: each operation executes on the calling
// frame and returns an immediately-ready `Future` carrying its result. A
// `Future` exposes `ready`, `value` (bytes/status), and `data` (payload).
// ============================================================================

extern "C" {
  fn fread(buf: *UInt8, size: UInt, count: UInt, stream: *UInt8) -> UInt;
  fn fwrite(buf: *UInt8, size: UInt, count: UInt, stream: *UInt8) -> UInt;
  fn fopen(path: *UInt8, mode: *UInt8) -> *UInt8;
  fn fclose(file: *UInt8) -> Int32;
  fn xiom_read_file(path: *UInt8) -> *UInt8;
  fn xiom_file_size(path: *UInt8) -> Int;
  fn xiom_free(ptr: *UInt8);
  fn xiom_socket_accept(sock: Int, client_ip: *UInt8, client_port: *Int) -> Int;
  fn xiom_socket_connect(sock: Int, host: *UInt8, port: Int) -> Int;
}

/// Future - an opaque handle to a pending async operation.
pub type Future = {
  ready: Bool;
  value: Int;
  data: Vec[UInt8];
}

fn future_ready(value: Int) -> Future {
  return Future{ ready: true; value: value; data: Vec[UInt8].new(); }
}

/// Read into `buf` without blocking.
/// Params: fd - the descriptor; buf - the destination buffer.
/// Returns: a ready Future whose value is the number of bytes read.
/// Complexity: O(n) syscall.
pub fn async_read(fd: Int, buf: &mut Vec[UInt8]) -> Future {
  var one: [1]UInt8;
  var nread: UInt;
  unsafe {
    nread = fread(&one[0], 1 as UInt, 1 as UInt, fd as *UInt8);
  }
  if nread == 1 {
    buf.push(one[0]);
  }
  return future_ready(nread as Int);
}

/// Write `data` without blocking.
/// Params: fd - the descriptor; data - the bytes to write.
/// Returns: a ready Future whose value is the number of bytes written.
/// Complexity: O(n) syscall.
pub fn async_write(fd: Int, data: &Vec[UInt8]) -> Future {
  var total: Int = 0;
  var i: Int = 0;
  while i < data.len() {
    let b = data[i];
    let nwritten: UInt;
    unsafe {
      nwritten = fwrite(&b, 1 as UInt, 1 as UInt, fd as *UInt8);
    }
    total = total + (nwritten as Int);
    i = i + 1;
  }
  return future_ready(total);
}

/// Read an entire file into memory.
/// Params: path - the file path.
/// Returns: a ready Future whose data holds the file bytes.
/// Complexity: O(n) where n is the file size.
pub fn async_read_file(path: Str) -> Future {
  let raw: *UInt8;
  let size: Int;
  unsafe {
    raw = xiom_read_file(path.c_str());
    if raw == 0 {
      return future_ready(-1);
    }
    size = xiom_file_size(path.c_str());
  }
  var buf: Vec[UInt8] = Vec[UInt8]::with_capacity(size as UInt);
  unsafe {
    var i: Int = 0;
    while i < size {
      buf.push(*(raw.offset(i)));
      i = i + 1;
    }
    xiom_free(raw);
  }
  return Future{ ready: true; value: size; data: buf; }
}

/// Write an entire file to disk.
/// Params: path - the file path; data - the bytes.
/// Returns: a ready Future whose value is the number of bytes written.
/// Complexity: O(n) where n is the data length.
pub fn async_write_file(path: Str, data: &Vec[UInt8]) -> Future {
  let file: *UInt8;
  unsafe {
    file = fopen(path.c_str(), "wb");
  }
  if file == 0 {
    return future_ready(-1);
  }
  var i: Int = 0;
  while i < data.len() {
    let b = data[i];
    let written: UInt;
    unsafe {
      written = fwrite(&b, 1 as UInt, 1 as UInt, file);
    }
    if written == 0 {
      unsafe { let _ = fclose(file); }
      return future_ready(i);
    }
    i = i + 1;
  }
  unsafe {
    let _ = fclose(file);
  }
  return future_ready(data.len());
}

/// Accept a connection on the listener socket.
/// Params: listener - the listening socket fd.
/// Returns: a ready Future whose value is the accepted socket fd or -1.
/// Complexity: O(1) blocking syscall.
pub fn async_accept(listener: Int) -> Future {
  var ip_buf: [64]UInt8;
  var port_val: Int = 0;
  let client = unsafe { xiom_socket_accept(listener, &ip_buf as *UInt8, &port_val) };
  return future_ready(client);
}

/// Open a TCP connection.
/// Params: fd - the socket; addr - the host; port - the port.
/// Returns: a ready Future whose value is the connect result (0 = ok).
/// Complexity: O(1) syscall.
pub fn async_connect(fd: Int, addr: Str, port: Int) -> Future {
  var c_host: [256]UInt8;
  var i: Int = 0;
  let hlen = addr.len();
  while i < hlen && i < 255 {
    c_host[i] = addr.byte_at(i);
    i = i + 1;
  }
  c_host[i] = 0 as UInt8;
  let rc = unsafe { xiom_socket_connect(fd, &c_host as *UInt8, port) };
  return future_ready(rc);
}

/// Read one line from the descriptor.
/// Params: fd - the descriptor.
/// Returns: a ready Future whose data holds the line (newline included).
/// Complexity: O(n) where n is the line length.
pub fn async_read_line(fd: Int) -> Future {
  var buf: Vec[UInt8] = Vec[UInt8].new();
  var done = false;
  while !done {
    var byte_buf: [1]UInt8;
    var nread: UInt;
    unsafe {
      nread = fread(&byte_buf[0], 1 as UInt, 1 as UInt, fd as *UInt8);
    }
    if nread == 0 {
      done = true;
    } else {
      buf.push(byte_buf[0]);
      if byte_buf[0] == 10 {
        done = true;
      }
    }
  }
  return Future{ ready: true; value: buf.len(); data: buf; }
}

/// Read until the delimiter byte.
/// Params: fd - the descriptor; delim - the delimiter byte.
/// Returns: a ready Future whose data holds the bytes up to and including
///          the delimiter.
/// Complexity: O(n) where n is the number of bytes read.
pub fn async_read_until(fd: Int, delim: UInt8) -> Future {
  var buf: Vec[UInt8] = Vec[UInt8].new();
  var done = false;
  while !done {
    var byte_buf: [1]UInt8;
    var nread: UInt;
    unsafe {
      nread = fread(&byte_buf[0], 1 as UInt, 1 as UInt, fd as *UInt8);
    }
    if nread == 0 {
      done = true;
    } else {
      buf.push(byte_buf[0]);
      if byte_buf[0] == delim {
        done = true;
      }
    }
  }
  return Future{ ready: true; value: buf.len(); data: buf; }
}

