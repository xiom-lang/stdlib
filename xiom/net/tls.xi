// XIOM -- TLS Protocol Helpers (xiom.net.tls)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Pure TLS version/cipher/alert/handshake name helpers per RFC 5246
// and related RFCs, plus (wave 154, plan item 9 wave-A; refs
// REL-20261015-2202-pulse item 1) the backend-independent TLS
// scaffolding:
//
//   (1) RFC 7301 ALPN codec -- alpn_encode / alpn_decode over the
//       ProtocolNameList wire format: a 2-byte big-endian total length
//       followed by one 1-byte-length-prefixed name per protocol
//       (names 1..255 bytes; list 2..65535 bytes).
//   (2) A backend loader over xiom.ffi.dl (tls_backend_load /
//       tls_backend_available) against the eight-symbol contract below.
//
// Wave 157 (stage B; refs REL-20261015-2202-pulse item 1,
// REL-20261016-1128-orbitdb ask 2, REL-20261016-1129-xvector item 3)
// lifts the wave-154 stage gate: the session driver below CALLS the
// eight resolved addresses, the server-half helpers and the error
// taxonomy land here, and the system-libssl backend module
// (xiom.net.tls_libssl) is the live in-tree leg. The registry package
// xiom.ssl is the ecosystem consumer route; docs/TLS_DECISION.md
// records the composition and the honest live/not-live boundary.
//
// Backend symbol contract (every symbol is mandatory; resolved by exact
// name with dl_sym, extern "C" ABI, no versioned or platform prefixes).
// Wave 154 fixed the names; wave 157 pins the signatures:
//
//   Int32 tls_init(void);                        // 0 = ok, nonzero = failure
//   Int   tls_server_new(Int fd, *UInt8 cert_pem_path, *UInt8 key_pem_path);
//                                                // >0 session handle, 0 = failure
//   Int   tls_client_new(Int fd, *UInt8 server_name);
//                                                // >0 session handle, 0 = failure
//   Int32 tls_handshake(Int sess);               // 1 done, 2 want-read,
//                                                // 3 want-write, <0 fatal
//   Int32 tls_read(Int sess, *UInt8 buf, Int cap);
//                                                // >0 bytes, 0 = clean
//                                                // close_notify, <0 fatal
//   Int32 tls_write(Int sess, *UInt8 buf, Int len);
//                                                // len accepted, <0 fatal
//   void  tls_close(Int sess);                   // release (idempotent)
//   Int32 tls_alpn_selected(Int sess, *UInt8 buf, Int cap);
//                                                // >=0 selected-name length
//                                                // (0 = none), <0 fatal
//
// The fd is attached by *_new (the contract has no separate attach
// symbol); server-side cert/key are PEM file paths; the caller keeps
// ownership of the fd. tls_backend_load resolves all eight symbols (a
// library that opens but misses any symbol fails the load and the handle
// is closed); the returned TlsBackend owns the module handle. The driver
// validates every handle and address it touches: zero/absent backends
// and bad handles fail with typed errors, never a crash.
//
// No cryptography and no network I/O are performed by the loader or the
// protocol helpers.

module xiom.net.tls

// Depends on: xiom.ffi.dl (backend loader + session driver), xiom.io
// (cert/key material pre-validation), xiom.net.socket (readiness pump)

use xiom.ffi.dl;
use xiom.io;
use xiom.net.socket;

/// tls_default_port returns the default TLS port (443).
/// Complexity: O(1). Pure.
pub fn tls_default_port() -> Int
  ensures: result == 443
{
  443
}

/// tls_version_name maps a TLS version code point to its name.
/// Recognised values: 0x0301 TLSv1.0, 0x0302 TLSv1.1, 0x0303 TLSv1.2,
/// 0x0304 TLSv1.3. Unknown values return "unknown". Complexity: O(1).
pub fn tls_version_name(version: Int) -> Str
  ensures: ((version == 0x0300) => (result == "SSLv3")) && ((version == 0x0301) => (result == "TLSv1.0")) && ((version == 0x0302) => (result == "TLSv1.1")) && ((version == 0x0303) => (result == "TLSv1.2")) && ((version == 0x0304) => (result == "TLSv1.3")) && (result.len() > 0)
{
  if version == 0x0301 { return "TLSv1.0"; }
  if version == 0x0302 { return "TLSv1.1"; }
  if version == 0x0303 { return "TLSv1.2"; }
  if version == 0x0304 { return "TLSv1.3"; }
  if version == 0x0300 { return "SSLv3"; }
  "unknown"
}

/// tls_handshake_type_name maps a TLS handshake message type to its
/// name. Complexity: O(1).
pub fn tls_handshake_type_name(t: Int) -> Str
  ensures: ((t == 0) => (result == "hello_request")) && ((t == 1) => (result == "client_hello")) && ((t == 2) => (result == "server_hello")) && ((t == 11) => (result == "certificate")) && ((t == 16) => (result == "client_key_exchange")) && ((t == 20) => (result == "finished")) && (result.len() > 0)
{
  if t == 0 { return "hello_request"; }
  if t == 1 { return "client_hello"; }
  if t == 2 { return "server_hello"; }
  if t == 4 { return "new_session_ticket"; }
  if t == 8 { return "encrypted_extensions"; }
  if t == 11 { return "certificate"; }
  if t == 12 { return "server_key_exchange"; }
  if t == 13 { return "certificate_request"; }
  if t == 14 { return "server_hello_done"; }
  if t == 15 { return "certificate_verify"; }
  if t == 16 { return "client_key_exchange"; }
  if t == 20 { return "finished"; }
  if t == 22 { return "certificate_status"; }
  if t == 23 { return "key_update"; }
  "unknown"
}

