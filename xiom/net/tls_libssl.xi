// XIOM -- Minimal in-tree libssl session backend (xiom.net.tls_libssl)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Wave 157 stage 2 (plan item 9 wave-B; refs REL-20261015-2202-pulse
// item 1, REL-20261016-1128-orbitdb ask 2, REL-20261016-1129-xvector
// item 3). The in-tree TLS route is the dl_open seam: this repo cannot
// import the registry package xiom.ssl, so this module dl_opens the
// SYSTEM libssl and drives the minimal session surface directly with
// fn-pointer casts -- the same discipline as the binding's ssl.xi,
// deliberately NOT a second xiom.ssl (no buffer/DER material, no chain
// or CA helpers, no memory BIOs, no SNI, no version/cipher/verify-result
// symbols; the packages binding has those).
//
// Candidate sonames (load order, the binding's list): libssl-3-x64.dll,
// libssl-1_1-x64.dll, libssl-1_1.dll, libssl.dll. With no candidate the
// loader is a clean Err(TLS_ERR_LOAD) and callers SKIP; a candidate that
// opens but misses an entry point is Err(TLS_ERR_ABI) (loud ABI
// mismatch, not a silent skip). On this box the live leg needs
// C:\Program Files\Git\mingw64\bin on PATH (the binding used exactly
// that path; its suite is the reference).
//
// Entry points (17): TLS_server_method, TLS_client_method, SSL_CTX_new,
// SSL_CTX_free, SSL_CTX_use_certificate_file, SSL_CTX_use_PrivateKey_file,
// SSL_new, SSL_free, SSL_set_fd, SSL_accept, SSL_connect, SSL_read,
// SSL_write, SSL_shutdown, SSL_get_error, SSL_CTX_set_alpn_protos,
// SSL_get0_alpn_selected.
//
// Session surface: load/close the library; server/client session open
// (context + session + fd attach + PEM cert/key load); step
// (SSL_accept/SSL_connect + SSL_get_error classified into the tls.xi
// taxonomy); read; write; shutdown; ALPN client set-list and negotiated
// read; free.
//
// Documented limitations (mirroring the binding):
//   - server-side ALPN SELECTION needs an SSL_CTX_set_alpn_select_cb C
//     callback (no callback bridging in the XIOM FFI), so a server here
//     negotiates ALPN "none" (alpn_selected == ""); use the pure policy
//     helper tls_alpn_select_server at the application layer;
//   - fatal handshake failures classify as TLS_ERR_HANDSHAKE; the verify
//     distinction needs SSL_get_verify_result, out of this minimal
//     surface (xiom.ssl binds it);
//   - read/write wait on WANT states with a bounded socket poll; fds
//     must be sockets.
//
// Classification: absent libssl -> TLS_ERR_LOAD (SKIP); missing entry
// point -> TLS_ERR_ABI; operational failures -> the tls.xi taxonomy
// kinds (CERT/ALPN/ARG/ALLOC/HANDSHAKE/IO/EOF/WANT_READ/WANT_WRITE).
//
// All unsafe/FFI lives in this module. Handles and resolved symbols are
// Ints; casts happen only at call sites (one call site per symbol);
// out-parameters are XIOM-owned byte slots read byte-indexed; the ALPN
// foreign buffer copies out through the ffi SafePtr bounds-checked
// reader.

module xiom.net.tls_libssl

use xiom.ffi.dl;
use xiom.ffi;
use xiom.net.socket;
use xiom.net.tls.TlsError;
use xiom.net.tls.TLS_ERR_LOAD;
use xiom.net.tls.TLS_ERR_ABI;
use xiom.net.tls.TLS_ERR_ARG;
use xiom.net.tls.TLS_ERR_ALLOC;
use xiom.net.tls.TLS_ERR_CERT;
use xiom.net.tls.TLS_ERR_ALPN;
use xiom.net.tls.TLS_ERR_HANDSHAKE;
use xiom.net.tls.TLS_ERR_IO;
use xiom.net.tls.TLS_ERR_EOF;
use xiom.net.tls.TLS_ERR_WANT_READ;
use xiom.net.tls.TLS_ERR_WANT_WRITE;
use xiom.net.tls.TLS_STEP_DONE;
use xiom.net.tls.TLS_STEP_WANT_READ;
use xiom.net.tls.TLS_STEP_WANT_WRITE;

// SSL_CTX_use_*_file file types (oracle: x509.h X509_FILETYPE_*).
const SSL_FILETYPE_PEM: Int = 1;

// SSL_get_error codes this module branches on (oracle: ssl.h).
const SSL_ERROR_WANT_READ: Int = 2;
const SSL_ERROR_WANT_WRITE: Int = 3;
const SSL_ERROR_ZERO_RETURN: Int = 6;

// Poll slice for the bounded internal WANT waits in read/write.
const TLS_LIBSSL_POLL_MS: Int = 25;

