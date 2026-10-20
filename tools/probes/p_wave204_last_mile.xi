// p_wave204_last_mile.xi -- wave 204: last-mile contract-clause lock.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Every call below re-evaluates a wave-204 requires/ensures at runtime, so a
// violated clause aborts the probe. Cases:
// 1. gzip.gzip_decompress_file: a real gzip file round-trips, and the
//    Err payload is non-empty for a missing path and for the empty path.
// 2. sync.Mutex.lock: the returned guard wraps the same lock/data (pointer
//    identity clauses) and reads back the guarded value.
// 3. text.diff_patch: a non-empty patch is newline-terminated; the
//    empty/empty patch stays empty or newline-terminated.
// 4. misc.levenshtein_align: both aligned strings have one char per column
//    (equal lengths), each is at least max(len(a), len(b)) and at most
//    len(a) + len(b); the empty-prefix cases emit one gap per other char.
//
// The bigfloat_set_round_mode() setter/getter clause is runtime-locked by
// tests/smoke/smoke_bigfloat.xi (round-mode block). bigfloat_to_float128
// stays compile-checked only: any caller crashes on this compiler
// (BUG 37), the same limit recorded in smoke_gapfill_glob_binary_radix.
// Documented skips (constants/table getters, no-ops, RNG/predicates, stubs)
// carry no runtime clause and are not exercised here.
// Returns 0 when every case holds.

module p_wave204_last_mile

use xiom.io;
use xiom.compress.gzip;
use xiom.sync;
use xiom.text.diff;
use xiom.misc.levenshtein;

fn main() -> Int {
  // 1: gzip_decompress_file -- success round-trip.
  var payload = Vec[UInt8].new();
  payload.push(119u8);
  payload.push(97u8);
  payload.push(118u8);
  payload.push(101u8);
  payload.push(50u8);
  payload.push(48u8);
  payload.push(52u8);
  let compressed = gzip.gzip_compress(&payload);
  var path = "__p_wave204_last_mile.gz";
  match io.write_file_bytes(path, &compressed) {
    Ok(_) => {},
    Err(_) => { return 1; },
  };
  let back = gzip.gzip_decompress_file(path);
  match back {
    Ok(b) => {
      if b.len() != payload.len() { io.remove_file(path); return 2; }
      var bi = 0;
      while bi < b.len() {
        if b[bi] != payload[bi] { io.remove_file(path); return 3; }
        bi = bi + 1;
      }
    },
    Err(_) => { io.remove_file(path); return 4; },
  };
  io.remove_file(path);

  // 1b: Err payload is non-empty (contract) on a missing and an empty path.
  let missing = gzip.gzip_decompress_file("__p_wave204_missing.gz");
  if missing.is_ok { return 6; }
  match missing {
    Err(m) => {
      if m.len() == 0 { return 7; }
    },
    Ok(_) => { return 6; },
  };
  let empty_path = gzip.gzip_decompress_file("");
  if empty_path.is_ok { return 8; }

  // 2: Mutex.lock -- guard identity and value.
  var m = sync.Mutex.new(41);
  let g = m.lock();
  if g.get() != 41 { g.drop(); return 9; }
  g.drop();

  // 3: diff_patch -- newline-terminated payload.
  let patch = diff.diff_patch("a\nb", "a\nc");
  if patch.len() == 0 { return 10; }
  if patch.byte_at(patch.len() - 1) != 10 { return 11; }
  let patch_empty = diff.diff_patch("", "");
  if patch_empty.len() > 0 && patch_empty.byte_at(patch_empty.len() - 1) != 10 { return 12; }

  // 4: levenshtein_align -- column-count and size bounds.
  let al = levenshtein.levenshtein_align("kitten", "sitting");
  if al.0.len() != al.1.len() { return 13; }
  if al.0.len() < 7 || al.0.len() < 6 { return 14; }
  if al.0.len() > 13 { return 15; }
  let a_empty = levenshtein.levenshtein_align("", "abc");
  if a_empty.0.len() != a_empty.1.len() { return 16; }
  if a_empty.0.len() != 3 { return 17; }
  let b_empty = levenshtein.levenshtein_align("abc", "");
  if b_empty.0.len() != 3 || b_empty.1.len() != 3 { return 18; }
  if b_empty.1.len() < 3 { return 19; }
  return 0;
}
