// XIOM stdlib stress -- io.list_dir returns files
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Creates a directory with files, lists contents, verifies count.
// Returns 0 on success. Uses the system temp dir so the test is identical
// on Windows and POSIX runners (relative dirs depend on the worker CWD).
//
// Tags: list_dir (Err from io.list_dir), count (< 2 entries), create_dir,
// write1, write2.

module smoke_stress_io_list_dir
use xiom.io;
use xiom.io.fs;

fn main() -> Int {
  let dir = fs.fs_temp_dir() + "/__smk_listdir";
  let cd = io.create_dir(dir);
  if cd.is_err && !fs.fs_is_dir(dir) {
    io.println("create_dir");
    return 3;
  }
  let w1 = io.write_file(dir + "/f1.txt", "a");
  if w1.is_err {
    io.println("write1");
    return 4;
  }
  let w2 = io.write_file(dir + "/f2.txt", "b");
  if w2.is_err {
    io.println("write2");
    return 5;
  }
  let ls = io.list_dir(dir);
  io.remove_file(dir + "/f1.txt");
  io.remove_file(dir + "/f2.txt");
  io.remove_file(dir);
  match ls {
    Ok(files) => {
      if files.len() >= 2 { return 0; } else { io.println("count"); return 1; }
    }
    Err(_) => { io.println("list_dir"); return 2; }
  }
}