// p_wave201_os_iter.xi -- wave 201: os/iter real-path contract clauses.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Every call below re-evaluates a wave-201 requires/ensures at runtime, so a
// violated clause aborts the probe. Cases:
// 1. os.err: demangle is the identity on non-empty and empty symbols.
// 2. os.env: set_var_if_absent/clear_var propagate the non-empty-name domain
//    of the underlying var_opt/set_var/remove_var contracts and round-trip.
// 3. flat os: env_set/env_unset carry the same non-empty-name domain and
//    round-trip.
// 4. path: exists means a non-empty path; is_dir means a non-empty path;
//    a successful metadata call means a non-empty path.
// 5. os.platform: platform_user_name keeps the empty-Some => USER fallback
//    law (the call itself re-checks it; the result is only matched).
// 6. iter: TakeIter terminal methods with an exhausted budget (take(0))
//    return the empty/identity results (collect 0, fold init, sum 0,
//    product 1, max/min/find/nth/last None, all true, any false), and a
//    non-empty take still yields its elements.
// 7. iter: EnumerateIter.collect advances the cursor by exactly the number
//    of pairs it returns.
// Returns 0 when every case holds.

module p_wave201_os_iter

use xiom.iter;
use xiom.io;
use xiom.env;
use xiom.os as osflat;
use xiom.os.err;
use xiom.os.platform as pf;
use xiom.path;

fn add(a: Int, b: Int) -> Int {
  return a + b;
}

fn is_even(x: &Int) -> Bool {
  return *x % 2 == 0;
}

fn main() -> Int {
  // 1: err.demangle identity law.
  if err.demangle("_ZN3foo3barEv") != "_ZN3foo3barEv" { return 1; }
  if err.demangle("") != "" { return 2; }

  // 2: env wrappers (non-empty-name domain) round-trip.
  env.set_var_if_absent("XIOM_W201_ABSENT", "alpha");
  if env.var_or("XIOM_W201_ABSENT", "") != "alpha" { return 3; }
  env.clear_var("XIOM_W201_ABSENT");
  if env.has_var("XIOM_W201_ABSENT") { return 4; }

  // 3: flat os env wrappers round-trip.
  osflat.env_set("XIOM_W201_FLAT", "on");
  if env.var_or("XIOM_W201_FLAT", "") != "on" { return 5; }
  osflat.env_unset("XIOM_W201_FLAT");
  if env.has_var("XIOM_W201_FLAT") { return 6; }

  // 4: path existence/dir/metadata laws on a real file and directory.
  let tmp = "p_wave201_os_iter_tmp.txt";
  let _ = io.remove_file(tmp);
  let wr = io.write_file(tmp, "wave201");
  if wr.is_err { return 7; }
  let file_path = path.Path.new(tmp);
  if !file_path.exists() { return 8; }
  if file_path.is_dir() { return 9; }
  let md = file_path.metadata();
  if md.is_err { return 10; }
  let dir_path = path.Path.new(".");
  if !dir_path.is_dir() { return 11; }
  let empty_path = path.Path.new("");
  if empty_path.exists() { return 13; }
  if empty_path.is_dir() { return 14; }
  io.remove_file(tmp);

  // 5: platform_user_name (the ensures is re-checked on return).
  let uname = pf.platform_user_name();
  match uname {
    Some(_) => {},
    None => {},
  };

  // 6: exhausted TakeIter budget laws.
  if iter.range(1, 5).take(3).collect().len() != 3 { return 15; }
  if iter.range(1, 5).take(0).collect().len() != 0 { return 16; }
  if iter.range(1, 5).take(0).fold(7, add) != 7 { return 17; }
  if iter.range(1, 5).take(0).sum() != 0 { return 18; }
  if iter.range(1, 5).take(0).product() != 1 { return 19; }
  if !iter.range(1, 5).take(0).max().is_none { return 20; }
  if !iter.range(1, 5).take(0).min().is_none { return 21; }
  if !iter.range(1, 5).take(0).find(is_even).is_none { return 22; }
  if !iter.range(1, 5).take(0).all(is_even) { return 23; }
  if iter.range(1, 5).take(0).any(is_even) { return 24; }
  if !iter.range(1, 5).take(0).nth(2).is_none { return 25; }
  if !iter.range(1, 5).take(0).last().is_none { return 26; }

  // 7: EnumerateIter.collect state/size law (post index advances by len).
  let epairs = iter.range(10, 15).enumerate().collect();
  if epairs.len() != 5 { return 27; }
  match epairs.get(0) {
    Some(p) => { if p.0 != 0 || p.1 != 10 { return 28; } },
    None => { return 29; },
  };

  io.println("p_wave201_os_iter: OK");
  return 0;
}
