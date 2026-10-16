// p_wave160_shapes.xi -- wave 160: popen-class non-blocking spawn
// (REL-20261015-2202-pulse item 3; multi-worker supervisor / drain-safe
// reload shape).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Rows (0 = all hold; a nonzero return names the first failing row; 20+
// are setup failures):
//   1  spawn_with_pipes("echo hello"/"printf hello") -> Ok, three fds >= 0
//   2  stdout drained byte-exact ("hello\r\n" on Windows, "hello" on POSIX)
//   3  wait -> exit code 0
//   4  nonzero-exit leg: stdout drained empty
//   5  nonzero-exit leg: exit code 7 ("exit /b 7" / "exit 7")
//   6  sleeper ("pause" / "exec sleep 60") is running right after spawn
//      (non-blocking spawn: no wait happened yet)
//   7  kill -> Ok (SIGKILL / TerminateProcess)
//   8  wait after kill -> killed code (Windows 1 / POSIX 128+SIGKILL=137)
//   9  binary/NUL stdout: temp fixture through "type"/"cat" byte-exact
//   10 binary leg exit code 0
//   11 popen(cmd, "r") -> Ok
//   12 popen drain byte-exact (echo hi / printf hi)
//   13 pclose -> exit code 0
//   14 posix_spawnp argv blob (no shell): sh/cmd.exe exits 7
//   15 posix_spawn absolute path (ComSpec / /bin/sh) exits 3
//   16 Err shapes: empty cmd / bad popen mode / empty spawnp+spawn file
// Setup failures: 21 nonzero spawn Err, 22 sleeper spawn Err, 23 binary
// fixture write Err, 24 binary spawn Err, 25 popen spawn Err, 26 spawnp
// spawn Err, 27 posix_spawn spawn Err.
//
// Platform note: the Windows legs run through cmd.exe builtins (echo,
// exit /b, pause, type) so no PATH dependency; the POSIX legs use sh,
// printf, cat and exec sleep. The kill-leg code differs by platform
// because POSIX reports signal death (128+9) and Windows reports the
// TerminateProcess exit code (1).

module p_wave160_shapes

use xiom.env;
use xiom.io;
use xiom.os.proc_ffi;

fn bytes(s: Str) -> Vec[UInt8] {
  var out: Vec[UInt8] = Vec[UInt8].with_capacity(s.len() as UInt);
  var i: Int = 0;
  while i < s.len() {
    out.push(s.byte_at(i));
    i = i + 1;
  }
  return out;
}

fn same(a: &Vec[UInt8], b: &Vec[UInt8]) -> Bool {
  if a.len() != b.len() {
    return false;
  }
  var i: Int = 0;
  while i < a.len() {
    if a[i] != b[i] {
      return false;
    }
    i = i + 1;
  }
  return true;
}

fn echo_expected(win: Bool, text: Str) -> Vec[UInt8] {
  var v = bytes(text);
  if win {
    v.push(13 as UInt8);
    v.push(10 as UInt8);
  }
  return v;
}

