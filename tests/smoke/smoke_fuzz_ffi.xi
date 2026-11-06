// XIOM stdlib fuzz smoke -- FFI boundary harness (roadmap A3).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Deterministic mutation fuzzing for the bounds-checked FFI surface:
//   - SafePtr read/write at valid, boundary, and out-of-range offsets;
//   - fill/copy/to_vec agree with the size field;
//   - FFIBuffer write/read reject capacity and range violations without
//     growing the buffer;
//   - ffi_check / ffi_check_nonzero / ffi_check_ptr classify codes and null.
// The harness never violates a documented precondition (no negative offsets,
// no out-of-range fill values, no null dereference); it tests the Err side of
// the bounds contract. Seeds and iteration count come from XIOM_FUZZ_SEED /
// XIOM_FUZZ_ITERS. Returns 0 on success, a unique error code on failure.

module smoke_fuzz_ffi
use xiom.ffi;
use xiom.ptr;
use xiom.io;
use xiom.env;
use xiom.string;

fn next_seed(s: Int) -> Int {
  (s * 1103515245 + 12345) % 2147483648
}

fn env_int(name: Str, dflt: Int) -> Int {
  let raw = env.var_or(name, "");
  var result = dflt;
  if raw != "" {
    match string.str_to_int(raw) {
      Ok(n) => { if n > 0 { result = n; } },
      Err(_) => {},
    };
  };
  result
}

fn check_byte_reads(p: &SafePtr, size: Int) -> Int {
  match ffi.safe_ptr_read_byte(p, 0) {
    Ok(_) => {},
    Err(_) => { return 201; },
  };
  match ffi.safe_ptr_read_byte(p, size - 1) {
    Ok(_) => {},
    Err(_) => { return 202; },
  };
  match ffi.safe_ptr_read_byte(p, size) {
    Ok(_) => { return 203; },
    Err(_) => {},
  };
  match ffi.safe_ptr_read_byte(p, size + 17) {
    Ok(_) => { return 204; },
    Err(_) => {},
  };
  return 0;
}

fn check_width_bounds(p: &SafePtr, size: Int) -> Int {
  if size >= 2 {
    match ffi.safe_ptr_read_u16(p, size - 2) {
      Ok(_) => {},
      Err(_) => { return 205; },
    };
    match ffi.safe_ptr_read_u16(p, size - 1) {
      Ok(_) => { return 206; },
      Err(_) => {},
    };
  };
  match ffi.safe_ptr_read_u16(p, size) {
    Ok(_) => { return 207; },
    Err(_) => {},
  };
  if size >= 4 {
    match ffi.safe_ptr_read_u32(p, size - 4) {
      Ok(_) => {},
      Err(_) => { return 208; },
    };
    match ffi.safe_ptr_read_u32(p, size - 3) {
      Ok(_) => { return 209; },
      Err(_) => {},
    };
  };
  match ffi.safe_ptr_read_u32(p, size) {
    Ok(_) => { return 210; },
    Err(_) => {},
  };
  if size >= 8 {
    match ffi.safe_ptr_read_i64(p, size - 8) {
      Ok(_) => {},
      Err(_) => { return 211; },
    };
    match ffi.safe_ptr_read_i64(p, size - 7) {
      Ok(_) => { return 212; },
      Err(_) => {},
    };
  };
  match ffi.safe_ptr_read_i64(p, size) {
    Ok(_) => { return 213; },
    Err(_) => {},
  };
  return 0;
}

