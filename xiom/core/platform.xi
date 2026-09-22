// XIOM -- Platform Abstraction (OS, arch, environment detection)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Provides a unified interface for querying the runtime platform.
// All functions are free-standing and delegate to xiom.env, xiom.os, or
// compile-time constants where available.
//
// Values are determined at compile time via xiom.env.OS and xiom.env.ARCH
// (set by the XIOM compiler / runtime). Endianness and pointer width are
// platform constants for the current build target.

module xiom.platform

use xiom.env;
use xiom.os;
use xiom.convert.cstring;

extern "C" {
  fn xiom_os_name() -> *UInt8;
}

// Runtime-backed (the compile-time env.OS constant reported "windows" on the
// ubuntu runner, 2026-09-22); arch_name still uses env.ARCH.
fn _rt_os_name() -> Str
  requires: true
{
  unsafe { return cstring.from_cstring(xiom_os_name() as Int); }
}

// -- OS name ------------------------------------------------------------------

/// Return the operating system name as a lowercase string.
/// Delegates to xiom.env.OS (compile-time constant).
/// Possible values: "windows", "linux", "macos", "freebsd", "openbsd", "unknown".
pub fn os_name() -> Str
    ensures: result.len() > 0
{
    return _rt_os_name();
}

// -- Boolean OS checks --------------------------------------------------------

/// True when the target OS is Windows.
pub fn is_windows() -> Bool {
    return _rt_os_name() == "windows";
}

/// True when the target OS is Linux.
pub fn is_linux() -> Bool {
    return _rt_os_name() == "linux";
}

/// True when the target OS is macOS (Darwin).
pub fn is_macos() -> Bool {
    return _rt_os_name() == "macos";
}

/// True when the target OS is a BSD variant (freebsd, openbsd, netbsd).
pub fn is_bsd() -> Bool {
    let os = _rt_os_name();
    return os == "freebsd" || os == "openbsd" || os == "netbsd" || os == "dragonfly";
}

/// True when the target OS is a Unix-like system (Linux, macOS, BSD).
/// This is the negation of is_windows().
pub fn is_unix() -> Bool {
    !is_windows()
}

// -- Architecture -------------------------------------------------------------

/// Return the CPU architecture name as a lowercase string.
/// Delegates to xiom.env.ARCH (compile-time constant).
/// Possible values: "x86_64", "aarch64", "riscv64", etc.
/// If no intrinsic is available, returns "unknown".
pub fn arch_name() -> Str
    ensures: result.len() > 0
{
    xiom.env.ARCH
}

// -- Endianness ---------------------------------------------------------------

/// Returns true if the current platform is little-endian.
/// On x86_64 and aarch64 (which dominate current hardware), this is always true.
/// For a full runtime check, a known integer pattern would be inspected via
/// pointer casting, but the XIOM compiler currently lacks raw pointer deref.
/// Documented as: true on all current XIOM targets (x86_64, aarch64).
pub fn endian_is_little() -> Bool {
    true
}

// -- System resources ---------------------------------------------------------

/// Return the system page size in bytes (typically 4096).
/// No cross-platform FFI intrinsic exists yet; returns the most common value.
pub fn page_size() -> Int
    ensures: result > 0
{
    4096
}

/// Return the number of logical CPU cores available.
/// Delegates to xiom.os.cpu_count() (which calls xiom_cpu_count runtime function).
pub fn cpu_count() -> Int
    ensures: result >= 1
{
    xiom.os.cpu_count()
}

// -- Text conventions ---------------------------------------------------------

/// Return the platform-specific newline sequence.
/// Returns "\r\n" on Windows, "\n" everywhere else.
pub fn newline() -> Str
    ensures: result.len() > 0
{
    if is_windows() {
        return "\r\n";
    };
    "\n"
}

/// Return the platform-specific path separator.
/// Returns "\\" on Windows, "/" everywhere else.
pub fn path_sep() -> Str
    ensures: result.len() > 0
{
    xiom.env.path_separator()
}

// -- Pointer width ------------------------------------------------------------

/// Returns true if the platform uses 64-bit pointers.
/// XIOM Int is always 64-bit, so this is always true.
pub fn is_64bit() -> Bool {
    true
}

// -- OS version (best-effort) -------------------------------------------------

/// Return the operating system version string.
/// Best-effort: reads environment variables or delegates to OS-specific APIs.
/// On Windows: attempts "OS" or "VER" environment variable.
/// On Unix: attempts "OSTYPE" or returns "unknown".
/// Returns "unknown" if no version information is available.
pub fn os_version() -> Str {
    if is_windows() {
        let ver_opt = xiom.env.var_opt("OS");
        match ver_opt {
            Some(v) => return v;
            None => {}
        };
        return "Windows";
    };
    if is_linux() {
        let ostype_opt = xiom.env.var_opt("OSTYPE");
        match ostype_opt {
            Some(v) => return v;
            None => {}
        };
        return "Linux";
    };
    if is_macos() {
        return "macOS";
    };
    "unknown"
}
