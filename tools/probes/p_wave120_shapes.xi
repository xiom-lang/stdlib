// p_wave120_shapes.xi -- wave 120 lock: the mmap family real
// (mmap_anonymous / mmap_file / mmap_writeable / mmap_unmap / mmap_sync /
// mmap_advise / mmap_protect / mmap_lock / mmap_unlock / mmap_copy /
// mmap_write + fs_ffi.mmap / munmap / msync / madvise / mlock / munlock).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the landed semantics on a 15-byte fixture written in the probe CWD
// (the repo root; truncate-first, cleaned up at the end):
//   * anonymous mapping: write 4 bytes, read them back, lock/unlock the
//     page, re-protect read-only, unmap all return Ok;
//   * file-backed writeable mapping (open_rw): copy matches the fixture,
//     a 1-byte write + msync(MS_SYNC) is visible through a fresh read;
//   * file-backed read-only mapping (open_read): copy matches;
//   * Err paths: negative fd, null ptr for unmap/sync, zero length, a
//     missing path, and fs_ffi.mmap on the missing path;
//   * fs_ffi path roundtrip: mmap Ok, msync/madvise/mlock/munlock Ok,
//     munmap closes. Every returned value is bound before comparing.
// Returns 0 when all cases hold. Red pre-fix (the stubs return Err),
// green post.

module p_wave120_shapes

use xiom.os.mmap;
use xiom.os.fs_ffi;
use xiom.os.sync_io;
use xiom.io;

