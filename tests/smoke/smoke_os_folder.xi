// XIOM stdlib smoke test -- xiom.os.fs, xiom.os.proc, xiom.os.term
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_os_folder
use xiom.os.fs;
use xiom.os.proc;
use xiom.os.term;
use xiom.os.signal;
use xiom.string;

fn main() -> Int {
  // --- fs_extension ---
  var e1 = xiom.os.fs.fs_extension("a/b.tar.gz");
  if e1.is_none { return 1; }
  if e1.value != "gz" { return 1; }
  var e2 = xiom.os.fs.fs_extension("a/b");
  if e2.is_some { return 1; }

  // --- fs_stem ---
  var s1 = xiom.os.fs.fs_stem("a/b.tar.gz");
  if s1.is_none { return 2; }
  if s1.value != "a/b.tar" { return 2; }

  // --- fs_is_hidden ---
  var h1 = xiom.os.fs.fs_is_hidden(".bashrc");
  if h1 != true { return 3; }
  var h2 = xiom.os.fs.fs_is_hidden("visible.txt");
  if h2 != false { return 3; }

  // --- fs_normalize ---
  var n1 = xiom.os.fs.fs_normalize("a/b/../c//d/./e");
  if n1 != "a/c/d/e" { return 4; }
  var n2 = xiom.os.fs.fs_normalize("/a/b/../c");
  if n2 != "/a/c" { return 4; }

  // --- fs_with_extension ---
  var w1 = xiom.os.fs.fs_with_extension("a/b.txt", "md");
  if w1 != "a/b.md" { return 5; }

  // --- fs_split ---
  var sp = xiom.os.fs.fs_split("/x/y/z.xi");
  if sp.0 != "/x/y" { return 6; }
  if sp.1 != "z.xi" { return 7; }

  // --- fs_unique_path ---
  // Use a fixed unlikely name; if it somehow exists the fn appends " (n)".
  var up = xiom.os.fs.fs_unique_path(".", "_xiom_fs_unique_zz_193847");
  if up.starts_with("./_xiom_fs_unique_zz_193847") != true { return 8; }

  // --- proc ---
  var ok0 = xiom.os.proc.proc_exit_code_success(0);
  if ok0 != true { return 9; }
  var sig9 = xiom.os.proc.proc_signal_name(9);
  if sig9 != "KILL" { return 10; }
  var st5 = xiom.os.proc.proc_status_text(5);
  if st5 != "exit(5)" { return 11; }

  // --- term ---
  var cs = xiom.os.term.term_clear_screen();
  var cs_len = cs.len();
  if cs_len < 2 { return 12; }
  var esc = cs.byte_at(0);
  if esc != 27 { return 13; }
  var reset = xiom.os.term.term_reset();
  var reset_len = reset.len();
  if reset_len == 0 { return 14; }
  var cm = xiom.os.term.term_cursor_move(3, 5);
  var has_rc = string.str_contains(cm, "3;5");
  if has_rc != true { return 15; }

  // --- signal: delivery API (wave 123) ---
  let si = xiom.os.signal.signal_install();
  if si.is_err { return 16; }
  let sp0 = xiom.os.signal.signal_pending();
  match sp0 {
    Ok(v) => { if v != 0 { return 16; } },
    Err(_) => { return 16; },
  };
  let sr = xiom.os.signal.signal_raise(15);
  if sr.is_err { return 17; }
  let sw = xiom.os.signal.signal_wait(1000);
  match sw {
    Ok(v) => { if v != 15 { return 17; } },
    Err(_) => { return 17; },
  };
  let sc = xiom.os.signal.signal_code("SIGINT");
  match sc {
    Some(v) => { if v != 2 { return 18; } },
    None => { return 18; },
  };
  let sn = xiom.os.signal.signal_name(15);
  if sn != "TERM" { return 18; }

  return 0;
}