fn check_width_roundtrips(p: &mut SafePtr, size: Int, seed: Int) -> Int {
  var s = seed;
  s = next_seed(s);
  let val = s % 1000000;
  if size >= 2 {
    match ffi.safe_ptr_write_u16(p, size - 2, val) {
      Ok(_) => {},
      Err(_) => { return 220; },
    };
    match ffi.safe_ptr_read_u16(p, size - 2) {
      Ok(v) => { if v != (val & 0xFFFF) { return 221; } },
      Err(_) => { return 222; },
    };
  };
  if size >= 4 {
    match ffi.safe_ptr_write_u32(p, size - 4, val) {
      Ok(_) => {},
      Err(_) => { return 223; },
    };
    match ffi.safe_ptr_read_u32(p, size - 4) {
      Ok(v) => { if v != (val & 0xFFFFFFFF) { return 224; } },
      Err(_) => { return 225; },
    };
  };
  if size >= 8 {
    match ffi.safe_ptr_write_i64(p, size - 8, val) {
      Ok(_) => {},
      Err(_) => { return 226; },
    };
    match ffi.safe_ptr_read_i64(p, size - 8) {
      Ok(v) => { if v != val { return 227; } },
      Err(_) => { return 228; },
    };
    let f64v: Float64 = 1.5;
    match ffi.safe_ptr_write_f64(p, size - 8, f64v) {
      Ok(_) => {},
      Err(_) => { return 229; },
    };
    match ffi.safe_ptr_read_f64(p, size - 8) {
      Ok(v) => { if v != f64v { return 230; } },
      Err(_) => { return 231; },
    };
  };
  if size >= 4 {
    let f32v: Float32 = 1.5;
    match ffi.safe_ptr_write_f32(p, size - 4, f32v) {
      Ok(_) => {},
      Err(_) => { return 232; },
    };
    match ffi.safe_ptr_read_f32(p, size - 4) {
      Ok(v) => { if v != f32v { return 233; } },
      Err(_) => { return 234; },
    };
  };
  return 0;
}

fn check_copy(src: &SafePtr, src_size: Int, seed: Int) -> Int {
  var s = seed;
  s = next_seed(s);
  let dst_size = 1 + (s % 128);
  match ffi.safe_ptr_alloc(dst_size) {
    Ok(d0) => {
      var dst = d0;
      s = next_seed(s);
      let count = s % (src_size + 4);
      let should_ok = count <= src_size && count <= dst_size;
      match ffi.safe_ptr_copy(&mut dst, src, count) {
        Ok(_) => {
          if !should_ok {
            ffi.safe_ptr_free(dst);
            return 240;
          }
        },
        Err(_) => {
          if should_ok {
            ffi.safe_ptr_free(dst);
            return 241;
          }
        },
      };
      if should_ok && count > 0 {
        match ffi.safe_ptr_read_byte(src, 0) {
          Ok(v1) => {
            match ffi.safe_ptr_read_byte(&dst, 0) {
              Ok(v2) => {
                if v1 != v2 {
                  ffi.safe_ptr_free(dst);
                  return 242;
                }
              },
              Err(_) => {
                ffi.safe_ptr_free(dst);
                return 243;
              },
            };
          },
          Err(_) => {
            ffi.safe_ptr_free(dst);
            return 244;
          },
        };
      };
      ffi.safe_ptr_free(dst);
    },
    Err(_) => { return 239; },
  };
  return 0;
}

fn check_buffer(seed: Int) -> Int {
  var s = seed;
  s = next_seed(s);
  let cap = 1 + (s % 64);
  match ffi.buffer_new(cap) {
    Ok(b0) => {
      var b = b0;
      s = next_seed(s);
      let len = 1 + (s % (cap + 4));
      var data = Vec[Int].new();
      var i = 0;
      while i < len {
        s = next_seed(s);
        data.push(s % 256);
        i = i + 1;
      };
      let wr = ffi.buffer_write(&mut b, &data);
      if len <= cap {
        match wr {
          Ok(n) => { if n != len { return 250; } },
          Err(_) => { return 251; },
        };
        if ffi.buffer_len(&b) != len { return 252; }
        s = next_seed(s);
        let off = s % len;
        s = next_seed(s);
        let rl = 1 + (s % (len - off));
        match ffi.buffer_read(&b, off, rl) {
          Ok(v) => { if v.len() != rl { return 253; } },
          Err(_) => { return 254; },
        };
        match ffi.buffer_read(&b, off, (len - off) + 1) {
          Ok(_) => { return 255; },
          Err(_) => {},
        };
        ffi.buffer_clear(&mut b);
        if ffi.buffer_len(&b) != 0 || !ffi.buffer_is_empty(&b) { return 256; }
      } else {
        match wr {
          Ok(_) => { return 257; },
          Err(_) => {},
        };
        if ffi.buffer_len(&b) != 0 { return 258; }
      };
    },
    Err(_) => { return 249; },
  };
  return 0;
}