/// tls_alert_name maps a TLS alert description to its name per RFC 5246
/// and RFC 8446. Complexity: O(1).
pub fn tls_alert_name(code: Int) -> Str
  ensures: ((code == 0) => (result == "close_notify")) && ((code == 20) => (result == "bad_record_mac")) && ((code == 40) => (result == "handshake_failure")) && ((code == 46) => (result == "certificate_unknown")) && ((code == 48) => (result == "unknown_ca")) && ((code == 70) => (result == "protocol_version")) && ((code == 120) => (result == "no_application_protocol")) && (result.len() > 0)
{
  if code == 0 { return "close_notify"; }
  if code == 10 { return "unexpected_message"; }
  if code == 20 { return "bad_record_mac"; }
  if code == 21 { return "decryption_failed"; }
  if code == 22 { return "record_overflow"; }
  if code == 40 { return "handshake_failure"; }
  if code == 42 { return "bad_certificate"; }
  if code == 43 { return "unsupported_certificate"; }
  if code == 44 { return "certificate_revoked"; }
  if code == 45 { return "certificate_expired"; }
  if code == 46 { return "certificate_unknown"; }
  if code == 47 { return "illegal_parameter"; }
  if code == 48 { return "unknown_ca"; }
  if code == 49 { return "access_denied"; }
  if code == 50 { return "decode_error"; }
  if code == 51 { return "decrypt_error"; }
  if code == 70 { return "protocol_version"; }
  if code == 71 { return "insufficient_security"; }
  if code == 80 { return "internal_error"; }
  if code == 86 { return "inappropriate_fallback"; }
  if code == 90 { return "user_canceled"; }
  if code == 100 { return "no_renegotiation"; }
  if code == 110 { return "unsupported_extension"; }
  if code == 112 { return "unrecognized_name"; }
  if code == 113 { return "bad_certificate_status_response"; }
  if code == 116 { return "unknown_psk_identity"; }
  if code == 120 { return "no_application_protocol"; }
  "unknown"
}

/// tls_cipher_suite_name maps a TLS cipher suite code to a
/// human-readable name for the most common suites, or "unknown" (0x0000-
/// 0xFFFF, two-byte IANA code). Complexity: O(1).
pub fn tls_cipher_suite_name(code: Int) -> Str
  ensures: ((code == 0x002F) => (result == "TLS_RSA_WITH_AES_128_CBC_SHA")) && ((code == 0xC02F) => (result == "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256")) && ((code == 0xC030) => (result == "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384")) && ((code == 0x1301) => (result == "TLS_AES_128_GCM_SHA256")) && ((code == 0x1302) => (result == "TLS_AES_256_GCM_SHA384")) && ((code == 0x1303) => (result == "TLS_CHACHA20_POLY1305_SHA256")) && (result.len() > 0)
{
  if code == 0x002F { return "TLS_RSA_WITH_AES_128_CBC_SHA"; }
  if code == 0x0035 { return "TLS_RSA_WITH_AES_256_CBC_SHA"; }
  if code == 0x003C { return "TLS_RSA_WITH_AES_128_CBC_SHA256"; }
  if code == 0x009C { return "TLS_RSA_WITH_AES_128_GCM_SHA256"; }
  if code == 0x009D { return "TLS_RSA_WITH_AES_256_GCM_SHA384"; }
  if code == 0xC02F { return "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"; }
  if code == 0xC030 { return "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"; }
  if code == 0xC02B { return "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"; }
  if code == 0xC02C { return "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384"; }
  if code == 0xC013 { return "TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA"; }
  if code == 0xC014 { return "TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA"; }
  if code == 0xC027 { return "TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256"; }
  if code == 0x1301 { return "TLS_AES_128_GCM_SHA256"; }
  if code == 0x1302 { return "TLS_AES_256_GCM_SHA384"; }
  if code == 0x1303 { return "TLS_CHACHA20_POLY1305_SHA256"; }
  "unknown"
}

// ============================================================================
// ALPN codec (RFC 7301). The wire format of the ALPN extension data is a
// ProtocolNameList:
//   - 2 bytes, big-endian: total length of the name entries that follow;
//   - for each protocol: 1 byte name length + that many name bytes
//     (ProtocolName is 1..255 bytes).
// ============================================================================

/// alpn_encode serialises protocol names into the RFC 7301
/// ProtocolNameList wire format (2-byte big-endian total length, then one
/// 1-byte-length-prefixed name each). Rejects an empty list, empty names,
/// names longer than 255 bytes, and a list longer than 65535 bytes.
/// Returns: Ok(the wire bytes); Err on an invalid protocol list.
/// Complexity: O(n). Pure.
pub fn alpn_encode(protocols: &Vec[Str]) -> Result[Vec[UInt8], Str]
  ensures: protocols.len() == 0 => result.is_err == true
  ensures: result.is_ok == true => protocols.len() > 0
{
  let count = protocols.len();
  if count == 0 {
    return Err("alpn_encode: empty protocol list");
  }
  var total: Int = 0;
  var i = 0;
  while i < count {
    let name = protocols[i];
    let nlen = name.len();
    if nlen == 0 {
      return Err("alpn_encode: empty protocol name");
    }
    if nlen > 255 {
      return Err("alpn_encode: protocol name longer than 255 bytes");
    }
    total = total + 1 + nlen;
    if total > 65535 {
      return Err("alpn_encode: protocol list longer than 65535 bytes");
    }
    i = i + 1;
  }
  var out = Vec[UInt8].new();
  out.push(((total >> 8) & 0xFF) as UInt8);
  out.push((total & 0xFF) as UInt8);
  var k = 0;
  while k < count {
    let name = protocols[k];
    let nlen = name.len();
    out.push(nlen as UInt8);
    var j = 0;
    while j < nlen {
      out.push(name.byte_at(j));
      j = j + 1;
    }
    k = k + 1;
  }
  Ok(out)
}

