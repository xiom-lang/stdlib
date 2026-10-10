// p_wave105_shapes.xi -- wave 105 shape validation: os batch 2 (env,
// sysinfo, term, proc, signal, dir/fs/args/process tails, flat os).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-105 clause guards:
//   (a) xiom.env: empty iterators, separator/join mirrors, var helper
//       round-trip (set/set_if_absent/clear), arg helpers and dirs;
//   (b) xiom.os.sysinfo: bounds (cpu >= 1, memory -1 sentinel), hostname/
//       user guards, constant mirrors;
//   (c) xiom.os.term ANSI sequences and xiom.os.proc/signal tables;
//   (d) xiom.os.dir / xiom.os.fs / xiom.os.args / xiom.process tails;
//   (e) flat xiom.os guards (is_unix, memory-MiB, page size, cpu model,
//       env_set/env_unset round-trip, process id).
// Values returned from the module surface are bound before comparing.
// Returns 0 when every case holds.

module p_wave105_shapes

use xiom.env as env;
use xiom.io;
use xiom.os.sysinfo as sysinfo;
use xiom.os.term as term;
use xiom.os.proc as proc;
use xiom.os.signal as signal;
use xiom.os.dir as dir;
use xiom.os.fs as fs;
use xiom.os.args as args;
use xiom.os as osflat;
use xiom.process as process;
use xiom.format.terminal as fterm;

