# Event loop beyond poll -- scoping plan (2026-10-17)

Status: scoping + first leg. This file records the phase-2 shelf plan for
REL-20261015-2202-pulse item 10 ("Event loop beyond poll") and the first
leg landed in wave 175 (`socket_listen_fds`).

## Current state (verified 2026-10-17)

- `xiom.net.socket.socket_poll_read/write` are real (`poll()` on POSIX,
  `WSAPoll` on Windows) but capped at 1024 fds and require a bounded
  timeout (`timeout_ms >= 0`; no unbounded wait).
- `socket_poll_*` compact ready fds in input order and treat error/invalid
  entries as ready so the caller can inspect them.
- `socket_listen_fds` (wave 175) adopts systemd socket activation:
  `LISTEN_PID` must match the process, `LISTEN_FDS` is the count, fds are
  `3..3+N-1`, max 1024. POSIX-only; consumes `LISTEN_PID`/`LISTEN_FDS` on
  success and leaves `LISTEN_FDNAMES` for the caller.
- No epoll/kqueue/IOCP/select wrapper exists. `xiom.net.socket` is the
  only readiness surface consumers use today.

## Target shape

One portable readiness layer with three backends and one compatibility
fallback:

| Platform | Backend | Notes |
|---|---|---|
| Linux | epoll | edge-triggered registration; level-triggered default; fd reuse across calls |
| macOS/BSD | kqueue | EVFILT_READ/WRITE; one-shot optional |
| Windows | IOCP | completion-based; a readiness shim may be needed for sockets |
| other POSIX | poll fallback | existing 1024-fd behavior, documented |

Proposed public surface (names provisional; keep it small):

```
pub type EventLoop = { handle: Int; }
pub type Event = { fd: Int; readable: Bool; writable: Bool; error: Bool; }

eventloop_new() -> Result[EventLoop, Str]
eventloop_add(loop: &mut EventLoop, fd: Int, read: Bool, write: Bool) -> Result[Unit, Str]
eventloop_modify(loop: &mut EventLoop, fd: Int, read: Bool, write: Bool) -> Result[Unit, Str]
eventloop_remove(loop: &mut EventLoop, fd: Int) -> Result[Unit, Str]
eventloop_wait(loop: &mut EventLoop, timeout_ms: Int, out: &mut Vec[Event]) -> Result[Int, Str]
eventloop_close(loop: &mut EventLoop)
```

`timeout_ms < 0` means block indefinitely; 0 means poll. `eventloop_wait`
returns the number of events appended to `out` (0 on timeout). The wrapper
owns only the loop handle; it never closes registered fds.

## Runtime work (C)

Add one ABI with four entry points, implemented per platform:

```
xiom_eventloop_create() -> Int
xiom_eventloop_ctl(handle, op, fd, read, write) -> Int
xiom_eventloop_wait(handle, timeout_ms, out_fds, out_flags, max) -> Int
xiom_eventloop_close(handle) -> Int
```

- Linux: `epoll_create1` + `epoll_ctl` + `epoll_wait`; flags map
  `EPOLLIN/EPOLLOUT/EPOLLERR/EPOLLHUP`.
- macOS/BSD: `kqueue` + `kevent`; read/write filters.
- Windows: IOCP is completion-based, not readiness-based. Stage it behind
  the same API using a socket readiness shim (WSAEventSelect + wait), or
  keep `WSAPoll` as the Windows backend and mark IOCP as a later slice.
  Do not pretend IOCP is a drop-in readiness API.
- Fallback: `poll()` over a dynamic array (no 1024 cap; allocate per call).

## Staged checklist

- [x] Wave 175: `socket_listen_fds` + this scoping plan + probe
  `p_wave175_shapes`.
- [x] Wave 176: runtime `xiom_eventloop_*` ABI + Linux epoll backend;
  pipe/socketpair probe (`p_wave176_shapes`) with timeout, read/write,
  error and remove rows. Landed 2026-10-17; Windows/macOS remain the
  explicit -1 stubs until waves 177/178.
- [ ] Wave 177: kqueue backend on macOS/BSD; same probe via the WSL/macOS
  leg; keep the poll fallback.
- [ ] Wave 178: Windows backend decision (WSAPoll shim first; IOCP only
  with a separate completion API); document the choice.
- [ ] Wave 179: `xiom.net.event` wrapper + typed `Event`; adapter from
  `socket_poll_read/write`; PULSE consumer smoke.
- [ ] Wave 180: `LISTEN_FDS` integration in the server path (adopt
  inherited listeners before `socket_listen`; support reload/drain).

## Contracts and lifetime rules

- The loop handle is opaque; `eventloop_close` is idempotent-safe and never
  closes registered fds.
- `eventloop_wait` appends to `out`; callers may reuse one vector per loop.
- Registration is level-triggered by default; edge-triggered is a later
  flag, not a separate API.
- `eventloop_wait` with `timeout_ms < 0` may block forever; the wrapper
  must expose that explicitly and the docs must warn.
- `eventloop_ctl` on a closed loop is an Err, never a trap.
- The 1024-fd cap stays only in the poll fallback; the epoll/kqueue paths
  accept the backend's descriptor limit.

## Test matrix

| Row | Linux | macOS/BSD | Windows |
|---|---|---|---|
| add/read readiness | epoll | kqueue | WSAPoll/IOCP shim |
| add/write readiness | epoll | kqueue | WSAPoll/IOCP shim |
| timeout 0 / bounded / -1 | epoll | kqueue | WSAPoll |
| remove then wait | epoll | kqueue | WSAPoll |
| closed/invalid fd | Err/ready | Err/ready | Err/ready |
| >1024 fds on fallback | poll Err | poll Err | poll Err |
| LISTEN_FDS adoption | wave 175 | unsupported (POSIX-only) | unsupported |

## Non-goals

- Replacing `socket_poll_read/write`; they stay as the compatibility path.
- A full async runtime or green threads.
- TLS/ALPN integration; that lives in `xiom.net.tls*`.
- HTTP/2 connection state; the frame/HPACK foundation is `xiom.net.h2`
  (wave 174), with connection state explicitly out of that module.