/// TlsLibssl is a loaded libssl: the module handle plus the resolved
/// session-surface entry points (17). Owned by the caller; release with
/// tls_libssl_close.
pub type TlsLibssl = {
  handle: Int;
  soname: Str;
  p_tls_server_method: Int;
  p_tls_client_method: Int;
  p_ctx_new: Int;
  p_ctx_free: Int;
  p_ctx_use_cert_file: Int;
  p_ctx_use_key_file: Int;
  p_new: Int;
  p_free: Int;
  p_set_fd: Int;
  p_accept: Int;
  p_connect: Int;
  p_read: Int;
  p_write: Int;
  p_shutdown: Int;
  p_get_error: Int;
  p_ctx_set_alpn_protos: Int;
  p_get0_alpn_selected: Int;
}

/// TlsLibSession is one libssl session: the SSL* handle, its owning
/// SSL_CTX and the attached fd. Owned by the caller; release with
/// tls_libssl_free (which frees the session AND its context).
pub type TlsLibSession = {
  ssl: Int;
  ctx: Int;
  fd: Int;
}

// =========================================================================
// Slot helpers (XIOM-owned out-buffers; byte-indexed reads)
// =========================================================================

/// n zero bytes in an XIOM-owned slot.
/// Complexity: O(n).
fn slot(n: Int) -> Vec[UInt8]
  requires: n > 0
  requires: n <= 65536
{
  Vec[UInt8].with_len(n)
}

/// Byte-indexed little-endian u64 read from an owned slot.
/// Complexity: O(1).
fn rd_u64_le(buf: &Vec[UInt8], off: Int) -> Int
  requires: off >= 0
  requires: off + 7 < buf.len()
{
  let b0 = buf[off] as Int;
  let b1 = buf[off + 1] as Int;
  let b2 = buf[off + 2] as Int;
  let b3 = buf[off + 3] as Int;
  let b4 = buf[off + 4] as Int;
  let b5 = buf[off + 5] as Int;
  let b6 = buf[off + 6] as Int;
  let b7 = buf[off + 7] as Int;
  b0 | (b1 << 8) | (b2 << 16) | (b3 << 24) | (b4 << 32) | (b5 << 40) | (b6 << 48) | (b7 << 56)
}

/// Byte-indexed little-endian u32 read from an owned slot.
/// Complexity: O(1).
fn rd_u32_le(buf: &Vec[UInt8], off: Int) -> Int
  requires: off >= 0
  requires: off + 3 < buf.len()
{
  let b0 = buf[off] as Int;
  let b1 = buf[off + 1] as Int;
  let b2 = buf[off + 2] as Int;
  let b3 = buf[off + 3] as Int;
  b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)
}

// =========================================================================
// Loader (multi-soname)
// =========================================================================

// fail_load closes a handle and reports an ABI-class load failure.
fn fail_load(handle: Int, message: Str) -> Result[TlsLibssl, TlsError]
  requires: message.len() > 0
{
  let ig = dl.dl_close(handle);
  let _ = ig;
  Err(TlsError{ kind: TLS_ERR_ABI; message: message })
}

// sym_or resolves one entry point by exact name.
fn sym_or(handle: Int, name: Str) -> Result[Int, Str]
  requires: handle != 0
  requires: name.len() > 0
{
  let a = dl.dl_sym(handle, name);
  if !a.is_ok {
    return Err("tls_libssl: missing entry point: " + name);
  }
  Ok(a.value)
}

fn try_load(soname: Str) -> Result[TlsLibssl, TlsError]
  requires: soname.len() > 0
{
  let h = dl.dl_open(soname);
  if !h.is_ok {
    // Not this candidate: report ABSENT so the caller can try the next.
    return Err(TlsError{ kind: TLS_ERR_LOAD; message: h.error });
  }
  let handle: Int = h.value;

  let n01 = sym_or(handle, "TLS_server_method");
  if !n01.is_ok { return fail_load(handle, n01.error); }
  let n02 = sym_or(handle, "TLS_client_method");
  if !n02.is_ok { return fail_load(handle, n02.error); }
  let n03 = sym_or(handle, "SSL_CTX_new");
  if !n03.is_ok { return fail_load(handle, n03.error); }
  let n04 = sym_or(handle, "SSL_CTX_free");
  if !n04.is_ok { return fail_load(handle, n04.error); }
  let n05 = sym_or(handle, "SSL_CTX_use_certificate_file");
  if !n05.is_ok { return fail_load(handle, n05.error); }
  let n06 = sym_or(handle, "SSL_CTX_use_PrivateKey_file");
  if !n06.is_ok { return fail_load(handle, n06.error); }
  let n07 = sym_or(handle, "SSL_new");
  if !n07.is_ok { return fail_load(handle, n07.error); }
  let n08 = sym_or(handle, "SSL_free");
  if !n08.is_ok { return fail_load(handle, n08.error); }
  let n09 = sym_or(handle, "SSL_set_fd");
  if !n09.is_ok { return fail_load(handle, n09.error); }
  let n10 = sym_or(handle, "SSL_accept");
  if !n10.is_ok { return fail_load(handle, n10.error); }
  let n11 = sym_or(handle, "SSL_connect");
  if !n11.is_ok { return fail_load(handle, n11.error); }
  let n12 = sym_or(handle, "SSL_read");
  if !n12.is_ok { return fail_load(handle, n12.error); }
  let n13 = sym_or(handle, "SSL_write");
  if !n13.is_ok { return fail_load(handle, n13.error); }
  let n14 = sym_or(handle, "SSL_shutdown");
  if !n14.is_ok { return fail_load(handle, n14.error); }
  let n15 = sym_or(handle, "SSL_get_error");
  if !n15.is_ok { return fail_load(handle, n15.error); }
  let n16 = sym_or(handle, "SSL_CTX_set_alpn_protos");
  if !n16.is_ok { return fail_load(handle, n16.error); }
  let n17 = sym_or(handle, "SSL_get0_alpn_selected");
  if !n17.is_ok { return fail_load(handle, n17.error); }

  Ok(TlsLibssl{
    handle: handle;
    soname: soname;
    p_tls_server_method: n01.value;
    p_tls_client_method: n02.value;
    p_ctx_new: n03.value;
    p_ctx_free: n04.value;
    p_ctx_use_cert_file: n05.value;
    p_ctx_use_key_file: n06.value;
    p_new: n07.value;
    p_free: n08.value;
    p_set_fd: n09.value;
    p_accept: n10.value;
    p_connect: n11.value;
    p_read: n12.value;
    p_write: n13.value;
    p_shutdown: n14.value;
    p_get_error: n15.value;
    p_ctx_set_alpn_protos: n16.value;
    p_get0_alpn_selected: n17.value;
  })
}

