// p_tz_ffi.xi -- probe for tzdata phase 1: OS local-time offset via the
// CRT (_localtime64_s + _mkgmtime64). struct tm layout (MSVC, x64):
// sec(0) min(4) hour(8) mday(12) mon(16) year(20) wday(24) yday(28)
// isdst(32); buffer padded to 64 bytes.
module p_tz_ffi
use xiom.io;
use xiom.ptr;

extern "C" {
  fn time(t: *Int) -> Int;
  fn _localtime64_s(tm: *UInt8, t: *Int) -> Int32;
  fn _mkgmtime64(tm: *UInt8) -> Int;
}

fn main() -> Int {
  var t: Int = 0;
  unsafe { t = time(0); }

  var buf = Vec[UInt8].new();
  var i = 0;
  while i < 64 { buf.push(0); i = i + 1; }

  var rc: Int32 = 0;
  unsafe { rc = _localtime64_s(buf.as_mut_ptr(), &t); }
  io.println("rc=" + (rc as Int));

  var base: Int = 0;
  var sec: Int = 0;
  var min: Int = 0;
  var hour: Int = 0;
  var mday: Int = 0;
  var mon: Int = 0;
  var year: Int = 0;
  var isdst: Int = 0;
  unsafe {
    base = buf.as_mut_ptr() as Int;
    sec = ptr.read((base + 0) as *Int32) as Int;
    min = ptr.read((base + 4) as *Int32) as Int;
    hour = ptr.read((base + 8) as *Int32) as Int;
    mday = ptr.read((base + 12) as *Int32) as Int;
    mon = ptr.read((base + 16) as *Int32) as Int;
    year = ptr.read((base + 20) as *Int32) as Int;
    isdst = ptr.read((base + 32) as *Int32) as Int;
  }
  io.println("local=" + (year + 1900) + "-" + (mon + 1) + "-" + mday + " " + hour + ":" + min + ":" + sec + " isdst=" + isdst);

  var loc: Int = 0;
  unsafe { loc = _mkgmtime64(buf.as_mut_ptr()); }
  let offset = loc - t;
  io.println("utc=" + t + " mktime_local=" + loc + " offset_secs=" + offset);

  // Sanity: offset must be a whole minute within +-14h (real zones).
  if offset % 60 != 0 { io.println("offset not minute-aligned"); return 1; }
  if offset > 14 * 3600 || offset < 0 - 12 * 3600 { io.println("offset out of range"); return 2; }

  io.println("TZ FFI OK");
  return 0;
}