/// alpn_decode parses an RFC 7301 ProtocolNameList. Strict: the declared
/// list length must consume the whole input, the list must hold at least
/// one name, and every name must be 1..255 bytes. Err on malformed or
/// truncated input (fewer than 2 bytes, a declared length below 2 or
/// mismatching the input size, a zero-length name, or a name that runs
/// past the end).
/// Returns: Ok(the protocol names in wire order); Err on malformed input.
/// Complexity: O(n). Pure.
pub fn alpn_decode(bytes: &Vec[UInt8]) -> Result[Vec[Str], Str]
  ensures: bytes.len() < 2 => result.is_err == true
{
  let blen = bytes.len();
  if blen < 2 {
    return Err("alpn_decode: truncated ProtocolNameList (length missing)");
  }
  let list_len = ((bytes[0] as Int) << 8) | (bytes[1] as Int);
  if list_len < 2 {
    return Err("alpn_decode: empty ProtocolNameList");
  }
  if list_len + 2 != blen {
    return Err("alpn_decode: declared list length does not match input size");
  }
  var out = Vec[Str].new();
  var pos = 2;
  while pos < blen {
    let nlen = bytes[pos] as Int;
    if nlen == 0 {
      return Err("alpn_decode: zero-length protocol name");
    }
    if pos + 1 + nlen > blen {
      return Err("alpn_decode: truncated protocol name");
    }
    var name_bytes = Vec[UInt8].new();
    var j = 0;
    while j < nlen {
      name_bytes.push(bytes[pos + 1 + j]);
      j = j + 1;
    }
    out.push(Str::from_utf8(name_bytes));
    pos = pos + 1 + nlen;
  }
  Ok(out)
}

// ============================================================================
// Backend loader skeleton (stage gate: symbol resolution only). The TLS
// binding package ships a shared library exporting the eight symbols
// documented in the module header; this loader only opens the library and
// resolves those addresses.
// ============================================================================

/// TlsBackend is a loaded backend library: the module handle plus the
/// resolved address of every mandatory backend symbol (see the module
/// header for the symbol contract). Stage gate: nothing in this module
/// calls through these addresses; the backend value owns the handle.
pub type TlsBackend = {
  handle: Int;
  tls_init: Int;
  tls_server_new: Int;
  tls_client_new: Int;
  tls_handshake: Int;
  tls_read: Int;
  tls_write: Int;
  tls_close: Int;
  tls_alpn_selected: Int;
}

// tls_backend_symbols returns the mandatory symbol names in TlsBackend
// field order.
fn tls_backend_symbols() -> Vec[Str] {
  var names = Vec[Str].new();
  names.push("tls_init");
  names.push("tls_server_new");
  names.push("tls_client_new");
  names.push("tls_handshake");
  names.push("tls_read");
  names.push("tls_write");
  names.push("tls_close");
  names.push("tls_alpn_selected");
  names
}

/// tls_backend_load opens the shared library at path and resolves the
/// eight mandatory backend symbols. The library handle is closed on every
/// failure path, so a failed load never leaks. Stage gate: no call is
/// ever made into the loaded backend.
/// Returns: Ok(TlsBackend) once every symbol resolves; Err("backend not
///          found") when the library cannot be opened, or Err naming the
///          missing symbol when one of the eight does not resolve.
/// Complexity: O(1) OS calls.
pub fn tls_backend_load(path: Str) -> Result[TlsBackend, Str]
  ensures: path.len() == 0 => result.is_err == true
{
  if path.len() == 0 {
    return Err("tls_backend_load: backend not found (empty path)");
  }
  let opened = dl.dl_open(path);
  match opened {
    Err(e) => {
      Err("tls_backend_load: backend not found: " + path + " (" + e + ")")
    }
    Ok(handle) => {
      let names = tls_backend_symbols();
      var addrs: Vec[Int] = Vec[Int].new();
      var i = 0;
      while i < names.len() {
        let name = names[i];
        let sym = dl.dl_sym(handle, name);
        match sym {
          Err(_) => {
            let cr = dl.dl_close(handle);
            let _ = cr;
            return Err("tls_backend_load: backend missing symbol: " + name);
          }
          Ok(a) => {
            addrs.push(a);
          }
        }
        i = i + 1;
      }
      Ok(TlsBackend{
        handle: handle;
        tls_init: addrs[0];
        tls_server_new: addrs[1];
        tls_client_new: addrs[2];
        tls_handshake: addrs[3];
        tls_read: addrs[4];
        tls_write: addrs[5];
        tls_close: addrs[6];
        tls_alpn_selected: addrs[7];
      })
    }
  }
}

/// tls_backend_available reports whether path loads and exports every
/// mandatory backend symbol (see the module header). It never calls into
/// the backend and closes the library before returning; a library that
/// loads but misses any symbol yields false.
/// Returns: true only when all eight symbols resolve.
/// Complexity: O(1) OS calls.
pub fn tls_backend_available(path: Str) -> Bool
  ensures: path.len() == 0 => result == false
{
  if path.len() == 0 {
    return false;
  }
  let opened = dl.dl_open(path);
  var exists = false;
  match opened {
    Err(_) => {
      exists = false;
    }
    Ok(handle) => {
      let names = tls_backend_symbols();
      var ok = true;
      var i = 0;
      while i < names.len() {
        if !dl.dl_has_symbol(handle, names[i]) {
          ok = false;
          break;
        }
        i = i + 1;
      }
      let cr = dl.dl_close(handle);
      let _ = cr;
      exists = ok;
    }
  }
  exists
}

