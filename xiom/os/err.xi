// XIOM - OS: Error
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.os.err

// Depends on: xiom.ffi

// ============================================================================
// Error introspection: errno access, errno names and messages, perror-style
// reporting, stack backtraces, symbol demangling, and the last captured
// error. The direct errno syscall is not exposed by the pure stdlib -- the
// errno value is reported as 0 and the code tables are used for name/message
// mapping (pure). backtrace/last_error are documented stubs.
// ============================================================================

use xiom.io;
use xiom.string;

/// Return the current errno value.
/// NOT IMPLEMENTED: the runtime does not expose errno(). Returns 0.
/// Complexity: O(1). Pure.
pub fn errno() -> Int {
  0
}

/// Return the symbolic name for an errno code.
/// Parameters: code -- the errno number.
/// Returns: the symbolic name (e.g. "ENOENT"), or "EUNKNOWN".
/// Complexity: O(1). Pure.
pub fn errno_name(code: Int) -> Str {
  if code == 1 { return "EPERM"; }
  if code == 2 { return "ENOENT"; }
  if code == 3 { return "ESRCH"; }
  if code == 4 { return "EINTR"; }
  if code == 5 { return "EIO"; }
  if code == 6 { return "ENXIO"; }
  if code == 7 { return "E2BIG"; }
  if code == 8 { return "ENOEXEC"; }
  if code == 9 { return "EBADF"; }
  if code == 10 { return "ECHILD"; }
  if code == 11 { return "EAGAIN"; }
  if code == 12 { return "ENOMEM"; }
  if code == 13 { return "EACCES"; }
  if code == 14 { return "EFAULT"; }
  if code == 15 { return "ENOTBLK"; }
  if code == 16 { return "EBUSY"; }
  if code == 17 { return "EEXIST"; }
  if code == 18 { return "EXDEV"; }
  if code == 19 { return "ENODEV"; }
  if code == 20 { return "ENOTDIR"; }
  if code == 21 { return "EISDIR"; }
  if code == 22 { return "EINVAL"; }
  if code == 23 { return "ENFILE"; }
  if code == 24 { return "EMFILE"; }
  if code == 25 { return "ENOTTY"; }
  if code == 26 { return "ETXTBSY"; }
  if code == 27 { return "EFBIG"; }
  if code == 28 { return "ENOSPC"; }
  if code == 29 { return "ESPIPE"; }
  if code == 30 { return "EROFS"; }
  if code == 31 { return "EMLINK"; }
  if code == 32 { return "EPIPE"; }
  if code == 33 { return "EDOM"; }
  if code == 34 { return "ERANGE"; }
  if code == 35 { return "EDEADLK"; }
  if code == 36 { return "ENAMETOOLONG"; }
  if code == 37 { return "ENOLCK"; }
  if code == 38 { return "ENOSYS"; }
  if code == 39 { return "ENOTEMPTY"; }
  if code == 40 { return "ELOOP"; }
  if code == 42 { return "ENOMSG"; }
  if code == 43 { return "EIDRM"; }
  if code == 61 { return "ENODATA"; }
  if code == 62 { return "ETIME"; }
  if code == 71 { return "EPROTO"; }
  if code == 74 { return "EBADMSG"; }
  if code == 75 { return "EOVERFLOW"; }
  if code == 84 { return "EILSEQ"; }
  if code == 88 { return "ENOTSOCK"; }
  if code == 89 { return "EDESTADDRREQ"; }
  if code == 90 { return "EMSGSIZE"; }
  if code == 91 { return "EPROTOTYPE"; }
  if code == 92 { return "ENOPROTOOPT"; }
  if code == 93 { return "EPROTONOSUPPORT"; }
  if code == 95 { return "EOPNOTSUPP"; }
  if code == 97 { return "EAFNOSUPPORT"; }
  if code == 98 { return "EADDRINUSE"; }
  if code == 99 { return "EADDRNOTAVAIL"; }
  if code == 100 { return "ENETDOWN"; }
  if code == 101 { return "ENETUNREACH"; }
  if code == 102 { return "ENETRESET"; }
  if code == 103 { return "ECONNABORTED"; }
  if code == 104 { return "ECONNRESET"; }
  if code == 105 { return "ENOBUFS"; }
  if code == 106 { return "EISCONN"; }
  if code == 107 { return "ENOTCONN"; }
  if code == 108 { return "ESHUTDOWN"; }
  if code == 110 { return "ETIMEDOUT"; }
  if code == 111 { return "ECONNREFUSED"; }
  if code == 112 { return "EHOSTDOWN"; }
  if code == 113 { return "EHOSTUNREACH"; }
  if code == 114 { return "EALREADY"; }
  if code == 115 { return "EINPROGRESS"; }
  "EUNKNOWN"
}

