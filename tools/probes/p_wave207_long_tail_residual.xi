// p_wave207_long_tail_residual.xi -- wave 207: residual long-tail clauses.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Every call below re-evaluates a wave-207 ensures at runtime, so a violated
// clause aborts the probe. Cases:
// 1. ffi.errno.errno_name: the table rows are symbolic (1 EPERM, 2 ENOENT),
//    code 0 is outside the table and maps to "UNKNOWN", and an arbitrary
//    unlisted code also maps to "UNKNOWN".
// 2. io.file_exists / io.is_dir: the empty path is a false answer for both
//    queries (fopen/stat reject it); a written file answers true/false.
// 3. test.assert_ok / test.assert_err: the returned TestResult carries the
//    supplied name and the expected pass/fail outcome.
//
// Documented skips (no clause added, no runtime clause here): printers
// (format.print/println, debug.trace_print/trace_log, log.log_flush,
// test.report_print), no-ops (log_flush_all, log_sink_rotate), constants
// (ansi_* terminal sequences, sha256/sha512 initial H0), allocation
// pass-throughs (to_cstring, to_wstring, cstring_copy), delegate wrappers
// (dl_open_global, dl_sym_address, to_json, from_json, into_str),
// RNG/clock outputs (crypto_random_*, crypto_seed_from_entropy,
// timestamp_now), hash outputs (city64_with_seed, siphash24_str_seeded),
// getters (Duration.as_secs, DateTime.year, date_year,
// SystemTime.secs_since_epoch), the errno_perror printer,
// file_modified_time (no value range holds for timestamps), the overflow
// tuple clauses (Bool-in-tuple codegen limit), and test_register
// (module-global contract reference is a codegen crash).
// Returns 0 when every case holds.

module p_wave207_long_tail_residual

use xiom.ffi.errno;
use xiom.io;
use xiom.test;

fn main() -> Int {
  // 1: errno_name table rows and unknown default.
  if errno.errno_name(1) != "EPERM" { return 1; }
  if errno.errno_name(2) != "ENOENT" { return 2; }
  if errno.errno_name(0) != "UNKNOWN" { return 3; }
  if errno.errno_name(13) != "EACCES" { return 4; }
  if errno.errno_name(9999) != "UNKNOWN" { return 5; }

  // 2: empty-path queries are false; a real file flips file_exists only.
  if io.file_exists("") { return 6; }
  if io.is_dir("") { return 7; }
  let path = "__p_wave207_residual.txt";
  var content = Vec[UInt8].new();
  content.push(55u8);
  content.push(48u8);
  content.push(55u8);
  match io.write_file_bytes(path, &content) {
    Ok(_) => {},
    Err(_) => { return 8; },
  };
  if !io.file_exists(path) { io.remove_file(path); return 9; }
  if io.is_dir(path) { io.remove_file(path); return 10; }
  io.remove_file(path);
  if io.file_exists(path) { return 11; }

  // 3: assert_ok / assert_err name round-trip and pass semantics.
  let okr: Result[Int, Str] = Ok(5);
  let ok = test.assert_ok(okr, "a-ok");
  if ok.name != "a-ok" { return 12; }
  if !ok.passed { return 13; }
  let errr: Result[Int, Str] = Err("nope");
  let er = test.assert_err(errr, "a-err");
  if er.name != "a-err" { return 14; }
  if !er.passed { return 15; }

  return 0;
}
