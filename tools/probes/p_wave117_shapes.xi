// p_wave117_shapes.xi -- wave 117 lock: durability P5 pairs
// (append_line_sync, file_last_byte / ends_with_newline, remove_dir,
// truncate_fd).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the landed primitives:
//   * io.append_line_sync creates and appends newline-terminated lines and
//     repairs a torn tail (a nonempty file not ending in '\n' gets one
//     first) with an fsync before returning;
//   * io.file_last_byte -> Some(last byte) / None (empty or missing);
//   * io.ends_with_newline -> true only for a '\n' tail (false for
//     empty/missing/non-newline);
//   * io.remove_dir removes an empty directory (dir_exists false after);
//   * sync_io.truncate_fd shrinks a held fd's file.
// Every returned value is bound before comparing. Returns 0 when all
// cases hold. Red pre-fix (surface absent), green post.

module p_wave117_shapes

use xiom.io;
use xiom.os.sync_io;

fn main() -> Int {
  let f1 = "p_wave117_f1.tmp";
  let f2 = "p_wave117_f2.tmp";
  let f3 = "p_wave117_f3.tmp";
  let f4 = "p_wave117_f4.tmp";
  let f6 = "p_wave117_f6.tmp";
  let d1 = "p_wave117_d";

  // fresh state (probe CWD is the repo root)
  var empty = Vec[UInt8].new();
  let pre1 = io.write_file_bytes(f1, &empty);
  match pre1 { Ok(_) => {}, Err(_) => { return 1; } };
  let pre2 = io.write_file_bytes(f2, &empty);
  match pre2 { Ok(_) => {}, Err(_) => { return 1; } };
  let pre3 = io.write_file_bytes(f4, &empty);
  match pre3 { Ok(_) => {}, Err(_) => { return 1; } };
  let pre4 = io.write_file_bytes(f6, &empty);
  match pre4 { Ok(_) => {}, Err(_) => { return 1; } };
  let prm = io.remove_file("p_wave117_f5.tmp");
  let _ = prm;

  // ---- 1. append_line_sync: create + append two lines -------------------
  let a1 = io.append_line_sync(f1, "l1");
  match a1 { Ok(_) => {}, Err(_) => { return 2; } };
  let a2 = io.append_line_sync(f1, "l2");
  match a2 { Ok(_) => {}, Err(_) => { return 2; } };
  let r1 = io.read_file_bytes(f1);
  match r1 {
    Ok(v) => {
      if v.len() != 6 { return 2; }
      if v[0] != (108 as UInt8) { return 2; }
      if v[1] != (49 as UInt8) { return 2; }
      if v[2] != (10 as UInt8) { return 2; }
      if v[3] != (108 as UInt8) { return 2; }
      if v[4] != (50 as UInt8) { return 2; }
      if v[5] != (10 as UInt8) { return 2; }
    },
    Err(_) => { return 2; },
  };

  // ---- 2. torn-tail repair: [65,66] + "x" -> [65,66,10,120,10] ----------
  var torn = Vec[UInt8].new();
  torn.push(65 as UInt8);
  torn.push(66 as UInt8);
  let w1 = io.write_file_bytes(f2, &torn);
  match w1 { Ok(_) => {}, Err(_) => { return 3; } };
  let a3 = io.append_line_sync(f2, "x");
  match a3 { Ok(_) => {}, Err(_) => { return 3; } };
  let r2 = io.read_file_bytes(f2);
  match r2 {
    Ok(v) => {
      if v.len() != 5 { return 3; }
      if v[0] != (65 as UInt8) { return 3; }
      if v[1] != (66 as UInt8) { return 3; }
      if v[2] != (10 as UInt8) { return 3; }
      if v[3] != (120 as UInt8) { return 3; }
      if v[4] != (10 as UInt8) { return 3; }
    },
    Err(_) => { return 3; },
  };

  // ---- 3. file_last_byte / ends_with_newline ----------------------------
  let lb1 = io.file_last_byte(f1);
  match lb1 {
    Some(b) => { if b != (10 as UInt8) { return 4; } },
    None => { return 4; },
  };
  let e1 = io.ends_with_newline(f1);
  if !e1 { return 4; }

  var nb = Vec[UInt8].new();
  nb.push(7 as UInt8);
  nb.push(8 as UInt8);
  let w2 = io.write_file_bytes(f3, &nb);
  match w2 { Ok(_) => {}, Err(_) => { return 4; } };
  let lb3 = io.file_last_byte(f3);
  match lb3 {
    Some(b) => { if b != (8 as UInt8) { return 4; } },
    None => { return 4; },
  };
  let e3 = io.ends_with_newline(f3);
  if e3 { return 4; }

  let lb4 = io.file_last_byte(f4); // empty file
  match lb4 {
    Some(_) => { return 4; },
    None => {},
  };
  let e4 = io.ends_with_newline(f4);
  if e4 { return 4; }

  let lb5 = io.file_last_byte("p_wave117_f5.tmp"); // missing file
  match lb5 {
    Some(_) => { return 4; },
    None => {},
  };
  let e5 = io.ends_with_newline("p_wave117_f5.tmp");
  if e5 { return 4; }

  // ---- 4. remove_dir -----------------------------------------------------
  let dc = io.create_dir(d1);
  match dc {
    Ok(_) => {},
    Err(_) => {
      if !io.dir_exists(d1) { return 5; }
    },
  };
  let dr = io.remove_dir(d1);
  match dr {
    Ok(_) => {},
    Err(_) => { return 5; },
  };
  if io.dir_exists(d1) { return 5; }

  // ---- 5. truncate_fd ----------------------------------------------------
  let h = sync_io.open_append(f6);
  match h {
    Ok(fd) => {
      var blk = Vec[UInt8].new();
      blk.push(1 as UInt8);
      blk.push(2 as UInt8);
      blk.push(3 as UInt8);
      blk.push(4 as UInt8);
      let wa = sync_io.write_all(fd, &blk);
      match wa { Ok(_) => {}, Err(_) => { return 6; } };
      let tf = sync_io.truncate_fd(fd, 2);
      match tf { Ok(_) => {}, Err(_) => { return 6; } };
      let cf = sync_io.close_fd(fd);
      match cf { Ok(_) => {}, Err(_) => { return 6; } };
    },
    Err(_) => { return 6; },
  };
  let r6 = io.read_file_bytes(f6);
  match r6 {
    Ok(v) => {
      if v.len() != 2 { return 6; }
      if v[0] != (1 as UInt8) { return 6; }
      if v[1] != (2 as UInt8) { return 6; }
    },
    Err(_) => { return 6; },
  };

  // ---- cleanup -----------------------------------------------------------
  let d2 = io.remove_file(f1);
  let d3 = io.remove_file(f2);
  let d4 = io.remove_file(f3);
  let d5 = io.remove_file(f4);
  let d6 = io.remove_file(f6);
  let _ = d2;
  let _ = d3;
  let _ = d4;
  let _ = d5;
  let _ = d6;

  return 0;
}
