// p_wave103_shapes.xi -- wave 103 shape validation: sleep, os fs/file/dir/
// platform/err/args, path tail.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-103 clause guards:
//   (a) xiom.time sleep_ms / sleep(Duration) real blocking (pulse-6 fix);
//   (b) xiom.os.fs pure helpers: empty-path None/"" guards + positive
//       controls (file_name, stem, is_hidden, normalize);
//   (c) xiom.os.file / xiom.os.dir empty-path guards;
//   (d) xiom.os.platform identity consistency (family/name predicates,
//       arch, os_version vs env.OS);
//   (e) xiom.os.err table pins; (f) xiom.os.args empty-scan guards.
// Values returned from the module surface are bound before comparing.
// Returns 0 when every case holds.

module p_wave103_shapes

use xiom.time;
use xiom.os.fs as fs;
use xiom.os.file as file;
use xiom.os.dir as dir;
use xiom.os.platform as platform;
use xiom.os.err as err;
use xiom.os.args as args;
use xiom.env as env;

fn main() -> Int {
  // ---- sleep (pulse-6): real blocking at millisecond resolution
  // (Instant is second-resolution; measure with monotonic_ms)
  let b1 = time.monotonic_ms();
  time.sleep_ms(400);
  let a1 = time.monotonic_ms();
  let e1 = a1 - b1;
  if e1 < 300 { return 1; }
  let b2 = time.monotonic_ms();
  time.sleep(time.Duration.from_millis(400));
  let a2 = time.monotonic_ms();
  let e2 = a2 - b2;
  if e2 < 300 { return 2; }
  time.sleep_ms(0);
  time.sleep_ms(-5);

  // ---- fs: empty-path guards
  let fn0 = fs.fs_file_name("");
  if fn0.is_none != true { return 3; }
  let fp0 = fs.fs_parent_dir("");
  if fp0.is_none != true { return 4; }
  let fe0 = fs.fs_extension("");
  if fe0.is_none != true { return 5; }
  let fst0 = fs.fs_stem("");
  if fst0.is_none != true { return 6; }
  let fh0 = fs.fs_is_hidden("");
  if fh0 != false { return 7; }
  var e_parts = Vec[Str].new();
  let fj0 = fs.fs_join_parts(e_parts);
  if fj0.len() != 0 { return 8; }
  let fnorm0 = fs.fs_normalize("");
  if fnorm0.len() != 0 { return 9; }
  let fwe0 = fs.fs_with_extension("", "md");
  if fwe0.len() < 1 { return 10; }
  let fsp0 = fs.fs_split("");
  if fsp0.0 != "" { return 11; }
  if fsp0.1 != "" { return 12; }

  // ---- fs: positive controls
  let fn1 = fs.fs_file_name("a/b.txt");
  match fn1 {
    Some(x) => { if x != "b.txt" { return 13; } },
    None => { return 13; }
  }
  let fst1 = fs.fs_stem("a/b.tar.gz");
  match fst1 {
    Some(x) => { if x != "a/b.tar" { return 14; } },
    None => { return 14; }
  }
  let fh1 = fs.fs_is_hidden(".git");
  if fh1 != true { return 15; }
  let fh2 = fs.fs_is_hidden("git");
  if fh2 != false { return 16; }
  let fnorm1 = fs.fs_normalize("a/b/../c");
  if fnorm1 != "a/c" { return 17; }
  let fe1 = fs.fs_extension("a/b.tar.gz");
  match fe1 {
    Some(x) => { if x != "gz" { return 18; } },
    None => { return 18; }
  }

  // ---- file: empty-path guards
  let fr0 = file.file_read("");
  if fr0.is_err != true { return 19; }
  let fw0 = file.file_write("", "x");
  if fw0.is_err != true { return 20; }
  let fa0 = file.file_append("", "x");
  if fa0.is_err != true { return 21; }
  let fex0 = file.file_exists("");
  if fex0 != false { return 22; }
  let frm0 = file.file_remove("");
  if frm0.is_err != true { return 23; }
  let fcp0 = file.file_copy("", "x");
  if fcp0.is_err != true { return 24; }
  let frn0 = file.file_rename("", "x");
  if frn0.is_err != true { return 25; }
  let fsz0 = file.file_size("");
  if fsz0.is_err != true { return 26; }
  let fx0 = file.file_extension("");
  if fx0.is_none != true { return 27; }
  let fsm0 = file.file_stem("");
  if fsm0.is_none != true { return 28; }
  let fnm0 = file.file_name("");
  if fnm0.is_none != true { return 29; }
  let fpr0 = file.file_parent("");
  if fpr0.is_none != true { return 30; }

  // ---- dir: empty-path guards
  let dc0 = dir.dir_create("");
  if dc0.is_err != true { return 31; }
  let dca0 = dir.dir_create_all("");
  if dca0.is_ok != true { return 32; }
  let dl0 = dir.dir_list("");
  if dl0.is_err != true { return 33; }
  let de0 = dir.dir_exists("");
  if de0 != false { return 34; }
  let dr0 = dir.dir_remove("");
  if dr0.is_err != true { return 35; }
  let die0 = dir.dir_is_empty("");
  if die0 != false { return 36; }
  let dt0 = dir.dir_temp();
  if dt0.len() < 1 { return 37; }
  let dp0 = dir.dir_parent("");
  if dp0.is_none != true { return 38; }

  // ---- platform: identity consistency
  let pname = platform.platform_name();
  if pname.len() < 1 { return 39; }
  let pfam = platform.platform_family();
  if pfam != "windows" && pfam != "unix" { return 40; }
  let pw = platform.platform_is_windows();
  let pwn = pname == "windows";
  if pw != pwn { return 41; }
  let pl = platform.platform_is_linux();
  let pln = pname == "linux";
  if pl != pln { return 42; }
  let pm = platform.platform_is_macos();
  let pmn = pname == "macos";
  if pm != pmn { return 43; }
  let pu = platform.platform_is_unix();
  let pun = pname != "windows";
  if pu != pun { return 44; }
  let parch = platform.platform_arch();
  if parch.len() < 1 { return 45; }
  let posv = platform.platform_os_version();
  if posv != env.OS { return 46; }

  // ---- err: table pins
  let en2 = err.errno_name(2);
  if en2 != "ENOENT" { return 47; }
  let en1 = err.errno_name(1);
  if en1 != "EPERM" { return 48; }
  let en0 = err.errno_name(0);
  if en0 != "EUNKNOWN" { return 49; }
  let se2 = err.strerror(2);
  if se2 != "no such file or directory" { return 50; }
  let se0 = err.strerror(0);
  if se0 != "unknown error" { return 51; }
  let ets2 = err.errno_to_string(2);
  if ets2 != "ENOENT (2): no such file or directory" { return 52; }

  // ---- args: pure scan guards
  var e_args = Vec[Str].new();
  let fl0 = args.flag_lookup(&e_args, "--x");
  if fl0 != false { return 53; }
  let ov0 = args.option_value(&e_args, "--x");
  if ov0.is_none != true { return 54; }
  let ps0 = args.positionals(&e_args);
  if ps0.len() != 0 { return 55; }
  var two_flags = Vec[Str].new();
  two_flags.push("--a");
  two_flags.push("--b");
  let ps1 = args.positionals(&two_flags);
  if ps1.len() != 0 { return 56; }
  var mixed = Vec[Str].new();
  mixed.push("hello");
  mixed.push("--a");
  mixed.push("1");
  let ps2 = args.positionals(&mixed);
  if ps2.len() != 1 { return 57; }

  return 0;
}
