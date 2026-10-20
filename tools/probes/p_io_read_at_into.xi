// p_io_read_at_into.xi -- caller-buffer page reader (m375 workaround).
// Verifies the returned count, byte contents, clamp-at-EOF, and buffer
// reuse without a fresh Vec per call. Expected rc 0.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_io_read_at_into

use xiom.io;

fn main() -> Int {
  let path = "__probe_read_at_into.bin";
  let _ = remove_file(path);

  var data = Vec[UInt8].new();
  var i = 0;
  while i < 10 {
    data.push((i + 1) as UInt8);
    i = i + 1;
  };
  match write_file_bytes(path, &data) {
    Ok(_) => {},
    Err(_) => { return 1; },
  };

  var buf = Vec[UInt8]::with_capacity(32 as UInt);

  let n1 = match read_at_into(path, 2, &mut buf, 4) {
    Ok(n) => n,
    Err(_) => { let _ = remove_file(path); return 2; },
  };
  if n1 != 4 || buf.len() != 4 { let _ = remove_file(path); return 3; }
  if buf[0] != (3 as UInt8) || buf[3] != (6 as UInt8) { let _ = remove_file(path); return 4; }

  let n2 = match read_at_into(path, 8, &mut buf, 100) {
    Ok(n) => n,
    Err(_) => { let _ = remove_file(path); return 5; },
  };
  if n2 != 2 || buf.len() != 2 { let _ = remove_file(path); return 6; }
  if buf[0] != (9 as UInt8) || buf[1] != (10 as UInt8) { let _ = remove_file(path); return 7; }

  let n3 = match read_at_into(path, 100, &mut buf, 5) {
    Ok(n) => n,
    Err(_) => { let _ = remove_file(path); return 8; },
  };
  if n3 != 0 || buf.len() != 0 { let _ = remove_file(path); return 9; }

  let n4 = match read_at_into(path, 0, &mut buf, 0) {
    Ok(n) => n,
    Err(_) => { let _ = remove_file(path); return 10; },
  };
  if n4 != 0 || buf.len() != 0 { let _ = remove_file(path); return 11; }

  let _ = remove_file(path);
  return 0;
}
