// XIOM - OS: Event
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.os.event

// Depends on: xiom.ffi

// ============================================================================
// Async I/O event loops via FFI: epoll, kqueue, eventfd, timerfd, signalfd,
// poll/ppoll, and select/pselect. The descriptor structs are provided so
// callers can build poll sets; the system calls themselves are Linux/BSD
// specific and not exposed by the pure stdlib -- every function is a
// documented stub returning Err.
// ============================================================================

/// struct EpollEvent { events: UInt32, data: UInt64 } - one epoll readiness
/// event; layout matches struct epoll_event.
pub type EpollEvent = {
  events: UInt32;
  data: UInt64;
}

/// struct KEvent { ident: UInt64, filter: Int16, flags: UInt16, fflags: UInt32,
///   data: Int64 } - one kqueue event; layout matches struct kevent.
pub type KEvent = {
  ident: UInt64;
  filter: Int16;
  flags: UInt16;
  fflags: UInt32;
  data: Int64;
}

/// struct PollFd { fd: Int, events: Int16, revents: Int16 } - one poll
/// descriptor; layout matches struct pollfd.
pub type PollFd = {
  fd: Int;
  events: Int16;
  revents: Int16;
}

/// Create an epoll instance and return its fd.
/// NOT IMPLEMENTED: requires the epoll syscall (Linux-only; not exposed by
/// the pure stdlib).
/// Returns: Err("epoll_create: epoll is not available in the pure stdlib").
pub fn epoll_create() -> Result[Int, Str] {
  Err("epoll_create: epoll is not available in the pure stdlib")
}

/// Register fd with the epoll instance.
/// NOT IMPLEMENTED: requires the epoll syscall (see epoll_create).
/// Returns: Err("epoll_add: epoll is not available in the pure stdlib").
pub fn epoll_add(ep: Int, fd: Int, events: Int) -> Result[Unit, Str] {
  let _ = ep;
  let _ = fd;
  let _ = events;
  Err("epoll_add: epoll is not available in the pure stdlib")
}

/// Change the event mask for fd.
/// NOT IMPLEMENTED: requires the epoll syscall (see epoll_create).
/// Returns: Err("epoll_mod: epoll is not available in the pure stdlib").
pub fn epoll_mod(ep: Int, fd: Int, events: Int) -> Result[Unit, Str] {
  let _ = ep;
  let _ = fd;
  let _ = events;
  Err("epoll_mod: epoll is not available in the pure stdlib")
}

/// Remove fd from the epoll instance.
/// NOT IMPLEMENTED: requires the epoll syscall (see epoll_create).
/// Returns: Err("epoll_del: epoll is not available in the pure stdlib").
pub fn epoll_del(ep: Int, fd: Int) -> Result[Unit, Str] {
  let _ = ep;
  let _ = fd;
  Err("epoll_del: epoll is not available in the pure stdlib")
}

/// Wait for and return ready events.
/// NOT IMPLEMENTED: requires the epoll syscall (see epoll_create).
/// Returns: Err("epoll_wait: epoll is not available in the pure stdlib").
pub fn epoll_wait(ep: Int, max_events: Int, timeout_ms: Int) -> Result[Vec[EpollEvent], Str] {
  let _ = ep;
  let _ = max_events;
  let _ = timeout_ms;
  Err("epoll_wait: epoll is not available in the pure stdlib")
}

/// Close the epoll fd.
/// NO-OP: no epoll instances exist in the pure stdlib.
pub fn epoll_close(ep: Int) -> Unit {
  let _ = ep;
}

/// Create a kqueue and return its fd.
/// NOT IMPLEMENTED: requires the kqueue syscall (BSD/macOS-only; not exposed
/// by the pure stdlib).
/// Returns: Err("kqueue_create: kqueue is not available in the pure stdlib").
pub fn kqueue_create() -> Result[Int, Str] {
  Err("kqueue_create: kqueue is not available in the pure stdlib")
}

/// Register fd for EVFILT_READ events.
/// NO-OP: no kqueue instances exist in the pure stdlib.
pub fn kqueue_add_read(kq: Int, fd: Int) -> Unit {
  let _ = kq;
  let _ = fd;
}

/// Register fd for EVFILT_WRITE events.
/// NO-OP: no kqueue instances exist in the pure stdlib.
pub fn kqueue_add_write(kq: Int, fd: Int) -> Unit {
  let _ = kq;
  let _ = fd;
}

/// Wait for and return kqueue events.
/// NOT IMPLEMENTED: requires the kqueue syscall (see kqueue_create).
/// Returns: Err("kqueue_wait: kqueue is not available in the pure stdlib").
pub fn kqueue_wait(kq: Int, timeout_ms: Int) -> Result[Vec[KEvent], Str] {
  let _ = kq;
  let _ = timeout_ms;
  Err("kqueue_wait: kqueue is not available in the pure stdlib")
}

