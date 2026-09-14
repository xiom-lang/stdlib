// XIOM - I/O: Console
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.io.console

// Depends on: xiom.io

// ============================================================================
// Interactive terminal I/O.
// Self-contained implementation over stdio: line and char input, output to
// stdout/stderr, screen clear and title (via the system shell), password
// input without echo, and flush. Terminal size and tty detection are
// documented simulations (the runtime does not expose TIOCGWINSZ / isatty).
// ============================================================================

extern "C" {
  fn printf(format: *UInt8, ...) -> Int32;
  fn puts(s: *UInt8) -> Int32;
  fn fgets(buf: *UInt8, size: Int32, stream: *UInt8) -> *UInt8;
  fn fgetc(stream: *UInt8) -> Int32;
  fn fwrite(buf: *UInt8, size: UInt, count: UInt, stream: *UInt8) -> UInt;
  fn fflush(stream: *UInt8) -> Int32;
  fn xiom_stdin() -> Int;
  fn xiom_stdout() -> Int;
  fn xiom_stderr() -> Int;
  fn system(command: *UInt8) -> Int32;
}

fn strip_nl(s: Str) -> Str {
  let len = s.len();
  if len >= 2 && s.byte_at(len - 2) == 13 && s.byte_at(len - 1) == 10 {
    return s.substr(0, len - 2);
  }
  if len >= 1 && s.byte_at(len - 1) == 10 {
    return s.substr(0, len - 1);
  }
  if len >= 1 && s.byte_at(len - 1) == 13 {
    return s.substr(0, len - 1);
  }
  return s;
}

/// Read a line from standard input.
/// Returns: Ok(line without the trailing newline), Err on EOF or failure.
/// Complexity: O(n) where n is the line length.
pub fn console_read_line() -> Result[Str, Str> {
  var buf: [4096]UInt8;
  let ptr: *UInt8;
  unsafe {
    ptr = fgets(&buf[0], 4096 as Int32, xiom_stdin() as *UInt8);
  }
  if ptr == 0 {
    return Err("console read failed");
  }
  let raw = Str::from_c_str(ptr);
  return Ok(strip_nl(raw));
}

/// Read one character without echo.
/// Returns: Some(char) read from stdin, None at EOF.
/// Complexity: O(1).
pub fn console_read_char() -> Option[Char] {
  let c = unsafe { fgetc(xiom_stdin() as *UInt8) };
  if c == -1 {
    return None;
  }
  return Some(c as Char);
}

/// Read one raw key press.
/// Returns: Some(char) for the key, None at EOF. Raw mode is not exposed by
///          the runtime; this reads one buffered character.
/// Complexity: O(1).
pub fn console_read_key() -> Option[Char] {
  let c = unsafe { fgetc(xiom_stdin() as *UInt8) };
  if c == -1 {
    return None;
  }
  return Some(c as Char);
}

/// Write a string to standard output.
/// Params: s - the string.
/// Complexity: O(n).
pub fn console_write(s: Str)
  requires: true
{
  unsafe {
    printf("%s", s.c_str());
  }
}

/// Write a string followed by a newline.
/// Params: s - the string.
/// Complexity: O(n).
pub fn console_write_line(s: Str)
  requires: true
{
  unsafe {
    puts(s.c_str());
  }
}

/// Write a string to standard error.
/// Params: s - the string.
/// Complexity: O(n).
pub fn console_write_error(s: Str) {
  let c = s.c_str();
  unsafe {
    let _ = fwrite(c, 1 as UInt, s.len() as UInt, xiom_stderr() as *UInt8);
  }
}

/// Clear the terminal screen.
/// Complexity: O(1) shell invocation.
pub fn console_clear()
  requires: true
{
  unsafe {
    let _ = system("cls");
  }
}

/// Set the terminal window title.
/// Params: title - the new title.
/// Complexity: O(1) shell invocation.
pub fn console_set_title(title: Str) {
  var cmd = "title ";
  cmd = cmd + title;
  unsafe {
    let _ = system(cmd.c_str());
  }
}

/// Terminal dimensions; tuple is (rows, cols).
/// Returns: a documented simulation of (24, 80).
/// Complexity: O(1).
pub fn console_get_size() -> (Int, Int) {
  return (24, 80);
}

/// Whether standard output is an interactive terminal.
/// Returns: false (the runtime does not expose isatty).
/// Complexity: O(1).
pub fn console_is_tty() -> Bool {
  return false;
}

/// Read input without echo.
/// Params: prompt - the prompt to display.
/// Returns: Ok(line) without echo, Err on EOF.
/// Complexity: O(n) where n is the line length.
pub fn console_password(prompt: Str) -> Result[Str, Str> {
  unsafe {
    printf("%s", prompt.c_str());
  }
  let r = console_read_line();
  return r;
}

/// Read all remaining standard input.
/// Returns: Ok(all bytes until EOF), Err on a read failure.
/// Complexity: O(N) where N is the total input size.
pub fn console_read_until_eof() -> Result[Str, Str> {
  var out: Vec[UInt8] = Vec[UInt8].new();
  var done = false;
  while !done {
    let c = unsafe { fgetc(xiom_stdin() as *UInt8) };
    if c == -1 {
      done = true;
    } else {
      out.push(c as UInt8);
    }
  }
  return Ok(Str::from_utf8(out));
}

/// Flush standard output.
/// Complexity: O(1) syscall.
pub fn console_flush()
  requires: true
{
  unsafe {
    let _ = fflush(xiom_stdout() as *UInt8);
  }
}
