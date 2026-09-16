// XIOM -- Time: timezone offset (tzdata phase 1)
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.time.tz

use xiom.time;
use xiom.string;
use xiom.convert;
use xiom.ptr;

// ============================================================================
// Local-time offset (tzdata phase 1).
//
// Phase 1 exposes the OS's CURRENT local offset from UTC, DST-aware, via the
// C runtime (`_localtime64_s` + `_mkgmtime64`: offset = mkgmtime(local(t)) -
// t). This is exact for the host's configured zone including DST at the
// queried instant; it is NOT a zone database -- no historical offsets, no
// zone names, no arbitrary-zone conversion (phase 2 / tzdata files).
// ============================================================================

extern "C" {
  fn time(t: *Int) -> Int;
  fn _localtime64_s(tm: *UInt8, t: *Int) -> Int32;
  fn _mkgmtime64(tm: *UInt8) -> Int;
}

const _TM_BYTES: Int = 64;   // struct tm fields (36 bytes) + padding
const _TM_OFF_ISDST: Int = 32;

fn _tm_zeroed() -> Vec[UInt8] {
  var buf = Vec[UInt8].new();
  var i = 0;
  while i < _TM_BYTES {
    buf.push(0);
    i = i + 1;
  }
  return buf;
}

fn _utc_now_secs() -> Int {
  var t: Int = 0;
  unsafe {
    t = time(0);
  }
  return t;
}

fn _tm_isdst(buf: &Vec[UInt8]) -> Int {
  var v: Int = 0;
  unsafe {
    let base = buf.as_mut_ptr() as Int;
    v = ptr.read((base + _TM_OFF_ISDST) as *Int32) as Int;
  }
  return v;
}

/// Local offset from UTC in seconds at an explicit Unix epoch (DST-aware).
/// Positive means local time is ahead of UTC.
pub fn tz_offset_secs_at(epoch: Int) -> Result[Int, Str] {
  var buf = _tm_zeroed();
  var e = epoch;
  var rc: Int32 = 0;
  unsafe {
    rc = _localtime64_s(buf.as_mut_ptr(), &e);
  }
  if rc != 0 {
    return Err("tz: localtime failed for epoch " + convert.int_to_string(epoch));
  }
  var loc: Int = 0;
  unsafe {
    loc = _mkgmtime64(buf.as_mut_ptr());
  }
  if loc == 0 - 1 {
    return Err("tz: mkgmtime failed for epoch " + convert.int_to_string(epoch));
  }
  return Ok(loc - epoch);
}

/// Current local offset from UTC in seconds (DST-aware for the host zone).
pub fn tz_local_offset_secs() -> Result[Int, Str] {
  return tz_offset_secs_at(_utc_now_secs());
}

/// True when the host zone is currently observing daylight saving time.
pub fn tz_is_dst() -> Result[Bool, Str] {
  var buf = _tm_zeroed();
  var e = _utc_now_secs();
  var rc: Int32 = 0;
  unsafe {
    rc = _localtime64_s(buf.as_mut_ptr(), &e);
  }
  if rc != 0 {
    return Err("tz: localtime failed");
  }
  return Ok(_tm_isdst(&buf) > 0);
}

/// Current local Unix epoch (UTC seconds + local offset).
pub fn tz_local_epoch_secs() -> Result[Int, Str] {
  let offset = tz_local_offset_secs();
  match offset {
    Ok(o) => { return Ok(_utc_now_secs() + o); },
    Err(err) => { return Err(err); },
  }
}

/// Current local wall-clock DateTime for the host zone.
pub fn tz_local_now() -> Result[DateTime, Str] {
  let local = tz_local_epoch_secs();
  match local {
    Ok(epoch) => { return Ok(time.datetime_from_epoch(epoch)); },
    Err(err) => { return Err(err); },
  }
}
