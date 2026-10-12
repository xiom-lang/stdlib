// p_wave115_shapes.xi -- wave 115 fix lock: the durability + byte-level IO
// drop (REL-20261012-1945-orbitdb / -1945-xvector-2 / -1946-pulse /
// REL-20261010-1550-packages fsync family).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the landed primitives pre/post:
//   * io.fsync on a FILE* handle from io.open (fflush + fsync/_commit);
//   * io.read_at clamped to the file size (exact bytes, no past-EOF
//     fabrication), incl. the len==0 early Ok;
//   * io.write_at into an existing file and with a zero-filled gap when
//     the offset is past the current end;
//   * io.append_file_bytes tail parity;
//   * io.truncate_file size + content;
//   * sync_io open_append/write_all/sync_fd/close_fd handle roundtrip,
//     open_read/read_exact exact-fill and the early-EOF Err;
//   * sync_io.fsync_dir(".") and io.flush_stdout() do not abort.
// Every returned value is bound before comparing. Returns 0 when all
// cases hold. Red pre-fix (the surface did not exist), green post.

module p_wave115_shapes

use xiom.io;
use xiom.os.fs_ffi;
use xiom.os.sync_io;

fn bytes3(a: UInt8, b: UInt8, c: UInt8) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  v.push(a);
  v.push(b);
  v.push(c);
  return v;
}