// ============================================================================
// Error taxonomy (wave 157). Session/step failures classify in stdlib
// terms so callers can branch without string matching:
//
//   TLS_ERR_NONE       -- no error
//   TLS_ERR_LOAD       -- backend library absent (no candidate loaded)
//   TLS_ERR_ARG        -- invalid handle, fd, or argument at the seam
//   TLS_ERR_ALLOC      -- session/context allocation failed
//   TLS_ERR_CERT       -- certificate/key material rejected or unloadable
//   TLS_ERR_ALPN       -- ALPN configuration rejected
//   TLS_ERR_HANDSHAKE  -- fatal handshake failure (peer/protocol)
//   TLS_ERR_VERIFY     -- peer certificate verification failed (fatal)
//   TLS_ERR_IO         -- fatal read/write/shutdown failure
//   TLS_ERR_EOF        -- clean peer close (close_notify) where data was
//                         expected: end of stream, not a transport failure
//   TLS_ERR_WANT_READ  -- non-fatal: retry when the fd is readable
//   TLS_ERR_WANT_WRITE -- non-fatal: retry when the fd is writable
//   TLS_ERR_ABI        -- backend library loaded but a contract symbol is
//                         missing (version/ABI mismatch)
//
// Step mapping: a handshake step that must wait reports Ok(TLS_STEP_*)
// on the step-shaped surface (tls_session_step, tls_libssl_step); where a
// seam reports waiting as an error (read/write/shutdown), it maps to
// TLS_ERR_WANT_READ/WRITE. A fatal handshake maps to
// TLS_ERR_HANDSHAKE; the verify distinction needs a verification result
// from the backend (the generic eight-symbol contract has no verify
// symbol; xiom.ssl binds SSL_get_verify_result for that).
// ============================================================================

/// No error.
pub const TLS_ERR_NONE: Int = 0;
/// Backend library absent: no candidate soname loaded.
pub const TLS_ERR_LOAD: Int = 1;
/// Invalid handle, fd, or argument at the seam (caller bug).
pub const TLS_ERR_ARG: Int = 2;
/// Session/context allocation failed.
pub const TLS_ERR_ALLOC: Int = 3;
/// Certificate/key material rejected or unloadable.
pub const TLS_ERR_CERT: Int = 4;
/// ALPN configuration rejected.
pub const TLS_ERR_ALPN: Int = 5;
/// Fatal handshake failure (peer/protocol).
pub const TLS_ERR_HANDSHAKE: Int = 6;
/// Peer certificate verification failed (fatal).
pub const TLS_ERR_VERIFY: Int = 7;
/// Fatal read/write/shutdown failure.
pub const TLS_ERR_IO: Int = 8;
/// Clean peer close (close_notify) where data was expected.
pub const TLS_ERR_EOF: Int = 9;
/// Non-fatal: retry when the fd is readable.
pub const TLS_ERR_WANT_READ: Int = 10;
/// Non-fatal: retry when the fd is writable.
pub const TLS_ERR_WANT_WRITE: Int = 11;
/// Backend library loaded but a contract symbol is missing (ABI mismatch).
pub const TLS_ERR_ABI: Int = 12;

/// Handshake step codes (Ok side of tls_session_step / tls_libssl_step;
/// these are also the backend contract's tls_handshake return codes).
pub const TLS_STEP_DONE: Int = 1;
/// Handshake needs more input: retry when the fd is readable.
pub const TLS_STEP_WANT_READ: Int = 2;
/// Handshake needs output drain: retry when the fd is writable.
pub const TLS_STEP_WANT_WRITE: Int = 3;

/// tls_err_kind_name maps a taxonomy kind to a short stable name
/// ("none", "load", "arg", "alloc", "cert", "alpn", "handshake",
/// "verify", "io", "eof", "want-read", "want-write", "abi"; "unknown"
/// for anything else). Complexity: O(1).
pub fn tls_err_kind_name(kind: Int) -> Str
  ensures: ((kind == TLS_ERR_NONE) => (result == "none")) && ((kind == TLS_ERR_LOAD) => (result == "load")) && ((kind == TLS_ERR_HANDSHAKE) => (result == "handshake")) && ((kind == TLS_ERR_ABI) => (result == "abi")) && (result.len() > 0)
{
  if kind == TLS_ERR_NONE { return "none"; }
  if kind == TLS_ERR_LOAD { return "load"; }
  if kind == TLS_ERR_ARG { return "arg"; }
  if kind == TLS_ERR_ALLOC { return "alloc"; }
  if kind == TLS_ERR_CERT { return "cert"; }
  if kind == TLS_ERR_ALPN { return "alpn"; }
  if kind == TLS_ERR_HANDSHAKE { return "handshake"; }
  if kind == TLS_ERR_VERIFY { return "verify"; }
  if kind == TLS_ERR_IO { return "io"; }
  if kind == TLS_ERR_EOF { return "eof"; }
  if kind == TLS_ERR_WANT_READ { return "want-read"; }
  if kind == TLS_ERR_WANT_WRITE { return "want-write"; }
  if kind == TLS_ERR_ABI { return "abi"; }
  "unknown"
}