/// tls_libssl_load loads the first available system libssl from the
/// candidate sonames (libssl-3-x64.dll, libssl-1_1-x64.dll,
/// libssl-1_1.dll, libssl.dll). An unopenable candidate moves to the
/// next; a candidate that opens but misses an entry point reports
/// Err(TLS_ERR_ABI) immediately (a loud ABI mismatch must not be masked
/// by falling through to another soname).
/// Returns: Ok(library); Err(TLS_ERR_LOAD) when no candidate loaded.
/// Complexity: O(candidates * entry points).
pub fn tls_libssl_load() -> Result[TlsLibssl, TlsError]
  ensures: true
{
  let c1 = try_load("libssl-3-x64.dll");
  if c1.is_ok { return Ok(c1.value); }
  if c1.error.kind == TLS_ERR_ABI { return Err(c1.error); }

  let c2 = try_load("libssl-1_1-x64.dll");
  if c2.is_ok { return Ok(c2.value); }
  if c2.error.kind == TLS_ERR_ABI { return Err(c2.error); }

  let c3 = try_load("libssl-1_1.dll");
  if c3.is_ok { return Ok(c3.value); }
  if c3.error.kind == TLS_ERR_ABI { return Err(c3.error); }

  let c4 = try_load("libssl.dll");
  if c4.is_ok { return Ok(c4.value); }
  if c4.error.kind == TLS_ERR_ABI { return Err(c4.error); }

  Err(TlsError{
    kind: TLS_ERR_LOAD;
    message: "tls_libssl_load: no libssl candidate found (tried libssl-3-x64.dll, libssl-1_1-x64.dll, libssl-1_1.dll, libssl.dll)",
  })
}

/// tls_libssl_load_named loads an explicitly named libssl build (a bogus
/// name exercises the absent/LOAD classification deterministically on
/// any host).
/// Returns: Ok(library); Err(TLS_ERR_LOAD) when the name does not open.
/// Complexity: O(entry points).
pub fn tls_libssl_load_named(soname: Str) -> Result[TlsLibssl, TlsError]
  ensures: (soname.len() == 0) => (result.is_err == true)
{
  if soname.len() == 0 {
    return Err(TlsError{ kind: TLS_ERR_LOAD; message: "tls_libssl_load_named: empty soname" });
  }
  try_load(soname)
}

/// tls_libssl_available reports whether any candidate soname opens and
/// exports every entry point. The library is closed before returning.
/// Returns: true only when a full candidate is present.
/// Complexity: O(candidates * entry points).
pub fn tls_libssl_available() -> Bool
  requires: true
{
  let c1 = try_load("libssl-3-x64.dll");
  if c1.is_ok {
    let cl = dl.dl_close(c1.value.handle);
    let _ = cl;
    return true;
  }
  if c1.error.kind == TLS_ERR_ABI { return false; }
  let c2 = try_load("libssl-1_1-x64.dll");
  if c2.is_ok {
    let cl = dl.dl_close(c2.value.handle);
    let _ = cl;
    return true;
  }
  if c2.error.kind == TLS_ERR_ABI { return false; }
  let c3 = try_load("libssl-1_1.dll");
  if c3.is_ok {
    let cl = dl.dl_close(c3.value.handle);
    let _ = cl;
    return true;
  }
  if c3.error.kind == TLS_ERR_ABI { return false; }
  let c4 = try_load("libssl.dll");
  if c4.is_ok {
    let cl = dl.dl_close(c4.value.handle);
    let _ = cl;
    return true;
  }
  false
}

