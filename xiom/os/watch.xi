// XIOM -- Directory Watch (xiom.os.watch)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Directory-change watching for asset hot reload / editors
// (REL-20261012-2012-engine-3; POSIX leg: REL-20261016-1129-xvector
// item 2). Native change notification on both desktop platforms: Windows
// via ReadDirectoryChangesW (overlapped buffers), Linux via inotify
// (IN_CREATE/IN_MODIFY/IN_ATTRIB/IN_DELETE/IN_MOVED_FROM/IN_MOVED_TO).
// Up to 8 concurrent watches, 4 KiB change buffer, relative UTF-8 paths.
// Recursive watches subtrees: Windows in-kernel; Linux attaches one watch
// per subdirectory (bounded at 256 directories per watch, adding new
// ones as they appear). WSL2 caveat: inotify sees no events under /mnt/*
// (drvfs/9p) paths -- watch Linux-native directories there. Other POSIX
// (darwin/BSD, kqueue) is a documented Err until implemented. Delivery
// is coalesced by the OS: extra events are fine, and a rare buffer/queue
// overflow surfaces as one WATCH_OVERFLOW event (empty path). Effective
// for consumers at the next re-vendoring pin (or XIOM_RUNTIME_DIR on
// older pins).

module xiom.os.watch

use xiom.env;

extern "C" {
  fn xiom_watch_open(path: *UInt8, recursive: Int) -> Int;
  fn xiom_watch_poll(handle: Int, timeout_ms: Int, kind_out: *Int, path_buf: *UInt8, buf_len: Int) -> Int;
  fn xiom_watch_close(handle: Int) -> Int;
}

/// const WATCH_CREATE: a path was added (1).
pub const WATCH_CREATE: Int = 1;
/// const WATCH_MODIFY: a path's contents/timestamp changed (2).
pub const WATCH_MODIFY: Int = 2;
/// const WATCH_REMOVE: a path was removed (3).
pub const WATCH_REMOVE: Int = 3;
/// const WATCH_RENAME: a path was renamed (old+new records) (4).
pub const WATCH_RENAME: Int = 4;
/// const WATCH_OVERFLOW: the change buffer overflowed; records were
/// dropped (5).
pub const WATCH_OVERFLOW: Int = 5;

/// struct WatchEvent { kind: Int; path: Str } - one directory change;
/// the path is relative to the watched directory (UTF-8).
pub type WatchEvent = {
  kind: Int;
  path: Str;
}

/// watch_kind_name returns the canonical name for a watch kind ("create",
/// "modify", "remove", "rename", "overflow", "unknown"). Complexity: O(1).
/// Pure.
pub fn watch_kind_name(kind: Int) -> Str
  ensures: result.len() > 0
{
  if kind == 1 { return "create"; }
  if kind == 2 { return "modify"; }
  if kind == 3 { return "remove"; }
  if kind == 4 { return "rename"; }
  if kind == 5 { return "overflow"; }
  "unknown"
}

/// watch_dir starts watching a directory and returns an opaque handle.
/// Real implementation: ReadDirectoryChangesW on Windows (wave 124),
/// inotify on Linux (wave 171); recursive watches subtrees (the Linux
/// leg attaches up to 256 directories per watch, adding new ones as they
/// appear). Other POSIX (darwin/BSD, kqueue) is a documented Err.
/// Returns: Ok(handle > 0); Err for an empty/missing path, a
/// non-directory, an unsupported platform, or when the 8-watch table or
/// the OS open fails.
pub fn watch_dir(path: Str, recursive: Bool) -> Result[Int, Str]
  ensures: result is Ok => path.len() > 0
{
  if path.len() == 0 {
    return Err("watch_dir: empty path");
  }
  var rec = 0;
  if recursive {
    rec = 1;
  }
  let h: Int;
  unsafe {
    h = xiom_watch_open(path.c_str(), rec);
  }
  if h <= 0 {
    if env.FAMILY == "windows" {
      return Err("watch_dir: open failed (missing directory or watch table full)");
    }
    return Err("watch_dir: open failed (missing directory, watch table full, or platform without inotify)");
  }
  Ok(h)
}

/// watch_poll collects the pending change events for a watch handle,
/// waiting up to timeout_ms for the first one and draining the rest
/// immediately (up to 256 per call; later calls pick up any remainder).
/// The blocking wait is the platform primitive (overlapped event on
/// Windows, poll(2) on Linux). A buffer overflow is surfaced as one
/// WATCH_OVERFLOW event (empty path).
/// Returns: Ok(events) (possibly empty on timeout); Err on a bad handle or
/// a negative timeout.
/// Complexity: blocking wait + O(events).
pub fn watch_poll(handle: Int, timeout_ms: Int) -> Result[Vec[WatchEvent], Str]
  ensures: result is Ok => timeout_ms >= 0
  ensures: result is Ok => handle > 0
{
  if handle <= 0 {
    return Err("watch_poll: invalid handle");
  }
  if timeout_ms < 0 {
    return Err("watch_poll: negative timeout");
  }
  var out: Vec[WatchEvent] = Vec[WatchEvent].new();
  var kindv: Int = 0;
  var pbuf: [1024]UInt8;
  var first = true;
  var guard = 0;
  while guard < 256 {
    guard = guard + 1;
    var wait_ms = 0;
    if first {
      wait_ms = timeout_ms;
    }
    let rc: Int;
    unsafe {
      rc = xiom_watch_poll(handle, wait_ms, &kindv, &pbuf[0] as *UInt8, 1024);
    }
    if rc < 0 {
      return Err("watch_poll: poll failed");
    }
    if rc == 0 {
      return Ok(out);
    }
    first = false;
    if rc == 2 {
      out.push(WatchEvent{ kind: WATCH_OVERFLOW; path: ""; });
    } else {
      var pb: Vec[UInt8] = Vec[UInt8].new();
      var bi = 0;
      while bi < 1024 {
        if pbuf[bi] == 0 { break; }
        pb.push(pbuf[bi]);
        bi = bi + 1;
      }
      out.push(WatchEvent{ kind: kindv; path: Str::from_utf8(pb); });
    }
  }
  Ok(out)
}

/// watch_close releases a watch handle (best-effort; the signature returns
/// no Result, mirroring fs_ffi.munmap).
pub fn watch_close(handle: Int) {
  if handle > 0 {
    let rc: Int;
    unsafe {
      rc = xiom_watch_close(handle);
    }
    let _ = rc;
  }
}
