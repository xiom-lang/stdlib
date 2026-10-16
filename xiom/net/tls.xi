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
//   (2) A backend-loader skeleton over xiom.ffi.dl (tls_backend_load /
//       tls_backend_available). STAGE GATE: the loader only resolves the
//       symbols below -- it never calls into the backend. The concrete
//       TLS binding (mbedTLS-class) ships via the packages/bindings
//       lane against this symbol contract.
//
// Backend symbol contract (every symbol is mandatory; resolved by exact
// name with dl_sym, extern "C" ABI, no versioned or platform prefixes):
//
//   tls_init           -- one-time backend initialisation
//   tls_server_new     -- create a server session/context
//   tls_client_new     -- create a client session/context
//   tls_handshake      -- drive the handshake on a session
//   tls_read           -- read plaintext from a session
//   tls_write          -- write plaintext into a session
//   tls_close          -- release a session/context
//   tls_alpn_selected  -- report the negotiated ALPN protocol name
//
// tls_backend_load resolves all eight symbols (a library that opens but
// misses any symbol fails the load and the handle is closed); the
// returned TlsBackend owns the module handle. Session calls themselves
// are out of scope until the backend package lands (stage gate above).
//
// No network I/O or cryptography is performed here.

module xiom.net.tls

// Depends on: xiom.ffi.dl (backend loader only)

use xiom.ffi.dl;

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