/// tls_libssl_close releases the library handle.
/// Returns: Ok(()) once closed; Err with the loader error if the handle
///          cannot be released.
/// Complexity: O(1).
pub fn tls_libssl_close(lib: &TlsLibssl) -> Result[Unit, Str]
  requires: lib.handle != 0
{
  let rc = dl.dl_close(lib.handle);
  if !rc.is_ok {
    return Err("tls_libssl_close: " + rc.error);
  }
  Ok(())
}

// lib_is_loaded reports whether every entry point in a library value is
// non-zero. A hand-built or zeroed TlsLibssl is not callable.
fn lib_is_loaded(lib: &TlsLibssl) -> Bool {
  if lib.handle == 0 { return false; }
  if lib.p_tls_server_method == 0 { return false; }
  if lib.p_tls_client_method == 0 { return false; }
  if lib.p_ctx_new == 0 { return false; }
  if lib.p_ctx_free == 0 { return false; }
  if lib.p_ctx_use_cert_file == 0 { return false; }
  if lib.p_ctx_use_key_file == 0 { return false; }
  if lib.p_new == 0 { return false; }
  if lib.p_free == 0 { return false; }
  if lib.p_set_fd == 0 { return false; }
  if lib.p_accept == 0 { return false; }
  if lib.p_connect == 0 { return false; }
  if lib.p_read == 0 { return false; }
  if lib.p_write == 0 { return false; }
  if lib.p_shutdown == 0 { return false; }
  if lib.p_get_error == 0 { return false; }
  if lib.p_ctx_set_alpn_protos == 0 { return false; }
  if lib.p_get0_alpn_selected == 0 { return false; }
  true
}

// ctx_release frees a context if it is live (failure-path cleanup).
fn ctx_release(lib: &TlsLibssl, ctx: Int) {
  if ctx == 0 { return; }
  unsafe {
    let f = lib.p_ctx_free as fn(Int) -> Unit;
    f(ctx);
  }
}

// ssl_release frees a session if it is live (failure-path cleanup).
fn ssl_release(lib: &TlsLibssl, ssl: Int) {
  if ssl == 0 { return; }
  unsafe {
    let f = lib.p_free as fn(Int) -> Unit;
    f(ssl);
  }
}

// =========================================================================
// ALPN helpers
// =========================================================================

/// tls_libssl_alpn_client_wire builds the client ALPN protocol list in
/// the format SSL_CTX_set_alpn_protos expects: one 1-byte-length-prefixed
/// name each, names 1..255 bytes, at most 65535 bytes total, WITHOUT the
/// RFC 7301 ProtocolNameList 2-byte outer length (the TLS stack adds that
/// outside the extension data; the binding's live suite locks this format
/// against OpenSSL 3.2.4). Use tls.alpn_encode when you need the
/// on-the-wire extension format instead.
/// Returns: Ok(wire bytes); Err on an empty list, empty/oversized name,
///          or an oversized total.
/// Complexity: O(total bytes). Pure.
pub fn tls_libssl_alpn_client_wire(names: &Vec[Str]) -> Result[Vec[UInt8], Str]
  ensures: names.len() == 0 => result.is_err == true
{
  if names.len() == 0 {
    return Err("tls_libssl_alpn_client_wire: empty protocol list");
  }
  var out: Vec[UInt8] = Vec[UInt8].new();
  var total = 0;
  var i = 0;
  while i < names.len() {
    let nm = names[i];
    if nm.len() == 0 {
      return Err("tls_libssl_alpn_client_wire: empty protocol name");
    }
    if nm.len() > 255 {
      return Err("tls_libssl_alpn_client_wire: protocol name longer than 255 bytes");
    }
    total = total + 1 + nm.len();
    if total > 65535 {
      return Err("tls_libssl_alpn_client_wire: protocol list longer than 65535 bytes");
    }
    out.push(nm.len() as UInt8);
    var j = 0;
    while j < nm.len() {
      out.push(nm.byte_at(j));
      j = j + 1;
    }
    i = i + 1;
  }
  Ok(out)
}

// =========================================================================
// Session operations
// =========================================================================