fn main() -> Int {
  // --- anonymous mapping ---
  let ra = mmap.mmap_anonymous(4096);
  match ra {
    Ok(pa) => {
      let wv = four_bytes();
      let w = mmap.mmap_write(pa, &wv);
      match w {
        Ok(_) => {},
        Err(_) => { return 2; },
      };
      let got = mmap.mmap_copy(pa, 4);
      let gl = got.len();
      if gl != 4 { return 3; }
      if got[0] != 1 || got[1] != 2 || got[2] != 3 || got[3] != 4 {
        return 4;
      }
      let lk = mmap.mmap_lock(pa, 4096);
      match lk {
        Ok(_) => {},
        Err(_) => { return 31; },
      };
      let ul = mmap.mmap_unlock(pa, 4096);
      match ul {
        Ok(_) => {},
        Err(_) => { return 32; },
      };
      let pr = mmap.mmap_protect(pa, 4096, 1); // PROT_READ
      match pr {
        Ok(_) => {},
        Err(_) => { return 30; },
      };
      let un = mmap.mmap_unmap(pa, 4096);
      match un {
        Ok(_) => {},
        Err(_) => { return 5; },
      };
    },
    Err(_) => { return 1; },
  };

  // --- fixture (truncate-first, probe CWD = repo root) ---
  let fixture = "p_wave120_fixture.bin";
  let _ = io.remove_file(fixture);
  let wf = io.write_file(fixture, "wave120-payload");
  match wf {
    Ok(_) => {},
    Err(_) => { return 6; },
  };

  // --- file-backed writeable mapping ---
  let of = sync_io.open_rw(fixture);
  let fd: Int;
  match of {
    Ok(f) => { fd = f; },
    Err(_) => { return 7; },
  };
  let rm = mmap.mmap_writeable(fd, 0, 15);
  match rm {
    Ok(mp) => {
      let c = mmap.mmap_copy(mp, 15);
      let cl = c.len();
      if cl != 15 { return 8; }
      let e = payload();
      var i = 0;
      var same = true;
      while i < 15 {
        if c[i] != e[i] { same = false; }
        i = i + 1;
      }
      if !same { return 9; }
      var mv = Vec[UInt8].new();
      mv.push(88); // 'X'
      let wr = mmap.mmap_write(mp, &mv);
      match wr {
        Ok(_) => {},
        Err(_) => { return 10; },
      };
      let sy = mmap.mmap_sync(mp, 15, 4); // MS_SYNC
      match sy {
        Ok(_) => {},
        Err(_) => { return 11; },
      };
      let ad = mmap.mmap_advise(mp, 15, 0); // MADV_NORMAL
      match ad {
        Ok(_) => {},
        Err(_) => { return 12; },
      };
      let un2 = mmap.mmap_unmap(mp, 15);
      match un2 {
        Ok(_) => {},
        Err(_) => { return 13; },
      };
    },
    Err(_) => { return 14; },
  };
  let cf = sync_io.close_fd(fd);
  match cf {
    Ok(_) => {},
    Err(_) => { return 15; },
  };

  // --- the write is visible through a fresh read (msync persisted it) ---
  let rb = io.read_file_bytes(fixture);
  match rb {
    Ok(v) => {
      let vl = v.len();
      if vl != 15 { return 16; }
      if v[0] != 88 { return 17; }
    },
    Err(_) => { return 18; },
  };

  // --- file-backed read-only mapping ---
  let orr = sync_io.open_read(fixture);
  match orr {
    Ok(rfd) => {
      let ro = mmap.mmap_file(rfd, 0, 15);
      match ro {
        Ok(rp) => {
          let rc = mmap.mmap_copy(rp, 15);
          let rcl = rc.len();
          if rcl != 15 { return 19; }
          if rc[0] != 88 { return 20; }
          let u3 = mmap.mmap_unmap(rp, 15);
          match u3 {
            Ok(_) => {},
            Err(_) => { return 21; },
          };
        },
        Err(_) => { return 22; },
      };
      var rbuf = Vec[UInt8].new();
      var bi = 0;
      while bi < 15 {
        rbuf.push(0);
        bi = bi + 1;
      }
      let rx = sync_io.read_exact(rfd, &rbuf);
      match rx {
        Ok(n) => {
          if n != 15 { return 41; }
        },
        Err(_) => { return 42; },
      };
      let r0 = rbuf[0];
      if r0 != 88 { return 43; }
      let _ = sync_io.close_fd(rfd);
    },
    Err(_) => { return 22; },
  };

  // --- Err paths ---
  let bad = mmap.mmap_file(-1, 0, 16);
  match bad {
    Ok(_) => { return 23; },
    Err(_) => {},
  };
  let bu = mmap.mmap_unmap(0, 16);
  match bu {
    Ok(_) => { return 24; },
    Err(_) => {},
  };
  let bs = mmap.mmap_sync(0, 16, 4);
  match bs {
    Ok(_) => { return 25; },
    Err(_) => {},
  };
  let ba = mmap.mmap_anonymous(0);
  match ba {
    Ok(_) => { return 26; },
    Err(_) => {},
  };
  let bp = mmap.mmap_copy(0, 16);
  let bpl = bp.len();
  if bpl != 0 { return 27; }

  // --- fd-open ABI (wave-119 family): a missing path must be Err, not a
  // --- 4294967295 i64 read of the C int -1. Invalid-fd _read/_write rows
  // --- are deliberately absent: the Windows UCRT fast-fails the process on
  // --- a closed/out-of-range fd before any return value exists.
  let mis = sync_io.open_read("p_wave120_missing.bin");
  match mis {
    Ok(_) => { return 40; },
    Err(_) => {},
  };

  // --- fs_ffi path-based roundtrip ---
  let nf = fs_ffi.mmap("p_wave120_missing.bin", 0, 16);
  match nf {
    Ok(_) => { return 28; },
    Err(_) => {},
  };
  let fm = fs_ffi.mmap(fixture, 0, 15);
  match fm {
    Ok(m) => {
      if m.ptr <= 0 { return 29; }
      let fc = mmap.mmap_copy(m.ptr, 15);
      let fcl = fc.len();
      if fcl != 15 { return 33; }
      let ms = fs_ffi.msync(m);
      match ms {
        Ok(_) => {},
        Err(_) => { return 34; },
      };
      let ma = fs_ffi.madvise(m, 0);
      match ma {
        Ok(_) => {},
        Err(_) => { return 35; },
      };
      let ml = fs_ffi.mlock(m);
      match ml {
        Ok(_) => {},
        Err(_) => { return 36; },
      };
      let mu = fs_ffi.munlock(m);
      match mu {
        Ok(_) => {},
        Err(_) => { return 37; },
      };
      fs_ffi.munmap(m);
    },
    Err(_) => { return 38; },
  };

  let _ = io.remove_file(fixture);
  return 0;
}

fn four_bytes() -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  v.push(1);
  v.push(2);
  v.push(3);
  v.push(4);
  v
}

fn payload() -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  v.push(119); // w
  v.push(97);  // a
  v.push(118); // v
  v.push(101); // e
  v.push(49);  // 1
  v.push(50);  // 2
  v.push(48);  // 0
  v.push(45);  // -
  v.push(112); // p
  v.push(97);  // a
  v.push(121); // y
  v.push(108); // l
  v.push(111); // o
  v.push(97);  // a
  v.push(100); // d
  v
}
