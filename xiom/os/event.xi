// XIOM - OS: Event
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.os.event

// ============================================================================
// Async I/O event loops via FFI: epoll, kqueue, eventfd, timerfd, signalfd,
// poll/ppoll, and select/pselect. Per-OS availability varies; the fallback
// set is poll/select which exist on all supported platforms.
// ============================================================================

// struct EpollEvent { events: UInt32, data: UInt64 } - one epoll readiness event; layout matches struct epoll_event.
// struct KEvent { ident: UInt64, filter: Int16, flags: UInt16, fflags: UInt32, data: Int64 } - one kqueue event; layout matches struct kevent.
// struct PollFd { fd: Int, events: Int16, revents: Int16 } - one poll descriptor; layout matches struct pollfd.

// fn epoll_create() -> Result[Int, Str] - create an epoll instance and return its fd. TODO(compiler): implement.
// fn epoll_add(ep: Int, fd: Int, events: Int) -> Result[Unit, Str] - register fd with the epoll instance. TODO(compiler): implement.
// fn epoll_mod(ep: Int, fd: Int, events: Int) -> Result[Unit, Str] - change the event mask for fd. TODO(compiler): implement.
// fn epoll_del(ep: Int, fd: Int) -> Result[Unit, Str] - remove fd from the epoll instance. TODO(compiler): implement.
// fn epoll_wait(ep: Int, max_events: Int, timeout_ms: Int) -> Result[Vec[EpollEvent], Str] - wait for and return ready events. TODO(compiler): implement.
// fn epoll_close(ep: Int) -> Unit - close the epoll fd. TODO(compiler): implement.
// fn kqueue_create() -> Result[Int, Str] - create a kqueue and return its fd. TODO(compiler): implement.
// fn kqueue_add_read(kq: Int, fd: Int) -> Unit - register fd for EVFILT_READ events. TODO(compiler): implement.
// fn kqueue_add_write(kq: Int, fd: Int) -> Unit - register fd for EVFILT_WRITE events. TODO(compiler): implement.
// fn kqueue_wait(kq: Int, timeout_ms: Int) -> Result[Vec[KEvent], Str] - wait for and return kqueue events. TODO(compiler): implement.
// fn kqueue_close(kq: Int) -> Unit - close the kqueue fd. TODO(compiler): implement.
// fn eventfd_new(init: Int) -> Result[Int, Str] - create an eventfd with the given initial counter. TODO(compiler): implement.
// fn eventfd_read(fd: Int) -> Result[Int, Str] - read and reset the eventfd counter. TODO(compiler): implement.
// fn eventfd_write(fd: Int, value: Int) -> Result[Unit, Str] - add value to the eventfd counter, waking readers. TODO(compiler): implement.
// fn timerfd_new() -> Result[Int, Str] - create a timerfd. TODO(compiler): implement.
// fn timerfd_set(fd: Int, ms: Int) -> Result[Unit, Str] - arm the timerfd to fire after ms milliseconds. TODO(compiler): implement.
// fn signalfd_new(signals: &Vec[Int]) -> Result[Int, Str] - create a signalfd for the given signal numbers. TODO(compiler): implement.
// fn poll(fds: &Vec[PollFd], timeout_ms: Int) -> Result[Int, Str] - poll the descriptors and update revents; returns ready count. TODO(compiler): implement.
// fn ppoll(fds: &Vec[PollFd], timeout_ms: Int) -> Result[Int, Str] - poll with a millisecond timeout, atomic wrt signal mask. TODO(compiler): implement.
// fn select(read_fds: &Vec[Int], write_fds: &Vec[Int], timeout_ms: Int) -> Result[Int, Str] - wait on the given fd sets; returns ready count. TODO(compiler): implement.
// fn pselect(read_fds: &Vec[Int], write_fds: &Vec[Int], timeout_ms: Int) -> Result[Int, Str] - select with a millisecond timeout, atomic wrt signal mask. TODO(compiler): implement.