fn main() -> Int {
  let win = env.OS == "windows";

  // ---- rows 1-3: echo leg (spawn, drain, exit 0)
  var echo_cmd = "printf hello";
  if win {
    echo_cmd = "echo hello";
  }
  let r1 = spawn_with_pipes(echo_cmd, "");
  match r1 {
    Ok(ch) => {
      if ch.pid <= 0 {
        return 1;
      }
      if ch.in_fd < 0 || ch.out_fd < 0 || ch.err_fd < 0 {
        return 1;
      }
      var b1: Vec[UInt8] = Vec[UInt8].new();
      let d1 = drain_fd(ch.out_fd, &mut b1);
      match d1 {
        Ok(n) => {
          if n < 0 {
            return 2;
          }
        }
        Err(_) => {
          return 2;
        }
      }
      if !same(b1, echo_expected(win, "hello")) {
        return 2;
      }
      ch.close_pipes();
      let w1 = ch.wait();
      match w1 {
        Ok(code) => {
          if code != 0 {
            return 3;
          }
        }
        Err(_) => {
          return 3;
        }
      }
    }
    Err(_) => {
      return 21;
    }
  };

  // ---- rows 4-5: nonzero exit leg (empty stdout, code 7)
  var fail_cmd = "exit 7";
  if win {
    fail_cmd = "exit /b 7";
  }
  let r2 = spawn_with_pipes(fail_cmd, "");
  match r2 {
    Ok(ch) => {
      var b2: Vec[UInt8] = Vec[UInt8].new();
      let d2 = drain_fd(ch.out_fd, &mut b2);
      match d2 {
        Ok(_) => {}
        Err(_) => {
          return 21;
        }
      }
      if b2.len() != 0 {
        return 4;
      }
      ch.close_pipes();
      let w2 = ch.wait();
      match w2 {
        Ok(code) => {
          if code != 7 {
            return 5;
          }
        }
        Err(_) => {
          return 5;
        }
      }
    }
    Err(_) => {
      return 21;
    }
  };

  // ---- rows 6-8: sleeper kill leg
  var sleeper_cmd = "exec sleep 60";
  if win {
    sleeper_cmd = "pause";
  }
  let r3 = spawn_with_pipes(sleeper_cmd, "");
  match r3 {
    Ok(ch) => {
      if !ch.is_running() {
        return 6;
      }
      match ch.kill() {
        Ok(_) => {}
        Err(_) => {
          return 7;
        }
      }
      let w3 = ch.wait();
      match w3 {
        Ok(code) => {
          if win {
            if code != 1 {
              return 8;
            }
          } else {
            if code != 137 {
              return 8;
            }
          }
        }
        Err(_) => {
          return 8;
        }
      }
      ch.close_pipes();
    }
    Err(_) => {
      return 22;
    }
  };

  // ---- rows 9-10: binary/NUL stdout via type/cat of a temp fixture
  // NOTE: the separator is chosen explicitly -- env.path_separator() returns
  // "\\" even on Linux targets on the pin (pre-existing; filed in the wave
  // report) and cmd's `type` is unhappy with mixed separators.
  var fname = env.temp_dir() + "/xiom_w160_bin.dat";
  if win {
    fname = env.temp_dir() + "\\xiom_w160_bin.dat";
  }
  var fixture: Vec[UInt8] = Vec[UInt8].new();
  fixture.push(0 as UInt8);
  fixture.push(65 as UInt8);
  fixture.push(10 as UInt8);
  fixture.push(66 as UInt8);
  fixture.push(0 as UInt8);
  fixture.push(127 as UInt8);
  fixture.push(255 as UInt8);
  let wr = io.write_file_bytes(fname, &fixture);
  match wr {
    Ok(_) => {}
    Err(_) => {
      return 23;
    }
  };
  var cat_cmd = "cat \"" + fname + "\"";
  if win {
    cat_cmd = "type \"" + fname + "\"";
  }
  let r4 = spawn_with_pipes(cat_cmd, "");
  match r4 {
    Ok(ch) => {
      var b4: Vec[UInt8] = Vec[UInt8].new();
      let d4 = drain_fd(ch.out_fd, &mut b4);
      match d4 {
        Ok(_) => {}
        Err(_) => {
          return 24;
        }
      }
      ch.close_pipes();
      let w4 = ch.wait();
      match w4 {
        Ok(code) => {
          if code != 0 {
            return 10;
          }
        }
        Err(_) => {
          return 10;
        }
      }
      let rm = io.remove_file(fname);
      match rm {
        Ok(_) => {}
        Err(_) => {}
      };
      if !same(b4, fixture) {
        return 9;
      }
    }
    Err(_) => {
      return 24;
    }
  };

  // ---- rows 11-13: popen / pclose
  var popen_cmd = "printf hi";
  if win {
    popen_cmd = "echo hi";
  }
  let r5 = popen(popen_cmd, "r");
  match r5 {
    Ok(ch) => {
      if ch.pid <= 0 || ch.out_fd < 0 {
        return 11;
      }
      var b5: Vec[UInt8] = Vec[UInt8].new();
      let d5 = drain_fd(ch.out_fd, &mut b5);
      match d5 {
        Ok(_) => {}
        Err(_) => {
          return 25;
        }
      }
      if !same(b5, echo_expected(win, "hi")) {
        return 12;
      }
      let pc = pclose(ch);
      match pc {
        Ok(code) => {
          if code != 0 {
            return 13;
          }
        }
        Err(_) => {
          return 13;
        }
      }
    }
    Err(_) => {
      return 25;
    }
  };

  // ---- row 14: posix_spawnp (argv blob, no shell) exits 7
  var sp_file: Str = "sh";
  var args: Vec[Str] = Vec[Str].new();
  if win {
    sp_file = "cmd.exe";
    args.push("cmd.exe");
    args.push("/c");
    args.push("exit /b 7");
  } else {
    args.push("sh");
    args.push("-c");
    args.push("exit 7");
  }
  let r6 = posix_spawnp(sp_file, &args);
  match r6 {
    Ok(pid) => {
      let w6 = wait_status(pid);
      match w6 {
        Ok(st) => {
          if win {
            if st != 7 {
              return 14;
            }
          } else {
            if exit_code(st) != 7 {
              return 14;
            }
          }
        }
        Err(_) => {
          return 14;
        }
      }
    }
    Err(_) => {
      return 26;
    }
  };

  // ---- row 15: posix_spawn with an absolute path exits 3
  var abs_ok = true;
  var abspath: Str = "/bin/sh";
  var args2: Vec[Str] = Vec[Str].new();
  if win {
    let cs = env.var_opt("ComSpec");
    match cs {
      Some(p) => {
        abspath = p;
      }
      None => {
        abs_ok = false;
      }
    }
    args2.push("cmd.exe");
    args2.push("/c");
    args2.push("exit /b 3");
  } else {
    args2.push("sh");
    args2.push("-c");
    args2.push("exit 3");
  }
  if abs_ok {
    let r7 = posix_spawn(abspath, &args2);
    match r7 {
      Ok(pid) => {
        let w7 = wait_status(pid);
        match w7 {
          Ok(st) => {
            if win {
              if st != 3 {
                return 15;
              }
            } else {
              if exit_code(st) != 3 {
                return 15;
              }
            }
          }
          Err(_) => {
            return 15;
          }
        }
      }
      Err(_) => {
        return 27;
      }
    }
  }

  // ---- row 16: Err shapes
  var empty_args: Vec[Str] = Vec[Str].new();
  let e1 = spawn_with_pipes("", "");
  if e1.is_ok {
    return 16;
  }
  let e2 = popen("echo x", "x");
  if e2.is_ok {
    return 16;
  }
  let e3 = popen("", "r");
  if e3.is_ok {
    return 16;
  }
  let e4 = posix_spawnp("", &empty_args);
  if e4.is_ok {
    return 16;
  }
  let e5 = posix_spawn("", &empty_args);
  if e5.is_ok {
    return 16;
  }

  return 0;
}