/// tls_libssl_server_session creates a server session on a connected fd:
/// TLS_server_method + SSL_CTX_new, PEM cert/key load from files
/// (SSL_CTX_use_certificate_file / SSL_CTX_use_PrivateKey_file,
/// X509_FILETYPE_PEM), SSL_new and SSL_set_fd. On any failure the
/// partially built context/session is released before returning.
/// Returns: Ok(session); Err(TLS_ERR_ARG) on a bad fd/empty path,
///          Err(TLS_ERR_ALLOC) when allocation fails, Err(TLS_ERR_CERT)
///          when the material is rejected, Err(TLS_ERR_IO) when the fd
///          cannot be attached; Err(TLS_ERR_LOAD) for an unloaded value.
/// Complexity: O(file size).
pub fn tls_libssl_server_session(lib: &TlsLibssl, fd: Int, cert_path: Str, key_path: Str) -> Result[TlsLibSession, TlsError]
  ensures: (fd < 0) => (result.is_err == true)
  ensures: (cert_path.len() == 0) => (result.is_err == true)
  ensures: (key_path.len() == 0) => (result.is_err == true)
{
  if !lib_is_loaded(lib) {
    return Err(TlsError{ kind: TLS_ERR_LOAD; message: "tls_libssl_server_session: library is not loaded" });
  }
  if fd < 0 {
    return Err(TlsError{ kind: TLS_ERR_ARG; message: "tls_libssl_server_session: invalid fd" });
  }
  if cert_path.len() == 0 {
    return Err(TlsError{ kind: TLS_ERR_ARG; message: "tls_libssl_server_session: empty certificate path" });
  }
  if key_path.len() == 0 {
    return Err(TlsError{ kind: TLS_ERR_ARG; message: "tls_libssl_server_session: empty key path" });
  }
  unsafe {
    let fm = lib.p_tls_server_method as fn() -> Int;
    let method = fm();
    if method == 0 {
      return Err(TlsError{ kind: TLS_ERR_ALLOC; message: "tls_libssl_server_session: TLS_server_method unavailable" });
    }
    let fn_ctx = lib.p_ctx_new as fn(Int) -> Int;
    let ctx = fn_ctx(method);
    if ctx == 0 {
      return Err(TlsError{ kind: TLS_ERR_ALLOC; message: "tls_libssl_server_session: SSL_CTX_new failed" });
    }
    let fc = lib.p_ctx_use_cert_file as fn(Int, *UInt8, Int) -> Int32;
    let rc1 = fc(ctx, cert_path.c_str(), SSL_FILETYPE_PEM) as Int;
    if rc1 != 1 {
      ctx_release(lib, ctx);
      return Err(TlsError{ kind: TLS_ERR_CERT; message: "tls_libssl_server_session: load certificate PEM file failed: " + cert_path });
    }
    let fk = lib.p_ctx_use_key_file as fn(Int, *UInt8, Int) -> Int32;
    let rc2 = fk(ctx, key_path.c_str(), SSL_FILETYPE_PEM) as Int;
    if rc2 != 1 {
      ctx_release(lib, ctx);
      return Err(TlsError{ kind: TLS_ERR_CERT; message: "tls_libssl_server_session: load private key PEM file failed: " + key_path });
    }
    let fn_new = lib.p_new as fn(Int) -> Int;
    let ssl = fn_new(ctx);
    if ssl == 0 {
      ctx_release(lib, ctx);
      return Err(TlsError{ kind: TLS_ERR_ALLOC; message: "tls_libssl_server_session: SSL_new failed" });
    }
    let fsf = lib.p_set_fd as fn(Int, Int) -> Int32;
    let rc3 = fsf(ssl, fd) as Int;
    if rc3 != 1 {
      ssl_release(lib, ssl);
      ctx_release(lib, ctx);
      return Err(TlsError{ kind: TLS_ERR_IO; message: "tls_libssl_server_session: SSL_set_fd failed" });
    }
    Ok(TlsLibSession{ ssl: ssl; ctx: ctx; fd: fd })
  }
}

/// tls_libssl_client_session creates a client session on a connected fd:
/// TLS_client_method + SSL_CTX_new, optional ALPN client list (set on the
/// context BEFORE SSL_new -- SSL_new copies the list to the session),
/// SSL_new and SSL_set_fd. On any failure the partially built
/// context/session is released before returning. No SNI host name is set
/// (out of the minimal entry-point set; xiom.ssl binds SSL_ctrl for it).
/// Returns: Ok(session); Err(TLS_ERR_ARG) on a bad fd, Err
///          (TLS_ERR_ALLOC) when allocation fails, Err(TLS_ERR_ALPN) when
///          the build rejects the ALPN list, Err(TLS_ERR_IO) when the fd
///          cannot be attached.
/// Complexity: O(ALPN list).
pub fn tls_libssl_client_session(lib: &TlsLibssl, fd: Int, alpn: &Vec[Str]) -> Result[TlsLibSession, TlsError]
  ensures: (fd < 0) => (result.is_err == true)
{
  if !lib_is_loaded(lib) {
    return Err(TlsError{ kind: TLS_ERR_LOAD; message: "tls_libssl_client_session: library is not loaded" });
  }
  if fd < 0 {
    return Err(TlsError{ kind: TLS_ERR_ARG; message: "tls_libssl_client_session: invalid fd" });
  }
  unsafe {
    let fm = lib.p_tls_client_method as fn() -> Int;
    let method = fm();
    if method == 0 {
      return Err(TlsError{ kind: TLS_ERR_ALLOC; message: "tls_libssl_client_session: TLS_client_method unavailable" });
    }
    let fn_ctx = lib.p_ctx_new as fn(Int) -> Int;
    let ctx = fn_ctx(method);
    if ctx == 0 {
      return Err(TlsError{ kind: TLS_ERR_ALLOC; message: "tls_libssl_client_session: SSL_CTX_new failed" });
    }
    if alpn.len() > 0 {
      let wire_r = tls_libssl_alpn_client_wire(alpn);
      if !wire_r.is_ok {
        ctx_release(lib, ctx);
        return Err(TlsError{ kind: TLS_ERR_ALPN; message: "tls_libssl_client_session: " + wire_r.error });
      }
      let wire: Vec[UInt8] = wire_r.value;
      let fa = lib.p_ctx_set_alpn_protos as fn(Int, *UInt8, Int) -> Int32;
      let ar = fa(ctx, &wire[0] as *UInt8, wire.len()) as Int;
      if ar != 0 {
        ctx_release(lib, ctx);
        return Err(TlsError{ kind: TLS_ERR_ALPN; message: "tls_libssl_client_session: set ALPN protocols failed (rc " + ar.to_str() + ")" });
      }
    }
    let fn_new = lib.p_new as fn(Int) -> Int;
    let ssl = fn_new(ctx);
    if ssl == 0 {
      ctx_release(lib, ctx);
      return Err(TlsError{ kind: TLS_ERR_ALLOC; message: "tls_libssl_client_session: SSL_new failed" });
    }
    let fsf = lib.p_set_fd as fn(Int, Int) -> Int32;
    let rc = fsf(ssl, fd) as Int;
    if rc != 1 {
      ssl_release(lib, ssl);
      ctx_release(lib, ctx);
      return Err(TlsError{ kind: TLS_ERR_IO; message: "tls_libssl_client_session: SSL_set_fd failed" });
    }
    Ok(TlsLibSession{ ssl: ssl; ctx: ctx; fd: fd })
  }
}

