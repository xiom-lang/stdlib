// p_wave124_shapes.xi -- wave 124 lock: directory-change watch
// (watch_dir / watch_poll / watch_close; REL-20261012-2012-engine-3,
// Windows-first per the ack).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// POSIX branch: watch_dir is a documented Err (inotify/kqueue not
// implemented yet) and watch_poll(handle, 0) errors.
// Windows branch: a real fixture rounds trip -- create/modify/remove a
// file under a watched dir and observe create-or-modify, modify and
// remove events (coalesced extra events are fine; the first record for a
// fresh file is ADDED), then recursive watch delivers a subdir event,
// closed handles and missing dirs are Err. Every returned value is bound
// before comparing. Returns 0 when all cases hold. Red pre-fix (the
// module does not exist), green post.

module p_wave124_shapes

use xiom.os.watch;
use xiom.env;
use xiom.io;

fn main() -> Int {
  // --- pure kind names ---
  let k1 = watch.watch_kind_name(1);
  if k1 != "create" {
    return 1;
  }
  let k2 = watch.watch_kind_name(2);
  if k2 != "modify" {
    return 1;
  }
  let k3 = watch.watch_kind_name(3);
  if k3 != "remove" {
    return 1;
  }
  let k4 = watch.watch_kind_name(4);
  if k4 != "rename" {
    return 1;
  }
  let k0 = watch.watch_kind_name(0);
  if k0 != "unknown" {
    return 1;
  }

  if env.FAMILY == "windows" {
    // --- fixture ---
    let _ = io.remove_file("p_wave124_dir/a.txt");
    let _ = io.remove_file("p_wave124_dir/sub/b.txt");
    let _ = io.remove_dir("p_wave124_dir/sub");
    let _ = io.remove_dir("p_wave124_dir");
    let cd = io.create_dir("p_wave124_dir");
    match cd {
      Ok(_) => {},
      Err(_) => { return 3; },
    };

    // --- non-recursive watch: create / modify / remove ---
    let hd = watch.watch_dir("p_wave124_dir", false);
    let h: Int;
    match hd {
      Ok(v) => { h = v; },
      Err(_) => { return 4; },
    };
    let w1 = io.write_file("p_wave124_dir/a.txt", "one");
    match w1 {
      Ok(_) => {},
      Err(_) => { return 3; },
    };
    let ev1 = watch.watch_poll(h, 3000);
    match ev1 {
      Ok(v) => {
        let n1 = v.len();
        if n1 < 1 { return 5; }
        let e0 = v[0];
        if e0.kind != 1 && e0.kind != 2 { return 6; }
        if !e0.path.ends_with("a.txt") { return 6; }
      },
      Err(_) => { return 5; },
    };
    let w2 = io.write_file("p_wave124_dir/a.txt", "two-two");
    match w2 {
      Ok(_) => {},
      Err(_) => { return 3; },
    };
    let ev2 = watch.watch_poll(h, 3000);
    match ev2 {
      Ok(v) => {
        let n2 = v.len();
        if n2 < 1 { return 5; }
        var found_mod = false;
        var mi = 0;
        while mi < n2 {
          let em = v[mi];
          if em.kind == 2 && em.path.ends_with("a.txt") { found_mod = true; }
          mi = mi + 1;
        }
        if !found_mod { return 7; }
      },
      Err(_) => { return 7; },
    };
    let r1 = io.remove_file("p_wave124_dir/a.txt");
    match r1 {
      Ok(_) => {},
      Err(_) => { return 3; },
    };
    let ev3 = watch.watch_poll(h, 3000);
    match ev3 {
      Ok(v) => {
        let n3 = v.len();
        if n3 < 1 { return 5; }
        var found_rm = false;
        var ri = 0;
        while ri < n3 {
          let er = v[ri];
          if er.kind == 3 && er.path.ends_with("a.txt") { found_rm = true; }
          ri = ri + 1;
        }
        if !found_rm { return 8; }
      },
      Err(_) => { return 8; },
    };
    watch.watch_close(h);
    let pc = watch.watch_poll(h, 0);
    match pc {
      Ok(_) => { return 9; },
      Err(_) => {},
    };

    // --- recursive watch: subdir event ---
    let cs = io.create_dir("p_wave124_dir/sub");
    match cs {
      Ok(_) => {},
      Err(_) => { return 3; },
    };
    let hr = watch.watch_dir("p_wave124_dir", true);
    let rh: Int;
    match hr {
      Ok(v) => { rh = v; },
      Err(_) => { return 4; },
    };
    let w3 = io.write_file("p_wave124_dir/sub/b.txt", "sub");
    match w3 {
      Ok(_) => {},
      Err(_) => { return 3; },
    };
    let ev4 = watch.watch_poll(rh, 3000);
    match ev4 {
      Ok(v) => {
        let n4 = v.len();
        if n4 < 1 { return 12; }
        var found_sub = false;
        var si = 0;
        while si < n4 {
          let es = v[si];
          if (es.kind == 1 || es.kind == 2) && es.path.ends_with("b.txt") { found_sub = true; }
          si = si + 1;
        }
        if !found_sub { return 12; }
      },
      Err(_) => { return 12; },
    };
    watch.watch_close(rh);

    // --- Err rows ---
    let md = watch.watch_dir("p_wave124_missing_dir", false);
    match md {
      Ok(_) => { return 10; },
      Err(_) => {},
    };
    let pb = watch.watch_poll(999999, 0);
    match pb {
      Ok(_) => { return 11; },
      Err(_) => {},
    };

    // --- cleanup ---
    let _ = io.remove_file("p_wave124_dir/sub/b.txt");
    let _ = io.remove_dir("p_wave124_dir/sub");
    let _ = io.remove_dir("p_wave124_dir");
  } else {
    // --- POSIX: documented Err until inotify/kqueue land ---
    let wd = watch.watch_dir(".", false);
    match wd {
      Ok(_) => { return 2; },
      Err(_) => {},
    };
    let pp = watch.watch_poll(1, 0);
    match pp {
      Ok(_) => { return 2; },
      Err(_) => {},
    };
    watch.watch_close(0);
  };
  return 0;
}
