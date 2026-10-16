// p_wave171_shapes.xi -- wave 171 lock: the POSIX (Linux/inotify) leg of
// xiom.os.watch (REL-20261016-1129-xvector item 2; the block-216 finding
// "watch_dir returns Ok on Linux" was the flat xiom.os polling facade, not
// this module). The Windows leg is re-verified alongside (wave-124 shape).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Platform branch: plat.platform_is_windows()/platform_is_linux() (runtime
// probes, so the branch is truthful on every target).
// Windows rows: open + empty timeout, create/modify/remove roundtrip,
// closed-handle Err, recursive subdir event, missing-dir Err (mirrors
// p_wave124_shapes).
// Linux rows: the real inotify leg -- open + empty timeout, create,
// modify, attrib (chmod), moved-to (rename), delete, closed-handle Err,
// recursive pre-existing subtree, directory attached on demand, close,
// missing-dir Err, non-directory Err. Extra coalesced events are fine:
// every row scans its batch for the expected kind + path suffix.
// Other POSIX (darwin/BSD): kqueue is still a documented Err; the Err
// surface is asserted so a future kqueue leg re-remembers this lock.
// Every returned value is bound before comparing. Returns 0 when all rows
// hold; a nonzero return names the first failing row; 20 = fixture setup
// failed. RED-BEFORE (WSL, official pin): watch_dir is Err on Linux, so
// row 9 fires (documented-Err era). Green post: Windows + WSL.
// WSL2 note: run this probe with a CWD on a Linux-native filesystem --
// /mnt/* (drvfs/9p) delivers no inotify events for changes made through
// the 9p client, so a repo-CWD WSL run is silent by design (the runtime
// is correct; the mount reports nothing). The lane compiles here and
// runs from /tmp/w171run.

module p_wave171_shapes

use xiom.os.watch;
use xiom.os.platform as plat;
use xiom.io;