/// tls_libssl_step advances the handshake one step (SSL_accept for
/// server == true, SSL_connect otherwise) and classifies SSL_get_error
/// into the tls.xi taxonomy.
/// Returns: Ok(TLS_STEP_DONE) when the handshake completed;
///          Ok(TLS_STEP_WANT_READ/WRITE) when the caller must wait for fd
///          readiness first (tls_wait_readable / tls_wait_writable) and
///          call again; Err(TLS_ERR_HANDSHAKE) on a fatal failure
///          (including a peer close mid-handshake).
/// Complexity: O(handshake progress).
pub fn tls_libssl_step(lib: &TlsLibssl, sess: &TlsLibSession, server: Bool) -> Result[Int, TlsError]
  ensures: (sess.ssl <= 0) => (result.is_err == true)
{
  if !lib_is_loaded(lib) {
    return Err(TlsError{ kind: TLS_ERR_LOAD; message: "tls_libssl_step: library is not loaded" });
  }
  if sess.ssl <= 0 {
    return Err(TlsError{ kind: TLS_ERR_ARG; message: "tls_libssl_step: session is not open" });
  }
  unsafe {
    var rc: Int = 0;
    if server {
      let f = lib.p_accept as fn(Int) -> Int32;
      rc = f(sess.ssl) as Int;
    } else {
      let f = lib.p_connect as fn(Int) -> Int32;
      rc = f(sess.ssl) as Int;
    }
    if rc == 1 {
      return Ok(TLS_STEP_DONE);
    }
    let fe = lib.p_get_error as fn(Int, Int) -> Int32;
    let err = fe(sess.ssl, rc as Int32) as Int;
    if err == SSL_ERROR_WANT_READ {
      return Ok(TLS_STEP_WANT_READ);
    }
    if err == SSL_ERROR_WANT_WRITE {
      return Ok(TLS_STEP_WANT_WRITE);
    }
    if err == SSL_ERROR_ZERO_RETURN {
      return Err(TlsError{ kind: TLS_ERR_HANDSHAKE; message: "tls_libssl_step: peer closed the connection mid-handshake" });
    }
    Err(TlsError{ kind: TLS_ERR_HANDSHAKE; message: "tls_libssl_step: handshake failed (ssl_error " + err.to_str() + ")" })
  }
}

