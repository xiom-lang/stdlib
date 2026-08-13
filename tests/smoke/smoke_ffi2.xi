// XIOM stdlib smoke - xiom.ffi.c + dl + errno
// Returns 0 on success, nonzero (and a tag) on failure.
//
// NOTE: the Int-to-pointer cast (`x as *UInt8`) is broken in this build, so
// the pointer-taking helpers (c_strlen, c_strcmp, dl_sym, ...) cannot be
// exercised from user code; the tested paths are the scalar helpers and the
// errno API.

module smoke_ffi2
use xiom.ffi.c;
use xiom.ffi.dl;
use xiom.ffi.errno;
use xiom.io;

fn fail(tag: Str) -> Int {
  io.println("smoke_ffi2 FAIL: " + tag);
  return 1;
}

fn main() -> Int {
  let msg2 = errno.errno_strerror(2);
  if msg2 != "No such file or directory" { return fail("e-strerror2"); }
  if errno.errno_name(2) != "ENOENT" { return fail("e-name-enoent"); }
  if errno.errno_name(13) != "EACCES" { return fail("e-name-eacces"); }
  if errno.errno_name(999) != "UNKNOWN" { return fail("e-name-unknown"); }
  if !errno.errno_is_error(2) { return fail("e-is-error"); }
  if errno.errno_is_error(0) { return fail("e-is-zero"); }
  errno.errno_set(2);
  if errno.errno_get() != 2 { return fail("e-get"); }
  if errno.errno_last() != 2 { return fail("e-last"); }
  errno.errno_set(0);
  errno.errno_perror("probe");

  if c.c_abs(-7) != 7 { return fail("c-abs"); }
  c.c_srand(42);
  let r1 = c.c_rand();
  c.c_srand(42);
  let r2 = c.c_rand();
  if r1 != r2 { return fail("c-rand-seeded"); }
  let r3 = c.c_rand();
  if r3 == 0 { return fail("c-rand-zero"); }
  let clk = c.c_clock();
  if clk < 0 { return fail("c-clock"); }

  let selfh = dl.dl_self();
  if selfh == 0 { return fail("d-self"); }
  let handle = dl.dl_open("kernel32.dll");
  match handle {
    Ok(h) => {
      if h == 0 { return fail("d-handle"); }
    };
    Err(_) => { return fail("d-open"); }
  }
  let badopen = dl.dl_open("no_such_library_xyz.dll");
  if badopen.is_ok { return fail("d-open-bad"); }
  let derr = dl.dl_error();
  if derr.len() == 0 { return fail("d-error-empty"); }
  let glob = dl.dl_open_global("kernel32.dll");
  match glob {
    Ok(h) => {
      if h == 0 { return fail("d-open-global-zero"); }
    };
    Err(_) => { return fail("d-open-global"); }
  }

  io.println("smoke_ffi2 OK");
  return 0;
}