/// Close the kqueue fd.
/// NO-OP: no kqueue instances exist in the pure stdlib.
pub fn kqueue_close(kq: Int) -> Unit {
  let _ = kq;
}

/// Create an eventfd with the given initial counter.
/// NOT IMPLEMENTED: requires the eventfd syscall (Linux-only; not exposed by
/// the pure stdlib).
/// Returns: Err("eventfd_new: eventfd is not available in the pure stdlib").
pub fn eventfd_new(init: Int) -> Result[Int, Str] {
  let _ = init;
  Err("eventfd_new: eventfd is not available in the pure stdlib")
}

/// Read and reset the eventfd counter.
/// NOT IMPLEMENTED: requires the eventfd syscall (see eventfd_new).
/// Returns: Err("eventfd_read: eventfd is not available in the pure stdlib").
pub fn eventfd_read(fd: Int) -> Result[Int, Str] {
  let _ = fd;
  Err("eventfd_read: eventfd is not available in the pure stdlib")
}

/// Add value to the eventfd counter, waking readers.
/// NOT IMPLEMENTED: requires the eventfd syscall (see eventfd_new).
/// Returns: Err("eventfd_write: eventfd is not available in the pure stdlib").
pub fn eventfd_write(fd: Int, value: Int) -> Result[Unit, Str] {
  let _ = fd;
  let _ = value;
  Err("eventfd_write: eventfd is not available in the pure stdlib")
}

/// Create a timerfd.
/// NOT IMPLEMENTED: requires the timerfd syscall (Linux-only; not exposed by
/// the pure stdlib).
/// Returns: Err("timerfd_new: timerfd is not available in the pure stdlib").
pub fn timerfd_new() -> Result[Int, Str] {
  Err("timerfd_new: timerfd is not available in the pure stdlib")
}

/// Arm the timerfd to fire after ms milliseconds.
/// NOT IMPLEMENTED: requires the timerfd syscall (see timerfd_new).
/// Returns: Err("timerfd_set: timerfd is not available in the pure stdlib").
pub fn timerfd_set(fd: Int, ms: Int) -> Result[Unit, Str] {
  let _ = fd;
  let _ = ms;
  Err("timerfd_set: timerfd is not available in the pure stdlib")
}

/// Create a signalfd for the given signal numbers.
/// NOT IMPLEMENTED: requires the signalfd syscall (Linux-only; not exposed by
/// the pure stdlib).
/// Returns: Err("signalfd_new: signalfd is not available in the pure stdlib").
pub fn signalfd_new(signals: &Vec[Int]) -> Result[Int, Str] {
  let _ = signals;
  Err("signalfd_new: signalfd is not available in the pure stdlib")
}

/// Poll the descriptors and update revents; returns the ready count.
/// NOT IMPLEMENTED: requires the poll syscall (not exposed by the pure
/// stdlib).
/// Returns: Err("poll: poll is not available in the pure stdlib").
pub fn poll(fds: &Vec[PollFd], timeout_ms: Int) -> Result[Int, Str] {
  let _ = fds;
  let _ = timeout_ms;
  Err("poll: poll is not available in the pure stdlib")
}

/// Poll with a millisecond timeout, atomic wrt the signal mask.
/// NOT IMPLEMENTED: requires the ppoll syscall (not exposed by the pure
/// stdlib).
/// Returns: Err("ppoll: ppoll is not available in the pure stdlib").
pub fn ppoll(fds: &Vec[PollFd], timeout_ms: Int) -> Result[Int, Str] {
  let _ = fds;
  let _ = timeout_ms;
  Err("ppoll: ppoll is not available in the pure stdlib")
}

/// Wait on the given fd sets; returns the ready count.
/// NOT IMPLEMENTED: requires the select syscall (not exposed by the pure
/// stdlib).
/// Returns: Err("select: select is not available in the pure stdlib").
pub fn select(read_fds: &Vec[Int], write_fds: &Vec[Int], timeout_ms: Int) -> Result[Int, Str] {
  let _ = read_fds;
  let _ = write_fds;
  let _ = timeout_ms;
  Err("select: select is not available in the pure stdlib")
}

/// Select with a millisecond timeout, atomic wrt the signal mask.
/// NOT IMPLEMENTED: requires the pselect syscall (not exposed by the pure
/// stdlib).
/// Returns: Err("pselect: pselect is not available in the pure stdlib").
pub fn pselect(read_fds: &Vec[Int], write_fds: &Vec[Int], timeout_ms: Int) -> Result[Int, Str] {
  let _ = read_fds;
  let _ = write_fds;
  let _ = timeout_ms;
  Err("pselect: pselect is not available in the pure stdlib")
}
