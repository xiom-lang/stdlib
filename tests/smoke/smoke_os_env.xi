// XIOM stdlib smoke test — xiom.env + xiom.os.platform + xiom.os.sysinfo
// Env, platform, and sysinfo helpers.
// Returns 0 on success, nonzero on failure (process exit code).
//
// NOTE: xiom.os.signal and xiom.os.term are tested in smoke_os_folder.xi
// because the compiler cannot resolve the `xiom.os.platform` module prefix
// when xiom.os.signal or xiom.os.term are also imported into the same
// program (module/function name collision — the flat xiom.os module exposes
// a `platform()` function and a `signal` extern, which shadow the sibling
// submodule prefixes).

module smoke_os_env

use xiom.os.sysinfo;
use xiom.os.platform;
use xiom.env;
use xiom.io;

fn main() -> Int {
  // --- env ---
  let v = env.var_opt("PATH");
  match v {
    Some(p) => {
      if p.len() == 0 {
        io.println("env-path");
        return 1;
      }
    }
    None => {
      io.println("env-path");
      return 1;
    }
  }
  // NOTE: env.set_var/remove_var are not exercised here because the
  // Windows runtime does not export setenv/unsetenv; they are covered
  // by the env module's own smokes where the runtime provides them.
  if env.has_var("PATH") != true {
    io.println("env-has");
    return 2;
  }
  var tdir = env.temp_dir();
  if tdir.len() == 0 {
    io.println("env-temp");
    return 3;
  }
  var osname = env.OS;
  if osname.len() == 0 {
    io.println("env-os");
    return 4;
  }

  // --- platform ---
  var pname = xiom.os.platform.platform_name();
  if pname.len() == 0 {
    io.println("plat-name");
    return 6;
  }
  var parch = xiom.os.platform.platform_arch();
  if parch.len() == 0 {
    io.println("plat-arch");
    return 7;
  }
  var pwin = xiom.os.platform.platform_is_windows();
  if pwin != (pname == "windows") {
    io.println("plat-win");
    return 8;
  }
  if xiom.os.platform.platform_family() != "windows" && xiom.os.platform.platform_family() != "unix" {
    io.println("plat-fam");
    return 9;
  }
  var ph = xiom.os.platform.platform_hostname();
  match ph {
    Ok(_) => {}
    Err(_) => {
      io.println("plat-host");
      return 10;
    }
  }
  var pu = xiom.os.platform.platform_user_name();
  match pu {
    Some(_) => {}
    None => {
      io.println("plat-user");
      return 11;
    }
  }

  // --- sysinfo ---
  var cc = sysinfo.sysinfo_cpu_count();
  if cc <= 0 {
    io.println("sys-cpu");
    return 12;
  }
  var tm = sysinfo.sysinfo_total_memory_mb();
  if tm <= 0 {
    io.println("sys-mem");
    return 13;
  }
  var page = sysinfo.sysinfo_page_size();
  if page <= 0 {
    io.println("sys-page");
    return 14;
  }
  var sname = sysinfo.sysinfo_os_name();
  if sname.len() == 0 {
    io.println("sys-os");
    return 15;
  }
  var spid = sysinfo.sysinfo_process_id();
  if spid <= 0 {
    io.println("sys-pid");
    return 16;
  }

  io.println("OK");
  return 0;
}