/// tls_err_kind_is_want reports whether the kind is the non-fatal
/// readiness form (retry when the fd is readable/writable).
/// Complexity: O(1). Pure.
pub fn tls_err_kind_is_want(kind: Int) -> Bool
  ensures: (kind == TLS_ERR_WANT_READ) => result == true
  ensures: (kind == TLS_ERR_WANT_WRITE) => result == true
  ensures: (kind == TLS_ERR_NONE) => result == false
{
  if kind == TLS_ERR_WANT_READ { return true; }
  if kind == TLS_ERR_WANT_WRITE { return true; }
  false
}

/// tls_err_kind_is_fatal reports whether the kind means the session
/// cannot continue (load/abi/arg/alloc/cert/alpn/handshake/verify/io).
/// NONE, EOF and the WANT kinds are not fatal in this sense (EOF is a
/// clean end of stream; ARG is caller misuse, not a session state).
/// Complexity: O(1). Pure.
pub fn tls_err_kind_is_fatal(kind: Int) -> Bool
  ensures: (kind == TLS_ERR_HANDSHAKE) => result == true
  ensures: (kind == TLS_ERR_IO) => result == true
  ensures: (kind == TLS_ERR_EOF) => result == false
  ensures: (kind == TLS_ERR_NONE) => result == false
{
  if kind == TLS_ERR_LOAD { return true; }
  if kind == TLS_ERR_ABI { return true; }
  if kind == TLS_ERR_ALLOC { return true; }
  if kind == TLS_ERR_CERT { return true; }
  if kind == TLS_ERR_ALPN { return true; }
  if kind == TLS_ERR_HANDSHAKE { return true; }
  if kind == TLS_ERR_VERIFY { return true; }
  if kind == TLS_ERR_IO { return true; }
  false
}

// ============================================================================
// Session driver over the eight-symbol contract. Every call is an
// fn-pointer cast over the resolved address; handles are Ints and are
// validated before every call, so a zero/absent backend or a bad session
// handle fails with a typed TlsError instead of a crash. Transport
// readiness is the caller's: a WANT step result pairs with
// tls_wait_readable / tls_wait_writable.
// ============================================================================

/// TlsError is a typed TLS failure: a taxonomy kind (TLS_ERR_*) plus a
/// message.
pub type TlsError = {
  kind: Int;
  message: Str;
}

/// TlsSession is one session on a loaded backend: the raw session id
/// (> 0 while open, 0 after tls_session_close), the role, and the
/// attached fd.
pub type TlsSession = {
  id: Int;
  server: Bool;
  fd: Int;
}

// tls_backend_is_loaded reports whether every contract address in a
// backend value is non-zero. A hand-built or zeroed TlsBackend is not
// callable; the driver checks this before every call.
fn tls_backend_is_loaded(backend: &TlsBackend) -> Bool {
  if backend.handle == 0 { return false; }
  if backend.tls_init == 0 { return false; }
  if backend.tls_server_new == 0 { return false; }
  if backend.tls_client_new == 0 { return false; }
  if backend.tls_handshake == 0 { return false; }
  if backend.tls_read == 0 { return false; }
  if backend.tls_write == 0 { return false; }
  if backend.tls_close == 0 { return false; }
  if backend.tls_alpn_selected == 0 { return false; }
  true
}

// tls_driver_err builds a typed driver error.
fn tls_driver_err(kind: Int, message: Str) -> TlsError {
  TlsError{ kind: kind; message: message }
}

/// tls_session_open opens a session against a loaded backend:
///   - server == true: cert_path/key_path are PEM file paths handed to
///     the backend (the fd is already connected); both must be non-empty;
///   - server == false: server_name is the peer name handed to the
///     backend (SNI or equivalent; may be empty).
/// The fd is attached by the backend's *_new call -- the contract has no
/// separate attach symbol; the caller keeps ownership of the fd. The
/// backend's tls_init runs first and must be idempotent (the driver calls
/// it on every open).
/// Returns: Ok(session); Err(TLS_ERR_LOAD) when the backend value is not
///          loaded, Err(TLS_ERR_ARG) on a bad fd or empty material path,
///          Err(TLS_ERR_ALLOC) when the backend refuses the session.
/// Complexity: O(paths).
pub fn tls_session_open(backend: &TlsBackend, server: Bool, fd: Int, cert_path: Str, key_path: Str, server_name: Str) -> Result[TlsSession, TlsError]
  ensures: (fd < 0) => (result.is_err == true)
  ensures: (server == true && cert_path.len() == 0) => (result.is_err == true)
  ensures: (server == true && key_path.len() == 0) => (result.is_err == true)
{
  if !tls_backend_is_loaded(backend) {
    return Err(tls_driver_err(TLS_ERR_LOAD, "tls_session_open: backend is not loaded (zero handle or unresolved symbol)"));
  }
  if fd < 0 {
    return Err(tls_driver_err(TLS_ERR_ARG, "tls_session_open: invalid fd"));
  }
  if server {
    if cert_path.len() == 0 {
      return Err(tls_driver_err(TLS_ERR_ARG, "tls_session_open: empty certificate path"));
    }
    if key_path.len() == 0 {
      return Err(tls_driver_err(TLS_ERR_ARG, "tls_session_open: empty key path"));
    }
  }
  unsafe {
    let fi = backend.tls_init as fn() -> Int32;
    let ir = fi() as Int;
    if ir != 0 {
      return Err(tls_driver_err(TLS_ERR_LOAD, "tls_session_open: backend initialisation failed (code " + ir.to_str() + ")"));
    }
    if server {
      let cert_c = cert_path.c_str();
      let key_c = key_path.c_str();
      let fs = backend.tls_server_new as fn(Int, *UInt8, *UInt8) -> Int;
      let h = fs(fd, cert_c, key_c);
      if h <= 0 {
        return Err(tls_driver_err(TLS_ERR_ALLOC, "tls_session_open: backend refused the server session"));
      }
      return Ok(TlsSession{ id: h; server: true; fd: fd });
    }
    let name_c = server_name.c_str();
    let fc = backend.tls_client_new as fn(Int, *UInt8) -> Int;
    let h = fc(fd, name_c);
    if h <= 0 {
      return Err(tls_driver_err(TLS_ERR_ALLOC, "tls_session_open: backend refused the client session"));
    }
    return Ok(TlsSession{ id: h; server: false; fd: fd });
  }
}