fn main() -> Int {
  // --- row 1: pure kind names ---
  if watch.watch_kind_name(1) != "create" { return 1; }
  if watch.watch_kind_name(2) != "modify" { return 1; }
  if watch.watch_kind_name(3) != "remove" { return 1; }
  if watch.watch_kind_name(4) != "rename" { return 1; }
  if watch.watch_kind_name(5) != "overflow" { return 1; }
  if watch.watch_kind_name(0) != "unknown" { return 1; }

  let is_win = plat.platform_is_windows();
  let is_linux = plat.platform_is_linux();

  // --- shared fixture truncate-first (leftovers from either platform run) ---
  let _ = io.remove_file("p_wave171_dir/a.txt");
  let _ = io.remove_file("p_wave171_dir/c1.txt");
  let _ = io.remove_file("p_wave171_dir/m1.txt");
  let _ = io.remove_file("p_wave171_dir/t1.txt");
  let _ = io.remove_file("p_wave171_dir/v1.txt");
  let _ = io.remove_file("p_wave171_dir/w1.txt");
  let _ = io.remove_file("p_wave171_dir/r1.txt");
  let _ = io.remove_file("p_wave171_dir/sub/b.txt");
  let _ = io.remove_file("p_wave171_dir/sub/p1.txt");
  let _ = io.remove_file("p_wave171_dir/sub2/n1.txt");
  let _ = io.remove_dir("p_wave171_dir/sub");
  let _ = io.remove_dir("p_wave171_dir/sub2");
  let _ = io.remove_dir("p_wave171_dir");

  if is_win {
    // --- Windows: wave-124 shape re-verified ---
    match io.create_dir("p_wave171_dir") {
      Ok(_) => {},
      Err(_) => { return 20; },
    };

    // row 2: open + empty timeout
    let hd = watch.watch_dir("p_wave171_dir", false);
    let h: Int;
    match hd {
      Ok(v) => { h = v; },
      Err(_) => { return 2; },
    };
    let pe = watch.watch_poll(h, 0);
    match pe {
      Ok(v) => { if v.len() != 0 { return 2; } },
      Err(_) => { return 2; },
    };

    // row 3: create
    match io.write_file("p_wave171_dir/a.txt", "one") {
      Ok(_) => {},
      Err(_) => { return 20; },
    };
    let ev1 = watch.watch_poll(h, 3000);
    match ev1 {
      Ok(v) => {
        var found = false;
        var i = 0;
        while i < v.len() {
          let e = v[i];
          if (e.kind == 1 || e.kind == 2) && e.path.ends_with("a.txt") { found = true; }
          i = i + 1;
        }
        if !found { return 3; }
      },
      Err(_) => { return 3; },
    };

    // row 4: modify
    match io.write_file("p_wave171_dir/a.txt", "two-two") {
      Ok(_) => {},
      Err(_) => { return 20; },
    };
    let ev2 = watch.watch_poll(h, 3000);
    match ev2 {
      Ok(v) => {
        var found = false;
        var i = 0;
        while i < v.len() {
          let e = v[i];
          if e.kind == 2 && e.path.ends_with("a.txt") { found = true; }
          i = i + 1;
        }
        if !found { return 4; }
      },
      Err(_) => { return 4; },
    };

    // row 5: remove
    match io.remove_file("p_wave171_dir/a.txt") {
      Ok(_) => {},
      Err(_) => { return 20; },
    };
    let ev3 = watch.watch_poll(h, 3000);
    match ev3 {
      Ok(v) => {
        var found = false;
        var i = 0;
        while i < v.len() {
          let e = v[i];
          if e.kind == 3 && e.path.ends_with("a.txt") { found = true; }
          i = i + 1;
        }
        if !found { return 5; }
      },
      Err(_) => { return 5; },
    };

    // row 6: closed handle is Err
    watch.watch_close(h);
    let pc = watch.watch_poll(h, 0);
    match pc {
      Ok(_) => { return 6; },
      Err(_) => {},
    };

    // row 7: recursive subdir event
    match io.create_dir("p_wave171_dir/sub") {
      Ok(_) => {},
      Err(_) => { return 20; },
    };
    let hr = watch.watch_dir("p_wave171_dir", true);
    let rh: Int;
    match hr {
      Ok(v) => { rh = v; },
      Err(_) => { return 7; },
    };
    match io.write_file("p_wave171_dir/sub/b.txt", "sub") {
      Ok(_) => {},
      Err(_) => { return 20; },
    };
    let ev4 = watch.watch_poll(rh, 3000);
    match ev4 {
      Ok(v) => {
        var found = false;
        var i = 0;
        while i < v.len() {
          let e = v[i];
          if (e.kind == 1 || e.kind == 2) && e.path.ends_with("b.txt") { found = true; }
          i = i + 1;
        }
        if !found { return 7; }
      },
      Err(_) => { return 7; },
    };
    watch.watch_close(rh);

    // row 8: missing dir is Err
    let md = watch.watch_dir("p_wave171_missing_dir", false);
    match md {
      Ok(_) => { return 8; },
      Err(_) => {},
    };

    let _ = io.remove_file("p_wave171_dir/sub/b.txt");
    let _ = io.remove_dir("p_wave171_dir/sub");
    let _ = io.remove_dir("p_wave171_dir");
  } else {
    if is_linux {
      // --- Linux: the real inotify leg ---
      match io.create_dir("p_wave171_dir") {
        Ok(_) => {},
        Err(_) => { return 20; },
      };
      match io.create_dir("p_wave171_dir/sub") {
        Ok(_) => {},
        Err(_) => { return 20; },
      };

      // row 9: open + empty timeout
      let hd = watch.watch_dir("p_wave171_dir", false);
      let h: Int;
      match hd {
        Ok(v) => { h = v; },
        Err(_) => { return 9; },
      };
      let pe = watch.watch_poll(h, 0);
      match pe {
        Ok(v) => { if v.len() != 0 { return 9; } },
        Err(_) => { return 9; },
      };

      // row 10: create
      match io.write_file("p_wave171_dir/c1.txt", "one") {
        Ok(_) => {},
        Err(_) => { return 20; },
      };
      let ev1 = watch.watch_poll(h, 3000);
      match ev1 {
        Ok(v) => {
          var found = false;
          var i = 0;
          while i < v.len() {
            let e = v[i];
            if (e.kind == 1 || e.kind == 2) && e.path.ends_with("c1.txt") { found = true; }
            i = i + 1;
          }
          if !found { return 10; }
        },
        Err(_) => { return 10; },
      };

      // row 11: modify
      match io.write_file("p_wave171_dir/m1.txt", "one") {
        Ok(_) => {},
        Err(_) => { return 20; },
      };
      match io.write_file("p_wave171_dir/m1.txt", "two-two") {
        Ok(_) => {},
        Err(_) => { return 20; },
      };
      let ev2 = watch.watch_poll(h, 3000);
      match ev2 {
        Ok(v) => {
          var found = false;
          var i = 0;
          while i < v.len() {
            let e = v[i];
            if e.kind == 2 && e.path.ends_with("m1.txt") { found = true; }
            i = i + 1;
          }
          if !found { return 11; }
        },
        Err(_) => { return 11; },
      };

      // row 12: attrib (chmod -> IN_ATTRIB mapped to modify)
      match io.write_file("p_wave171_dir/t1.txt", "one") {
        Ok(_) => {},
        Err(_) => { return 20; },
      };
      let ev3 = watch.watch_poll(h, 3000);
      match ev3 {
        Ok(_) => {},
        Err(_) => { return 20; },
      };
      match io.set_permissions("p_wave171_dir/t1.txt", 420) {
        Ok(_) => {},
        Err(_) => { return 20; },
      };
      let ev4 = watch.watch_poll(h, 3000);
      match ev4 {
        Ok(v) => {
          var found = false;
          var i = 0;
          while i < v.len() {
            let e = v[i];
            if e.kind == 2 && e.path.ends_with("t1.txt") { found = true; }
            i = i + 1;
          }
          if !found { return 12; }
        },
        Err(_) => { return 12; },
      };

      // row 13: moved-to (rename -> kind 4 on old and new name)
      match io.write_file("p_wave171_dir/v1.txt", "one") {
        Ok(_) => {},
        Err(_) => { return 20; },
      };
      let ev5 = watch.watch_poll(h, 3000);
      match ev5 {
        Ok(_) => {},
        Err(_) => { return 20; },
      };
      match io.rename("p_wave171_dir/v1.txt", "p_wave171_dir/w1.txt") {
        Ok(_) => {},
        Err(_) => { return 20; },
      };
      let ev6 = watch.watch_poll(h, 3000);
      match ev6 {
        Ok(v) => {
          var found = false;
          var i = 0;
          while i < v.len() {
            let e = v[i];
            if e.kind == 4 && (e.path.ends_with("v1.txt") || e.path.ends_with("w1.txt")) { found = true; }
            i = i + 1;
          }
          if !found { return 13; }
        },
        Err(_) => { return 13; },
      };

      // row 14: delete
      match io.write_file("p_wave171_dir/r1.txt", "one") {
        Ok(_) => {},
        Err(_) => { return 20; },
      };
      let ev7 = watch.watch_poll(h, 3000);
      match ev7 {
        Ok(_) => {},
        Err(_) => { return 20; },
      };
      match io.remove_file("p_wave171_dir/r1.txt") {
        Ok(_) => {},
        Err(_) => { return 20; },
      };
      let ev8 = watch.watch_poll(h, 3000);
      match ev8 {
        Ok(v) => {
          var found = false;
          var i = 0;
          while i < v.len() {
            let e = v[i];
            if e.kind == 3 && e.path.ends_with("r1.txt") { found = true; }
            i = i + 1;
          }
          if !found { return 14; }
        },
        Err(_) => { return 14; },
      };

      // row 15: closed handle is Err
      watch.watch_close(h);
      let pc = watch.watch_poll(h, 0);
      match pc {
        Ok(_) => { return 15; },
        Err(_) => {},
      };

      // row 16: recursive pre-existing subtree (sub/ was attached at open)
      let hr = watch.watch_dir("p_wave171_dir", true);
      let rh: Int;
      match hr {
        Ok(v) => { rh = v; },
        Err(_) => { return 16; },
      };
      match io.write_file("p_wave171_dir/sub/p1.txt", "one") {
        Ok(_) => {},
        Err(_) => { return 20; },
      };
      let ev9 = watch.watch_poll(rh, 3000);
      match ev9 {
        Ok(v) => {
          var found = false;
          var i = 0;
          while i < v.len() {
            let e = v[i];
            if (e.kind == 1 || e.kind == 2) && e.path.ends_with("p1.txt") { found = true; }
            i = i + 1;
          }
          if !found { return 16; }
        },
        Err(_) => { return 16; },
      };

      // row 17: directory attached on demand (sub2 appears while watching)
      match io.create_dir("p_wave171_dir/sub2") {
        Ok(_) => {},
        Err(_) => { return 20; },
      };
      let ev10 = watch.watch_poll(rh, 3000);
      match ev10 {
        Ok(v) => {
          var found_dir = false;
          var i = 0;
          while i < v.len() {
            let e = v[i];
            if e.path.ends_with("sub2") { found_dir = true; }
            i = i + 1;
          }
          if !found_dir { return 17; }
        },
        Err(_) => { return 17; },
      };
      match io.write_file("p_wave171_dir/sub2/n1.txt", "one") {
        Ok(_) => {},
        Err(_) => { return 20; },
      };
      let ev11 = watch.watch_poll(rh, 3000);
      match ev11 {
        Ok(v) => {
          var found = false;
          var i = 0;
          while i < v.len() {
            let e = v[i];
            if (e.kind == 1 || e.kind == 2) && e.path.ends_with("n1.txt") { found = true; }
            i = i + 1;
          }
          if !found { return 17; }
        },
        Err(_) => { return 17; },
      };

      // row 18: close + closed handle is Err
      watch.watch_close(rh);
      let pb = watch.watch_poll(rh, 0);
      match pb {
        Ok(_) => { return 18; },
        Err(_) => {},
      };

      // row 19: Err surface -- missing dir and a non-directory path
      let md = watch.watch_dir("p_wave171_missing_dir", false);
      match md {
        Ok(_) => { return 19; },
        Err(_) => {},
      };
      let fd = watch.watch_dir("p_wave171_dir/sub/p1.txt", false);
      match fd {
        Ok(_) => { return 19; },
        Err(_) => {},
      };
      let bad = watch.watch_poll(999999, 0);
      match bad {
        Ok(_) => { return 19; },
        Err(_) => {},
      };

      let _ = io.remove_file("p_wave171_dir/c1.txt");
      let _ = io.remove_file("p_wave171_dir/m1.txt");
      let _ = io.remove_file("p_wave171_dir/t1.txt");
      let _ = io.remove_file("p_wave171_dir/w1.txt");
      let _ = io.remove_file("p_wave171_dir/sub/p1.txt");
      let _ = io.remove_file("p_wave171_dir/sub2/n1.txt");
      let _ = io.remove_dir("p_wave171_dir/sub");
      let _ = io.remove_dir("p_wave171_dir/sub2");
      let _ = io.remove_dir("p_wave171_dir");
    } else {
      // --- other POSIX (darwin/BSD): kqueue is still a documented Err ---
      let wd = watch.watch_dir(".", false);
      match wd {
        Ok(_) => { return 19; },
        Err(_) => {},
      };
      let pp = watch.watch_poll(1, 0);
      match pp {
        Ok(_) => { return 19; },
        Err(_) => {},
      };
      watch.watch_close(0);
    };
  };
  return 0;
}