fn main() -> Int {
  let path = "p_wave115_a.tmp";
  let path2 = "p_wave115_b.tmp";

  // fresh state: truncate both fixtures (probe CWD is the repo root)
  var empty = Vec[UInt8].new();
  let pre1 = io.write_file_bytes(path, &empty);
  match pre1 {
    Ok(_) => {},
    Err(_) => { return 1; },
  };
  let pre2 = io.write_file_bytes(path2, &empty);
  match pre2 {
    Ok(_) => {},
    Err(_) => { return 1; },
  };

  // ---- seed a 5-byte file
  var seed = Vec[UInt8].new();
  seed.push(10 as UInt8);
  seed.push(11 as UInt8);
  seed.push(12 as UInt8);
  seed.push(13 as UInt8);
  seed.push(14 as UInt8);
  let w0 = io.write_file_bytes(path, &seed);
  match w0 {
    Ok(_) => {},
    Err(_) => { return 1; },
  };

  // ---- io.fsync on an io.open handle (append mode), no content change
  let oh = io.open(path, "ab");
  match oh {
    Ok(h) => {
      let f0 = io.fsync(h);
      match f0 {
        Ok(_) => {},
        Err(_) => { return 2; },
      };
      let c0 = io.close(h);
      match c0 {
        Ok(_) => {},
        Err(_) => { return 2; },
      };
    },
    Err(_) => { return 2; },
  };

  // ---- io.read_at: middle slice, clamped tail, past EOF, len 0
  let r1 = io.read_at(path, 1, 2);
  match r1 {
    Ok(v) => {
      let l1 = v.len();
      if l1 != 2 { return 3; }
      if v[0] != (11 as UInt8) { return 3; }
      if v[1] != (12 as UInt8) { return 3; }
    },
    Err(_) => { return 3; },
  };
  let r2 = io.read_at(path, 3, 10);
  match r2 {
    Ok(v) => {
      let l2 = v.len();
      if l2 != 2 { return 3; }
      if v[0] != (13 as UInt8) { return 3; }
      if v[1] != (14 as UInt8) { return 3; }
    },
    Err(_) => { return 3; },
  };
  let r3 = io.read_at(path, 99, 4);
  match r3 {
    Ok(v) => {
      let l3 = v.len();
      if l3 != 0 { return 3; }
    },
    Err(_) => { return 3; },
  };
  let r4 = io.read_at(path, 2, 0);
  match r4 {
    Ok(v) => {
      let l4 = v.len();
      if l4 != 0 { return 3; }
    },
    Err(_) => { return 3; },
  };

  // ---- io.write_at: overwrite two bytes, then a zero-filled gap write
  var two = Vec[UInt8].new();
  two.push(99 as UInt8);
  two.push(98 as UInt8);
  let w1 = io.write_at(path, 2, &two);
  match w1 {
    Ok(_) => {},
    Err(_) => { return 4; },
  };
  var one = Vec[UInt8].new();
  one.push(7 as UInt8);
  let w2 = io.write_at(path, 7, &one);
  match w2 {
    Ok(_) => {},
    Err(_) => { return 4; },
  };
  let after = io.read_file_bytes(path);
  match after {
    Ok(v) => {
      let la = v.len();
      if la != 8 { return 4; }
      if v[0] != (10 as UInt8) { return 4; }
      if v[1] != (11 as UInt8) { return 4; }
      if v[2] != (99 as UInt8) { return 4; }
      if v[3] != (98 as UInt8) { return 4; }
      if v[4] != (14 as UInt8) { return 4; }
      if v[5] != (0 as UInt8) { return 4; }
      if v[6] != (0 as UInt8) { return 4; }
      if v[7] != (7 as UInt8) { return 4; }
    },
    Err(_) => { return 4; },
  };

  // ---- io.append_file_bytes tail
  var tail = Vec[UInt8].new();
  tail.push(20 as UInt8);
  tail.push(21 as UInt8);
  let a1 = io.append_file_bytes(path, &tail);
  match a1 {
    Ok(_) => {},
    Err(_) => { return 5; },
  };
  let appended = io.read_file_bytes(path);
  match appended {
    Ok(v) => {
      let la2 = v.len();
      if la2 != 10 { return 5; }
      if v[8] != (20 as UInt8) { return 5; }
      if v[9] != (21 as UInt8) { return 5; }
    },
    Err(_) => { return 5; },
  };

  // ---- io.truncate_file
  let t1 = io.truncate_file(path, 3);
  match t1 {
    Ok(_) => {},
    Err(_) => { return 6; },
  };
  let trunc = io.read_file_bytes(path);
  match trunc {
    Ok(v) => {
      let lt = v.len();
      if lt != 3 { return 6; }
      if v[0] != (10 as UInt8) { return 6; }
      if v[1] != (11 as UInt8) { return 6; }
      if v[2] != (99 as UInt8) { return 6; }
    },
    Err(_) => { return 6; },
  };

  // ---- sync_io handle path: open_append/write_all/sync_fd/close_fd
  let h1 = sync_io.open_append(path2);
  match h1 {
    Ok(fd1) => {
      var blk = Vec[UInt8].new();
      blk.push(1 as UInt8);
      blk.push(2 as UInt8);
      blk.push(3 as UInt8);
      let wa = sync_io.write_all(fd1, &blk);
      match wa {
        Ok(n) => {
          if n != 3 { return 7; }
        },
        Err(_) => { return 7; },
      };
      let sf = sync_io.sync_fd(fd1);
      match sf {
        Ok(_) => {},
        Err(_) => { return 7; },
      };
      let cf = sync_io.close_fd(fd1);
      match cf {
        Ok(_) => {},
        Err(_) => { return 7; },
      };
    },
    Err(_) => { return 7; },
  };
  // append once more through a fresh handle: tail parity
  let h2 = sync_io.open_append(path2);
  match h2 {
    Ok(fd2) => {
      var blk2 = Vec[UInt8].new();
      blk2.push(4 as UInt8);
      let wa2 = sync_io.write_all(fd2, &blk2);
      match wa2 {
        Ok(n) => {
          if n != 1 { return 7; }
        },
        Err(_) => { return 7; },
      };
      let sf2 = sync_io.sync_fd(fd2);
      match sf2 {
        Ok(_) => {},
        Err(_) => { return 7; },
      };
      let cf2 = sync_io.close_fd(fd2);
      match cf2 {
        Ok(_) => {},
        Err(_) => { return 7; },
      };
    },
    Err(_) => { return 7; },
  };
  let b2 = io.read_file_bytes(path2);
  match b2 {
    Ok(v) => {
      let lb = v.len();
      if lb != 4 { return 7; }
      if v[0] != (1 as UInt8) { return 7; }
      if v[1] != (2 as UInt8) { return 7; }
      if v[2] != (3 as UInt8) { return 7; }
      if v[3] != (4 as UInt8) { return 7; }
    },
    Err(_) => { return 7; },
  };

  // ---- fs_ffi: fd-based fsync/fdatasync on a real fd -------------------
  let h4 = sync_io.open_append(path2);
  match h4 {
    Ok(fd4) => {
      let f4 = fs_ffi.fsync(fd4);
      match f4 {
        Ok(_) => {},
        Err(_) => { return 11; },
      };
      let f5 = fs_ffi.fdatasync(fd4);
      match f5 {
        Ok(_) => {},
        Err(_) => { return 11; },
      };
      let c4 = sync_io.close_fd(fd4);
      match c4 {
        Ok(_) => {},
        Err(_) => { return 11; },
      };
    },
    Err(_) => { return 11; },
  };

  // ---- sync_io read_exact: exact fill, then early-EOF Err
  let h3 = sync_io.open_read(path2);
  match h3 {
    Ok(fd3) => {
      var rb = Vec[UInt8].with_len(3);
      let re = sync_io.read_exact(fd3, &mut rb);
      match re {
        Ok(n) => {
          if n != 3 { return 8; }
        },
        Err(_) => { return 8; },
      };
      let rl = rb.len();
      if rl != 3 { return 8; }
      if rb[0] != (1 as UInt8) { return 8; }
      if rb[1] != (2 as UInt8) { return 8; }
      if rb[2] != (3 as UInt8) { return 8; }
      var rb2 = Vec[UInt8].with_len(10);
      let re2 = sync_io.read_exact(fd3, &mut rb2);
      match re2 {
        Ok(_) => { return 8; }, // only 1 byte left -> must Err
        Err(_) => {},
      };
      let cf3 = sync_io.close_fd(fd3);
      match cf3 {
        Ok(_) => {},
        Err(_) => { return 8; },
      };
    },
    Err(_) => { return 8; },
  };

  // ---- dir sync + stdout flush do not abort
  let df = sync_io.fsync_dir(".");
  match df {
    Ok(_) => {},
    Err(_) => { return 9; },
  };
  io.flush_stdout();

  // ---- cleanup fixtures
  let d1 = io.remove_file(path);
  match d1 {
    Ok(_) => {},
    Err(_) => { return 10; },
  };
  let d2 = io.remove_file(path2);
  match d2 {
    Ok(_) => {},
    Err(_) => { return 10; },
  };

  return 0;
}