/// tls_session_step advances the handshake one step (server: accept
/// side, client: connect side).
/// Returns: Ok(TLS_STEP_DONE) when the handshake is complete;
///          Ok(TLS_STEP_WANT_READ) / Ok(TLS_STEP_WANT_WRITE) when the
///          caller must wait for fd readiness first (tls_wait_readable /
///          tls_wait_writable) and call again; Err(TLS_ERR_HANDSHAKE) on
///          a fatal handshake failure; Err(TLS_ERR_ARG/TLS_ERR_LOAD) on
///          a bad handle or an unloaded backend.
/// Complexity: O(handshake progress).
pub fn tls_session_step(backend: &TlsBackend, sess: &TlsSession) -> Result[Int, TlsError]
  ensures: (sess.id <= 0) => (result.is_err == true)
{
  if !tls_backend_is_loaded(backend) {
    return Err(tls_driver_err(TLS_ERR_LOAD, "tls_session_step: backend is not loaded"));
  }
  if sess.id <= 0 {
    return Err(tls_driver_err(TLS_ERR_ARG, "tls_session_step: session is not open"));
  }
  unsafe {
    let f = backend.tls_handshake as fn(Int) -> Int32;
    let rc = f(sess.id) as Int;
    if rc == TLS_STEP_DONE { return Ok(TLS_STEP_DONE); }
    if rc == TLS_STEP_WANT_READ { return Ok(TLS_STEP_WANT_READ); }
    if rc == TLS_STEP_WANT_WRITE { return Ok(TLS_STEP_WANT_WRITE); }
    return Err(tls_driver_err(TLS_ERR_HANDSHAKE, "tls_session_step: fatal handshake failure (backend code " + rc.to_str() + ")"));
  }
}

/// tls_session_read reads up to max plaintext bytes.
/// Returns: Ok(bytes) with bytes.len() >= 1; Err(TLS_ERR_EOF) when the
///          peer closed the connection cleanly (close_notify); Err
///          (TLS_ERR_IO) on a fatal read failure; Err(TLS_ERR_ARG) on a
///          bad handle or max outside 1..65536.
/// Complexity: O(max).
pub fn tls_session_read(backend: &TlsBackend, sess: &TlsSession, max: Int) -> Result[Vec[UInt8], TlsError]
  ensures: (max <= 0) => (result.is_err == true)
  ensures: (max > 65536) => (result.is_err == true)
{
  if !tls_backend_is_loaded(backend) {
    return Err(tls_driver_err(TLS_ERR_LOAD, "tls_session_read: backend is not loaded"));
  }
  if sess.id <= 0 {
    return Err(tls_driver_err(TLS_ERR_ARG, "tls_session_read: session is not open"));
  }
  if max <= 0 || max > 65536 {
    return Err(tls_driver_err(TLS_ERR_ARG, "tls_session_read: max outside 1..65536"));
  }
  unsafe {
    var buf = Vec[UInt8].with_len(max);
    let f = backend.tls_read as fn(Int, *UInt8, Int) -> Int32;
    let rc = f(sess.id, buf.as_mut_ptr(), max) as Int;
    if rc > max {
      return Err(tls_driver_err(TLS_ERR_IO, "tls_session_read: backend over-reported the byte count"));
    }
    if rc > 0 {
      var out: Vec[UInt8] = Vec[UInt8].new();
      var i = 0;
      while i < rc {
        out.push(buf[i]);
        i = i + 1;
      }
      return Ok(out);
    }
    if rc == 0 {
      return Err(tls_driver_err(TLS_ERR_EOF, "tls_session_read: peer closed the connection (close_notify)"));
    }
    return Err(tls_driver_err(TLS_ERR_IO, "tls_session_read: fatal read failure (backend code " + rc.to_str() + ")"));
  }
}

/// tls_session_write writes data into the session. The contract is
/// all-or-nothing per call: the driver hands the whole payload to the
/// backend and a short count is a typed TLS_ERR_IO (the backend owns its
/// retries).
/// Returns: Ok(len) when the whole payload was accepted (Ok(0) for an
///          empty payload on a live session); Err on a fatal write
///          failure or a bad handle.
/// Complexity: O(len).
pub fn tls_session_write(backend: &TlsBackend, sess: &TlsSession, data: &Vec[UInt8]) -> Result[Int, TlsError]
  ensures: (sess.id <= 0) => (result.is_err == true)
{
  if !tls_backend_is_loaded(backend) {
    return Err(tls_driver_err(TLS_ERR_LOAD, "tls_session_write: backend is not loaded"));
  }
  if sess.id <= 0 {
    return Err(tls_driver_err(TLS_ERR_ARG, "tls_session_write: session is not open"));
  }
  let n = data.len();
  if n == 0 {
    return Ok(0);
  }
  unsafe {
    let base = &data[0] as *UInt8;
    let f = backend.tls_write as fn(Int, *UInt8, Int) -> Int32;
    let rc = f(sess.id, base, n) as Int;
    if rc == n {
      return Ok(rc);
    }
    if rc > 0 {
      return Err(tls_driver_err(TLS_ERR_IO, "tls_session_write: partial write (" + rc.to_str() + " of " + n.to_str() + " bytes)"));
    }
    return Err(tls_driver_err(TLS_ERR_IO, "tls_session_write: fatal write failure (backend code " + rc.to_str() + ")"));
  }
}