/// Return the human-readable message for an errno code.
/// Parameters: code -- the errno number.
/// Returns: the descriptive message, or "unknown error".
/// Complexity: O(1). Pure.
pub fn strerror(code: Int) -> Str {
  if code == 1 { return "operation not permitted"; }
  if code == 2 { return "no such file or directory"; }
  if code == 3 { return "no such process"; }
  if code == 4 { return "interrupted system call"; }
  if code == 5 { return "input/output error"; }
  if code == 9 { return "bad file descriptor"; }
  if code == 11 { return "resource temporarily unavailable"; }
  if code == 12 { return "cannot allocate memory"; }
  if code == 13 { return "permission denied"; }
  if code == 16 { return "device or resource busy"; }
  if code == 17 { return "file exists"; }
  if code == 20 { return "not a directory"; }
  if code == 21 { return "is a directory"; }
  if code == 22 { return "invalid argument"; }
  if code == 24 { return "too many open files"; }
  if code == 28 { return "no space left on device"; }
  if code == 32 { return "broken pipe"; }
  if code == 36 { return "file name too long"; }
  if code == 38 { return "function not implemented"; }
  if code == 39 { return "directory not empty"; }
  if code == 90 { return "message too long"; }
  if code == 98 { return "address already in use"; }
  if code == 99 { return "cannot assign requested address"; }
  if code == 101 { return "network is unreachable"; }
  if code == 104 { return "connection reset by peer"; }
  if code == 110 { return "connection timed out"; }
  if code == 111 { return "connection refused"; }
  if code == 113 { return "no route to host"; }
  if code == 115 { return "operation now in progress"; }
  "unknown error"
}

/// Print msg plus the current errno message.
/// Parameters: msg -- the prefix message.
/// Returns: Unit. Prints "msg: <errno message>" (stdout; the runtime exposes
///          no stderr writer).
/// Complexity: O(1). Pure.
pub fn perror(msg: Str) -> Unit {
  let joined = msg + ": " + errno_message();
  let _ = io.println(joined);
}

/// Return the message for the current errno value.
/// Returns: strerror(errno()).
/// Complexity: O(1). Pure.
pub fn errno_message() -> Str {
  strerror(errno())
}

/// Set the errno value.
/// NOT IMPLEMENTED: the runtime does not expose errno(). No-op.
pub fn errno_set(code: Int) -> Unit {
  let _ = code;
}

/// Capture the current call stack as formatted frame strings.
/// NOT IMPLEMENTED: the runtime does not expose a backtrace API. Returns an
/// empty vector.
/// Complexity: O(1). Pure.
pub fn backtrace() -> Vec[Str] {
  var out = Vec[Str].new();
  out
}

/// Resolve raw frame addresses to symbols.
/// NOT IMPLEMENTED: the runtime does not expose a symbolizer. Returns an
/// empty vector.
/// Complexity: O(1). Pure.
pub fn backtrace_symbols(frames: &Vec[Int]) -> Vec[Str] {
  let _ = frames;
  var out = Vec[Str].new();
  out
}

/// Demangle a compiler-mangled symbol name.
/// NOT IMPLEMENTED: no demangler is available. Returns the symbol unchanged.
/// Complexity: O(1). Pure.
pub fn demangle(symbol: Str) -> Str {
  symbol
}

/// Return the most recently captured error string.
/// NOT IMPLEMENTED: no error capture is wired in. Returns "".
/// Complexity: O(1). Pure.
pub fn last_error() -> Str {
  ""
}

/// Format an errno code as "name (code): message".
/// Parameters: code -- the errno number.
/// Returns: the formatted string.
/// Complexity: O(1). Pure.
pub fn errno_to_string(code: Int) -> Str {
  let name = errno_name(code);
  let message = strerror(code);
  var result = name;
  result = result + " (";
  result = result + code.to_str();
  result = result + "): ";
  result = result + message;
  result
}