/// tls_libssl_read reads up to max plaintext bytes. On a WANT state the
/// call waits on the attached socket with a bounded poll and retries.
/// Returns: Ok(bytes) with bytes.len() >= 1; Err(TLS_ERR_EOF) on a clean
///          close_notify; Err(TLS_ERR_IO) on a fatal failure; Err
///          (TLS_ERR_WANT_READ) when the bounded wait timed out.
/// Complexity: O(max + wait).
pub fn tls_libssl_read(lib: &TlsLibssl, sess: &TlsLibSession, max: Int) -> Result[Vec[UInt8], TlsError]
  ensures: (max <= 0) => (result.is_err == true)
  ensures: (max > 65536) => (result.is_err == true)
  ensures: (sess.ssl <= 0) => (result.is_err == true)
{
  if !lib_is_loaded(lib) {
    return Err(TlsError{ kind: TLS_ERR_LOAD; message: "tls_libssl_read: library is not loaded" });
  }
  if sess.ssl <= 0 {
    return Err(TlsError{ kind: TLS_ERR_ARG; message: "tls_libssl_read: session is not open" });
  }
  if max <= 0 || max > 65536 {
    return Err(TlsError{ kind: TLS_ERR_ARG; message: "tls_libssl_read: max outside 1..65536" });
  }
  unsafe {
    var buf = slot(max);
    let f = lib.p_read as fn(Int, *UInt8, Int) -> Int32;
    let fe = lib.p_get_error as fn(Int, Int) -> Int32;
    var i = 0;
    while i < 4000 {
      let rc = f(sess.ssl, buf.as_mut_ptr(), max) as Int;
      if rc > 0 {
        if rc > max {
          return Err(TlsError{ kind: TLS_ERR_IO; message: "tls_libssl_read: over-reported the byte count" });
        }
        var out: Vec[UInt8] = Vec[UInt8].new();
        var j = 0;
        while j < rc {
          out.push(buf[j]);
          j = j + 1;
        }
        return Ok(out);
      }
      let err = fe(sess.ssl, rc as Int32) as Int;
      if err == SSL_ERROR_ZERO_RETURN {
        return Err(TlsError{ kind: TLS_ERR_EOF; message: "tls_libssl_read: peer closed the connection (close_notify)" });
      }
      if err == SSL_ERROR_WANT_READ {
        if sess.fd < 0 {
          return Err(TlsError{ kind: TLS_ERR_WANT_READ; message: "tls_libssl_read: no fd attached to wait on" });
        }
        var fds: Vec[Int] = Vec[Int].new();
        fds.push(sess.fd);
        let pr = socket.socket_poll_read(&fds, TLS_LIBSSL_POLL_MS);
        let _ = pr;
      } elif err == SSL_ERROR_WANT_WRITE {
        if sess.fd < 0 {
          return Err(TlsError{ kind: TLS_ERR_WANT_WRITE; message: "tls_libssl_read: no fd attached to wait on" });
        }
        var wfds: Vec[Int] = Vec[Int].new();
        wfds.push(sess.fd);
        let pw = socket.socket_poll_write(&wfds, TLS_LIBSSL_POLL_MS);
        let _ = pw;
      } else {
        return Err(TlsError{ kind: TLS_ERR_IO; message: "tls_libssl_read: read failed (ssl_error " + err.to_str() + ")" });
      }
      i = i + 1;
    }
    Err(TlsError{ kind: TLS_ERR_WANT_READ; message: "tls_libssl_read: timed out waiting for data" })
  }
}

/// tls_libssl_write writes every byte of data, retrying partial writes
/// and waiting on WANT states with a bounded socket poll.
/// Returns: Ok(data.len()) when the whole payload was written; Err
///          (TLS_ERR_IO) on a fatal failure or when the bounded wait
///          runs out; Err(TLS_ERR_ARG) on a bad handle.
/// Complexity: O(len + wait).
pub fn tls_libssl_write(lib: &TlsLibssl, sess: &TlsLibSession, data: &Vec[UInt8]) -> Result[Int, TlsError]
  ensures: (data.len() == 0) => (result.is_ok == true)
  ensures: (sess.ssl <= 0) => (result.is_err == true)
{
  if !lib_is_loaded(lib) {
    return Err(TlsError{ kind: TLS_ERR_LOAD; message: "tls_libssl_write: library is not loaded" });
  }
  if sess.ssl <= 0 {
    return Err(TlsError{ kind: TLS_ERR_ARG; message: "tls_libssl_write: session is not open" });
  }
  let n = data.len();
  if n == 0 {
    return Ok(0);
  }
  unsafe {
    let f = lib.p_write as fn(Int, *UInt8, Int) -> Int32;
    let fe = lib.p_get_error as fn(Int, Int) -> Int32;
    let base = &data[0] as *UInt8;
    var total = 0;
    var i = 0;
    while i < 8000 {
      if total == n {
        return Ok(total);
      }
      let rc = f(sess.ssl, base, n - total) as Int;
      if rc > 0 {
        total = total + rc;
        continue;
      }
      let err = fe(sess.ssl, rc as Int32) as Int;
      if err == SSL_ERROR_WANT_READ {
        if sess.fd < 0 {
          return Err(TlsError{ kind: TLS_ERR_WANT_READ; message: "tls_libssl_write: no fd attached to wait on" });
        }
        var fds: Vec[Int] = Vec[Int].new();
        fds.push(sess.fd);
        let pr = socket.socket_poll_read(&fds, TLS_LIBSSL_POLL_MS);
        let _ = pr;
      } elif err == SSL_ERROR_WANT_WRITE {
        if sess.fd < 0 {
          return Err(TlsError{ kind: TLS_ERR_WANT_WRITE; message: "tls_libssl_write: no fd attached to wait on" });
        }
        var wfds: Vec[Int] = Vec[Int].new();
        wfds.push(sess.fd);
        let pw = socket.socket_poll_write(&wfds, TLS_LIBSSL_POLL_MS);
        let _ = pw;
      } else {
        return Err(TlsError{ kind: TLS_ERR_IO; message: "tls_libssl_write: write failed (ssl_error " + err.to_str() + ")" });
      }
      i = i + 1;
    }
    Err(TlsError{ kind: TLS_ERR_IO; message: "tls_libssl_write: timed out with " + (n - total).to_str() + " bytes pending" })
  }
}