/// tls_session_alpn_selected reports the negotiated ALPN protocol name of
/// the session ("" when none was selected -- server-side selection needs
/// a C callback no XIOM backend can install; see tls_alpn_select_server
/// for the application-layer policy).
/// Returns: Ok(name); Err(TLS_ERR_IO) when the backend cannot report it;
///          Err(TLS_ERR_ARG/TLS_ERR_LOAD) on a bad handle.
/// Complexity: O(name length).
pub fn tls_session_alpn_selected(backend: &TlsBackend, sess: &TlsSession) -> Result[Str, TlsError]
  ensures: (sess.id <= 0) => (result.is_err == true)
{
  if !tls_backend_is_loaded(backend) {
    return Err(tls_driver_err(TLS_ERR_LOAD, "tls_session_alpn_selected: backend is not loaded"));
  }
  if sess.id <= 0 {
    return Err(tls_driver_err(TLS_ERR_ARG, "tls_session_alpn_selected: session is not open"));
  }
  unsafe {
    var buf = Vec[UInt8].with_len(256);
    let f = backend.tls_alpn_selected as fn(Int, *UInt8, Int) -> Int32;
    let rc = f(sess.id, buf.as_mut_ptr(), 256) as Int;
    if rc < 0 {
      return Err(tls_driver_err(TLS_ERR_IO, "tls_session_alpn_selected: read failed (backend code " + rc.to_str() + ")"));
    }
    if rc == 0 {
      return Ok("");
    }
    if rc > 256 {
      return Err(tls_driver_err(TLS_ERR_IO, "tls_session_alpn_selected: name length out of range"));
    }
    var bytes: Vec[UInt8] = Vec[UInt8].new();
    var i = 0;
    while i < rc {
      bytes.push(buf[i]);
      i = i + 1;
    }
    return Ok(Str::from_utf8(bytes));
  }
}

/// tls_session_close releases the session through the backend and marks
/// the handle closed (sess.id := 0), so a second close on the same value
/// is a clean Ok: the backend is never called twice for one session.
/// Returns: Ok(()) once closed (or already closed); Err(TLS_ERR_LOAD)
///          when the backend value is not loaded; Err(TLS_ERR_ARG) for a
///          negative id.
/// Complexity: O(1).
pub fn tls_session_close(backend: &TlsBackend, sess: &mut TlsSession) -> Result[Unit, TlsError]
  ensures: (backend.handle == 0) => (result.is_err == true)
{
  if !tls_backend_is_loaded(backend) {
    return Err(tls_driver_err(TLS_ERR_LOAD, "tls_session_close: backend is not loaded"));
  }
  if sess.id < 0 {
    return Err(tls_driver_err(TLS_ERR_ARG, "tls_session_close: negative session id"));
  }
  if sess.id == 0 {
    return Ok(());
  }
  unsafe {
    let f = backend.tls_close as fn(Int) -> Unit;
    f(sess.id);
  }
  sess.id = 0;
  Ok(())
}

// ============================================================================
// Server-half helpers (pure). Certificate/key material pre-validation and
// the server-side ALPN selection policy. The selection policy lives at the
// application layer because OpenSSL-class backends can only select the
// server protocol through an SSL_CTX_set_alpn_select_cb C callback, which
// the current XIOM FFI cannot install (documented binding limitation).
// ============================================================================

/// tls_material_sniff classifies certificate/key material by its leading
/// bytes: "pem" (begin marker "-----BEGIN"), "der" (ASN.1 SEQUENCE tag
/// 0x30), or "unknown" (empty or anything else). Pure; a pre-flight
/// classification helper (backends load PEM files directly).
/// Complexity: O(1).
pub fn tls_material_sniff(bytes: &Vec[UInt8]) -> Str
  ensures: bytes.len() == 0 => result == "unknown"
{
  if bytes.len() >= 10 {
    if bytes[0] == 45 as UInt8 && bytes[1] == 45 as UInt8 && bytes[2] == 45 as UInt8 && bytes[3] == 45 as UInt8 && bytes[4] == 45 as UInt8 && bytes[5] == 66 as UInt8 && bytes[6] == 69 as UInt8 && bytes[7] == 71 as UInt8 && bytes[8] == 73 as UInt8 && bytes[9] == 78 as UInt8 {
      return "pem";
    }
  }
  if bytes.len() >= 1 {
    if bytes[0] == 48 as UInt8 {
      return "der";
    }
  }
  "unknown"
}

