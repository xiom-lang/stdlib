// p_wave151_shapes.xi -- wave 151 guard: pipe failure semantics on the pin.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the REL-20261015-2343 i32-extern class in xiom/io/pipe.xi after the
// wave-151 fix (xiom_read/xiom_write retyped to Int32 + declared-form
// bindings): a FAILED read/write must be Err -- pre-fix the bare inline
// form read the full register, so -1 (0xFFFFFFFF) looked positive and
// pipe_read/pipe_write/pipe_read_timeout returned Ok with a garbage count.
//
// Rows are deterministic and must never block: failed ops use the wrong
// access direction on live pipe fds (EBADF/EACCES, immediate, no SIGPIPE)
// or a closed fd; EOF is reached by closing the write end. Contract per
// the pipe.xi docs: Ok(bytes read) at EOF (0 bytes), Err on failure.
//
// PLATFORM NOTE (closed-fd rows 18/19): POSIX read/write on a closed fd
// returns -1/EBADF, so those rows run everywhere except Windows. On
// Windows the UCRT itself fast-fails (0xC0000409) inside _read/_write
// before any stdlib code, so the rows are skipped there (detected via
// the Windows-only OS env var); the wrong-direction rows 13-16 still
// cover the failed-read/failed-write Err contract on Windows.
//
// Windows + WSL return 0 when every row holds; each nonzero return names
// the first failing row.

module p_wave151_shapes

use xiom.env;
use xiom.io.pipe;

fn bytes(s: Str) -> Vec[UInt8] {
  var out: Vec[UInt8] = Vec[UInt8].with_capacity(s.len() as UInt);
  var i: Int = 0;
  while i < s.len() {
    out.push(s.byte_at(i));
    i = i + 1;
  }
  return out;
}

fn main() -> Int {
  let fds = pipe.pipe_create();
  if fds.0 < 0 || fds.1 < 0 { return 1; }

  // Happy path (retype regression guard): write "ab", read it back.
  let w = pipe.pipe_write(fds.1, bytes("ab"));
  match w {
    Ok(n) => { if n != 2 { return 2; } }
    Err(_) => { return 3; }
  }
  var buf: Vec[UInt8] = Vec[UInt8].new();
  let r = pipe.pipe_read(fds.0, &mut buf);
  match r {
    Ok(n) => { if n != 2 { return 4; } }
    Err(_) => { return 5; }
  }
  if buf.len() != 2 { return 6; }
  if buf[0] != 97 as UInt8 { return 7; }
  if buf[1] != 98 as UInt8 { return 8; }

  // Read-timeout happy row.
  let w2 = pipe.pipe_write(fds.1, bytes("x"));
  match w2 {
    Ok(n) => { if n != 1 { return 9; } }
    Err(_) => { return 10; }
  }
  let rt = pipe.pipe_read_timeout(fds.0, 5);
  match rt {
    Ok(n) => { if n != 1 { return 11; } }
    Err(_) => { return 12; }
  }

  // Wrong-direction FAILED rows on live fds (both ends open, buffer
  // empty): read from the write end / write to the read end must be Err.
  // Pre-fix these returned Ok(huge positive garbage).
  var fbuf: Vec[UInt8] = Vec[UInt8].new();
  let bad_read = pipe.pipe_read(fds.1, &mut fbuf);
  if bad_read.is_ok { return 13; }
  let bad_read_to = pipe.pipe_read_timeout(fds.1, 5);
  if bad_read_to.is_ok { return 14; }
  let bad_write = pipe.pipe_write(fds.0, bytes("q"));
  if bad_write.is_ok { return 15; }
  let bad_write_to = pipe.pipe_write_timeout(fds.0, bytes("q"), 0);
  if bad_write_to.is_ok { return 16; }

  // EOF: close the write end; the documented contract is Ok(bytes read)
  // -- an immediate 0, not a failure and never a garbage count. Err is
  // accepted only as the alternative per the wave-151 task note.
  pipe.pipe_close(fds.1);
  var ebuf: Vec[UInt8] = Vec[UInt8].new();
  let eof = pipe.pipe_read(fds.0, &mut ebuf);
  match eof {
    Ok(n) => { if n != 0 { return 17; } }
    Err(_) => { }
  }

  // Closed-fd FAILED rows (POSIX only; see the platform note above).
  var on_windows = false;
  let osv = env.var_opt("OS");
  match osv {
    Some(v) => { if v == "Windows_NT" { on_windows = true; } }
    None => { }
  }
  if !on_windows {
    pipe.pipe_close(fds.0);
    var cbuf: Vec[UInt8] = Vec[UInt8].new();
    let closed_read = pipe.pipe_read(fds.0, &mut cbuf);
    if closed_read.is_ok { return 18; }
    let closed_write = pipe.pipe_write(fds.0, bytes("q"));
    if closed_write.is_ok { return 19; }
  } else {
    pipe.pipe_close(fds.0);
  }

  return 0;
}
