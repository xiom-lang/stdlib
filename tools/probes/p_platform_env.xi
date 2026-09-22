// p_platform_env.xi -- print the compile-time platform constants and the
// platform helpers; used by the ubuntu smoke probe to verify env.OS/FAMILY
// on Linux (smoke_os_ffi's Windows guard depends on platform_is_windows).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_platform_env

use xiom.io;
use xiom.io.fs;
use xiom.os;
use xiom.convert;
use xiom.os.platform;

fn main() -> Int {
  io.println("env.OS=[" + xiom.env.OS + "]");
  io.println("env.FAMILY=[" + xiom.env.FAMILY + "]");
  io.println("env.ARCH=[" + xiom.env.ARCH + "]");
  io.println("os.platform.name=[" + platform.platform_name() + "]");
  io.println("os.platform.is_windows=" + convert.bool_to_string(platform.platform_is_windows()));
  io.println("os.platform.is_linux=" + convert.bool_to_string(platform.platform_is_linux()));
  io.println("core.platform.is_windows=" + convert.bool_to_string(xiom.core.platform.is_windows()));
  io.println("core.platform.os_name=[" + xiom.core.platform.os_name() + "]");
  io.println("fs.fs_temp_dir=[" + fs.fs_temp_dir() + "]");
  io.println("os.temp_dir=[" + os.temp_dir() + "]");
  io.println("platform.family=[" + platform.platform_family() + "]");
  return 0;
}