/// tls_cert_material_check pre-validates a certificate/key file pair
/// before any backend call: each path must be non-empty, the files must
/// exist, be readable, and hold at least one byte. A cheap application
/// -layer gate (a missing file is a configuration mistake, not a
/// handshake failure); the material itself is not parsed.
/// Returns: Ok(()) when both files pass; Err naming the first failure.
/// Complexity: O(file size).
pub fn tls_cert_material_check(cert_path: Str, key_path: Str) -> Result[Unit, Str]
  ensures: (cert_path.len() == 0) => (result.is_err == true)
  ensures: (key_path.len() == 0) => (result.is_err == true)
{
  if cert_path.len() == 0 {
    return Err("tls_cert_material_check: empty certificate path");
  }
  if key_path.len() == 0 {
    return Err("tls_cert_material_check: empty key path");
  }
  if !io.file_exists(cert_path) {
    return Err("tls_cert_material_check: certificate file not found: " + cert_path);
  }
  if !io.file_exists(key_path) {
    return Err("tls_cert_material_check: key file not found: " + key_path);
  }
  let cb = io.read_file_bytes(cert_path);
  match cb {
    Err(_) => {
      return Err("tls_cert_material_check: certificate file unreadable: " + cert_path);
    },
    Ok(cbytes) => {
      if cbytes.len() == 0 {
        return Err("tls_cert_material_check: certificate file empty: " + cert_path);
      }
    },
  }
  let kb = io.read_file_bytes(key_path);
  match kb {
    Err(_) => {
      return Err("tls_cert_material_check: key file unreadable: " + key_path);
    },
    Ok(kbytes) => {
      if kbytes.len() == 0 {
        return Err("tls_cert_material_check: key file empty: " + key_path);
      }
    },
  }
  Ok(())
}

/// Err value of tls_alpn_select_server when no offered protocol is
/// acceptable (the classified RFC 7301 / RFC 8446 no_application_protocol
/// alert class; see tls_alert_name(120)).
pub const TLS_ALPN_NO_APPLICATION_PROTOCOL: Str = "no_application_protocol";

/// tls_alpn_select_server picks the server-side ALPN protocol by server
/// preference: the first entry of server_pref that the client offered.
/// This is the application-layer policy the backend cannot express (no
/// callback bridging), so servers negotiate here and can refuse with the
/// classified no_application_protocol error.
/// Returns: Ok(selected name); Err(TLS_ALPN_NO_APPLICATION_PROTOCOL)
///          when the client offered nothing usable; Err on an empty
///          server preference list (misconfiguration).
/// Complexity: O(server_pref * client_offered). Pure.
pub fn tls_alpn_select_server(server_pref: &Vec[Str], client_offered: &Vec[Str]) -> Result[Str, Str]
  ensures: (server_pref.len() == 0) => (result.is_err == true)
  ensures: (client_offered.len() == 0) => (result.is_err == true)
{
  if server_pref.len() == 0 {
    return Err("tls_alpn_select_server: empty server preference list");
  }
  if client_offered.len() == 0 {
    return Err(TLS_ALPN_NO_APPLICATION_PROTOCOL);
  }
  var i = 0;
  while i < server_pref.len() {
    let wanted = server_pref[i];
    var j = 0;
    while j < client_offered.len() {
      if client_offered[j] == wanted {
        return Ok(wanted);
      }
      j = j + 1;
    }
    i = i + 1;
  }
  Err(TLS_ALPN_NO_APPLICATION_PROTOCOL)
}

// ============================================================================
// fd-readiness pump. Built on the real poll wrappers from
// xiom.net.socket (wave 122: poll() on POSIX, WSAPoll on Windows; up to
// 1024 fds, bounded waits). These drive step-shaped handshakes: a
// TLS_STEP_WANT_READ / WRITE result pairs with the matching helper and a
// bounded retry loop; the timeout is the remaining slice of the caller's
// deadline budget (compose with time.monotonic_ms). Note the poll layer
// reports invalid entries as ready so the caller can inspect them: a
// returned Ok(true) means "inspect now", not "data is guaranteed".
// ============================================================================

/// tls_wait_readable waits until fd is readable or the timeout budget
/// runs out (timeout_ms == 0 polls once). An already-ready fd returns
/// immediately.
/// Returns: Ok(true) when the fd reports activity, Ok(false) on timeout;
///          Err on a negative fd or timeout.
/// Complexity: network wait.
pub fn tls_wait_readable(fd: Int, timeout_ms: Int) -> Result[Bool, Str]
  ensures: (fd < 0) => (result.is_err == true)
  ensures: (timeout_ms < 0) => (result.is_err == true)
{
  if fd < 0 {
    return Err("tls_wait_readable: invalid fd");
  }
  if timeout_ms < 0 {
    return Err("tls_wait_readable: negative timeout");
  }
  var fds: Vec[Int] = Vec[Int].new();
  fds.push(fd);
  let pr = socket.socket_poll_read(&fds, timeout_ms);
  match pr {
    Err(e) => {
      return Err("tls_wait_readable: " + e);
    },
    Ok(ready) => {
      if ready.len() > 0 {
        return Ok(true);
      }
      return Ok(false);
    },
  }
}

/// tls_wait_writable waits until fd is writable or the timeout budget
/// runs out (timeout_ms == 0 polls once).
/// Returns: Ok(true) when the fd reports writability, Ok(false) on
///          timeout; Err on a negative fd or timeout.
/// Complexity: network wait.
pub fn tls_wait_writable(fd: Int, timeout_ms: Int) -> Result[Bool, Str]
  ensures: (fd < 0) => (result.is_err == true)
  ensures: (timeout_ms < 0) => (result.is_err == true)
{
  if fd < 0 {
    return Err("tls_wait_writable: invalid fd");
  }
  if timeout_ms < 0 {
    return Err("tls_wait_writable: negative timeout");
  }
  var fds: Vec[Int] = Vec[Int].new();
  fds.push(fd);
  let pw = socket.socket_poll_write(&fds, timeout_ms);
  match pw {
    Err(e) => {
      return Err("tls_wait_writable: " + e);
    },
    Ok(ready) => {
      if ready.len() > 0 {
        return Ok(true);
      }
      return Ok(false);
    },
  }
}