fn check_error_codes(seed: Int) -> Int {
  var s = seed;
  s = next_seed(s);
  let code = (s % 201) - 100;
  match ffi.ffi_check(code, "fuzz") {
    Ok(v) => {
      if code < 0 || v != code { return 260; }
    },
    Err(e) => {
      if code >= 0 || e.code != code { return 261; }
    },
  };
  match ffi.ffi_check_nonzero(code, "fuzz") {
    Ok(v) => {
      if code != 0 || v != code { return 262; }
    },
    Err(e) => {
      if code == 0 || e.code != code { return 263; }
    },
  };
  return 0;
}

fn main() -> Int {
  let iters = env_int("XIOM_FUZZ_ITERS", 120);
  let base = env_int("XIOM_FUZZ_SEED", 20261106);
  var run = 0;
  while run < 3 {
    var seed = base + run * 7919;
    var i = 0;
    while i < iters {
      seed = next_seed(seed);
      let size = 1 + (seed % 128);
      match ffi.safe_ptr_alloc(size) {
        Ok(p0) => {
          var p = p0;
          let rc1 = check_byte_reads(&p, size);
          if rc1 != 0 {
            ffi.safe_ptr_free(p);
            return rc1;
          };
          seed = next_seed(seed);
          let fillv = seed % 256;
          match ffi.safe_ptr_fill(&mut p, fillv) {
            Ok(_) => {},
            Err(_) => {
              ffi.safe_ptr_free(p);
              return 270;
            },
          };
          match ffi.safe_ptr_read_byte(&p, 0) {
            Ok(v) => {
              if v != fillv {
                ffi.safe_ptr_free(p);
                return 271;
              }
            },
            Err(_) => {
              ffi.safe_ptr_free(p);
              return 272;
            },
          };
          match ffi.safe_ptr_read_byte(&p, size - 1) {
            Ok(v) => {
              if v != fillv {
                ffi.safe_ptr_free(p);
                return 273;
              }
            },
            Err(_) => {
              ffi.safe_ptr_free(p);
              return 274;
            },
          };
          match ffi.safe_ptr_to_vec(&p) {
            Ok(v) => {
              if v.len() != size {
                ffi.safe_ptr_free(p);
                return 275;
              }
            },
            Err(_) => {
              ffi.safe_ptr_free(p);
              return 276;
            },
          };
          let rc2 = check_width_bounds(&p, size);
          if rc2 != 0 {
            ffi.safe_ptr_free(p);
            return rc2;
          };
          let rc3 = check_width_roundtrips(&mut p, size, seed);
          if rc3 != 0 {
            ffi.safe_ptr_free(p);
            return rc3;
          };
          seed = next_seed(seed);
          let off = seed % size;
          let val = seed % 256;
          match ffi.safe_ptr_write_byte(&mut p, off, val) {
            Ok(_) => {},
            Err(_) => {
              ffi.safe_ptr_free(p);
              return 277;
            },
          };
          match ffi.safe_ptr_read_byte(&p, off) {
            Ok(v) => {
              if v != (val & 0xFF) {
                ffi.safe_ptr_free(p);
                return 278;
              }
            },
            Err(_) => {
              ffi.safe_ptr_free(p);
              return 279;
            },
          };
          match ffi.ffi_check_ptr(p.ptr, "fuzz") {
            Ok(_) => {},
            Err(_) => {
              ffi.safe_ptr_free(p);
              return 280;
            },
          };
          let rc4 = check_copy(&p, size, seed);
          if rc4 != 0 {
            ffi.safe_ptr_free(p);
            return rc4;
          };
          ffi.safe_ptr_free(p);
        },
        Err(_) => { return 200; },
      };
      let rc5 = check_buffer(seed);
      if rc5 != 0 { return rc5; }
      let rc6 = check_error_codes(seed);
      if rc6 != 0 { return rc6; }
      let nullp = ptr.null[UInt8]();
      match ffi.ffi_check_ptr(nullp, "fuzz") {
        Ok(_) => { return 281; },
        Err(e) => { if e.code != -1 { return 282; } },
      };
      i = i + 1;
    };
    run = run + 1;
  };
  io.println("fuzz-ffi: 3 seeds x " + iters.to_str() + " inputs OK");
  return 0;
}