/// tls_libssl_shutdown runs one SSL_shutdown step.
/// Returns: Ok(0) when this side's close_notify was sent and the peer's
///          is pending; Ok(1) when the shutdown is complete; Err
///          (TLS_ERR_WANT_READ/WRITE) when the caller should wait for fd
///          readiness and call again; Err(TLS_ERR_IO) on a fatal failure.
/// Complexity: O(1).
pub fn tls_libssl_shutdown(lib: &TlsLibssl, sess: &TlsLibSession) -> Result[Int, TlsError]
  ensures: (sess.ssl <= 0) => (result.is_err == true)
{
  if !lib_is_loaded(lib) {
    return Err(TlsError{ kind: TLS_ERR_LOAD; message: "tls_libssl_shutdown: library is not loaded" });
  }
  if sess.ssl <= 0 {
    return Err(TlsError{ kind: TLS_ERR_ARG; message: "tls_libssl_shutdown: session is not open" });
  }
  unsafe {
    let f = lib.p_shutdown as fn(Int) -> Int32;
    let rc = f(sess.ssl) as Int;
    if rc >= 0 {
      return Ok(rc);
    }
    let fe = lib.p_get_error as fn(Int, Int) -> Int32;
    let err = fe(sess.ssl, rc as Int32) as Int;
    if err == SSL_ERROR_WANT_READ {
      return Err(TlsError{ kind: TLS_ERR_WANT_READ; message: "tls_libssl_shutdown: waiting for the peer's close_notify" });
    }
    if err == SSL_ERROR_WANT_WRITE {
      return Err(TlsError{ kind: TLS_ERR_WANT_WRITE; message: "tls_libssl_shutdown: retry when writable" });
    }
    if err == SSL_ERROR_ZERO_RETURN {
      return Ok(1);
    }
    Err(TlsError{ kind: TLS_ERR_IO; message: "tls_libssl_shutdown: shutdown failed (ssl_error " + err.to_str() + ")" })
  }
}

/// tls_libssl_alpn_selected reports the negotiated ALPN protocol of the
/// session ("" when none was selected -- a server without a select
/// callback negotiates none; see tls_alpn_select_server for the
/// application-layer policy). The length comes from OpenSSL's
/// out-parameter slots; the bytes copy out through the ffi SafePtr
/// bounds-checked reader.
/// Returns: Ok(name); Err(TLS_ERR_IO) when the report cannot be read.
/// Complexity: O(name length).
pub fn tls_libssl_alpn_selected(lib: &TlsLibssl, sess: &TlsLibSession) -> Result[Str, TlsError]
  ensures: (sess.ssl <= 0) => (result.is_err == true)
{
  if !lib_is_loaded(lib) {
    return Err(TlsError{ kind: TLS_ERR_LOAD; message: "tls_libssl_alpn_selected: library is not loaded" });
  }
  if sess.ssl <= 0 {
    return Err(TlsError{ kind: TLS_ERR_ARG; message: "tls_libssl_alpn_selected: session is not open" });
  }
  unsafe {
    var data_slot = slot(8);
    var len_slot = slot(8);
    let f = lib.p_get0_alpn_selected as fn(Int, *UInt8, *UInt8) -> Unit;
    f(sess.ssl, data_slot.as_mut_ptr(), len_slot.as_mut_ptr());
    let p = rd_u64_le(&data_slot, 0);
    let n = rd_u32_le(&len_slot, 0);
    if p == 0 || n == 0 {
      return Ok("");
    }
    if n > 255 {
      return Err(TlsError{ kind: TLS_ERR_IO; message: "tls_libssl_alpn_selected: name length out of range" });
    }
    let sp = ffi.safe_ptr_from_raw(p as *UInt8, n);
    if !sp.is_ok {
      return Err(TlsError{ kind: TLS_ERR_IO; message: "tls_libssl_alpn_selected: " + sp.error });
    }
    let spv = sp.value;
    var bytes: Vec[UInt8] = Vec[UInt8].new();
    var i = 0;
    while i < n {
      let rb = ffi.safe_ptr_read_byte(&spv, i);
      if !rb.is_ok {
        return Err(TlsError{ kind: TLS_ERR_IO; message: "tls_libssl_alpn_selected: " + rb.error });
      }
      bytes.push(rb.value as UInt8);
      i = i + 1;
    }
    Ok(Str::from_utf8(bytes))
  }
}

/// tls_libssl_free releases the session and its owning context (SSL_free
/// then SSL_CTX_free). A zeroed/closed session value is a clean no-op;
/// the caller must not reuse the session after this.
/// Complexity: O(1).
pub fn tls_libssl_free(lib: &TlsLibssl, sess: &TlsLibSession)
  requires: true
{
  if !lib_is_loaded(lib) {
    return;
  }
  if sess.ssl != 0 {
    ssl_release(lib, sess.ssl);
  }
  if sess.ctx != 0 {
    ctx_release(lib, sess.ctx);
  }
}