fn main() -> Int {
  // ---- env: empty iterators and path constants
  let v0 = env.vars();
  if v0.len() != 0 { return 1; }
  let avn0 = env.all_var_names();
  if avn0.len() != 0 { return 2; }
  let avv0 = env.all_var_values();
  if avv0.len() != 0 { return 3; }
  let sep = env.path_separator();
  if sep.len() != 1 { return 4; }
  if sep != "\\" && sep != "/" { return 5; }
  let jp = env.join_paths("a", "b");
  if jp.len() != 3 { return 6; }
  if jp != "a" + sep + "b" { return 7; }

  // ---- env: variable round-trip
  env.set_var("XIOM_W105_PROBE", "1");
  let h1 = env.has_var("XIOM_W105_PROBE");
  if h1 != true { return 8; }
  let vo1 = env.var_or("XIOM_W105_PROBE", "d");
  if vo1 != "1" { return 9; }
  let vo2 = env.var_or("XIOM_W105_PROBE_MISSING", "d");
  if vo2 != "d" { return 10; }
  env.set_var_if_absent("XIOM_W105_PROBE", "2");
  let vo3 = env.var_or("XIOM_W105_PROBE", "d");
  if vo3 != "1" { return 11; }
  env.set_var_if_absent("XIOM_W105_ABSENT", "3");
  let vo4 = env.var_or("XIOM_W105_ABSENT", "d");
  if vo4 != "3" { return 12; }
  env.clear_var("XIOM_W105_PROBE");
  let h2 = env.has_var("XIOM_W105_PROBE");
  if h2 != false { return 13; }
  env.remove_var("XIOM_W105_ABSENT");
  let h3 = env.has_var("XIOM_W105_ABSENT");
  if h3 != false { return 14; }

  // ---- env: arg helpers (bound against io.args)
  let aa_neg = env.arg_at(-1);
  if aa_neg.is_none != true { return 15; }
  let aa_big = env.arg_at(1000000000);
  if aa_big.is_none != true { return 16; }
  let ac0 = env.arg_contains("__XIOM_W105_NO_SUCH_ARG__");
  if ac0 != false { return 17; }
  let raw = io.args();
  let alen = env.args_len();
  if alen != raw.len() { return 18; }
  let ar = env.args();
  if ar.len() != raw.len() { return 19; }
  let aros = env.args_os();
  if aros.len() != ar.len() { return 20; }

  // ---- env: current exe and per-user dirs consistency
  let ce = env.current_exe();
  if ce.is_ok == true {
    match ce {
      Ok(p) => { if p.len() < 1 { return 21; } },
      Err(e) => { if e.len() < 0 { return 21; } }
    }
  }
  let dd = env.data_dir();
  if dd.is_some == true {
    let xdg = env.var_opt("XDG_DATA_HOME");
    let hd = env.home_dir();
    if xdg.is_some != true && hd.is_some != true { return 22; }
  }
  let cd = env.cache_dir();
  if cd.is_some == true {
    let xdg2 = env.var_opt("XDG_CACHE_HOME");
    let hd2 = env.home_dir();
    if xdg2.is_some != true && hd2.is_some != true { return 23; }
  }
  let cfd = env.config_dir();
  if cfd.is_some == true {
    let xdg3 = env.var_opt("XDG_CONFIG_HOME");
    let hd3 = env.home_dir();
    if xdg3.is_some != true && hd3.is_some != true { return 24; }
  }
  let ed = env.executable_dir();
  if ed.is_some == true && ce.is_ok != true { return 25; }

  // ---- dir tails
  let dc2 = dir.dir_current();
  if dc2.is_ok == true {
    match dc2 {
      Ok(p) => { if p.len() < 1 { return 26; } },
      Err(e) => { if e.len() < 0 { return 26; } }
    }
  }
  match dir.dir_home() {
    Some(h) => { if h.len() < 1 { return 27; } },
    None => {}
  }
  let dj = dir.dir_join("a", "b");
  if dj.len() != 3 { return 28; }

  // ---- fs tail: unique path is always non-empty
  let tmpd = env.temp_dir();
  let fup = fs.fs_unique_path(tmpd, "xiom_w105_probe");
  if fup.len() < 1 { return 29; }

  // ---- sysinfo bounds and guards
  let cc = sysinfo.sysinfo_cpu_count();
  if cc < 1 { return 30; }
  let tm = sysinfo.sysinfo_total_memory();
  if tm < -1 { return 31; }
  let fm = sysinfo.sysinfo_free_memory();
  if fm < -1 { return 32; }
  let tmb = sysinfo.sysinfo_total_memory_mb();
  if tmb < -1 { return 33; }
  let fmb = sysinfo.sysinfo_free_memory_mb();
  if fmb < -1 { return 34; }
  let ps = sysinfo.sysinfo_page_size();
  if ps != 4096 { return 35; }
  let hn = sysinfo.sysinfo_hostname();
  if hn.is_ok == true {
    match hn {
      Ok(h) => { if h.len() < 1 { return 36; } },
      Err(e) => { if e.len() < 0 { return 36; } }
    }
  }
  let on = sysinfo.sysinfo_os_name();
  if on != env.OS { return 37; }
  let ov = sysinfo.sysinfo_os_version();
  if ov != env.OS { return 38; }
  let pid = sysinfo.sysinfo_process_id();
  if pid <= 0 { return 39; }
  let un = sysinfo.sysinfo_user_name();
  if un.is_some == true {
    let u1 = env.var_opt("USERNAME");
    let u2 = env.var_opt("USER");
    if u1.is_some != true && u2.is_some != true { return 40; }
  }
  let cm = sysinfo.sysinfo_cpu_model();
  if cm != "unknown" { return 41; }

  // ---- term: ANSI sequence pins
  let tcs = term.term_clear_screen();
  if tcs != "\x1b[2J\x1b[H" { return 42; }
  let tfg0 = term.term_set_foreground(0);
  if tfg0 != "\x1b[38;5;0m" { return 43; }
  let tfg = term.term_set_foreground(255);
  if tfg != "\x1b[38;5;255m" { return 44; }
  let tch = term.term_cursor_hide();
  if tch != "\x1b[?25l" { return 45; }
  let tsh = term.term_cursor_show();
  if tsh != "\x1b[?25h" { return 46; }
  let tcm = term.term_cursor_move(1, 2);
  if tcm != "\x1b[1;2H" { return 47; }
  let tcm2 = term.term_cursor_move(10, 20);
  if tcm2 != "\x1b[10;20H" { return 48; }
  let tr = term.term_reset();
  let trc = fterm.ansi_reset();
  if tr != trc { return 49; }
  let tb = term.term_bold();
  let tbc = fterm.ansi_bold();
  if tb != tbc { return 50; }
  let td = term.term_dim();
  let tdc = fterm.ansi_dim();
  if td != tdc { return 51; }
  let tu = term.term_underline();
  let tuc = fterm.ansi_underline();
  if tu != tuc { return 52; }
  let tty = term.term_is_tty(1);
  if tty != false { return 53; }
  let tw = term.term_width();
  if tw != 0 { return 54; }

  // ---- proc table pins
  let pr0 = proc.proc_is_running(-1);
  if pr0 != false { return 55; }
  let pr1 = proc.proc_is_running(0);
  if pr1 != false { return 56; }
  let pe0 = proc.proc_exit_code_success(0);
  if pe0 != true { return 57; }
  let pe1 = proc.proc_exit_code_success(7);
  if pe1 != false { return 58; }
  let pn9 = proc.proc_signal_name(9);
  if pn9 != "KILL" { return 59; }
  let pn15 = proc.proc_signal_name(15);
  if pn15 != "TERM" { return 60; }
  let pn1234 = proc.proc_signal_name(1234);
  if pn1234 != "SIG1234" { return 61; }
  let pst0 = proc.proc_status_text(0);
  if pst0 != "exit(0)" { return 62; }
  let pst3 = proc.proc_status_text(3);
  if pst3 != "exit(3)" { return 63; }
  let pce = proc.proc_command_exists("");
  if pce != false { return 64; }

  // ---- signal table pins
  let sn2 = signal.signal_name(2);
  if sn2 != "INT" { return 65; }
  let sn999 = signal.signal_name(999);
  if sn999 != "unknown" { return 66; }
  match signal.signal_code("TERM") {
    Some(v) => { if v != 15 { return 67; } },
    None => { return 67; }
  }
  let scn = signal.signal_code("NOPE");
  if scn.is_none != true { return 68; }
  let si2 = signal.signal_is_ignorable(2);
  if si2 != true { return 69; }
  let si9 = signal.signal_is_ignorable(9);
  if si9 != false { return 70; }
  let si0 = signal.signal_is_ignorable(0);
  if si0 != false { return 71; }
  let sk19 = signal.signal_is_catchable(19);
  if sk19 != false { return 72; }
  let da15 = signal.signal_default_action(15);
  if da15 != "term" { return 73; }
  let da18 = signal.signal_default_action(18);
  if da18 != "cont" { return 74; }
  let da4 = signal.signal_default_action(4);
  if da4 != "core" { return 75; }
  let sr0 = signal.signal_raise(0);
  if sr0.is_err != true { return 76; }
  let srn = signal.signal_raise(-3);
  if srn.is_err != true { return 77; }

  // ---- flat os: guards and set/unset round-trip
  let iu = osflat.is_unix();
  let iun = env.OS == "linux" || env.OS == "macos";
  if iu != iun { return 78; }
  let ops = osflat.page_size();
  if ops != 4096 { return 79; }
  let otmb = osflat.total_memory_mb();
  if otmb < -1 { return 80; }
  let ofmb = osflat.free_memory_mb();
  if ofmb < -1 { return 81; }
  let otw = osflat.terminal_width();
  if otw.is_none != true { return 82; }
  let ocm = osflat.cpu_model();
  if ocm != "unknown" { return 83; }
  let oun = osflat.user_name();
  if oun.is_some == true {
    let ou1 = env.var_opt("USERNAME");
    let ou2 = env.var_opt("USER");
    if ou1.is_some != true && ou2.is_some != true { return 84; }
  }
  let ocep = osflat.current_exe_path();
  if ocep.is_some == true && ce.is_ok != true { return 85; }
  osflat.env_set("XIOM_W105_OS", "9");
  let ovv = env.var_or("XIOM_W105_OS", "");
  if ovv != "9" { return 86; }
  osflat.env_unset("XIOM_W105_OS");
  let ohv = env.has_var("XIOM_W105_OS");
  if ohv != false { return 87; }
  let opid = osflat.process_id();
  if opid <= 0 { return 88; }

  // ---- process tail consistency
  let pcep = process.current_exe_path();
  if pcep.is_some == true && ce.is_ok != true { return 89; }

  // ---- signal_raise link fix: Windows returns documented Err for any
  // positive number (CRT raise fail-fasts on unsupported signals); on
  // POSIX a positive number would actually deliver the signal, so the
  // success path stays untested by design.
  if env.OS == "windows" {
    let srw1 = signal.signal_raise(1);
    if srw1.is_err != true { return 90; }
    let srw15 = signal.signal_raise(15);
    if srw15.is_err != true { return 91; }
    osflat.raise_signal(15);
  }

  return 0;
}
